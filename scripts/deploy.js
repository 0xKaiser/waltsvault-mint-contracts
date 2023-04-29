const {ethers, upgrades} = require ('hardhat');

async function main() {
    let owner;
    [owner] = await ethers.getSigners();

    const WaltsVault = await ethers.getContractFactory('WaltsVaultReservation');
    let waltsVault = await upgrades.deployProxy(WaltsVault,["Walt's Vault", 'WV']);
    await waltsVault.deployed();
    console.log("----------------------")
    console.log("Deployer address: ", owner.address);
    console.log("Contract deployed at: ", waltsVault.address);
    console.log("----------------------")
    await verify(waltsVault.address, [])
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