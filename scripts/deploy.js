const {ethers, upgrades} = require ('hardhat');

async function main() {
    let owner;
    [owner] = await ethers.getSigners();
    // const MockERC721 = await ethers.getContractFactory('MockERC721');
    // let mockERC721 = await upgrades.deployProxy(MockERC721,['MockERC721', 'MERC721']);
    // await mockERC721.deployed();
    // console.log('MockERC721 deployed to:', mockERC721.address);
    // await verify(mockERC721.address, ['MockERC721', 'MERC721'])
    // const mockERC721 = await MockERC721.attach("0x99dB81bEF1b5c7F5458D70590B1726d5046546F8")



    // let tx = await mockERC721.mint("0x455217d7d192a447ea31c7584Dba9cbD84EfD973",20)
    // await tx.wait()
    const WaultsVault = await ethers.getContractFactory('WaltsVaultReservation');
    let waultsVault = await upgrades.upgradeProxy("0xF30d71c7DDA7244842650F3D4D569eeb60C0960b",WaultsVault);
    await waultsVault.deployed();
    console.log('WaultsVault deployed to:', waultsVault.address);
    await verify(waultsVault.address, [])
    // let tx = await waultsVault.openReservation()
    // await tx.wait()
    // console.log('WaultsVault deployed to:', waultsVault.address);
    // // const waltsVault = await WaultsVault.attach("0xcaaB2f368a4B8d8A13C3ce1f88b50D084444c043")
    // tx = await waultsVault.transferOwnership("0xca191a12662c3B875c2cac2Dc7E2EF09dFa20Cf4")
    // await tx.wait()
    // tx = await waultsVault.placeOrder([],[1,1,owner.address,owner.address],0,2, {value: ethers.utils.parseEther("0.02")});
    // await tx.wait()
    // console.log("Transfered ownership")

    // await tx.wait()
    console.log("Transaction hash", tx.hash)
    // await verify(waultsVault.address, [mockERC721.address,owner.address])
}

async function verify (contractAddress, args) {
    console.log('Verify')
    try {
        await hre.run("verify:verify", {
            address: contractAddress,
            constructorArguments: args,
        });
    }catch (e) {
        console.log('The error is ', e)
    }
}
main()