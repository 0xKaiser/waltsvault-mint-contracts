const {ethers, upgrades} = require ('hardhat');

async function main() {
    let owner;
    [owner] = await ethers.getSigners();

    const MintController = await ethers.getContractFactory("WaltsVaultMintController");
    const mintController = await upgrades.upgradeProxy('0xf9ae821914097DFb8C23D27aA2ECfC22C279aFDc', MintController);
    await mintController.deployed();
    console.log('Order deployed to:', mintController.address);
}
main()