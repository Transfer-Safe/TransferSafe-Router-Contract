import "dotenv/config";
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
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY
  },
  mocha: {
    reporter: 'mocha-junit-reporter',
    reporterOptions: {
      mochaFile: './test-report.xml'
    }
  }
};

export default config;
