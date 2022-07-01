pragma solidity >=0.4.21 <0.6.0;

import "../../erc20/IERC20.sol";
import "./IPoolBase.sol";
import "../../erc20/SafeERC20.sol";

contract CurveInterfaceGusd{
  function add_liquidity(uint256[4] memory uamounts, uint256 min_mint_amount) public returns(uint256);
  function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_mint_amount) public returns(uint256);
  address public pool;
}

contract GUSDPool is IUSDCPoolBase{

  using SafeERC20 for IERC20;
  CurveInterfaceGusd public pool_deposit;

  constructor() public{
    name = "GUSD";
    lp_token_addr = address(0xD2967f45c4f384DEEa880F807Be904762a3DeA07);
    crv_gauge_addr = CRVGaugeInterfaceERC20(0xC5cfaDA84E902aD92DD40194f0883ad49639b023);
    pool_deposit = CurveInterfaceGusd(0x64448B78561690B70E17CBE8029a3e5c1bB7136e);
  }

  //@_amount: USDC amount
  function deposit_usdc(uint256 _amount) internal {
    IERC20(usdc).transferFrom(msg.sender, address(this), _amount);
    IERC20(usdc).approve(address(pool_deposit), 0);
    IERC20(usdc).approve(address(pool_deposit), _amount);
    uint256[4] memory uamounts = [uint256(0), 0, _amount, 0];
    pool_deposit.add_liquidity(uamounts, 0);
  }

  function withdraw_from_curve(uint256 _amount) internal{
    require(_amount <= get_lp_token_balance(), "withdraw_from_curve: too large amount");
    IERC20(lp_token_addr).approve(address(pool_deposit), _amount);
    pool_deposit.remove_liquidity_one_coin(_amount, 2, 0);

    /*pool_deposit.remove_liquidity(_amount, [uint256(0), 0, 0, 0]);

    uint256 dai_amount = IERC20(dai).balanceOf(address(this));
    IERC20(dai).safeApprove(pool_deposit.curve(), dai_amount);
    PriceInterface(pool_deposit.curve()).exchange_underlying(0, 1, dai_amount, 0);

    uint256 usdt_amount = IERC20(usdt).balanceOf(address(this));
    IERC20(usdt).safeApprove(pool_deposit.curve(), usdt_amount);
    PriceInterface(pool_deposit.curve()).exchange_underlying(2, 1, usdt_amount, 0);

    uint256 busd_amount = IERC20(busd).balanceOf(address(this));
    IERC20(busd).safeApprove(pool_deposit.curve(), busd_amount);
    PriceInterface(pool_deposit.curve()).exchange_underlying(3, 1, busd_amount, 0);*/
  }
  function get_virtual_price() public view returns(uint256){
    return PriceInterfaceERC20(pool_deposit.pool()).get_virtual_price();
  }
}
