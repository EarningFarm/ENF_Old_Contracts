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

@pytest.fixture()
def exchange():
    crv = "0xD533a949740bb3306d119CC777fa900bA034cd52"
    owner = accounts[0]
    e = CRVExchange.deploy(crv, {"from":owner})

    e.addPath("0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"]);#Add CRV->WETH->USDC Path
    e.addPath("0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"]);#Add CRV->WETH->WBTC Path
    e.addPath("0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"]);#Add CRV->WETH

    e.addPath("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"]);#Add CRV->WETH->USDC Path
    e.addPath("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"]);#Add CRV->WETH->WBTC Path
    e.addPath("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", ["0x85Eee30c52B0b379b046Fb0F85F4f3Dc3009aFEC","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"]);#Add KEEP->WETH->WBTC Path
    e.addPath("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"]);#Add CRV->WETH
    e.addPath("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0x6b175474e89094c44da98b954eedeac495271d0f","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"]);#Add CRV->DAI->WETH

    return e

# deploy hack contract
@pytest.fixture()
def hack(Vault, compoundPool, LPERC20):
    hacker = accounts[1]


    c = CFFEThHack.deploy( Vault.address, compoundPool.address, LPERC20.address,  {"from":hacker})
    # mock initial balance
    hacker.transfer(c.address, '5 ether')
    return c

def hackForERC20(Pool, lp, vault):
    owner = accounts[0]
    hacker = accounts[0]

    c = CFFEThHack.deploy( vault.address, Pool.address, lp.address,  {"from":hacker})
    return c

# deploy ETH vault
@pytest.fixture()
def Vault(LPERC20, controller):
    owner = accounts[0]

    v = CFETHVaultV2.deploy( LPERC20, controller,{"from":owner})
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
def controller(safemath, addressArray, exchange):
    crv = "0xD533a949740bb3306d119CC777fa900bA034cd52"
    target = "0x0000000000000000000000000000000000000000"
    owner = accounts[0]
    c = CFETHControllerV3.deploy(crv, 2, {"from":owner})
    c.changeCRVHandler(exchange)
    c.changeFeePool(accounts[0])
    c.changeHarvestFee(1000)
    return c

@pytest.fixture()
def sethPool(safemath):
    owner = accounts[0]
    c = SethPool.deploy({"from":owner})
    return c

# # ------------------------tbtcPool Test----------------------------------------
def test_sethPool(controller, sethPool, Vault, trustList, LPERC20):
    owner = accounts[0]
    hacker = accounts[1]
    hackContract = hackForERC20(sethPool, LPERC20, Vault)
    # mock initial balance
    hacker.transfer(hackContract.address, '5 ether')
    # add pool to controller
    controller.add_pool(sethPool.address)

    Vault.set_max_amount(int(99999999999999999999999999999999999999999999999999999999) )
    Vault.set_slippage(9000)
    # add Vault address to trustlist
    trustList.add_trusted(Vault.address)
    # set controller and Vault address for Gusd Pool
    sethPool.setController(controller.address, Vault.address)
    # mint USDC for prepare

    vaultAddress = hackContract.cfVault()
    assert vaultAddress == Vault.address
    log("-----------Testing seth Deposit------------")
    log(" Pool SethPool deposit start")

    hackContract.supplyETH()
    LPBalance = LPERC20.balanceOf(hackContract.address)
    log("LP Gained: ", str(LPBalance))
    log("-----------Withdrawing LP----------------------")

    log(str(sethPool.get_lp_token_balance()))
    hackContract.withdraw(LPBalance)

    controller.earnCRV(0, 0)
