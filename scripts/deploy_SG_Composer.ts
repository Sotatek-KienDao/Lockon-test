import { ethers, network, run } from "hardhat";
import { getContracts, saveContract } from "./utils";

async function main() {
  const StargateComposer = await ethers.deployContract("StargateComposer", [
    "0x629B57D89b1739eE1C0c0fD9eab426306e11cF42",
    "0x817436a076060D158204d955E5403b6Ed0A5fac0",
    "0x0000000000000000000000000000000000000000",
    13,
  ]);

  await StargateComposer.waitForDeployment();
  saveContract(network.name, "stargateComposer", StargateComposer.target);
  console.log(
    "Deploy contracts Stargate Composer to address:",
    StargateComposer.target
  );

  await run("verify:verify", {
    address: "0x7E94cB20Cd432Abe1d7EBf949C6f94c47D404615",
    constructorArguments: [
      "0x629B57D89b1739eE1C0c0fD9eab426306e11cF42",
      "0x817436a076060D158204d955E5403b6Ed0A5fac0",
      "0x0000000000000000000000000000000000000000",
      13,
    ],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
