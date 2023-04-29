const {ethers, upgrades} = require ('hardhat');

async function main() {
    let owner;
    [owner] = await ethers.getSigners();

    let ravendale = "0xf83A99E084C1D575AF8e12FF492F5E6C7b768b48";
    let designatedSigner = "0xA4CC419dB3F709B2E2f3f9Eb06B6cEC14DeDdDC6";
    let treasury = "0x2F86b325E8FfeE20703C93A8F28Ab7a5Dd711b7E";

    const Reservation = await ethers.getContractFactory('WaltsVaultReservation');
    let reservation = await upgrades.deployProxy(Reservation,[ravendale,designatedSigner,treasury]);
    await reservation.deployed();

    console.log('---------------------------')
    console.log('deployer address: ', owner.address);
    console.log('reservation deployed at:', reservation.address);
    console.log('---------------------------')


    await verify(reservation.address, []);
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