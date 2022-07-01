import pytest
from brownie import *

def log(text, desc=''):
    print('\033[32m' + text + '\033[0m' + desc)
# deploy safemath
@pytest.fixture
def safemath():
    owner = accounts[0]
    SafeMath.deploy({"from":owner})

# deploy AddressArray
@pytest.fixture()
def addressArray():
    owner = accounts[0]
    a = AddressArray.deploy({"from":owner})
    return a
# deploy hack contract
@pytest.fixture()
def hack(Vault, compoundPool, LPERC20):
    hacker = accounts[1]
    cEther = "0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5"
    cWBTC = '0xC11b1268C1A384e55C48c2391d8d480264A3A7F4'
    WBTC = "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599"
    ctrl = "0x3d9819210a31b4961b30ef54be2aed79b9c9cd3b"
    c = CFFHack.deploy(cEther, cWBTC, WBTC, ctrl, Vault.address, compoundPool.address, LPERC20.address,  {"from":hacker})
    # mock initial balance
    hacker.transfer(c.address, '5 ether')
    return c

def hackForERC20(Pool, lp, vault):
    owner = accounts[0]
    hacker = accounts[0]
    cEther = "0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5"
    cWBTC = '0xC11b1268C1A384e55C48c2391d8d480264A3A7F4'
    WBTC = "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599"
    ctrl = "0x3d9819210a31b4961b30ef54be2aed79b9c9cd3b"
    c = CFFHack.deploy(cEther, cWBTC, WBTC, ctrl, vault.address, Pool.address, lp.address,  {"from":hacker})
    return c

# deploy ETH vault
@pytest.fixture()
def Vault(LPERC20, controller):
    owner = accounts[0]
    targetToken = "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599"
    v = CFVault.deploy(targetToken, LPERC20, controller,{"from":owner})
    return v

# deploy trustlist
@pytest.fixture()
def trustList(addressArray):
    owner = accounts[0]
    t = TrustList.deploy([], {"from":owner})
    return t

# deploy ERC20 factory
@pytest.fixture()
def LPERC20(trustList):
    owner = accounts[0]
    e = ERC20Token.deploy("0x0000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000",0,"USDCLP",18,"ULP",True,trustList.address, {"from":owner})
    return e

@pytest.fixture()
def controller(safemath, addressArray):
    crv = "0xD533a949740bb3306d119CC777fa900bA034cd52"
    target = "0x0000000000000000000000000000000000000000"
    owner = accounts[0]
    c = CFController.deploy(crv, target, '5 ether', {"from":owner})
    return c

@pytest.fixture()
def hbtcPool(safemath):
    owner = accounts[0]
    c = HbtcPool.deploy({"from":owner})
    return c


@pytest.fixture()
def bbtcPool(safemath):
    owner = accounts[0]
    c = BbtcPool.deploy({"from":owner})
    return c


@pytest.fixture()
def tbtcPool(safemath):
    owner = accounts[0]
    c = TbtcPool.deploy({"from":owner})
    return c



# # # ------------------------hbtcPool Test----------------------------------------
def test_hbtcPool(controller, hbtcPool, Vault, trustList, LPERC20):
    owner = accounts[0]
    hacker = accounts[1]
    hackContract = hackForERC20(hbtcPool, LPERC20, Vault)
    # mock initial balance
    hacker.transfer(hackContract.address, '5 ether')
    # add pool to controller
    controller.add_pool(hbtcPool.address)

    Vault.set_max_amount(int(99999999999999999999999999999999999999999999999999999999) )
    Vault.set_slippage(9000)
    # add Vault address to trustlist
    trustList.add_trusted(Vault.address)
    # set controller and Vault address for Gusd Pool
    hbtcPool.setController(controller.address, Vault.address)
    # mint USDC for prepare
    hackContract.mintAndLoan(5000000, {"from":hacker})
    vaultAddress = hackContract.cfVault()
    assert vaultAddress == Vault.address
    log("-----------Testing hBtc Deposit------------")
    log(" HbtcPool WBTC deposit start")

    USDCBalanceBefore = hackContract.getDAIBalance()
    log("USDC Balance before withdraw ", str(USDCBalanceBefore))
    hackContract.supplyUSDC()
    LPBalance = LPERC20.balanceOf(hackContract.address)
    log("LP Gained: ", str(LPBalance))
    log("-----------Withdrawing LP----------------------")
    log(str(hbtcPool.get_lp_token_balance()))
    hackContract.withdraw(LPBalance)
    USDCBalanceAfter = hackContract.getDAIBalance()
    log("Wbtc Balance after withdraw ", str(USDCBalanceAfter))


