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
            url: "https://goerli.infura.io/v3/3932027bc24b4df089d1ab33886ad3db",
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            saveDeployments: true,
            chainId: 5,
        },
        mainnet: {
            url: "https://mainnet.infura.io/v3/3932027bc24b4df089d1ab33886ad3db",
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            saveDeployments: true,
            chainId: 1,
        }
    },
    solidity: {
        version: "0.8.18",
        settings: {
            optimizer: {
                enabled: true,
                runs: 500,
            },
        },
    },
    etherscan: {
        apiKey: {
            goerli:'31WXEYFAGW4JBBSRRJZRJQB2GB5D6MB48W',
            mainnet: '31WXEYFAGW4JBBSRRJZRJQB2GB5D6MB48W'
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
