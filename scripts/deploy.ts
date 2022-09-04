import { ethers } from "hardhat";

const chainId = (() => {
  switch(process.env.NETWORK) {
    case 'evmos_test':
      return 9000;
    case 'evmos':
      return 9001;
    default:
      return 80001;
  }
})();

async function main() {
  const TransferSafeRouter = await ethers.getContractFactory("TransferSafeRouter");

  // Start deployment, returning a promise that resolves to a contract object
  const hello_world = await TransferSafeRouter.deploy(chainId);
  console.log("Contract deployed to address:", hello_world.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
