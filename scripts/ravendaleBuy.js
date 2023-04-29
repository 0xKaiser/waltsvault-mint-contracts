const {ethers, upgrades} = require ('hardhat');

async function main() {
    let owner;
    [owner] = await ethers.getSigners();

    const WaltsVault = await ethers.getContractFactory('VaultNFT');
    let waltsVault = await upgrades.upgradeProxy("0xB9aA289728E046cB8BA7e63f85119cf34130DdF6",WaltsVault);
    await waltsVault.deployed();
    console.log('WaltsVault deployed to:', waltsVault.address);
    let tx = await waltsVault.callStatic.transferOwnership("0xca191a12662c3B875c2cac2Dc7E2EF09dFa20Cf4");
    await tx.wait();

    // const Reservation = await ethers.getContractFactory('Reservation');
    // let reservation = await Reservation.attach('0x5e22b190BA005BDEC74E00fA98a144eD544fb5B7')
    // console.log('reservation deployed to:', reservation.address);
    // let tx = await reservation.setDesignatedSigner("0xA4CC419dB3F709B2E2f3f9Eb06B6cEC14DeDdDC6");
    // await tx.wait();
    // // let reservation = await upgrades.upgradeProxy('0x8B52369Cb1F1D4D6045f1c54cbaef2c150fA95d1', Reservation);
    // let tx= await reservation.toggleControllers("0xA4CC419dB3F709B2E2f3f9Eb06B6cEC14DeDdDC6");
    // // let tx = await reservation.setDesignatedSigner("0xA4CC419dB3F709B2E2f3f9Eb06B6cEC14DeDdDC6");
    // await tx.wait();
    // console.log("Designated Signer", await reservation.designatedSigner())
    console.log('Controllers Toggled')
}

main()