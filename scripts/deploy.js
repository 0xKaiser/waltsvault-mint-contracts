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

    let designatedSigner = "0xF30d71c7DDA7244842650F3D4D569eeb60C0960b";

    const WaltsVault = await ethers.getContractFactory('WaltsVaultV1');
    let waltsVault = await upgrades.deployProxy(WaltsVault,['Test WaltsVault', 'Test WV', designatedSigner]);
    await waltsVault.deployed();
    console.log('WaltsVault deployed to:', waltsVault.address);
    // await verify(waltsVault.address, [])
    
    const WaultsVault = await ethers.getContractFactory('WaltsVaultReservationV1');
    let reservation = await upgrades.deployProxy(WaultsVault,[mockERC721.address,owner.address]);
    await reservation.deployed();
    console.log('reservation deployed to:', reservation.address);
    // await verify(waultsVault.address, [])

    let tx = await reservation.toggleControllers(owner.address);
    await tx.wait();
    console.log('Controllers Toggled')
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