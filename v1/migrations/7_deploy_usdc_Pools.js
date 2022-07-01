const CompoundPool = artifacts.require("CompoundPool");
const BUSDPool = artifacts.require("BUSDPool");
const TriPool = artifacts.require("TriPool");
const YPool = artifacts.require("YPool");
const GUSDPool = artifacts.require("GUSDPool");
const AavePool = artifacts.require("AavePool");

const SafeERC20 = artifacts.require("SafeERC20");
const SafeMath = artifacts.require("SafeMath");
const CFVault = artifacts.require("CFVault");
const CFController = artifacts.require("CFController");


async function performMigration(deployer, network, accounts) {

  await SafeERC20.deployed();
  await SafeMath.deployed();

  await deployer.link(SafeERC20, CompoundPool);
  await deployer.deploy(CompoundPool);

  await deployer.link(SafeERC20, YPool);
  await deployer.deploy(YPool);

  await deployer.link(SafeERC20, BUSDPool);
  await deployer.deploy(BUSDPool);

  await deployer.link(SafeERC20, TriPool);
  await deployer.deploy(TriPool);

  await deployer.link(SafeERC20, AavePool);
  await deployer.deploy(AavePool);

  await deployer.link(SafeERC20, GUSDPool);
  await deployer.deploy(GUSDPool);

  c = await CompoundPool.deployed();
  b = await BUSDPool.deployed();
  t = await TriPool.deployed();
  y = await YPool.deployed();
  a = await AavePool.deployed();
  g = await GUSDPool.deployed();
  console.log("CompoundPool: ", c.address);
  console.log("BUSDPool: ", b.address);
  console.log("TriPool: ", t.address);
  console.log("YPool: ", y.address);
  console.log("AavePool: ", a.address);
  console.log("GUSDPool: ", g.address);

  vault = await CFVault.deployed()
  controller = await CFController.deployed()
  await c.setController(controller.address, vault.address)
  await b.setController(controller.address, vault.address)
  await t.setController(controller.address, vault.address)
  await y.setController(controller.address, vault.address)
  await a.setController(controller.address, vault.address)
  await g.setController(controller.address, vault.address)

  await controller.add_pool(c.address);
  await controller.add_pool(b.address);
  await controller.add_pool(t.address);
  await controller.add_pool(y.address);
  await controller.add_pool(a.address);
  await controller.add_pool(g.address);

  if(network.includes("main")){
    console.log("Transferring ownership")
    owner = "0x66945268093f28c28A2dcE11a1640e06c070df7B"
    await c.transferOwnership(owner)
    await b.transferOwnership(owner)
    await t.transferOwnership(owner)
    await y.transferOwnership(owner)
    await a.transferOwnership(owner)
    await g.transferOwnership(owner)

    await vault.transferOwnership(owner)
    await controller.transferOwnership(owner)
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
