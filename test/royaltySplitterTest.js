const {ethers, upgrades, waffle } = require('hardhat');
const {expect} = require('chai');

describe('RoyaltySplitter', async function () {

    let splitter, erc20, erc721,  owner, addr1, addr2, addr3, dump;
    before('Setting up the contracts',async function () {

        [owner, addr1, addr2, addr3, dump] = await ethers.getSigners();

        const ERC20 = await ethers.getContractFactory('MockERC20');
        erc20 = await upgrades.deployProxy(ERC20, ['MockERC20', 'MERC20']);

        const ERC721 = await ethers.getContractFactory('MockERC721');
        erc721 = await upgrades.deployProxy(ERC721, ['MockERC721', 'MERC721']);


        const RoyaltySplitter = await ethers.getContractFactory('WaltsVaultFundsSplitter');
        splitter = await upgrades.deployProxy(RoyaltySplitter, [erc721.address, erc20.address]);

        let tx = await owner.sendTransaction({to: splitter.address, value: ethers.utils.parseEther('100')});
        await expect(tx)
            .to
            .emit(splitter, "FundsReceived")
            .withArgs(owner.address, ethers.utils.parseEther('100'))

        await erc20.mint(splitter.address, ethers.utils.parseEther('100'));

        await erc721.mint(addr2.address, 10);
        await erc721.mint(addr1.address, 10);
        await erc721.mint(dump.address, 80);

        expect(await erc721.balanceOf(addr2.address)).to.equal(10);
        expect(await erc721.balanceOf(addr1.address)).to.equal(10);
        expect(await erc721.balanceOf(dump.address)).to.equal(80);

        expect(await erc20.balanceOf(splitter.address)).to.equal(ethers.utils.parseEther('100'));

        expect(await splitter.owner()).to.equal(owner.address);

    })

    it('Should split the funds correctly', async function () {

        const provider = waffle.provider;
        const ownerBalanceBeforeClaim = await provider.getBalance(owner.address);

        let tx = await splitter.claimFunds()
        await expect(tx)
            .to
            .emit(splitter, "FundsReleased")
            .withArgs(owner.address, ethers.utils.parseEther('50'), ethers.utils.parseEther('50'))

        expect(await erc20.balanceOf(splitter.address)).to.equal(ethers.utils.parseEther('50'));
        expect(await erc20.balanceOf(owner.address)).to.equal(ethers.utils.parseEther('50'));
        const ownerBalanceAfterClaim = await provider.getBalance(owner.address);

        expect(Math.ceil(ethers.utils.formatEther(ownerBalanceAfterClaim.sub(ownerBalanceBeforeClaim)))).to.equal(50);
        expect(await splitter.ETH_FUNDS_STORED_FOR_HOLDERS()).to.equal(ethers.utils.parseEther('50'));
        expect(await splitter.WETH_FUNDS_STORED_FOR_HOLDERS()).to.equal(ethers.utils.parseEther('50'));
        expect(await splitter.WETH_FUNDS_STORED_FOR_CREATOR()).to.equal(0);
        expect(await splitter.WETH_FUNDS_STORED_FOR_HOLDERS()).to.equal(ethers.utils.parseEther('50'));

        await expect(splitter.claimFunds())
            .to
            .be
            .revertedWith("No outstanding funds left to release")

    })

    it('Should split the funds correctly to Addr1 holding 10 tokens', async function () {

        let tx = await splitter.connect(addr1).claimFunds()
        await expect(tx)
            .to
            .emit(splitter, "FundsReleased")
            .withArgs(addr1.address, ethers.utils.parseEther('5'), ethers.utils.parseEther('5'))


        await expect(splitter.connect(addr1).claimFunds())
            .to
            .be
            .revertedWith("No outstanding funds left to release")
    })

    it('Should split the funds correctly to Addr2 holding 10 tokens', async function () {

            let tx = await splitter.connect(addr2).claimFunds()
            await expect(tx)
                .to
                .emit(splitter, "FundsReleased")
                .withArgs(addr2.address, ethers.utils.parseEther('5'), ethers.utils.parseEther('5'))

            await expect(splitter.connect(addr2).claimFunds())
                .to
                .be
                .revertedWith("No outstanding funds left to release")
    })

    it('Should split the funds correctly to Dump holding 80 tokens', async function () {

            let tx = await splitter.connect(dump).claimFunds()
            await expect(tx)
                .to
                .emit(splitter, "FundsReleased")
                .withArgs(dump.address, ethers.utils.parseEther('40'), ethers.utils.parseEther('40'))

            await expect(splitter.connect(dump).claimFunds())
                .to
                .be
                .revertedWith("No outstanding funds left to release")
    })

    it("Check funds inside the contract", async function () {

        const provider = waffle.provider;

        const balanceOfSplitter = await provider.getBalance(splitter.address);
        expect(balanceOfSplitter).to.equal(0);
        const wethBalanceOfSplitter = await erc20.balanceOf(splitter.address);
        expect(wethBalanceOfSplitter).to.equal(0);
    })

    it("Send funds inside the contract again", async function () {


        let tx = await owner.sendTransaction({to: splitter.address, value: ethers.utils.parseEther('100')});
        await expect(tx)
            .to
            .emit(splitter, "FundsReceived")
            .withArgs(owner.address, ethers.utils.parseEther('100'))
    })

    it("Try claiming funds from addr1 wallet", async function () {

        const provider = waffle.provider;

        const addr1BalanceBeforeClaim = await provider.getBalance(addr1.address);

        let tx = await splitter.connect(addr1).claimFunds()
        const addr1BalanceAfterClaim = await provider.getBalance(addr1.address);
        expect(Math.ceil(ethers.utils.formatEther(addr1BalanceAfterClaim.sub(addr1BalanceBeforeClaim)))).to.equal(5);
        await expect(tx)
            .to
            .emit(splitter, "FundsReleased")
            .withArgs(addr1.address, ethers.utils.parseEther('5'), ethers.utils.parseEther('0'))
    })


    it("Try claiming funds from owner wallet", async function () {

        const provider = waffle.provider;

        const addr1BalanceBeforeClaim = await provider.getBalance(owner.address);

        let tx = await splitter.claimFunds()
        const addr1BalanceAfterClaim = await provider.getBalance(owner.address);
        expect(Math.ceil(ethers.utils.formatEther(addr1BalanceAfterClaim.sub(addr1BalanceBeforeClaim)))).to.equal(50);
        await expect(tx)
            .to
            .emit(splitter, "FundsReleased")
            .withArgs(owner.address, ethers.utils.parseEther('50'), ethers.utils.parseEther('0'))

    })

})