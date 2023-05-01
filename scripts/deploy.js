const {ethers, upgrades} = require ('hardhat');

async function main() {
    let owner;
    [owner] = await ethers.getSigners();

    // const Test = await ethers.getContractFactory('TestToken300423');
    // const test = await upgrades.deployProxy(Test, ['TestToken300423', 'TST']);
    // await test.deployed();
    // console.log('test deployed at:', test.address);
    //
    const WaltsVault = await ethers.getContractFactory('TestMintController');
    // const waltsVault = await upgrades.deployProxy(WaltsVault, ['TestVault', 'TV']);
    const wault = await WaltsVault.attach('0xDa67FD1Cb01a81dADec6727b9D0B74a8F2Dc1437');
    let tx = await wault.transferOwnership("0x75dCAb9bDBEe7b907441d517d56491EA6DCBd608");
    // let tx = await wault.toggleController(owner.address);
    await tx.wait()
    // tx = await wault.airdrop(["0xE4B1903789c0CCE595A47A1dC921874DcF656F5f"],[20])
    // await tx.wait()
    // console.log('wault deployed at:', wault.address);
    // await waltsVault.deployed();
    // console.log('waltsVault deployed at:', waltsVault.address);

    // const MintController = await ethers.getContractFactory('TestMintController');
    // const mintController = await upgrades.deployProxy(MintController, []);
    // await mintController.deployed();

    console.log('---------------------------')
    console.log('deployer address: ', owner.address);
    // console.log('MintController deployed at:', mintController.address);
    // console.log('---------------------------')
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