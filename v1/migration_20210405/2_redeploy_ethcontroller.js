const CFVault = artifacts.require("CFVault");
const USDC = artifacts.require("USDC");
const WBTC = artifacts.require("WBTC");
const CRV = artifacts.require("CRV");
const CFController = artifacts.require("CFController");
const TestUSDCPool = artifacts.require("TestUSDCPool");
const TestUSDCPool2 = artifacts.require("TestUSDCPool2");
const SafeERC20 = artifacts.require("SafeERC20");
const SafeMath = artifacts.require("SafeMath");
const AddressArray = artifacts.require("AddressArray");
const TrustListFactory = artifacts.require("TrustListFactory");
const TrustList = artifacts.require("TrustList");
const ERC20TokenFactory = artifacts.require("ERC20TokenFactory");
const ERC20Token = artifacts.require("ERC20Token");
const ERC20DepositApprover = artifacts.require("ERC20DepositApprover");
const CFETHVault = artifacts.require("CFETHVault");
const CFETHControllerV2 = artifacts.require("CFETHControllerV2");
const CRVExchange = artifacts.require("CRVExchange");
const {DHelper} = require("./util.js");

async function performMigration(deployer, network, accounts, dhelper) {
  console.log("network is ", network);
  if(network.includes("development") ||
    network.includes("ganache") ||
    network.includes("ropsten")){

    crv_contract = await CRV.deployed();
    crv = crv_contract.address;
    egap = 10;
  }
  if(network.includes("main")){
    crv = "0xD533a949740bb3306d119CC777fa900bA034cd52";
    egap = 5760;
  }

  //await SafeMath.deployed();
  //await AddressArray.deployed();
  //await SafeERC20.deployed();
  //await deployer.link(SafeERC20, CFETHControllerV2);
  //await deployer.link(SafeMath, CFETHControllerV2);
  //await deployer.link(AddressArray, CFETHControllerV2);
  //await deployer.deploy(CFETHControllerV2, crv, egap);
  controler_contract = await dhelper.readOrCreateContract(CFETHControllerV2, [SafeMath, AddressArray, SafeERC20], crv, egap)

  //controler_contract = await CFETHControllerV2.deployed();
  //exchange = await CRVExchange.deployed();
  exchange = await dhelper.readOrCreateContract(CRVExchange);
  await controler_contract.changeCRVHandler(exchange.address);

  await controler_contract.changeHarvestFee(1000);
  await controler_contract.changeFeePool("0x39F4Ef6294512015AB54ed3ab32BAA1794E8dE70");

  console.log("CFController: ", controler_contract.address);

}

module.exports = function(deployer, network, accounts){
deployer
    .then(function() {
      return performMigration(deployer, network, accounts, DHelper(deployer, network, accounts))
    })
    .catch(error => {
      console.log(error)
      process.exit(1)
    })
};
