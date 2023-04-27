const {Signature} = require( "ethers");
const ethers = require("ethers");
const wallet = new ethers.Wallet(process.env.HARDHAT_PRIVATE_KEY_Alice);


const signTransaction = async (
    rarity,
    tokenId,
    nonce,
    contractAddress
) => {

    const domain = {
        name: "MerkelCoin",
        version: "1",
        chainId: 31337, //put the chain id
        verifyingContract: contractAddress, //contract address
    };

    const types = {
        rarityInfo: [
            { name: "rarity", type: "uint8"},
            { name: "tokenId", type: "uint16"},
            { name: "nonce", type: "uint32"},
        ],
    };

    const value = {
        rarity: rarity,
        tokenId: tokenId,
        nonce: nonce,
    };

    let sign = await wallet._signTypedData(domain, types, value);
    return sign;
}

exports.signTransaction = signTransaction;