pragma solidity >=0.4.21 <0.6.0;

import "../../erc20/IERC20.sol";
import "./IPoolBase.sol";
import "../../erc20/SafeERC20.sol";

contract CurveInterfaceY{
  function add_liquidity(uint256[4] memory uamounts, uint256 min_mint_amount) public;
  function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_mint_amount) public;
  address public curve;
}

contract YPool is IUSDCPoolBase{
  using SafeERC20 for IERC20;
  CurveInterfaceY public pool_deposit;

  constructor() public{
    name = "yPool";

    lp_token_addr = address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);
    crv_gauge_addr = CRVGaugeInterfaceERC20(0xFA712EE4788C042e2B7BB55E6cb8ec569C4530c1);
    pool_deposit = CurveInterfaceY(0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3);
  }

  //@_amount: USDC amount
  function deposit_usdc(uint256 _amount) internal {
    IERC20(usdc).transferFrom(msg.sender, address(this), _amount);
    IERC20(usdc).approve(address(pool_deposit), 0);
    IERC20(usdc).approve(address(pool_deposit), _amount);
    uint256[4] memory uamounts = [uint256(0), _amount, 0, 0];
    pool_deposit.add_liquidity(uamounts, 0);
  }

  function withdraw_from_curve(uint256 _amount) internal{
    require(_amount <= get_lp_token_balance(), "withdraw_from_curve: too large amount");
    IERC20(lp_token_addr).approve(address(pool_deposit), _amount);
    pool_deposit.remove_liquidity_one_coin(_amount, 1, 0);
    /*pool_deposit.remove_liquidity(_amount, [uint256(0), 0, 0, 0]);

    uint256 dai_amount = IERC20(dai).balanceOf(address(this));
    IERC20(dai).safeApprove(pool_deposit.curve(), dai_amount);
    PriceInterface(pool_deposit.curve()).exchange_underlying(0, 1, dai_amount, 0);

    uint256 usdt_amount = IERC20(usdt).balanceOf(address(this));
    IERC20(usdt).safeApprove(pool_deposit.curve(), usdt_amount);
    PriceInterface(pool_deposit.curve()).exchange_underlying(2, 1, usdt_amount, 0);

    uint256 tusd_amount = IERC20(tusd).balanceOf(address(this));
    IERC20(tusd).safeApprove(pool_deposit.curve(), tusd_amount);
    PriceInterface(pool_deposit.curve()).exchange_underlying(3, 1, tusd_amount, 0);*/
  }

  function get_virtual_price() public view returns(uint256){
    return PriceInterfaceERC20(pool_deposit.curve()).get_virtual_price();
  }
}
