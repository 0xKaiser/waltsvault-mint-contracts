const {ethers, upgrades} = require ('hardhat');

async function main() {
    let owner;
    [owner] = await ethers.getSigners();
  

    const MockERC20 = await ethers.getContractFactory('MockERC20');
    let mockERC20 = await upgrades.deployProxy(MockERC20,['MockERC20', 'MERC20']);
    await mockERC20.deployed();
    console.log('MockERC20 deployed to:', mockERC20.address);

    const MockERC721 = await ethers.getContractFactory('MockERC721');
    let mockERC721 = await upgrades.deployProxy(MockERC721,['MockERC721', 'MERC721']);
    await mockERC721.deployed();
    console.log('MockERC721 deployed to:', mockERC721.address);

    let designatedSigner = "";

    const WaltsVault = await ethers.getContractFactory('WaltsVault');
    let waltsVault = await upgrades.deployProxy(WaltsVault,['Test WaltsVault', 'Test WV',mockERC20.address, designatedSigner]);
    await waltsVault.deployed();
    console.log('WaltsVault deployed to:', waltsVault.address);
    await verify(waltsVault.address, [])
    
    const WaultsVault = await ethers.getContractFactory('WaltsVaultReservation');
    let waultsVault = await upgrades.deployProxy(WaultsVault,[mockERC721.address,mockERC20.address,owner.address]);
    await waultsVault.deployed();
    console.log('WaultsVault deployed to:', waultsVault.address);
    await verify(waultsVault.address, [])
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