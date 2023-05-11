const {ethers, upgrades} = require ('hardhat');

async function main() {
    let owner;
    [owner] = await ethers.getSigners();

    const MintController = await ethers.getContractFactory("WaltsVaultMintController");
    // const mintController = await upgrades.upgradeProxy('0xf9ae821914097DFb8C23D27aA2ECfC22C279aFDc', MintController);
    const mintController = await MintController.attach('0xf9ae821914097DFb8C23D27aA2ECfC22C279aFDc');
    // await mintController.deployed();
    console.log("Available Amount For VL", await mintController.AVAILABLE_AMOUNT_FOR_VL());
    console.log('Order deployed to:', mintController.address);
}
main()