const { ethers, upgrades, waffle } = require("hardhat");
const Web3 = require("web3");
const { fromWei } = Web3.utils;
const { expect } = require("chai");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Order", async function () {

    let mintController, owner, addr1, addr2, ravendale, wault, price;
    before(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();
        price = 0.928;
        const Mock = await ethers.getContractFactory("TestToken300423");
        ravendale = await upgrades.deployProxy(Mock, ['MockERC721', 'MERC721']);
        await ravendale.deployed();

        const NFT = await ethers.getContractFactory("TestVault");
        wault = await upgrades.deployProxy(NFT, ['WaltsVault', 'WV'], { initializer: 'initialize' });
        await wault.deployed();


        const Order = await ethers.getContractFactory("TestMintController");
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

        let tx = await mintController.mint(10, 0, 0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [0, 0, mintController.address, mintController.address], {value: ethers.utils.parseEther((price).toString())})
        for (let i = 1; i < 11; i++)
            await expect(tx)
                .to.emit(mintController, 'RavendaleClaim')
                .withArgs(owner.address, i);


        await expect(tx)
            .to.emit(mintController, 'RavendaleMint')
            .withArgs(owner.address, 10);

        console.log("Total Balance ", 20);

        await time.increase(86400*2);
        let tx1 = await mintController.mint(0, 0, 2, [], [0, 0, mintController.address, mintController.address], {value: ethers.utils.parseEther((2 * 0.0928).toString())})

        await expect(tx1)
            .to.emit(mintController, 'PublicMint')
            .withArgs(owner.address, 2);
    })
})