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
    cUSDC = '0x39aa39c021dfbae8fac545936693ac917d5e7563'
    USDC = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
    ctrl = "0x3d9819210a31b4961b30ef54be2aed79b9c9cd3b"
    c = CFFHack.deploy(cEther, cUSDC, USDC, ctrl, Vault.address, compoundPool.address, LPERC20.address,  {"from":hacker})
    # mock initial balance
    hacker.transfer(c.address, '5 ether')
    return c

def hackForERC20(Pool, lp, vault):
    owner = accounts[0]
    hacker = accounts[0]
    cEther = "0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5"
    cUSDC = '0x39aa39c021dfbae8fac545936693ac917d5e7563'
    USDC = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
    ctrl = "0x3d9819210a31b4961b30ef54be2aed79b9c9cd3b"
    c = CFFHack.deploy(cEther, cUSDC, USDC, ctrl, vault.address, Pool.address, lp.address,  {"from":hacker})
    return c

# deploy ETH vault
@pytest.fixture()
def Vault(LPERC20, controller):
    owner = accounts[0]
    targetToken = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
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
def exchange():
    crv = "0xD533a949740bb3306d119CC777fa900bA034cd52"
    e = CRVExchange.deploy(crv, {"from":accounts[0]})
    # sushi
    e.addPath("0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"]) #Add CRV->WETH->USDC Path
    e.addPath("0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"]) #Add CRV->WETH->WBTC Path
    e.addPath("0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"]) #Add CRV->WETH
    #uni
    e.addPath("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", ["0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"]) #Add lqty->WETH->USDC Path
    e.addPath("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"]) #Add CRV->WETH->USDC Path
    e.addPath("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"]) #Add CRV->WETH->WBTC Path
    e.addPath("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", ["0x85Eee30c52B0b379b046Fb0F85F4f3Dc3009aFEC","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"]) #Add KEEP->WETH->WBTC Path
    e.addPath("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"]) #Add CRV->WETH
    e.addPath("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0x6b175474e89094c44da98b954eedeac495271d0f","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"]) #Add CRV->DAI->WETH
    return e



@pytest.fixture()
def controller(safemath, addressArray, exchange):
    crv = "0xD533a949740bb3306d119CC777fa900bA034cd52"
    target = "0x0000000000000000000000000000000000000000"
    owner = accounts[0]
    c = CFController.deploy(crv, target, 2, {"from":owner})
    c.changeCRVHandler(exchange)
    return c

@pytest.fixture()
def compoundPool(safemath):
    owner = accounts[0]
    c = CompoundPool.deploy({"from":owner})
    return c

@pytest.fixture()
def aavePool():
    owner = accounts[0]
    a = AavePool.deploy({"from":owner})
    return a

@pytest.fixture()
def busdPool():
    owner = accounts[0]
    b = BUSDPool.deploy({"from":owner})
    return b

@pytest.fixture()
def gusdPool():
    owner = accounts[0]
    b = GUSDPool.deploy({"from":owner})
    return b

@pytest.fixture()
def yPool():
    owner = accounts[0]
    b = YPool.deploy({"from":owner})
    return b

@pytest.fixture()
def triPool():
    owner = accounts[0]
    b = TriPool.deploy({"from":owner})
    return b

@pytest.fixture()
def lusdPool():
    return LusdPool.deploy({"from":accounts[0]})

#--------------------------LusdPool Test--------------------------------------
def test_LusdPool(hack, controller, lusdPool, Vault, trustList, LPERC20):

    owner = accounts[0]
    hacker = accounts[1]
    hackContract = hackForERC20(lusdPool, LPERC20, Vault)
    # mock initial balance
    hacker.transfer(hackContract.address, '10 ether')
    # add pool to controller
    controller.add_pool(lusdPool.address)
    #controller.changeExtraToken("0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D")

    # cfVault
    Vault.set_max_amount(int(99999999999999999999999999999999999999999999999999999999) )
    Vault.set_slippage(9000)
    # add Vault address to trustlist
    trustList.add_trusted(Vault.address)
    # set controller and Vault address for Aave Pool
    lusdPool.setController(controller.address, Vault.address)
    # mint USDC for prepare
    hackContract.mintAndLoan(1000000000, {"from":hacker})


    crv = "0xD533a949740bb3306d119CC777fa900bA034cd52"
    lqty = "0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D"

    vaultAddress = hackContract.cfVault()
    #log("v1: ", vaultAddress, " should be ", hackContract.cfVault())
    assert vaultAddress == Vault.address
    log("-----------Testing LusdPool Deposit------------")

    USDCBalanceBefore = hackContract.getDAIBalance()
    log("USDC Balance before supply ", str(USDCBalanceBefore))
    log("lusdPool Pool USDC deposit start")
    hackContract.supplyUSDC()
    LPBalance = LPERC20.balanceOf(hackContract.address)
    log("LP Gained: ", str(LPBalance))

    log("-----------Earning Farm----------------------")
    chain.mine(576)
    log("asset before: ", str(Vault.get_asset()))
    controller.earnCRV(0, 0)
    log("asset after : ", str(Vault.get_asset()))  


    log("-----------Withdrawing LP----------------------")
    
    USDCBalanceBefore = hackContract.getDAIBalance()
    log("USDC Balance before withdraw ", str(USDCBalanceBefore))
    
    hackContract.withdraw(LPBalance)
    
    USDCBalanceAfter = hackContract.getDAIBalance()
    log("USDC Balance after withdraw ", str(USDCBalanceAfter))


