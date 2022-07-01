const AddressArray = artifacts.require("AddressArray");
const ERC20TokenFactory = artifacts.require("ERC20TokenFactory");
const TrustListFactory = artifacts.require("TrustListFactory");
const ERC20DepositApprover = artifacts.require("ERC20DepositApprover");
const SafeERC20 = artifacts.require("SafeERC20");
const SafeMath = artifacts.require("SafeMath");


async function performMigration(deployer, network, accounts) {
  await AddressArray.deployed();
  await deployer.link(AddressArray, ERC20TokenFactory);
  await deployer.deploy(ERC20TokenFactory);

  await deployer.link(AddressArray, TrustListFactory);
  await deployer.deploy(TrustListFactory);

  await SafeERC20.deployed();
  await SafeMath.deployed();
  await deployer.link(SafeERC20, ERC20DepositApprover);
  await deployer.link(SafeMath, ERC20DepositApprover);
  await deployer.deploy(ERC20DepositApprover);
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
