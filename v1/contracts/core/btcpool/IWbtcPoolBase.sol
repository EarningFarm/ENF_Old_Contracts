pragma solidity >=0.4.21 <0.6.0;
import "../../utils/Ownable.sol";
import "../IPool.sol";
import "../../utils/TokenClaimer.sol";
import "../../erc20/IERC20.sol";


contract PriceInterfaceWbtc{
  function get_virtual_price() public view returns(uint256);
  //function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) public;
  //function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) public;
}

contract CRVGaugeInterfaceWbtc{
  function deposit(uint256 _value) public;
  function withdraw(uint256 _value) public;
  function claim_rewards(address _address) public;
}

contract MinterInterfaceWbtc{
  function mint(address gauge_addr) public;
}

contract IWbtcPoolBase is ICurvePool, TokenClaimer, Ownable{
  address public wbtc;

  address public crv_token_addr;
  address public controller;
  address public vault;
  address public lp_token_addr;
  address public extra_token_addr;

  CRVGaugeInterfaceWbtc public crv_gauge_addr;
  MinterInterfaceWbtc public crv_minter_addr;

  uint256 public lp_balance;
  uint256 public deposit_wbtc_amount;
  uint256 public withdraw_wbtc_amount;

  modifier onlyController(){
    require((controller == msg.sender)||(vault == msg.sender), "only controller can call this");
    _;
  }

  constructor() public{

    wbtc = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);

    crv_token_addr = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    crv_minter_addr = MinterInterfaceWbtc(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
  }

  function deposit_wbtc(uint256 _amount) internal;

  //@_amount: USDC amount
  function deposit(uint256 _amount) public onlyController{
    deposit_wbtc_amount = deposit_wbtc_amount + _amount;
    deposit_wbtc(_amount);
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

    IERC20(wbtc).transfer(msg.sender, IERC20(wbtc).balanceOf(address(this)));
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
    require(crv_minter_addr != MinterInterfaceWbtc(0x0), "no crv minter");
    crv_minter_addr.mint(address(crv_gauge_addr));
    IERC20(crv_token_addr).transfer(msg.sender, IERC20(crv_token_addr).balanceOf(address(this)));
    if (extra_token_addr != address(0x0)) {
      crv_gauge_addr.claim_rewards(address(this));
      IERC20(extra_token_addr).transfer(msg.sender, IERC20(extra_token_addr).balanceOf(address(this)));
    }
  }

  function get_lp_token_balance() public view returns(uint256){
    return lp_balance;
  }

  function get_lp_token_addr() public view returns(address){
    return lp_token_addr;
  }
}
