const TestAddressList = artifacts.require("TestAddressList");
const AddressArray = artifacts.require("AddressArray")
const TestTokenClaimer = artifacts.require("TestTokenClaimer");
const USDT = artifacts.require("USDT");
const StdERC20 = artifacts.require("StdERC20");
const TestERC20 = artifacts.require("TestERC20");
const SafeERC20 = artifacts.require("SafeERC20");
const SafeMath = artifacts.require("SafeMath");
const TestUSDCPool = artifacts.require("TestUSDCPool");
const USDC = artifacts.require("USDC");
const CRV = artifacts.require("CRV");


async function performMigration(deployer, network, accounts) {
  console.log("network is ", network);
  if(network.includes("development") ||
    network.includes("ganache")
    ){
    await AddressArray.deployed();
    await deployer.link(AddressArray, TestAddressList);
    await deployer.deploy(TestAddressList);
    await deployer.deploy(TestTokenClaimer);
    await deployer.deploy(USDT);
    await deployer.deploy(StdERC20);
    await SafeMath.deployed();
    await deployer.link(SafeMath, TestERC20);
    await deployer.deploy(TestERC20, "TEST", 18, "TST");

    await deployer.deploy(USDC);
    await deployer.deploy(CRV);
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
