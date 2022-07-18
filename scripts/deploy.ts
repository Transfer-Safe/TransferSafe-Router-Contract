import { ethers } from "hardhat";

async function main() {
  const TransferSafeRouter = await ethers.getContractFactory("TransferSafeRouter");

  // Start deployment, returning a promise that resolves to a contract object
  const hello_world = await TransferSafeRouter.deploy();
  console.log("Contract deployed to address:", hello_world.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
