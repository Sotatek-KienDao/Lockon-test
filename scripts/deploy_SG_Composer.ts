import { ethers, network, run } from "hardhat";
import { getContracts, saveContract } from "./utils";

async function main() {
  const contract = getContracts(network.name)[network.name];
  const StargateComposer = await ethers.deployContract("StargateComposer", [
    contract.stargateBridge,
    contract.stargateRouter,
    contract.SGETH,
    13,
  ]);

  await StargateComposer.waitForDeployment();
  saveContract(network.name, "stargateComposer", StargateComposer.target);
  console.log(
    "Deploy contracts Stargate Composer to address:",
    StargateComposer.target
  );

  await run("verify:verify", {
    address: StargateComposer.target,
    constructorArguments: [
      contract.stargateBridge,
      contract.stargateRouter,
      contract.SGETH,
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
