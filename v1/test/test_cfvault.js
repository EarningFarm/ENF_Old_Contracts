const TestERC20 = artifacts.require("TestERC20");
const { BN, constants, expectEvent, expectRevert  } = require('openzeppelin-test-helpers');
const { expect  } = require('chai');
const getBlockNumber = require('./blockNumber')(web3)
const CFVault = artifacts.require("CFVault");
const CFController = artifacts.require("CFController");
const USDC = artifacts.require("USDC");
const CRV = artifacts.require("CRV");
const TestUSDCPool = artifacts.require("TestUSDCPool");
const TestUSDCPool2 = artifacts.require("TestUSDCPool2");
const CRVExchange = artifacts.require("CRVExchange");
const ERC20DepositApprover = artifacts.require("ERC20DepositApprover");
const ERC20Token = artifacts.require("ERC20Token");

contract('CFVault', (accounts) =>{
  let approver = {}
  let cft = {}
  let vault = {}
  let crv = {}
  let usdc = {}
  let b = {}
  let lp_token = {}
  let controller = {}
  let tpool = {}
  let tpool2 = {}


  context('init', () =>{
    it('init', async() =>{
      vault = await CFVault.deployed();
      //usdc = await USDC.deployed();
      usdc = await USDC.at(await vault.target_token());
      crv = await CRV.deployed();
      controller = await CFController.at(await vault.controller());
      tpool = await TestUSDCPool.deployed();
      cft = await ERC20Token.at(await vault.lp_token());
      approver = await ERC20DepositApprover.deployed();

      tpool2 = await TestUSDCPool2.deployed();
      lp_token = await TestERC20.at(await tpool.lp_addr());

      await usdc.issue(accounts[0], 1000000000000);
    });

    it('deposit', async() =>{
      //await usdc.approve(vault.address, 10000000);
      //await vault.deposit(10000000, {from:accounts[0]});
      await usdc.approve(approver.address, 10000000, {from:accounts[0]});
      await approver.deposit(usdc.address, 10000000, vault.address, cft.address, {from:accounts[0]});
      b = (await cft.balanceOf(accounts[0])).toString();
      console.log("amount after deposit: ", (await usdc.balanceOf(accounts[0])).toNumber());
      console.log("lp supply: ", (await lp_token.totalSupply()).toString());
      console.log("balance b1 : ", b);
    });
    it('withdraw', async() =>{
      await vault.withdraw(b, {from:accounts[0]})
      console.log("amount after withdraw: ", (await usdc.balanceOf(accounts[0])).toNumber());
    });

    it('deposit and withdraw with fee', async() =>{
      await vault.changeWithdrawFee(100);
      await vault.changeFeePool(accounts[1]);

      //await usdc.approve(vault.address, 1000000);
      //await vault.deposit(1000000, {from:accounts[0]});
      await usdc.approve(approver.address, 1000000);
      tx1 = await approver.deposit(usdc.address, 1000000, vault.address, cft.address, {from:accounts[0]});
      b = (await cft.balanceOf(accounts[0])).toString();
      console.log("balance b : ", b);
      console.log("total supply : ", (await cft.totalSupply()).toString());
      tx2 = await vault.withdraw(b, {from:accounts[0]});
      console.log('deposit tx: ', tx1.receipt.rawLogs);
      console.log('withdraw tx: ', tx2.receipt.rawLogs);

      b = (await usdc.balanceOf(accounts[1])).toNumber();
      expect(b).to.equal(10000);
      await vault.changeWithdrawFee(0);
    });

    it('deposit without withdraw', async() =>{
      //await usdc.approve(vault.address, 1000000);
      //await vault.deposit(1000000, {from:accounts[0]});
      await usdc.approve(approver.address, 1000000);
      await approver.deposit(usdc.address, 1000000, vault.address, cft.address, {from:accounts[0]});
    })

    it('switch pool and withdraw', async() =>{
      await controller.change_current_pool(tpool2.address, {from:accounts[0]});

      b1 = (await tpool.get_lp_token_balance()).toNumber();
      expect(b1).to.equal(0);

      b2 = (await tpool2.get_lp_token_balance()).toString();
      expect(b2).to.not.equal("0");
      before = (await usdc.balanceOf(accounts[0])).toNumber();
      b = (await cft.balanceOf(accounts[0])).toString();
      await vault.withdraw(b, {from:accounts[0]});
      after = (await usdc.balanceOf(accounts[0])).toNumber();
      expect(after).to.equal(before + 1000000);
    });

    it('exchange crv in dex', async() =>{
      b1 = (await tpool2.get_lp_token_balance()).toString();
      await controller.earnCRV();
      b2 = (await tpool2.get_lp_token_balance()).toString();
      expect(b1).to.not.equal(b2);
    });

  })
});
