pragma solidity >=0.4.21 <0.6.0;

import "./IETHPoolBase.sol";
import "../../erc20/SafeERC20.sol";
import "../../erc20/IERC20.sol";

contract CurveInterfaceAleth{
  function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) public payable returns(uint256);
  function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_receive_amount) public returns(uint256);
}

contract AlethPool is IETHPoolBase{
  using SafeERC20 for IERC20;

  CurveInterfaceAleth public pool_deposit;

  constructor() public{
    name = "Aleth";
    lp_token_addr = address(0xC4C319E2D4d66CcA4464C0c2B32c9Bd23ebe784e);
    pool_deposit = CurveInterfaceAleth(0xC4C319E2D4d66CcA4464C0c2B32c9Bd23ebe784e);
  }

  function deposit_eth(uint256 _amount) internal {
    uint256[2] memory uamounts = [_amount, 0];
    pool_deposit.add_liquidity.value(_amount)(uamounts, 0);
  }


  function withdraw_from_curve(uint256 _amount) internal{
    require(_amount <= get_lp_token_balance(), "withdraw_from_curve: too large amount");
    require(address(pool_deposit).balance > 0, "money is 0");
    pool_deposit.remove_liquidity_one_coin(_amount, 0, 0);

  }

  function get_virtual_price() public view returns(uint256){
    return PriceInterfaceEth(address(pool_deposit)).get_virtual_price();
  }
}
