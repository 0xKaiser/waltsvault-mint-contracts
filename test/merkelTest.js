const {ethers, upgrades, waffle } = require('hardhat');
const {expect} = require('chai');
const { time } = require('@nomicfoundation/hardhat-network-helpers');
const {signTransaction} = require('./signer');
describe('Merkel Claim', async function () {

    let waltsVault, reservation, merkel, ravendale, owner, addr1, addr2, addr3, vestingStartTime;
    before('Setting up the contracts', async function () {

        [owner, addr1, addr2, addr3] = await ethers.getSigners();

        const ERC20 = await ethers.getContractFactory('MockERC20');
        merkel = await upgrades.deployProxy(ERC20, ['MockERC20', 'MERC20']);

        const ERC721 = await ethers.getContractFactory('MockERC721');
        ravendale = await upgrades.deployProxy(ERC721, ['MockERC721', 'MERC721']);

        let WaltsVaultV1 = await ethers.getContractFactory('WaltsVault');
        waltsVault = await upgrades.deployProxy(WaltsVaultV1,['Test WaltsVault', 'Test WV', owner.address]);
        await waltsVault.deployed();

        let WaltsVaultReservationV1 = await ethers.getContractFactory('WaltsVaultReservation');
        reservation = await upgrades.deployProxy(WaltsVaultReservationV1,[ravendale.address,owner.address]);
        await reservation.deployed();


        await ravendale.mint(owner.address,10)
        await ravendale.mint(addr1.address,10)
        await ravendale.mint(addr2.address,10)
        await ravendale.mint(addr3.address,10)


        await waltsVault.toggleController(owner.address);
        await waltsVault.airdrop([owner.address,addr1.address,addr2.address,addr3.address],[10,10,10,10]);


        await merkel.mint(reservation.address,ethers.utils.parseEther('100000000'));
        await merkel.mint(waltsVault.address,ethers.utils.parseEther('150000000'));

        await waltsVault.setMinimumInterval(24*3600)
        await waltsVault.setVestingPeriod(60)
        await waltsVault.setBaseAmount(ethers.utils.parseEther('10000'))
        await waltsVault.setMerkel(merkel.address)
        await waltsVault.setNonceValidityTime(300)
        await waltsVault.setRarityMultiplier(1,10)
        await waltsVault.setRarityMultiplier(2,20)
        await waltsVault.setRarityMultiplier(3,30)
        await waltsVault.toggleBurningStatus();

        await reservation.setMerkelAddress(merkel.address);
        await reservation.setMerkelAllocationPerToken(ethers.utils.parseEther('108000'));
        await reservation.setMinClaimInterval(86400);
        await reservation.setMinAmountReleasedPerInterval(ethers.utils.parseEther('1800'));

    })

    describe('Testing Burn and Claim', async function () {

        it('Should be able to burn WaltsVault token in order to register for claim', async function () {
            const blockNumBefore = await ethers.provider.getBlockNumber();
            const blockBefore = await ethers.provider.getBlock(blockNumBefore);
            const timestampBefore = blockBefore.timestamp;
            let signature1 = await signTransaction(1,1,timestampBefore,waltsVault.address);
            let signature2 = await signTransaction(2,2,timestampBefore,waltsVault.address);
            await waltsVault.burnToClaim([[1,1,timestampBefore,signature1],[2,2,timestampBefore,signature2]])
            await expect(waltsVault.ownerOf(1)).to.be.revertedWith('OwnerQueryForNonexistentToken')
            let signature3 = await signTransaction(1,31,timestampBefore,waltsVault.address);
            let signature4 = await signTransaction(2,32,timestampBefore,waltsVault.address);
            await waltsVault.connect(addr3).burnToClaim([[1,31,timestampBefore,signature3],[2,32,timestampBefore,signature4]])
        })

        it('Should be able to claim after min Time interval', async function () {
            await time.increase(24*3600);
            let unclaimedBalance = await waltsVault.getUnclaimedBalance(owner.address);
            unclaimedBalance = ethers.utils.formatEther(unclaimedBalance);
            unclaimedBalance = parseInt(unclaimedBalance);
            expect(unclaimedBalance).to.equal(4999);
            expect(await merkel.balanceOf(owner.address)).to.equal(0);
            await waltsVault.claimMerkelCoins();
            let balance = await merkel.balanceOf(owner.address);
            balance = ethers.utils.formatEther(balance);
            balance = parseInt(balance);
            expect(balance).to.equal(4999);
        })

        it('Should not be able to claim before min Time interval', async function () {
            await time.increase(22*3600);
            await expect(waltsVault.claimMerkelCoins()).to.be.revertedWith('Nothing to Claim')
        })


        it("Should receive all the tokens if first time claiming after vesting period is over", async function () {

            await time.increase(86400*60);
            let unclaimedBalance = await waltsVault.getUnclaimedBalance(addr3.address);
            unclaimedBalance = ethers.utils.formatEther(unclaimedBalance);
            unclaimedBalance = parseInt(unclaimedBalance);
            // expect(unclaimedBalance).to.equal(300000);
            expect(await merkel.balanceOf(addr3.address)).to.equal(0);
            await waltsVault.connect(addr3).claimMerkelCoins();
            let balance = await merkel.balanceOf(addr3.address);
            balance = ethers.utils.formatEther(balance);
            balance = parseInt(balance);
            expect(balance).to.equal(300000);
        })

        it('Should not be able to claim after full amount is claimed', async function () {
          await expect(waltsVault.connect(addr3).claimMerkelCoins()).to.be.revertedWith('Nothing to Claim')
        })
    })

    describe('Testing Claim by Locking Revendale Tokens', async function () {

        it('Should be able to set vesting start time', async function () {
            const blockNumBefore = await ethers.provider.getBlockNumber();
            const blockBefore = await ethers.provider.getBlock(blockNumBefore);
            vestingStartTime = blockBefore.timestamp;
            await reservation.setVestingStartTime(vestingStartTime);
        })

        it('Should be able to lock ravendale tokens and claim', async function () {
            await ravendale.connect(addr1).setApprovalForAll(reservation.address,true);
            await reservation.connect(addr1).placeOrder([11,12,13,14],[0,0,addr3.address,addr3.address],0,0);
            await time.increase(86400);
            expect(await merkel.balanceOf(addr1.address)).to.equal(0);
            expect(await reservation.getUnclaimedBalance(addr1.address)).to.equal(ethers.utils.parseEther((1800*4).toString()));
            await reservation.connect(addr1).claimMerkel();
            expect(await merkel.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther((1800*4).toString()));
        })

        it('Should not be able claim before min time period', async function () {
            await time.increase(86000);
            await expect(reservation.connect(addr1).claimMerkel()).to.be.revertedWith('Nothing to claim')
        })



        it('Should be able to claim after min time period', async function () {
            await time.increase(401);
            expect(await merkel.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther((1800*4).toString()));
            await reservation.connect(addr1).claimMerkel();
            expect(await merkel.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther((1800*4*2).toString()));
        })

        it('Should be able to claim all token after locking for 60 days', async function () {
            await time.increase(86400*60);
            await ravendale.connect(addr2).setApprovalForAll(reservation.address,true);
            expect(await merkel.balanceOf(addr2.address)).to.equal(0);
            await reservation.connect(addr2).placeOrder([21],[0,0,addr3.address,addr3.address],0,0);

            await reservation.toggleControllers(owner.address);

            await expect(reservation.connect(addr2).getTotalTokensLocked(addr2.address)).to.be.revertedWith('Not controllers')

            expect(await reservation.getUnclaimedBalance(addr2.address)).to.equal(ethers.utils.parseEther((1800*60).toString()));
            await reservation.connect(addr2).claimMerkel();
            expect(await merkel.balanceOf(addr2.address)).to.equal(ethers.utils.parseEther((1800*60).toString()));
            expect(await merkel.balanceOf(addr2.address)).to.equal(await reservation.merkelAllocationPerToken());
            expect(ethers.utils.parseEther((1800*60).toString())).to.equal(await reservation.merkelAllocationPerToken());
        })

        it('Should not be able to claim after all tokens are claimed', async function () {
            expect(await reservation.getUnclaimedBalance(addr2.address)).to.equal(ethers.utils.parseEther((0).toString()));
            await expect(reservation.connect(addr2).claimMerkel()).to.be.revertedWith('Nothing to claim')
        })

    });
});