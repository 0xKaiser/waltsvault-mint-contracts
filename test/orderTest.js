const { ethers, upgrades, waffle } = require("hardhat");
const Web3 = require("web3");
const { fromWei } = Web3.utils;
const { expect } = require("chai");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Order", async function () {

    let mintController, owner, addr1, addr2, ravendale, wault, price;
    before(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();
        price = 0.0928;
        const Mock = await ethers.getContractFactory("TestToken300423");
        ravendale = await upgrades.deployProxy(Mock, ['MockERC721', 'MERC721']);
        await ravendale.deployed();

        const NFT = await ethers.getContractFactory("WaltsVault");
        wault = await upgrades.deployProxy(NFT, ['WaltsVault', 'WV'], { initializer: 'initialize' });
        await wault.deployed();

        const Order = await ethers.getContractFactory("WaltsVaultMintController");
        mintController = await upgrades.deployProxy(Order,[]);
        await mintController.deployed();

        await mintController.setWaltsVaultAddr(wault.address);
        await mintController.setRavendaleAddr(ravendale.address);
        await wault.toggleController(mintController.address);
        await ravendale.mint(owner.address, 10);

        await wault.toggleController(owner.address);
        await wault.airdrop([mintController.address],[10])

        for (let i = 1; i < 11; i++) {
            expect(await ravendale.ownerOf(i)).to.equal(owner.address);
            // console.log('owner of ', i, ' is ', await ravendale.ownerOf(i))
        }
        await ravendale.setApprovalForAll(mintController.address, true);

    })

    it("Should reserve a slot locking the ravendale tokens", async function () {
        await time.increase(60*60*4);

        // await mintController.setAvailableSupply(10);

//      uint16 amountRD,
// 		uint16 amountVL,
// 		uint16 amountPUBLIC,
// 		uint256[] calldata tokensToLockRD,
// 		signedData memory spotsDataVL

        await mintController.mint(2,2,0,[1,2,3],[0,3,owner.address, owner.address],{value: ethers.utils.parseEther((4 * price).toString())})
        console.log('Available amount', await mintController.AVAILABLE_AMOUNT_FOR_VL());

        await mintController.connect(addr1).mint(0,2,0,[],[0,3,owner.address, owner.address],{value: ethers.utils.parseEther((2 * price).toString())})
        console.log('Available amount', await mintController.AVAILABLE_AMOUNT_FOR_VL());

        // await mintController.setAvailableSupply(0);

        await mintController.mint(2,0,0,[4,5,6],[0,3,owner.address, owner.address],{value: ethers.utils.parseEther((2 * price).toString())})
        console.log('Available amount', await mintController.AVAILABLE_AMOUNT_FOR_VL());
        console.log(await mintController.getTokensLockedByAddr(owner.address));
        console.log(await mintController.lockerOf(1))
        console.log(await mintController.lockerOf(2))
        console.log(await mintController.lockerOf(3))
        await mintController.releaseRavendale([owner.address]);
        console.log(await mintController.getTokensLockedByAddr(owner.address))
        console.log(await mintController.lockerOf(1))
        console.log(await mintController.lockerOf(2))
        console.log(await mintController.lockerOf(3))
    })
})