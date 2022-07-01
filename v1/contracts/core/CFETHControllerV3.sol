pragma solidity >=0.4.21 <0.6.0;

import "../utils/Ownable.sol";
import "../erc20/SafeERC20.sol";
import "./IPool.sol";
import "../utils/AddressArray.sol";
import "../utils/SafeMath.sol";

contract CRVHandlerETHInterface{
  function handleCRV(address target_token, uint256 amount, uint min_amount) public;
  function handleExtraToken(address from, address target_token, uint256 amount, uint min_amount) public;
}

contract CFETHControllerV3 is Ownable{
  using SafeERC20 for IERC20;
  using AddressArray for address[];
  using SafeMath for uint256;

  address[] public all_pools;

  address public current_pool;

  uint256 public last_earn_block;
  uint256 public earn_gap;
  address public crv_token;
  address public target_token;

  address payable public fee_pool;
  uint256 public harvest_fee_ratio;
  uint256 public ratio_base;

  address public extra_yield_token;
  CRVHandlerETHInterface public crv_handler;

  constructor(address _crv, uint256 _earn_gap) public{
    last_earn_block = 0;
    if(_earn_gap == 0){
      earn_gap = 5760;
    }else{
      earn_gap = _earn_gap;
    }

    last_earn_block = block.number;
    if(_crv == address(0x0)){
      crv_token = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    }else{
      crv_token = _crv;
    }

    ratio_base = 10000;
  }

  function get_current_pool() public view returns(ICurvePoolForETH) {
    return ICurvePoolForETH(current_pool);
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
    uint256 cur = ICurvePoolForETH(current_pool).get_lp_token_balance();
    ICurvePoolForETH(current_pool).withdraw(cur);
    uint256 b = address(this).balance;
    current_pool = addr;

    //deposit to new pool
    ICurvePoolForETH(current_pool).deposit.value(b)();
  }

  address weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  event EarnCRV(address addr, uint256 amount);
  event EarnExtra(address addr, address token, uint256 amount);
  //at least 24 hours to call this
  function earnCRV(uint crv_min_amount, uint extra_min_amount) public onlyOwner{
    require(block.number.safeSub(last_earn_block) >= earn_gap, "not long enough");
    last_earn_block = block.number;

    ICurvePoolForETH(current_pool).earn_crv();

    uint256 amount = IERC20(crv_token).balanceOf(address(this));
    emit EarnCRV(address(this), amount);

    if(amount > 0){
      require(crv_handler != CRVHandlerETHInterface(0x0), "invalid crv handler");
      IERC20(crv_token).approve(address(crv_handler), amount);
      crv_handler.handleCRV(weth, amount, crv_min_amount);
    }

    if(extra_yield_token != address(0x0)){
      amount = IERC20(extra_yield_token).balanceOf(address(this));
      emit EarnExtra(address(this), extra_yield_token, amount);
      if(amount > 0){
        IERC20(extra_yield_token).approve(address(crv_handler), amount);
        crv_handler.handleExtraToken(extra_yield_token, weth, amount, extra_min_amount);
      }
    }
  }

  event CFFRefund(uint256 amount, uint256 fee);
  function refundTarget() public payable{
    //IERC20(target_token).safeTransferFrom(msg.sender, address(this), _amount);
    uint _amount = msg.value;
    if(harvest_fee_ratio != 0 && fee_pool != address(0x0)){
      uint256 f = _amount.safeMul(harvest_fee_ratio).safeDiv(ratio_base);
      emit CFFRefund(_amount, f);
      _amount = _amount.safeSub(f);
      if(f != 0){
        fee_pool.call.value(f)("");
      }
    }else{
      emit CFFRefund(_amount, 0);
    }
    ICurvePoolForETH(current_pool).deposit.value(_amount)();
  }

  function pauseAndTransferTo(address payable _target) public onlyOwner{
    //pull out all target token
    uint256 cur = ICurvePoolForETH(current_pool).get_lp_token_balance();
    ICurvePoolForETH(current_pool).withdraw(cur);
    uint b = address(this).balance;
    _target.transfer(b);

    current_pool = address(0x0);
  }

  event ChangeExtraToken(address old, address _new);
  function changeExtraToken(address _new) public onlyOwner{
    address old = extra_yield_token;
    extra_yield_token = _new;
    emit ChangeExtraToken(old, extra_yield_token);
  }

  event ChangeCRVHandler(address old, address _new);
  function changeCRVHandler(address _new) public onlyOwner{
    address old = address(crv_handler);
    crv_handler = CRVHandlerETHInterface(_new);
    emit ChangeCRVHandler(old, address(crv_handler));
  }

  event ChangeFeePool(address old, address _new);
  function changeFeePool(address payable _fp) public onlyOwner{
    address payable old = fee_pool;
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

contract CFETHControllerV3Factory{
  event NewCFETHController(address addr);
  function createCFETHController(address _crv, uint256 _earn_gap) public returns(address){
    CFETHControllerV3 cf = new CFETHControllerV3(_crv, _earn_gap);
    emit NewCFETHController(address(cf));
    cf.transferOwnership(msg.sender);
    return address(cf);
  }
}