#--------------------------CompoundPool Test--------------------------------------
def test_CompoundPool(hack, controller, compoundPool, Vault, trustList, LPERC20):

    owner = accounts[0]
    hacker = accounts[1]
    hackContract = hackForERC20(compoundPool, LPERC20, Vault)
    # mock initial balance
    hacker.transfer(hackContract.address, '10 ether')
    # add pool to controller
    controller.add_pool(compoundPool.address)

    # cfVault
    Vault.set_max_amount(int(99999999999999999999999999999999999999999999999999999999) )
    Vault.set_slippage(9000)
    # add Vault address to trustlist
    trustList.add_trusted(Vault.address)
    # set controller and Vault address for Aave Pool
    compoundPool.setController(controller.address, Vault.address)
    # mint USDC for prepare
    hackContract.mintAndLoan(1000000000, {"from":hacker})


    crv = "0xD533a949740bb3306d119CC777fa900bA034cd52";

    vaultAddress = hackContract.cfVault()
    #log("v1: ", vaultAddress, " should be ", hackContract.cfVault())
    assert vaultAddress == Vault.address
    log("-----------Testing compoundPool Deposit------------")

    log("CRV balance at controller ", str(interface.IERC20(crv).balanceOf(controller.address)))
    USDCBalanceBefore = hackContract.getDAIBalance()
    log("USDC Balance before supply ", str(USDCBalanceBefore))
    log("compoundPool Pool USDC deposit start")
    hackContract.supplyUSDC()
    LPBalance = LPERC20.balanceOf(hackContract.address)
    log("LP Gained: ", str(LPBalance))
    log("-----------Withdrawing LP----------------------")
    USDCBalanceBefore = hackContract.getDAIBalance()
    log("USDC Balance before withdraw ", str(USDCBalanceBefore))
    hackContract.withdraw(LPBalance)

    controller.earnCRV(0, 0);
    USDCBalanceAfter = hackContract.getDAIBalance()
    log("USDC Balance after withdraw ", str(USDCBalanceAfter))



#--------------------------AavePool Test--------------------------------------
def test_AavePool(controller, aavePool, Vault, trustList, LPERC20):
    owner = accounts[0]
    hacker = accounts[1]
    hackContract = hackForERC20(aavePool, LPERC20, Vault)
    # mock initial balance
    hacker.transfer(hackContract.address, '5 ether')
    # add pool to controller
    controller.add_pool(aavePool.address)

    # cfVault
    Vault.set_max_amount(int(99999999999999999999999999999999999999999999999999999999) )
    Vault.set_slippage(9000)
    # add Vault address to trustlist
    trustList.add_trusted(Vault.address)
    # set controller and Vault address for Aave Pool
    aavePool.setController(controller.address, Vault.address)
    # mint USDC for prepare
    hackContract.mintAndLoan(1000000000, {"from":hacker})
    vaultAddress = hackContract.cfVault()
    assert vaultAddress == Vault.address
    log("-----------Testing AavePool Deposit------------")
    log("Aave Pool USDC deposit start")

    USDCBalanceBefore = hackContract.getDAIBalance()
    log("USDC Balance before withdraw ", str(USDCBalanceBefore))
    hackContract.supplyUSDC()
    LPBalance = LPERC20.balanceOf(hackContract.address)
    log("LP Gained: ", str(LPBalance))
    log("-----------Withdrawing LP----------------------")
    hackContract.withdraw(LPBalance)
    USDCBalanceAfter = hackContract.getDAIBalance()
    log("USDC Balance after withdraw ", str(USDCBalanceAfter))

# # ------------------------BusdPool Test----------------------------------------
def test_BusdPool(controller, busdPool, Vault, trustList, LPERC20):
    owner = accounts[0]
    hacker = accounts[1]
    hackContract = hackForERC20(busdPool, LPERC20, Vault)
    # mock initial balance
    hacker.transfer(hackContract.address, '5 ether')
    # add pool to controller
    controller.add_pool(busdPool.address)

    Vault.set_max_amount(int(99999999999999999999999999999999999999999999999999999999) )
    Vault.set_slippage(9000)
    # add Vault address to trustlist
    trustList.add_trusted(Vault.address)
    # set controller and Vault address for Busd Pool
    busdPool.setController(controller.address, Vault.address)
    # mint USDC for prepare
    hackContract.mintAndLoan(1000000000, {"from":hacker})
    vaultAddress = hackContract.cfVault()
    assert vaultAddress == Vault.address
    log("-----------Testing Busd Pool Deposit------------")
    log("busd Pool USDC deposit start")


    USDCBalanceBefore = hackContract.getDAIBalance()
    log("USDC Balance before withdraw ", str(USDCBalanceBefore))
    hackContract.supplyUSDC()
    LPBalance = LPERC20.balanceOf(hackContract.address)
    log("LP Gained: ", str(LPBalance))
    log("-----------Withdrawing LP----------------------")
    hackContract.withdraw(LPBalance)
    USDCBalanceAfter = hackContract.getDAIBalance()
    log("USDC Balance after withdraw ", str(USDCBalanceAfter))


