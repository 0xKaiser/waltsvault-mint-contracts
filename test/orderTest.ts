import { expect } from "chai";
import {ethers, upgrades} from "hardhat";
describe("Order", async function () {

    let order: any, owner: any, addr1: any, addr2: any, mock:any;
    beforeEach(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();

        const Mock = await ethers.getContractFactory("MockERC721");
        mock = await Mock.deploy();
        await mock.deployed();


        const Order = await ethers.getContractFactory("WaltsVaultReservation");
        order = await Order.deploy();
        await order.deployed();

        await mock.mint(addr1.address, 10);
        await mock.setApprovalForAll(order.address, true);

    })

    it("Should create a new order by locking the mock tokens", async function () {

        let tx = await order.openReservation();
         await expect(tx)
             .to
            .emit(order, "openReservation")

    });

})