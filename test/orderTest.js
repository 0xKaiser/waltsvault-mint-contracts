const { ethers, upgrades, waffle } = require("hardhat");
const Web3 = require("web3");
const { fromWei } = Web3.utils;
const { expect } = require("chai");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Order", async function () {

    let order, owner, addr1, addr2, mock, nft, price;
    before(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();
        price = 0.0928;
        const Mock = await ethers.getContractFactory("TestToken300423");
        mock = await upgrades.deployProxy(Mock, ['MockERC721', 'MERC721']);
        await mock.deployed();

        const NFT = await ethers.getContractFactory("TestVault");
        nft = await upgrades.deployProxy(NFT, ['WaltsVault', 'WV'], { initializer: 'initialize' });
        await nft.deployed();


        const Order = await ethers.getContractFactory("TestMintController");
        order = await upgrades.deployProxy(Order,[]);
        await order.deployed();

        await order.setWaltsVaultAddr(nft.address);
        await order.setRavendaleAddr(mock.address);
        await nft.toggleController(order.address);
        await mock.mint(owner.address, 10);

        await nft.toggleController(owner.address);
        await nft.airdrop([order.address],[10])

        for (let i = 1; i < 11; i++) {
            expect(await mock.ownerOf(i)).to.equal(owner.address);
            // console.log('owner of ', i, ' is ', await mock.ownerOf(i))
        }
        await mock.setApprovalForAll(order.address, true);

    })

    it("Should reserve a slot locking the mock tokens", async function () {
        await time.increase(60*60*4);

        let tx = await order.mint(1, 0, 0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [0, 0, order.address, order.address], {value: ethers.utils.parseEther((1 * price).toString())})
        for (let i = 1; i < 11; i++)
            await expect(tx)
                .to.emit(order, 'RavendaleClaim')
                .withArgs(owner.address, i);


        await expect(tx)
            .to.emit(order, 'RavendaleMint')
            .withArgs(owner.address, 1);

        await time.increase(86400*2);
        let tx1 = await order.mint(0, 0, 2, [], [0, 0, order.address, order.address], {value: ethers.utils.parseEther((2 * price).toString())})

        await expect(tx1)
            .to.emit(order, 'PublicMint')
            .withArgs(owner.address, 2);
    })
})