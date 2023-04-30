const {ethers, upgrades} = require ('hardhat');

async function main() {
    let owner;
    [owner] = await ethers.getSigners();

    // const Test = await ethers.getContractFactory('TestToken300423');
    // const test = await upgrades.deployProxy(Test, ['TestToken300423', 'TST']);
    // await test.deployed();
    // console.log('test deployed at:', test.address);
    //
    // const WaltsVault = await ethers.getContractFactory('TestVault');
    // const waltsVault = await upgrades.deployProxy(WaltsVault, ['TestVault', 'TV']);
    // await waltsVault.deployed();
    // console.log('waltsVault deployed at:', waltsVault.address);

    const MintController = await ethers.getContractFactory('TestMintController');
    const mintController = await upgrades.deployProxy(MintController, []);
    await mintController.deployed();

    console.log('---------------------------')
    console.log('deployer address: ', owner.address);
    console.log('MintController deployed at:', mintController.address);
    console.log('---------------------------')
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