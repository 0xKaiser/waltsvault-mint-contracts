const { ethers, upgrades, waffle } = require("hardhat");
const Web3 = require("web3");
const { fromWei } = Web3.utils;
const { expect } = require("chai");

describe("Order", async function () {

    let order, owner, addr1, addr2, mock, nft, price;
    before(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();
        price = 10;
        const Mock = await ethers.getContractFactory("MockERC721");
        mock = await upgrades.deployProxy(Mock, ['MockERC721', 'MERC721']);
        await mock.deployed();

        const NFT = await ethers.getContractFactory("WaltsVault");
        nft = await upgrades.deployProxy(NFT, ['WaltsVault', 'WV', owner.address], { initializer: 'initialize' });
        await nft.deployed();


        const Order = await ethers.getContractFactory("WaltsVaultReservation");
        order = await upgrades.deployProxy(Order,[mock.address,owner.address]);
        await order.deployed();
        await order.setReservationPrice(ethers.utils.parseEther(price.toString()))

        await mock.mint(owner.address, 10);
        await mock.mint(addr1.address, 11);
        await mock.setApprovalForAll(order.address, true);
        await mock.connect(addr1).setApprovalForAll(order.address, true);

        await order.toggleControllers(owner.address);
    })

    it("Should not allow to reserve spots before opening", async function () {
      await expect(order.connect(addr1).placeOrder([],[1,1,owner.address,owner.address],0,2,{value: ethers.utils.parseEther((price*2).toString())})).to.be.revertedWith("Reservation not live")
    })

    it("Should reserve a slot locking the mock tokens", async function () {

        let tx = await order.openReservation();
         await expect(tx)
             .to
            .emit(order, "OpenReservation")

        tx = await order.placeOrder([1,2,3],[1,1,owner.address,owner.address],0,0);
        await expect(tx)
            .to
            .emit(order, "LockRavendale")
            .withArgs(owner.address,3)

        expect(await order.getTotalTokensLocked(owner.address)).to.equal(3)

        tx = await order.connect(addr1).placeOrder([14,15,16],[1,1,owner.address,owner.address],0,1,{value: ethers.utils.parseEther((price*1).toString())})
        await expect(tx)
            .to
            .emit(order, "LockRavendale")
            .withArgs(addr1.address,14)
        await expect(tx)
            .to
            .emit(order, "Reserve")
            .withArgs(addr1.address,1)

        expect(await order.getTotalTokensLocked(addr1.address)).to.equal(3)
        // console.log("Locked tokens by addr1: ", await order.getTokensLockedByAddr(addr1.address));
    });

    it("Should revert if the caller is not the owner", async function () {
        await expect(order.connect(addr1).placeOrder([4,5,6],[1,1,owner.address,owner.address],0,0)).to.be.revertedWith("ERC721: transfer from incorrect owner")
        await expect(order.connect(owner).placeOrder([11,12,13],[1,1,owner.address,owner.address],0,0)).to.be.revertedWith("ERC721: transfer from incorrect owner")
    });

    it("Should allow to reserve spots in FCFS", async function () {
        let tx = await order.connect(addr1).placeOrder([],[1,1,owner.address,owner.address],0,1,{value: ethers.utils.parseEther((price*1).toString())});
        await expect(tx)
            .to
            .emit(order, "Reserve")
            .withArgs(addr1.address,1)
        await order.connect(addr2).placeOrder([],[1,1,owner.address,owner.address],0,2,{value: ethers.utils.parseEther((price*2).toString())});
    })

    it("Should revert if try to purchase more than the available spots in FCFS", async function () {
       await expect(order.connect(addr1).placeOrder([],[1,1,owner.address,owner.address],0,1,{value: ethers.utils.parseEther((price*1).toString())})).to.be.revertedWith("Exceeding reservation allowance")
       await expect(order.connect(addr2).placeOrder([],[1,1,owner.address,owner.address],0,3,{value: ethers.utils.parseEther((price*3).toString())})).to.be.revertedWith("Exceeding reservation allowance")
    })

    it("Should be able to return the mock tokens", async function () {
        expect(await mock.ownerOf(1)).to.equal(order.address)
        expect(await mock.ownerOf(2)).to.equal(order.address)
        expect(await mock.ownerOf(3)).to.equal(order.address)
        expect(await mock.ownerOf(14)).to.equal(order.address)
        expect(await mock.ownerOf(15)).to.equal(order.address)
        expect(await mock.ownerOf(16)).to.equal(order.address)
        let tx = await order.releaseRavendale([owner.address,addr1.address]);
        for(let i = 1; i <= 3; i++){
            await expect(tx)
                .to
                .emit(order, "ReleaseRavendale")
                .withArgs(owner.address, i)
        }
        for(let i = 14; i <= 16; i++){
            await expect(tx)
                .to
                .emit(order, "ReleaseRavendale")
                .withArgs(addr1.address, i)
        }
        expect(await mock.ownerOf(1)).to.equal(owner.address)
        expect(await mock.ownerOf(2)).to.equal(owner.address)
        expect(await mock.ownerOf(3)).to.equal(owner.address)
        expect(await mock.ownerOf(14)).to.equal(addr1.address)
        expect(await mock.ownerOf(15)).to.equal(addr1.address)
        expect(await mock.ownerOf(16)).to.equal(addr1.address)
    })

    it("Airdropping Single Token", async ()=> {
        await nft.toggleController(owner.address)
        let tx = await nft.airdrop([addr1.address], [1]);
    })


})