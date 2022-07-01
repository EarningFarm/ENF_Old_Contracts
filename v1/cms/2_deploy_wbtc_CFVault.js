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
const CRVExchange = artifacts.require("CRVExchange");

async function performMigration(deployer, network, accounts) {
  console.log("network is ", network);
  if(network.includes("development") ||
    network.includes("ganache") ||
    network.includes("ropsten")){
    await deployer.deploy(WBTC);

    wbtc_contract = await WBTC.deployed();
    wbtc = wbtc_contract.address;
    crv_contract = await CRV.deployed();
    crv = crv_contract.address;
    egap = 10;
  }
  if(network.includes("main")){
    wbtc = "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599";
    crv = "0xD533a949740bb3306d119CC777fa900bA034cd52";
    egap = 5760;
  }

  tlistfactory = await TrustListFactory.at("0x21991E2cDD280558A398814e20a36E244d014520");
  tx = await tlistfactory.createTrustList(['0x0000000000000000000000000000000000000000']);
  tlist = await TrustList.at(tx.logs[0].args.addr);

  tf = await ERC20TokenFactory.at("0x7eeCa09D822BCfDe306947C015ca7Bff4223d3c3");

  tx = await tf.createCloneToken('0x0000000000000000000000000000000000000000', 0, "ENF_vBTC", 18, "ENF_vBTC", true, tlist.address);
  cft = await ERC20Token.at(tx.logs[0].args._cloneToken);


  //da = await ERC20DepositApprover.deployed();

  await SafeMath.deployed();
  await AddressArray.deployed();
  await SafeERC20.deployed();
  await deployer.link(SafeERC20, CFController);
  await deployer.link(SafeMath, CFController);
  await deployer.link(AddressArray, CFController);
  await deployer.deploy(CFController, crv, wbtc, egap);

  controller_contract = await CFController.deployed();
  exchange = await CRVExchange.at("0x65Ff67D6a61Ae6bab8821c584f5f394D35e9b50e");
  await controller_contract.changeCRVHandler(exchange.address);

  //Add Keep here
  await controller_contract.changeExtraToken("0x85Eee30c52B0b379b046Fb0F85F4f3Dc3009aFEC");
  await controller_contract.changeHarvestFee(1000);
  await controller_contract.changeFeePool("0x39F4Ef6294512015AB54ed3ab32BAA1794E8dE70");

  await deployer.link(SafeMath, CFVault);
  await deployer.deploy(CFVault, wbtc, cft.address, controller_contract.address);

  vault = await CFVault.deployed();
  await vault.set_slippage(9975);
  await vault.changeWithdrawFee(50);
  await vault.changeFeePool("0x39F4Ef6294512015AB54ed3ab32BAA1794E8dE70");
  console.log('----- WBTC address -----');
  console.log("CFToken trust list: ", tlist.address);
  console.log("CFToken: ", cft.address);
  //console.log("ERC20DepositApprover: ", da.address);

  console.log("CFVault: ", vault.address);
  console.log("CFController: ", controller_contract.address);
  console.log("WBTC: ", wbtc);
  console.log("CRV: ", crv);
  await tlist.add_trusted(vault.address);

  if(network.includes("development") ||
    network.includes("ganache") ||
    network.includes("ropsten")){
    await deployer.link(SafeERC20, TestUSDCPool);
    await deployer.link(SafeMath, TestUSDCPool);
    await deployer.deploy(TestUSDCPool, wbtc, crv);
    up = await TestUSDCPool.deployed();
    await controller_contract.add_pool(up.address)

    await deployer.link(SafeERC20, TestUSDCPool2);
    await deployer.link(SafeMath, TestUSDCPool2);
    await deployer.deploy(TestUSDCPool2, wbtc, crv);
    up2 = await TestUSDCPool2.deployed();
    await controller_contract.add_pool(up2.address)
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
