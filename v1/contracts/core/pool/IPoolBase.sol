pragma solidity >=0.4.21 <0.6.0;
import "../../utils/Ownable.sol";
import "../IPool.sol";
import "../../utils/TokenClaimer.sol";
import "../../erc20/IERC20.sol";


contract PriceInterfaceERC20{
  function get_virtual_price() public view returns(uint256);
  //function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) public;
  //function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) public;
}

contract CRVGaugeInterfaceERC20{
  function deposit(uint256 _value) public;
  function withdraw(uint256 _value) public;
}

contract MinterInterfaceERC20{
  function mint(address gauge_addr) public;
}

contract IUSDCPoolBase is ICurvePool, TokenClaimer, Ownable{
  address public usdc;
  address public dai;
  address public usdt;
  address public busd;
  address public tusd;

  address public crv_token_addr;
  address public controller;
  address public vault;
  address public lp_token_addr;

  CRVGaugeInterfaceERC20 public crv_gauge_addr;
  MinterInterfaceERC20 public crv_minter_addr;

  uint256 public lp_balance;
  uint256 public deposit_usdc_amount;
  uint256 public withdraw_usdc_amount;

  modifier onlyController(){
    require((controller == msg.sender)||(vault == msg.sender), "only controller or vault can call this");
    _;
  }

  constructor() public{
    usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    //dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    //usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    //busd = address(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
    //tusd = address(0x0000000000085d4780B73119b644AE5ecd22b376);

    crv_token_addr = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    crv_minter_addr = MinterInterfaceERC20(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
  }

  function deposit_usdc(uint256 _amount) internal;

  //@_amount: USDC amount
  function deposit(uint256 _amount) public{
    deposit_usdc_amount = deposit_usdc_amount + _amount;
    deposit_usdc(_amount);
    uint256 cur = IERC20(lp_token_addr).balanceOf(address(this));
    lp_balance = lp_balance + cur;
    deposit_to_gauge();
  }

  //deposit all lp token to gauage to mine CRV
  function deposit_to_gauge() internal {
    IERC20(lp_token_addr).approve(address(crv_gauge_addr), 0);
    uint256 cur = IERC20(lp_token_addr).balanceOf(address(this));
    IERC20(lp_token_addr).approve(address(crv_gauge_addr), cur);
    crv_gauge_addr.deposit(cur);
    require(IERC20(lp_token_addr).balanceOf(address(this)) == 0, "deposit_to_gauge: unexpected exchanges");
  }

  function withdraw_from_curve(uint256 _amount) internal;

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

  function setController(address _controller, address _vault) public onlyOwner{
    controller = _controller;
    vault = _vault;
  }
  function claimStdToken(address _token, address payable to) public onlyOwner{
    _claimStdTokens(_token, to);
  }

  function earn_crv() public onlyController{
    require(crv_minter_addr != MinterInterfaceERC20(0x0), "no crv minter");
    crv_minter_addr.mint(address(crv_gauge_addr));
    IERC20(crv_token_addr).transfer(msg.sender, IERC20(crv_token_addr).balanceOf(address(this)));
  }

  function get_lp_token_balance() public view returns(uint256){
    return lp_balance;
  }

  function get_lp_token_addr() public view returns(address){
    return lp_token_addr;
  }
}
