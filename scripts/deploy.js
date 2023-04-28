const {ethers, upgrades} = require ('hardhat');

async function main() {
    let owner;
    [owner] = await ethers.getSigners();
  
    let ravendale = "0xf83A99E084C1D575AF8e12FF492F5E6C7b768b48";
    let designatedSigner = "0xA4CC419dB3F709B2E2f3f9Eb06B6cEC14DeDdDC6";
    let treasury = "";

    const WaltsVault = await ethers.getContractFactory('WaltsVaultV1');
    let waltsVault = await upgrades.deployProxy(WaltsVault,['WaltsVault', 'WV', designatedSigner]);
    await waltsVault.deployed();
    console.log('WaltsVault deployed to:', waltsVault.address);

    const Reservation = await ethers.getContractFactory('WaltsVaultReservationV1');
    let reservation = await upgrades.deployProxy(Reservation,[ravendale,designatedSigner,treasury]);
    await reservation.deployed();
    console.log('reservation deployed to:', reservation.address);

    let tx = await reservation.toggleControllers(owner.address);
    await tx.wait();
    console.log('Controllers Toggled')

    await verify(waltsVault.address, [])
    await verify(reservation.address, [])
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