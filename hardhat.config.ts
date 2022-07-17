import 'dotenv/config'
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const { API_URL, PRIVATE_KEY } = process.env;

const config: HardhatUserConfig = {
  solidity: "0.8.9",
  defaultNetwork: "polygon_mumbai",
   networks: {
      hardhat: {},
      polygon_mumbai: {
         url: API_URL || '',
         accounts: PRIVATE_KEY ? [`0x${PRIVATE_KEY}`] : []
      }
   },
};

export default config;
