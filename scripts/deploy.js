const {ethers, upgrades} = require ('hardhat');

async function main() {
    let owner;
    [owner] = await ethers.getSigners();



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