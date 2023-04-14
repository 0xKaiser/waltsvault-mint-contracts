require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("@openzeppelin/hardhat-upgrades");
require("hardhat-deploy");
require("solidity-coverage");
require("hardhat-gas-reporter");
require("hardhat-contract-sizer");
require("hardhat-abi-exporter");
require("dotenv").config();
require("@nomicfoundation/hardhat-network-helpers");


const PRIVATE_KEY = process.env.PRIVATE_KEY;
const FORKING_BLOCK_NUMBER = process.env.FORKING_BLOCK_NUMBER;
const REPORT_GAS = process.env.REPORT_GAS || false;

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
const POLYGON_API_KEY = process.env.POLYGON_API_KEY;

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        goerli: {
            url: "https://goerli.infura.io/v3/6422400310bc4cb784d6a819632808b9",
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            saveDeployments: true,
            chainId: 5,
        },
        mainnet: {
            url: "https://mainnet.infura.io/v3/6422400310bc4cb784d6a819632808b9",
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            saveDeployments: true,
            chainId: 1,
        },
        mumbai: {
            url: "https://polygon-mumbai.infura.io/v3/6422400310bc4cb784d6a819632808b9",
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            saveDeployments: true,
            chainId: 80001,
        },
        polygon: {
            url: "https://polygon-mainnet.infura.io/v3/6422400310bc4cb784d6a819632808b9",
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            saveDeployments: true,
            chainId: 137,
        },
    },
    solidity: {
        version: "0.8.13",
        settings: {
            optimizer: {
                enabled: true,
                runs: 500,
            },
        },
    },
    etherscan: {
        apiKey: {
            goerli: ETHERSCAN_API_KEY,
            rinkeby: ETHERSCAN_API_KEY,
            polygonMumbai: "VIT7XVFNT1RIGIMPDPY6QKEVJJ94DSNVVW",
            polygon: 'VIT7XVFNT1RIGIMPDPY6QKEVJJ94DSNVVW',
            mainnet: ETHERSCAN_API_KEY
        },
    },
    gasReporter: {
        enabled: REPORT_GAS,
        outputFile: "gas-report.txt",
        noColors: true,
    },
    contractSizer: {
        runOnCompile: false,
        only: [],
    },
    mocha: {
        timeout: 200000,
    },
};
