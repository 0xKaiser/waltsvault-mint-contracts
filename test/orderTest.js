const { ethers, upgrades } = require("hardhat");
const Web3 = require("web3");
const { fromWei } = Web3.utils;
const { expect } = require("chai");

describe("Order", async function () {

    let order, owner, addr1, addr2, mock, nft;
    before(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();

        const Mock = await ethers.getContractFactory("MockERC721");
        mock = await Mock.deploy('Mock', 'MOCK');
        await mock.deployed();

        const NFT = await ethers.getContractFactory("WaultsVault");
        nft = await upgrades.deployProxy(NFT, ['WaultsVault', 'WV'], { initializer: 'initialize' });
        await nft.deployed();


        const Order = await ethers.getContractFactory("WaltsVaultReservation");
        order = await Order.deploy(mock.address,owner.address);
        await order.deployed();

        await mock.mint(owner.address, 10);
        await mock.mint(addr1.address, 11);
        await mock.setApprovalForAll(order.address, true);
        await mock.connect(addr1).setApprovalForAll(order.address, true);

    })

    it("Should not allow to reserve spots before opening", async function () {
      await expect(order.connect(addr1).placeOrder([],[1,1,owner.address,owner.address],0,2,{value: ethers.utils.parseEther("0.02")})).to.be.revertedWith("Reservation not started yet")
    })

    

    it("Should reserve a slot locking the mock tokens", async function () {

        let tx = await order.openReservation();
         await expect(tx)
             .to
            .emit(order, "OpenReservation")

        tx = await order.placeOrder([1,2,3],[1,1,owner.address,owner.address],0,0);
        await expect(tx)
            .to
            .emit(order, "PlaceOrder")
            .withArgs(owner.address,3)

        expect(await order.getTotalTokensLockedByAddr(owner.address)).to.equal(3)
        // console.log("Locked tokens by owner: ", await order.getTokensLockedByAddr(owner.address));

        tx = await order.connect(addr1).placeOrder([14,15,16],[1,1,owner.address,owner.address],0,1,{value: ethers.utils.parseEther("0.01")})
        await expect(tx)
            .to
            .emit(order, "PlaceOrder")
            .withArgs(addr1.address,4)

        expect(await order.getTotalTokensLockedByAddr(addr1.address)).to.equal(3)
        // console.log("Locked tokens by addr1: ", await order.getTokensLockedByAddr(addr1.address));
    });

    it("Should revert if the caller is not the owner", async function () {
        await expect(order.connect(addr1).placeOrder([4,5,6],[1,1,owner.address,owner.address],0,0)).to.be.revertedWith("ERC721: transfer from incorrect owner")
        await expect(order.connect(owner).placeOrder([11,12,13],[1,1,owner.address,owner.address],0,0)).to.be.revertedWith("ERC721: transfer from incorrect owner")
    });

    it("Should allow to reserve spots in FCFS", async function () {
        let tx = await order.connect(addr1).placeOrder([],[1,1,owner.address,owner.address],0,1,{value: ethers.utils.parseEther("0.01")});
        await expect(tx)
            .to
            .emit(order, "PlaceOrder")
            .withArgs(addr1.address,1)
    })

    it("Should revert if try to purchase more than the available spots in FCFS", async function () {
       await expect(order.connect(addr1).placeOrder([],[1,1,owner.address,owner.address],0,1,{value: ethers.utils.parseEther("0.01")})).to.be.revertedWith("Exceeds max allowed reservation")
       await expect(order.connect(addr2).placeOrder([],[1,1,owner.address,owner.address],0,3,{value: ethers.utils.parseEther("0.03")})).to.be.revertedWith("Exceeds max allowed reservation")
    })

    it("Should be able to return the mock tokens", async function () {
        await order.startReturn();
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

    it('Mint from contract', async function () {
        await nft.toggleController(owner.address);
        await nft.mint(owner.address, 1);
        await nft.mint(owner.address, 1);
        await nft.mintToMultipleUsers([owner.address], [1]);
    });

})