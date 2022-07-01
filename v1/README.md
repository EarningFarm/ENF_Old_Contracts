
### Migrate

1. Link truffle-config.js and remember checking the gas price.

  ln -s truffle-config.mainnet.js truffle-config.js

2. check which account to use

  echo $ACCOUNT
  export ACCOUNT=0xxxxx

3. Do migration
  truffle migrate --network main

#### Migrate to ropsten
  ln -s truffle-config.ropsten.js truffle-config.js
  truffle migrate --network main



### Using Mainnet to test

  brownie test test/test_CFF.py  -s --network mainnet-fork

  brownie test test/test_CFF.py::test_CompoundPool  -s --network mainnet-fork