# # # ------------------------GusdPool Test----------------------------------------
def test_GusdPool(controller, gusdPool, Vault, trustList, LPERC20):
    owner = accounts[0]
    hacker = accounts[1]
    hackContract = hackForERC20(gusdPool, LPERC20, Vault)
    # mock initial balance
    hacker.transfer(hackContract.address, '5 ether')
    # add pool to controller
    controller.add_pool(gusdPool.address)
    Vault.set_max_amount(int(99999999999999999999999999999999999999999999999999999999) )
    Vault.set_slippage(9000)
    # add Vault address to trustlist
    trustList.add_trusted(Vault.address)
    # set controller and Vault address for Gusd Pool
    gusdPool.setController(controller.address, Vault.address)
    # mint USDC for prepare
    hackContract.mintAndLoan(1000000000, {"from":hacker})
    vaultAddress = hackContract.cfVault()
    assert vaultAddress == Vault.address
    log("-----------Testing GUSD Deposit------------")
    log("gusd Pool USDC deposit start")

    USDCBalanceBefore = hackContract.getDAIBalance()
    log("USDC Balance before withdraw ", str(USDCBalanceBefore))
    hackContract.supplyUSDC()
    LPBalance = LPERC20.balanceOf(hackContract.address)
    log("LP Gained: ", str(LPBalance))
    log("-----------Withdrawing LP----------------------")
    hackContract.withdraw(LPBalance)
    USDCBalanceAfter = hackContract.getDAIBalance()
    log("USDC Balance after withdraw ", str(USDCBalanceAfter))


# # ------------------------YPool Test----------------------------------------
def test_YPool(controller, yPool, Vault, trustList, LPERC20):
    owner = accounts[0]
    hacker = accounts[1]
    hackContract = hackForERC20(yPool, LPERC20, Vault)
    # mock initial balance
    hacker.transfer(hackContract.address, '5 ether')
    # add pool to controller
    controller.add_pool(yPool.address)

    Vault.set_max_amount(int(99999999999999999999999999999999999999999999999999999999) )
    Vault.set_slippage(9000)
    # add Vault address to trustlist
    trustList.add_trusted(Vault.address)
    # set controller and Vault address for Gusd Pool
    yPool.setController(controller.address, Vault.address)
    # mint USDC for prepare
    hackContract.mintAndLoan(1000000000, {"from":hacker})
    vaultAddress = hackContract.cfVault()
    assert vaultAddress == Vault.address
    log("-----------Testing Ypool Deposit------------")
    log("Y Pool USDC deposit start")

    USDCBalanceBefore = hackContract.getDAIBalance()
    log("USDC Balance before withdraw ", str(USDCBalanceBefore))
    hackContract.supplyUSDC()
    LPBalance = LPERC20.balanceOf(hackContract.address)
    log("LP Gained: ", str(LPBalance))
    log("-----------Withdrawing LP----------------------")
    hackContract.withdraw(LPBalance)
    USDCBalanceAfter = hackContract.getDAIBalance()
    log("USDC Balance after withdraw ", str(USDCBalanceAfter))




# # ------------------------TriPool Test----------------------------------------
def test_TriPool(controller, triPool, Vault, trustList, LPERC20):
    owner = accounts[0]
    hacker = accounts[1]
    hackContract = hackForERC20(triPool, LPERC20, Vault)
    # mock initial balance
    hacker.transfer(hackContract.address, '5 ether')
    # add pool to controller
    controller.add_pool(triPool.address)

    Vault.set_max_amount(int(99999999999999999999999999999999999999999999999999999999) )
    Vault.set_slippage(9000)
    # add Vault address to trustlist
    trustList.add_trusted(Vault.address)
    # set controller and Vault address for Gusd Pool
    triPool.setController(controller.address, Vault.address)
    # mint USDC for prepare
    hackContract.mintAndLoan(1000000000, {"from":hacker})
    vaultAddress = hackContract.cfVault()
    assert vaultAddress == Vault.address
    log("-----------Testing TriPool Deposit------------")
    log("Tri Pool USDC deposit start")

    USDCBalanceBefore = hackContract.getDAIBalance()
    log("USDC Balance before withdraw ", str(USDCBalanceBefore))
    hackContract.supplyUSDC()
    LPBalance = LPERC20.balanceOf(hackContract.address)
    log("LP Gained: ", str(LPBalance))
    log("-----------Withdrawing LP----------------------")
    hackContract.withdraw(LPBalance)
    USDCBalanceAfter = hackContract.getDAIBalance()
    log("USDC Balance after withdraw ", str(USDCBalanceAfter))
