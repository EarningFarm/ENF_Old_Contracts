const SethPool = artifacts.require("SethPool");
const SafeERC20 = artifacts.require("SafeERC20");
const SafeMath = artifacts.require("SafeMath");
const CFETHVault = artifacts.require("CFETHVault");
const CFETHController = artifacts.require("CFETHController");


async function performMigration(deployer, network, accounts) {

  await SafeERC20.deployed();

  await deployer.link(SafeERC20, SethPool);
  await deployer.deploy(SethPool);
  s = await SethPool.deployed();


  console.log("SethPool: ", s.address);

  vault = await CFETHVault.deployed()
  controller = await CFETHController.deployed()
  await s.setController(controller.address, vault.address)

  await controller.add_pool(s.address);

  if(network.includes("main")){
    console.log("Transferring ownership")
    owner = "0x66945268093f28c28A2dcE11a1640e06c070df7B"
    await s.transferOwnership(owner)

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
