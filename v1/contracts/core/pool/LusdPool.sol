pragma solidity >=0.4.21 <0.6.0;

import "../../utils/Ownable.sol";
import "../IPool.sol";
import "../../utils/TokenClaimer.sol";
import "../../erc20/IERC20.sol";
import "./IPoolBase.sol";

contract CurveInterfaceLusd{
  function add_liquidity(address _pool, uint256[4] memory _deposit_amounts, uint256 _min_mint_amount) public returns(uint256);
  function remove_liquidity_one_coin(address _pool, uint256 _burn_amount, int128 i, uint256 _min_amount) public returns(uint256);
}

contract CRVGaugeInterfaceERC20_lusd{
  function deposit(uint256 _value) public;
  function withdraw(uint256 _value) public;
  function claim_rewards(address _address) public;
}


contract LusdPool is ICurvePool, TokenClaimer, Ownable{
  address public usdc;
  address public extra_token_addr;
  address public lp_token_addr;
  address public crv_token_addr;

  address public controller;
  address public vault;

  CRVGaugeInterfaceERC20_lusd public crv_gauge_addr;
  MinterInterfaceERC20 public crv_minter_addr;
  
  CurveInterfaceLusd public pool_deposit;
  address public meta_pool_addr;

  uint256 public lp_balance;
  uint256 public deposit_usdc_amount;
  uint256 public withdraw_usdc_amount;

  modifier onlyController(){
    require((controller == msg.sender)||(vault == msg.sender), "only controller or vault can call this");
    _;
  }

  constructor() public{
    name = "Lusd";

    usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    extra_token_addr = address(0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D); //lqty

    crv_token_addr = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    crv_minter_addr = MinterInterfaceERC20(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    crv_gauge_addr = CRVGaugeInterfaceERC20_lusd(0x9B8519A9a00100720CCdC8a120fBeD319cA47a14);
    pool_deposit = CurveInterfaceLusd(0xA79828DF1850E8a3A3064576f380D90aECDD3359);
    meta_pool_addr = address(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA);
    lp_token_addr = address(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA);
  }

  //@_amount: USDC amount
  function deposit(uint256 _amount) public{
    deposit_usdc_amount = deposit_usdc_amount + _amount;
    deposit_usdc(_amount);
    uint256 cur = IERC20(lp_token_addr).balanceOf(address(this));
    lp_balance = lp_balance + cur;
    deposit_to_gauge();
  }

  //@_amount: USDC amount
  function deposit_usdc(uint256 _amount) internal {
    IERC20(usdc).transferFrom(msg.sender, address(this), _amount);
    IERC20(usdc).approve(address(pool_deposit), 0);
    IERC20(usdc).approve(address(pool_deposit), _amount);
    uint256[4] memory uamounts = [0,0, _amount, 0];
    pool_deposit.add_liquidity(
        meta_pool_addr,
        uamounts, 
        0
    );
  }

  //deposit all lp token to gauage to mine CRV
  function deposit_to_gauge() internal {
    IERC20(lp_token_addr).approve(address(crv_gauge_addr), 0);
    uint256 cur = IERC20(lp_token_addr).balanceOf(address(this));
    IERC20(lp_token_addr).approve(address(crv_gauge_addr), cur);
    crv_gauge_addr.deposit(cur);
    require(IERC20(lp_token_addr).balanceOf(address(this)) == 0, "deposit_to_gauge: unexpected exchanges");
  }

  //@_amount: lp token amount
  function withdraw(uint256 _amount) public onlyController{
    withdraw_from_gauge(_amount);
    withdraw_from_curve(_amount);
    lp_balance = lp_balance - _amount;
    IERC20(usdc).transfer(msg.sender, IERC20(usdc).balanceOf(address(this)));
  }

  function withdraw_from_gauge(uint256 _amount) internal{
    require(_amount <= lp_balance, "withdraw_from_gauge: insufficient amount");
    crv_gauge_addr.withdraw(_amount);
  }

  function withdraw_from_curve(uint256 _amount) internal {
    require(_amount <= get_lp_token_balance(), "withdraw_from_curve: too large amount");
    IERC20(lp_token_addr).approve(address(pool_deposit), _amount);
    pool_deposit.remove_liquidity_one_coin(
        meta_pool_addr,
        _amount,
        2,
        0
    );
  }

  function earn_crv() public onlyController{
    require(crv_minter_addr != MinterInterfaceERC20(0x0), "no crv minter");
    crv_minter_addr.mint(address(crv_gauge_addr));
    IERC20(crv_token_addr).transfer(msg.sender, IERC20(crv_token_addr).balanceOf(address(this)));
    if (extra_token_addr != address(0x0)) {
      crv_gauge_addr.claim_rewards(address(this));
      IERC20(extra_token_addr).transfer(msg.sender, IERC20(extra_token_addr).balanceOf(address(this)));
    }
  }

  function setController(address _controller, address _vault) public onlyOwner{
    controller = _controller;
    vault = _vault;
  }
  function claimStdToken(address _token, address payable to) public onlyOwner{
    _claimStdTokens(_token, to);
  }
  function get_lp_token_balance() public view returns(uint256){
    return lp_balance;
  }
  function get_lp_token_addr() public view returns(address){
    return lp_token_addr;
  }
  function get_virtual_price() public view returns(uint256) {
    return PriceInterfaceERC20(address(meta_pool_addr)).get_virtual_price();
  }
}
