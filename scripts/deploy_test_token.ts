import { ethers, network, run } from "hardhat";
import { getContracts, saveContract } from "./utils";

async function main() {
  const MockERC20 = await ethers.deployContract("MockERC20", []);

  await MockERC20.waitForDeployment();
  saveContract(network.name, "mockERC20", MockERC20.target);
  console.log("Test token deploy to:", MockERC20.target);

  // Set timeout so that the contract bytescode can be recognized by scan

  await run("verify:verify", {
    address: MockERC20.target,
    constructorArguments: [],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
