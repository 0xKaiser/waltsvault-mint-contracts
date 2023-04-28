const {ethers, upgrades} = require ('hardhat');

async function main() {
    let owner;
    [owner] = await ethers.getSigners();
  
    let ravendale = "";
    let designatedSigner = "0xF30d71c7DDA7244842650F3D4D569eeb60C0960b";
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