const CFVault = artifacts.require("CFVault");
const USDC = artifacts.require("USDC");
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
const CRVExchange = artifacts.require("CRVExchange");

async function performMigration(deployer, network, accounts) {
  console.log("network is ", network);
  if(network.includes("development") ||
    network.includes("ganache") ||
    network.includes("ropsten")){

    usdc_contract = await USDC.deployed();
    usdc = usdc_contract.address;
    crv_contract = await CRV.deployed();
    crv = crv_contract.address;
    egap = 10;
  }
  if(network.includes("main")){
    usdc = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    crv = "0xD533a949740bb3306d119CC777fa900bA034cd52";
    egap = 5760;
  }

  tlistfactory = await TrustListFactory.deployed();
  tx = await tlistfactory.createTrustList(['0x0000000000000000000000000000000000000000']);
  tlist = await TrustList.at(tx.logs[0].args.addr);

  tf = await ERC20TokenFactory.deployed();

  tx = await tf.createCloneToken('0x0000000000000000000000000000000000000000', 0, "ENF_vUSDC", 18, "ENF_vUSDC", true, tlist.address);
  cft = await ERC20Token.at(tx.logs[0].args._cloneToken);

  da = await ERC20DepositApprover.deployed();

  await SafeMath.deployed();
  await AddressArray.deployed();
  await SafeERC20.deployed();
  await deployer.link(SafeERC20, CFController);
  await deployer.link(SafeMath, CFController);
  await deployer.link(AddressArray, CFController);
  await deployer.deploy(CFController, crv, usdc, egap);

  controler_contract = await CFController.deployed();
  exchange = await CRVExchange.deployed();
  await controler_contract.changeCRVHandler(exchange.address);

  await controler_contract.changeHarvestFee(1000);
  await controler_contract.changeFeePool("0x39F4Ef6294512015AB54ed3ab32BAA1794E8dE70");

  await deployer.link(SafeMath, CFVault);
  await deployer.deploy(CFVault, usdc, cft.address, controler_contract.address);

  vault = await CFVault.deployed();
  await vault.set_slippage(9975);
  await vault.changeWithdrawFee(50);
  await vault.changeFeePool("0x39F4Ef6294512015AB54ed3ab32BAA1794E8dE70");

  console.log('----- USDC address -----');
  console.log("CFToken trust list: ", tlist.address);
  console.log("CFToken: ", cft.address);
  console.log("ERC20DepositApprover: ", da.address);

  console.log("CFVault: ", vault.address);
  console.log("CFController: ", controler_contract.address);
  console.log("USDC: ", usdc);
  console.log("CRV: ", crv);
  await tlist.add_trusted(vault.address);

  if(network.includes("development") ||
    network.includes("ganache") ||
    network.includes("ropsten")){
    await deployer.link(SafeERC20, TestUSDCPool);
    await deployer.link(SafeMath, TestUSDCPool);
    await deployer.deploy(TestUSDCPool, usdc, crv);
    up = await TestUSDCPool.deployed();
    await controler_contract.add_pool(up.address)

    await deployer.link(SafeERC20, TestUSDCPool2);
    await deployer.link(SafeMath, TestUSDCPool2);
    await deployer.deploy(TestUSDCPool2, usdc, crv);
    up2 = await TestUSDCPool2.deployed();
    await controler_contract.add_pool(up2.address)
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
