const {ethers, upgrades} = require ('hardhat');

async function main() {
    let owner;
    [owner] = await ethers.getSigners();

    const WaltsVaultMintController = await ethers.getContractFactory('WaltsVaultMintController');
    const mintController = await upgrades.deployProxy(WaltsVaultMintController, []);
    await mintController.deployed()
    console.log('---------------------------')
    console.log('deployer address: ', owner.address);
    console.log('MintController deployed at:', mintController.address);
    console.log('---------------------------')

    await verify(mintController.address, []);
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