const {ethers, upgrades} = require ('hardhat');

async function main() {
    let owner;
    [owner] = await ethers.getSigners();

    const MintController = await ethers.getContractFactory("WaltsVaultMintController");
    const mintController = await upgrades.upgradeProxy('0x8f723c1fbEDD6B7d389e2B610d947967c2CE4Ff6', MintController);
    await mintController.deployed();
    console.log('Order deployed to:', mintController.address);
}
main()