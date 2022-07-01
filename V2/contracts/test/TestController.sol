pragma solidity >=0.4.21 <0.6.0;

import "../utils/Ownable.sol";
import "../utils/Address.sol";
import "../erc20/SafeERC20.sol";
import "../core/IPool.sol";
import "../utils/AddressArray.sol";
import "../utils/SafeMath.sol";
import "../utils/TransferableToken.sol";

contract TYieldHandlerInterface{
  function handleExtraToken(address from, address target_token, uint256 amount, uint min_amount) public;
}


contract TestCFController is Ownable{
  using SafeERC20 for IERC20;
  using TransferableToken for address;
  using AddressArray for address[];
  using SafeMath for uint256;
  using Address for address;

  address[] public all_pools;

  address public current_pool;

  uint256 public last_earn_block;
  uint256 public earn_gap;
  address public crv_token;
  address public target_token;

  address public fee_pool;
  uint256 public harvest_fee_ratio;
  uint256 public ratio_base;

  address[] public extra_yield_tokens;

  TYieldHandlerInterface public yield_handler;

  address public vault;
  address weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  //@param _target, when it's 0, means ETH
  constructor(address _crv, address _target, uint256 _earn_gap) public{
    last_earn_block = 0;
    require(_crv != address(0x0), "invalid crv address");
    //require(_target != address(0x0), "invalid target address");
    require(_earn_gap != 0, "invalid earn gap");
    crv_token = _crv;
    target_token = _target;
    earn_gap = _earn_gap;
    ratio_base = 10000;
  }

  function setVault(address _vault) public onlyOwner{
    require(_vault != address(0x0), "invalid vault");
    vault = _vault;
  }

  modifier onlyVault{
    require(msg.sender == vault, "only vault can call this");
    _;
  }

  function get_current_pool() public view returns(ICurvePool) {
    return ICurvePool(current_pool);
  }

  function add_pool(address addr) public onlyOwner{
    require(!all_pools.exists(addr), "already exist");
    if(current_pool == address(0x0)){
      current_pool = addr;
    }
    all_pools.push(addr);
  }

  function remove_pool(address addr) public onlyOwner{
    require(all_pools.exists(addr), "not exist");
    require(current_pool != addr, "active, cannot remove");
    all_pools.remove(addr);
  }

  event ChangeCurrentPool(address old, address _new);
  function change_current_pool(address addr) public onlyOwner{
    require(all_pools.exists(addr), "not exist");
    require(current_pool != addr, "already active");

    emit ChangeCurrentPool(current_pool, addr);
    //pull out all target token
    uint256 cur = ICurvePool(current_pool).get_lp_token_balance();
    ICurvePool(current_pool).withdraw(cur);
    uint256 b = TransferableToken.balanceOfAddr(target_token, address(this));
    current_pool = addr;

    //deposit to new pool
    TransferableToken.transfer(target_token, current_pool.toPayable(), b);
    _deposit(b);
  }

  function _deposit(uint256 _amount) internal{
    require(current_pool != address(0x0), "cannot deposit with 0x0 pool");
    ICurvePool(current_pool).deposit(_amount);
  }

  function deposit(uint256 _amount) public onlyVault{
    _deposit(_amount);
  }


  function withdraw(uint256 _amount) public onlyVault{
    ICurvePool(current_pool).withdraw(_amount);

    uint256 b = TransferableToken.balanceOfAddr(target_token, address(this));
    require(b != 0, "too small target token");
    TransferableToken.transfer(target_token, msg.sender, b);
  }

  event EarnExtra(address addr, address token, uint256 amount);
  //at least min_amount blocks to call this
  function earnReward(uint min_amount) public onlyOwner{
    require(block.number.safeSub(last_earn_block) >= earn_gap, "not long enough");
    last_earn_block = block.number;
    _refundTarget(0);
  }


  event CFFRefund(uint256 amount, uint256 fee);
  function _refundTarget(uint256 _amount) internal{
    if(_amount == 0){
      return ;
    }
    if(harvest_fee_ratio != 0 && fee_pool != address(0x0)){
      uint256 f = _amount.safeMul(harvest_fee_ratio).safeDiv(ratio_base);
      emit CFFRefund(_amount, f);
      _amount = _amount.safeSub(f);
      if(f != 0){
        TransferableToken.transfer(target_token, fee_pool.toPayable(), f);
      }
    }else{
      emit CFFRefund(_amount, 0);
    }
    TransferableToken.transfer(target_token, current_pool.toPayable(), _amount);
    _deposit(_amount);
  }

  function pause() public onlyOwner{
    current_pool = address(0x0);
  }

  event AddExtraToken(address _new);
  function addExtraToken(address _new) public onlyOwner{
    require(_new != address(0x0), "invalid extra token");
    extra_yield_tokens.push(_new);
    emit AddExtraToken(_new);
  }

  event RemoveExtraToken(address _addr);
  function removeExtraToken(address _addr) public onlyOwner{
    require(_addr != address(0x0), "invalid address");
    uint len = extra_yield_tokens.length;
    for(uint i = 0; i < len; i++){
      if(extra_yield_tokens[i] == _addr){
        extra_yield_tokens[i] = extra_yield_tokens[len - 1];
        extra_yield_tokens[len - 1] =address(0x0);
        extra_yield_tokens.length = len - 1;
        emit RemoveExtraToken(_addr);
      }
    }
  }

  event ChangeYieldHandler(address old, address _new);
  function changeYieldHandler(address _new) public onlyOwner{
    address old = address(yield_handler);
    yield_handler = TYieldHandlerInterface(_new);
    emit ChangeYieldHandler(old, address(yield_handler));
  }

  event ChangeFeePool(address old, address _new);
  function changeFeePool(address _fp) public onlyOwner{
    address old = fee_pool;
    fee_pool = _fp;
    emit ChangeFeePool(old, fee_pool);
  }

  event ChangeHarvestFee(uint256 old, uint256 _new);
  function changeHarvestFee(uint256 _fee) public onlyOwner{
    require(_fee < ratio_base, "invalid fee");
    uint256 old = harvest_fee_ratio;
    harvest_fee_ratio = _fee;
    emit ChangeHarvestFee(old, harvest_fee_ratio);
  }

  function() external payable{}
}
