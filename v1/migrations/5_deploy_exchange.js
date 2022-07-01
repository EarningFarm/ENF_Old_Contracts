const CFController = artifacts.require("CFController");
const AddressArray = artifacts.require("AddressArray");
const USDC = artifacts.require("USDC");
const CRV = artifacts.require("CRV");
const SafeERC20 = artifacts.require("SafeERC20");
const SafeMath = artifacts.require("SafeMath");

const CRVExchange = artifacts.require("CRVExchange");
const DummyDex = artifacts.require("DummyDex");


async function performMigration(deployer, network, accounts) {
  console.log("network is ", network);
  if(network.includes("development") ||
    network.includes("ganache") ||
    network.includes("ropsten")){
    usdc_contract = await USDC.deployed();
    usdc = usdc_contract.address;
    crv_contract = await CRV.deployed();
    crv = crv_contract.address;
  }
  if(network.includes("main")){
    usdc = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    crv = "0xD533a949740bb3306d119CC777fa900bA034cd52";
  }

  //USDC controller
  //controler_contract = await CFController.deployed();


  await AddressArray.deployed();
  await deployer.link(AddressArray, CRVExchange);
  await deployer.deploy(CRVExchange, crv);

  exchange = await CRVExchange.deployed();
  console.log("exchange address: ", exchange.address);
  //await controler_contract.changeCRVHandler(exchange.address);

  if(network.includes("development") ||
    network.includes("ganache") ||
    network.includes("ropsten")){

    await deployer.link(SafeMath, DummyDex);
    await deployer.deploy(DummyDex);
    dummy = await DummyDex.deployed();
    await exchange.addPath(dummy.address, [crv, usdc]);
  }

  if(network.includes("main")){
    await exchange.addPath("0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"]);//Add CRV->WETH->USDC Path
    await exchange.addPath("0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"]);//Add CRV->WETH->WBTC Path
    await exchange.addPath("0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"]);//Add CRV->WETH

    await exchange.addPath("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"]);//Add CRV->WETH->USDC Path
    await exchange.addPath("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"]);//Add CRV->WETH->WBTC Path
    await exchange.addPath("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", ["0x85Eee30c52B0b379b046Fb0F85F4f3Dc3009aFEC","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2","0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"]);//Add KEEP->WETH->WBTC Path
    await exchange.addPath("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"]);//Add CRV->WETH
    await exchange.addPath("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", ["0xD533a949740bb3306d119CC777fa900bA034cd52","0x6b175474e89094c44da98b954eedeac495271d0f","0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"]);//Add CRV->DAI->WETH
  }
}

module.exports = function(deployer, network, accounts){
deployer
    .then(function() {
      return performMigration(deployer, network, accounts)
    })
    .catch(error => {
      console.log(error)
      process.exit(1)
    })
};
