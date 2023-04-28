const {ethers, upgrades} = require ('hardhat');

async function main() {
    let owner;
    [owner] = await ethers.getSigners();

    const MockERC721 = await ethers.getContractFactory('MockERC721');
    let mockERC721 = await upgrades.deployProxy(MockERC721,['MockERC721', 'MERC721']);
    await mockERC721.deployed();
    console.log('MockERC721 deployed to:', mockERC721.address);

    let designatedSigner = "0xA4CC419dB3F709B2E2f3f9Eb06B6cEC14DeDdDC6";
    let treasury = "0x270e023D99c16d4dDa9d485a56E91c05E5F604C4"

    const WaltsVault = await ethers.getContractFactory('VaultNFT');
    let waltsVault = await upgrades.deployProxy(WaltsVault,['Test NFT', 'TNFT', designatedSigner]);
    await waltsVault.deployed();
    console.log('WaltsVault deployed to:', waltsVault.address);
    
    const WaultsVault = await ethers.getContractFactory('Reservation');
    let reservation = await upgrades.deployProxy(WaultsVault,[mockERC721.address,owner.address,treasury]);
    await reservation.deployed();
    console.log('reservation deployed to:', reservation.address);

    let tx = await reservation.toggleControllers(owner.address);
    await tx.wait();
    console.log('Controllers Toggled')

    await verify(mockERC721.address, [])
    await verify(reservation.address, [])
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