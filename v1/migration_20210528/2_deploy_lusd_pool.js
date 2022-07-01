const CRV = artifacts.require("CRV");
const LusdPool = artifacts.require("LusdPool");
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

  lusd_pool = await dhelper.readOrCreateContract(LusdPool, [])
  await lusd_pool.setController("0x6c57eA7e3B81b8a166ED5b8E396a401C7a9c890b", "0xa1E263225E24333CA4d26083C94092D6bfEe1DDd")
  console.log("lusd_pool: ", lusd_pool.address);

  //to ringo first
  owner = "0x66945268093f28c28A2dcE11a1640e06c070df7B"
  await lusd_pool.transferOwnership(owner);
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