# # ------------------------tbtcPool Test----------------------------------------
def test_tbtcPool(controller, tbtcPool, Vault, trustList, LPERC20):
    owner = accounts[0]
    hacker = accounts[1]
    hackContract = hackForERC20(tbtcPool, LPERC20, Vault)
    # mock initial balance
    hacker.transfer(hackContract.address, '5 ether')
    # add pool to controller
    controller.add_pool(tbtcPool.address)

    Vault.set_max_amount(int(99999999999999999999999999999999999999999999999999999999) )
    Vault.set_slippage(9000)
    # add Vault address to trustlist
    trustList.add_trusted(Vault.address)
    # set controller and Vault address for Gusd Pool
    tbtcPool.setController(controller.address, Vault.address)
    # mint USDC for prepare
    hackContract.mintAndLoan(5000000, {"from":hacker})
    vaultAddress = hackContract.cfVault()
    assert vaultAddress == Vault.address
    log("-----------Testing tBtc Deposit------------")
    log("tbtcPool Pool WBTC deposit start")

    USDCBalanceBefore = hackContract.getDAIBalance()
    log("USDC Balance before withdraw ", str(USDCBalanceBefore))
    hackContract.supplyUSDC()
    LPBalance = LPERC20.balanceOf(hackContract.address)
    log("LP Gained: ", str(LPBalance))
    log("-----------Withdrawing LP----------------------")
    log(str(tbtcPool.get_lp_token_balance()))
    hackContract.withdraw(LPBalance)
    USDCBalanceAfter = hackContract.getDAIBalance()
    log("Wbtc Balance after withdraw ", str(USDCBalanceAfter))

# # ------------------------bbtcPool Test----------------------------------------
def test_bbtcPool(controller, bbtcPool, Vault, trustList, LPERC20):
    owner = accounts[0]
    hacker = accounts[1]
    hackContract = hackForERC20(bbtcPool, LPERC20, Vault)
    # mock initial balance
    hacker.transfer(hackContract.address, '5 ether')
    # add pool to controller
    controller.add_pool(bbtcPool.address)

    Vault.set_max_amount(int(99999999999999999999999999999999999999999999999999999999) )
    Vault.set_slippage(9000)
    # add Vault address to trustlist
    trustList.add_trusted(Vault.address)
    # set controller and Vault address for Gusd Pool
    bbtcPool.setController(controller.address, Vault.address)
    # mint USDC for prepare
    hackContract.mintAndLoan(5000000, {"from":hacker})
    vaultAddress = hackContract.cfVault()
    assert vaultAddress == Vault.address
    log("-----------Testing bBtc Deposit------------")
    log("bbtcPool Pool WBTC deposit start")

    USDCBalanceBefore = hackContract.getDAIBalance()
    log("USDC Balance before withdraw ", str(USDCBalanceBefore))
    hackContract.supplyUSDC()
    LPBalance = LPERC20.balanceOf(hackContract.address)
    log("LP Gained: ", str(LPBalance))
    log("-----------Withdrawing LP----------------------")
    log(str(bbtcPool.get_lp_token_balance()))
    hackContract.withdraw(LPBalance)
    USDCBalanceAfter = hackContract.getDAIBalance()
    log("bbtc Balance after withdraw ", str(USDCBalanceAfter))
