pragma solidity >=0.4.21 <0.6.0;

import "../utils/Ownable.sol";
import "../utils/SafeMath.sol";
import "../erc20/SafeERC20.sol";
import "../erc20/ERC20Impl.sol";
import "./IPool.sol";

contract CFControllerInterface{
  function get_current_pool() public view returns(ICurvePool);
}

contract TokenInterfaceERC20{
  function destroyTokens(address _owner, uint _amount) public returns(bool);
  function generateTokens(address _owner, uint _amount) public returns(bool);
}

contract CFVault is Ownable{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address public target_token; //USDC
  CFControllerInterface public controller;

  uint256 public ratio_base;
  uint256 public withdraw_fee_ratio;
  uint256 public deposit_fee_ratio;
  address public fee_pool;
  address public lp_token;
  uint256 public max_amount;
  uint256 public slip;

  constructor(address _target_token, address _lp_token, address _controller) public {
    require(_target_token != address(0x0), "invalid target token");
    require(_controller != address(0x0), "invalid controller");
    target_token = _target_token;
    controller = CFControllerInterface(_controller);
    ratio_base = 10000;
    lp_token = _lp_token;
  }

  event ChangeMaxAmount(uint256 old, uint256 _new);
  function set_max_amount(uint _amount) public onlyOwner{
    uint256 old = max_amount;
    max_amount = _amount;
    emit ChangeMaxAmount(old, max_amount);
  }

  event CFFDeposit(address from, uint256 usdc_amount, uint256 cff_amount, uint256 virtual_price);
  event CFFDepositFee(address from, uint256 usdc_amount, uint256 fee_amount);

  event ChangeSlippage(uint256 old, uint256 _new);
  function set_slippage(uint256 _slip) public onlyOwner{
    //base: 10000
    uint256 old = slip;
    slip = _slip;
    emit ChangeSlippage(old, slip);
  }

  function deposit(uint256 _amount) public{
    require(controller != CFControllerInterface(0x0) && controller.get_current_pool() != ICurvePool(0x0), "paused");
    require(IERC20(target_token).allowance(msg.sender, address(this)) >= _amount, "CFVault: not enough allowance");
    require(_amount <= max_amount, "too large amount");
    require(slip != 0, "Slippage not set");

    uint tt_before = IERC20(target_token).balanceOf(address(this));
    IERC20(target_token).safeTransferFrom(msg.sender, address(this), _amount);

    if(deposit_fee_ratio != 0 && fee_pool != address(0x0)){
      uint256 f = _amount.safeMul(deposit_fee_ratio).safeDiv(ratio_base);
      emit CFFDepositFee(msg.sender, _amount, f);
      if(f != 0){
        IERC20(target_token).safeTransfer(fee_pool, f);
      }
    }

    uint tt_after = IERC20(target_token).balanceOf(address(this));
    _amount = tt_after.safeSub(tt_before);

    uint dec = uint(10)**(ERC20Base(target_token).decimals());
    uint vir = controller.get_current_pool().get_virtual_price();
    uint min_amount = _amount.safeMul(uint(1e32)).safeMul(slip).safeDiv(dec).safeDiv(vir);


    IERC20(target_token).safeApprove(address(controller.get_current_pool()), 0);
    IERC20(target_token).safeApprove(address(controller.get_current_pool()),_amount);

    //check exchanges
    uint lp_before = controller.get_current_pool().get_lp_token_balance();
    controller.get_current_pool().deposit(_amount);
    uint tt_left = IERC20(target_token).balanceOf(address(this));
    uint actual_deposit = tt_after - tt_left;
    require(actual_deposit <= _amount, "deposit overflow");

    if(_amount != actual_deposit){
      IERC20(target_token).safeTransfer(msg.sender,_amount - actual_deposit);
    }

    uint lp_after = controller.get_current_pool().get_lp_token_balance();
    uint256 lp_amount = lp_after.safeSub(lp_before);

    require(lp_amount >= min_amount, "Slippage");

    uint256 d = ERC20Base(controller.get_current_pool().get_lp_token_addr()).decimals();
    require(d <= 18, "invalid decimal");
    uint cff_amount = 0;
    if (lp_before == 0){
      cff_amount = lp_amount.safeMul(uint256(10)**18).safeDiv(uint256(10)**d);
    }
    else{
      cff_amount = lp_amount.safeMul(IERC20(lp_token).totalSupply()).safeDiv(lp_before);
    }
    TokenInterfaceERC20(lp_token).generateTokens(msg.sender, cff_amount);
    emit CFFDeposit(msg.sender, actual_deposit, cff_amount, get_virtual_price());
  }


  event CFFWithdraw(address from, uint256 usdc_amount, uint256 cff_amount, uint256 usdc_fee, uint256 virtual_price);
  //@_amount: CFLPToken amount
  function withdraw(uint256 _amount) public{
    require(controller != CFControllerInterface(0x0) && controller.get_current_pool() != ICurvePool(0x0), "paused");
    require(slip != 0, "Slippage not set");
    uint256 amount = IERC20(lp_token).balanceOf(msg.sender);
    require(amount >= _amount, "no enough LP tokens");

    uint LP_token_amount = _amount.safeMul(controller.get_current_pool().get_lp_token_balance()).safeDiv(IERC20(lp_token).totalSupply());

    uint dec = uint(10)**(ERC20Base(target_token).decimals());
    uint vir = controller.get_current_pool().get_virtual_price();
    uint min_amount = LP_token_amount.safeMul(vir).safeMul(slip).safeMul(dec).safeDiv(uint(1e40));

    uint256 _before = IERC20(target_token).balanceOf(address(this));
    controller.get_current_pool().withdraw(LP_token_amount);
    uint256 _after = IERC20(target_token).balanceOf(address(this));
    uint256 usdc_amount = _after.safeSub(_before);

    require(usdc_amount >= min_amount, "Slippage");


    if(withdraw_fee_ratio != 0 && fee_pool != address(0x0)){
      uint256 f = usdc_amount.safeMul(withdraw_fee_ratio).safeDiv(ratio_base);
      uint256 r = usdc_amount.safeSub(f);
      IERC20(target_token).safeTransfer(msg.sender, r);
      IERC20(target_token).safeTransfer(fee_pool, f);
      TokenInterfaceERC20(lp_token).destroyTokens(msg.sender, _amount);
      emit CFFWithdraw(msg.sender, r, _amount, f, get_virtual_price());
    }else{
      IERC20(target_token).safeTransfer(msg.sender, usdc_amount);
      TokenInterfaceERC20(lp_token).destroyTokens(msg.sender, _amount);
      emit CFFWithdraw(msg.sender, usdc_amount, _amount, 0, get_virtual_price());
    }
  }

  event ChangeWithdrawFee(uint256 old, uint256 _new);
  function changeWithdrawFee(uint256 _fee) public onlyOwner{
    require(_fee < ratio_base, "invalid fee");
    uint256 old = withdraw_fee_ratio;
    withdraw_fee_ratio = _fee;
    emit ChangeWithdrawFee(old, withdraw_fee_ratio);
  }

  event ChangeDepositFee(uint256 old, uint256 _new);
  function changeDepositFee(uint256 _fee) public onlyOwner{
    require(_fee < ratio_base, "invalid fee");
    uint256 old = deposit_fee_ratio;
    deposit_fee_ratio = _fee;
    emit ChangeDepositFee(old, deposit_fee_ratio);
  }

  event ChangeController(address old, address _new);
  function changeController(address _ctrl) public onlyOwner{
    address old = address(controller);
    controller = CFControllerInterface(_ctrl);
    emit ChangeController(old, address(controller));
  }

  event ChangeFeePool(address old, address _new);
  function changeFeePool(address _fp) public onlyOwner{
    address old = fee_pool;
    fee_pool = _fp;
    emit ChangeFeePool(old, fee_pool);
  }

  function get_virtual_price() public view returns(uint256){
    ICurvePool cp = controller.get_current_pool();
    uint256 v1 = cp.get_lp_token_balance().safeMul(uint256(10)**ERC20Base(lp_token).decimals());
    uint256 v2 = IERC20(lp_token).totalSupply().safeMul(uint256(10) ** ERC20Base(cp.get_lp_token_addr()).decimals());
    if(v2 == 0){
      return 0;
    }
    return v1.safeMul(cp.get_virtual_price()).safeDiv(v2);
  }
}

contract CFVaultFactory{
  event NewCFVault(address addr);

  function createCFVault(address _target_token, address _lp_token, address _controller) public returns(address){
    CFVault cf = new CFVault(_target_token, _lp_token, _controller);
    cf.transferOwnership(msg.sender);
    emit NewCFVault(address(cf));
    return address(cf);
  }

}
