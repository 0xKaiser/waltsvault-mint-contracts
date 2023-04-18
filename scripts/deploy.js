const {ethers} = require ('hardhat');

async function main() {
    let owner;
    [owner] = await ethers.getSigners();
    const MockERC721 = await ethers.getContractFactory('MockERC721');
    let mockERC721 = await MockERC721.deploy('MockERC721', 'MERC721');
    await mockERC721.deployed();
    console.log('MockERC721 deployed to:', mockERC721.address);
    await verify(mockERC721.address, ['MockERC721', 'MERC721'])

    let tx = await mockERC721.mint("0x455217d7d192a447ea31c7584Dba9cbD84EfD973",20)
    await tx.wait()
    const WaultsVault = await ethers.getContractFactory('WaltsVaultReservation');
    let waultsVault = await WaultsVault.deploy(mockERC721.address,owner.address);
    await waultsVault.deployed();
    tx = await waultsVault.openReservation()
    await tx.wait()
    console.log('WaultsVault deployed to:', waultsVault.address);
    await verify(waultsVault.address, [mockERC721.address,owner.address])
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