import {ethers, upgrades} from 'hardhat';

async function main() {
    const MockERC721 = await ethers.getContractFactory('MockERC721');
    // let mockERC721 = await upgrades.deployProxy(MockERC721, ['MockERC721', 'MERC721']);
    // await mockERC721.deployed();
    let mockERC721 = await MockERC721.attach('0xAa204BB68Bd6B48ac8F9D93048ed96b01746CD8a');
    // let transfer = await mockERC721.transferOwnership('0x270e023D99c16d4dDa9d485a56E91c05E5F604C4')
    // await transfer.wait()
    // console.log('done')
    // for (let i = 2; i < 20; i++) {
    //     let tx = await mockERC721.mint("0x455217d7d192a447ea31c7584Dba9cbD84EfD973",i)
    //     await tx.wait()
    // }
    const WaultsVault = await ethers.getContractFactory('ReserveForMint');
    // let waultVault = await WaultsVault.attach('0x2928F868F6fDA6874bF66b26E814EcBA65b7f256');

    let waultsVault = await upgrades.upgradeProxy('0x2928F868F6fDA6874bF66b26E814EcBA65b7f256',WaultsVault);
    await waultsVault.deployed();
    let tx = await waultsVault.openReservation()
    await tx.wait()
    let ownership = await waultsVault.transferOwnership('0x270e023D99c16d4dDa9d485a56E91c05E5F604C4')
    await ownership.wait()
    console.log('done')
}
main()