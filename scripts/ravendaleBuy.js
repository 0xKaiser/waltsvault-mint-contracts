const {ethers, upgrades} = require ('hardhat');

async function main() {
    let owner;
    [owner] = await ethers.getSigners();

    // const MockERC721 = await ethers.getContractFactory('MockERC721');
    // // let mockERC721 = await upgrades.deployProxy(MockERC721,['MockERC721', 'MERC721']);
    // let mockERC721 = await MockERC721.attach('0x0AdCc22167f9Bb8032091cA2571e75A29a219F54');
    // console.log('MockERC721 deployed to:', mockERC721.address);
    // await mockERC721.mint("0xb9c470a28b7500a32f604B365155539153a0f57b",5)

    const Reservation = await ethers.getContractFactory('Reservation');
    let reservation = await Reservation.attach('0x5e22b190BA005BDEC74E00fA98a144eD544fb5B7')
    console.log('reservation deployed to:', reservation.address);
    let tx = await reservation.setDesignatedSigner("0xA4CC419dB3F709B2E2f3f9Eb06B6cEC14DeDdDC6");
    await tx.wait();
    // // let reservation = await upgrades.upgradeProxy('0x8B52369Cb1F1D4D6045f1c54cbaef2c150fA95d1', Reservation);
    // let tx= await reservation.toggleControllers("0xA4CC419dB3F709B2E2f3f9Eb06B6cEC14DeDdDC6");
    // // let tx = await reservation.setDesignatedSigner("0xA4CC419dB3F709B2E2f3f9Eb06B6cEC14DeDdDC6");
    // await tx.wait();
    // console.log("Designated Signer", await reservation.designatedSigner())
    console.log('Controllers Toggled')
}

main()