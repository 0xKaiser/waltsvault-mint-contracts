const {ethers, upgrades, waffle } = require('hardhat');
const {expect} = require('chai');
const { time } = require('@nomicfoundation/hardhat-network-helpers');
const {signTransaction} = require('./signer');
describe('Merkel Splitter', async function () {

    let merkelSplitter, merkel, owner, addr1, addr2, addr3;
    before('Setting up the contracts', async function () {

        [owner, addr1, addr2, addr3] = await ethers.getSigners();

        const ERC20 = await ethers.getContractFactory('MockERC20');
        merkel = await upgrades.deployProxy(ERC20, ['MockERC20', 'MERC20']);

        const MerkelSplitter = await ethers.getContractFactory('MerkelSplitter');
        merkelSplitter = await upgrades.deployProxy(MerkelSplitter, [merkel.address]);

        await merkel.mint(merkelSplitter.address,ethers.utils.parseEther('100000000'));
    })

    describe('Testing Claim and Split', async function () {

        it("Should be able to add payees", async function () {

            await merkelSplitter.addPayee(addr1.address,5000);
            await merkelSplitter.addPayee(addr2.address,3000);
            await merkelSplitter.addPayee(addr3.address,2000);
            expect(await merkelSplitter.shares(addr1.address)).to.equal(5000);
            expect(await merkelSplitter.shares(addr2.address)).to.equal(3000);
            expect(await merkelSplitter.shares(addr3.address)).to.equal(2000);
        })


        it('Should be not be able to claim before 1 year', async function () {
            await time.increase(86400*364);
            // console.log('364 days have passed since contract deployment');
            // await expect(merkelSplitter.withdraw()).to.be.revertedWith('Claim not started');
        })

        it('Should be able to claim after 13 months', async function () {
            await time.increase(86400*36);
            // await merkelSplitter.withdraw();
            // expect(await merkel.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther('1388888.5'));
            // expect(await merkel.balanceOf(addr2.address)).to.equal(ethers.utils.parseEther('833333.1'));
            // expect(await merkel.balanceOf(addr3.address)).to.equal(ethers.utils.parseEther('555555.4'));
        })

        it("Should return exact value if called after 43 months", async function () {
            await time.increase(86400*30*30);
            // await merkelSplitter.withdraw();
            // expect(await merkel.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther('43055543.5'));
            // expect(await merkel.balanceOf(addr2.address)).to.equal(ethers.utils.parseEther('25833326.1'));
            // expect(await merkel.balanceOf(addr3.address)).to.equal(ethers.utils.parseEther('17222217.4'));
        })

        it("Claiming after 48 months", async function () {
            await time.increase(86400*30*5);
            // await merkelSplitter.withdraw();
            // expect(await merkel.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther('49999986'));
            // expect(await merkel.balanceOf(addr2.address)).to.equal(ethers.utils.parseEther('29999991.6'));
            // expect(await merkel.balanceOf(addr3.address)).to.equal(ethers.utils.parseEther('19999994.4'));
        })

        it("Claiming after 63 months", async function () {
            await time.increase(86400*30*15);
            await merkelSplitter.withdraw();
            expect(await merkel.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther('50000000'));
            expect(await merkel.balanceOf(addr2.address)).to.equal(ethers.utils.parseEther('30000000'));
            expect(await merkel.balanceOf(addr3.address)).to.equal(ethers.utils.parseEther('20000000'));
        })

        it("Claiming after 65 months", async function () {
            await time.increase(86400*30*2);
            await expect(merkelSplitter.withdraw()).to.be.revertedWith('Nothing to claim');

        })

    })

});