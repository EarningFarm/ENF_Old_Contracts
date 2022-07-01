const fs = require("fs");

var DHelper = function(_deployer, _network, _accounts){
  if (!(this instanceof DHelper)) {
    return new DHelper(_deployer, _network, _accounts)
  }

  var deployer = _deployer;
  var network = _network;
  var accounts = _accounts;

  var file_path = "contract_info.json";

  this.readOrCreateContract = async function(contract, libraries, ...args) {
    const data = JSON.parse(fs.readFileSync(file_path, 'utf-8').toString());
    if(network.includes("main")){
      address = data["main"][contract._json.contractName]
      if(address){
        console.log("Using exised contract ", contract.name, " at ", address)
        return await contract.at(address)
      }
    }

    for(let lib of libraries ){
      if(network.includes("main")){
        var r= {};
        r.contract_name = lib._json.contractName;
        address = data["main"][lib._json.contractName]
        r.address = address
	      lib.networks["1"] = {"address":address}
	      await deployer.link(lib, contract);
	      console.log("linked ", r.contract_name, ":", r.address, " to ", contract._json.contractName);
      }else{
        await deployer.link(lib, contract)
      }
    }
    await deployer.deploy(contract, ...args);
    return await contract.deployed();
  }

}

module.exports = {DHelper }
