const HbtcPool = artifacts.require("HbtcPool");
const BbtcPool = artifacts.require("BbtcPool");
const TbtcPool = artifacts.require("TbtcPool");
const SafeERC20 = artifacts.require("SafeERC20");
const SafeMath = artifacts.require("SafeMath");

const CFVault = artifacts.require("CFVault");
const CFController = artifacts.require("CFController");


async function performMigration(deployer, network, accounts) {

  await SafeERC20.deployed();
  await deployer.link(SafeERC20, HbtcPool);
  await deployer.deploy(HbtcPool);
  h = await HbtcPool.deployed();

  await deployer.link(SafeERC20, BbtcPool);
  await deployer.deploy(BbtcPool);
  b = await BbtcPool.deployed();

  await deployer.link(SafeERC20, TbtcPool);
  await deployer.deploy(TbtcPool);
  t = await TbtcPool.deployed();

  console.log("HbtcPool: ", h.address);
  console.log("BbtcPool: ", b.address);
  console.log("TbtcPool: ", t.address);

  vault = await CFVault.deployed()
  controller = await CFController.deployed()
  await h.setController(controller.address, vault.address)
  await b.setController(controller.address, vault.address)
  await t.setController(controller.address, vault.address)

  await controller.add_pool(h.address);
  await controller.add_pool(b.address);
  await controller.add_pool(t.address);


  if(network.includes("main")){
    console.log("Transferring ownership")
    owner = "0x66945268093f28c28A2dcE11a1640e06c070df7B"
    await h.transferOwnership(owner)
    await b.transferOwnership(owner)
    await t.transferOwnership(owner)

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
