import "dotenv/config";
import { reporters } from 'mocha';
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";

const { API_URL, PRIVATE_KEY, ETHERSCAN_API_KEY, NETWORK } = process.env;

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000
      }
    }
  },
  defaultNetwork: NETWORK || "polygon_mumbai",
  networks: {
    hardhat: {
      
    },
    polygon_mumbai: {
      url: API_URL || "",
      accounts: PRIVATE_KEY ? [`0x${PRIVATE_KEY}`] : [],
    },
    evmos_test: {
      url: 'https://eth.bd.evmos.dev:8545',
      accounts: PRIVATE_KEY ? [`0x${PRIVATE_KEY}`] : [],
      chainId: 9000,
    },
    evmos: {
      url: 'https://eth.bd.evmos.org:8545',
      accounts: PRIVATE_KEY ? [`0x${PRIVATE_KEY}`] : [],
      chainId: 9001,
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
    customChains: [
      {
        chainId: 9000,
        network: 'evmos_test',
        urls: {
          apiURL: 'https://evm.evmos.dev/api',
          browserURL: 'https://evm.evmos.dev',
        }
      },
      {
        chainId: 9001,
        network: 'evmos',
        urls: {
          apiURL: 'https://evm.evmos.org/api',
          browserURL: 'https://evm.evmos.org',
        }
      }
    ]
  },
  mocha: process.env.CI ? {
    reporter: reporters.JSON,
    reporterOptions: {
      mochaFile: './test-report.json'
    }
  } : undefined
};

export default config;
