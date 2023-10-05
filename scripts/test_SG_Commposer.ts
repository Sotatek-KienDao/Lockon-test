import { Contract } from "ethers";
import { ethers, network, run } from "hardhat";
// import { getContracts, saveContract } from "./utils";

async function main() {
  //   const contract = getContracts(network.name)[network.name];
  const etherValue = ethers.parseEther("0.01");
  const StargateComposer = await ethers.getContractFactory("StargateComposer");
  const stargateComposer = StargateComposer.attach(
    "0x7C5B3F4865b41b9d2B6dE65fdfbB47af06AC41f0"
  ) as Contract;
  await stargateComposer.waitForDeployment();
  console.log(
    "Contract Stargate Composer attach to address:",
    stargateComposer.target
  );

  await stargateComposer.swap(
    10109,
    1,
    1,
    "0x2Be8020eB1Afee72383783C9eD1f83402086cf64",
    100000000,
    1000,
    {
      dstGasForCall: 0,
      dstNativeAmount: 0,
      dstNativeAddr: "0x0000000000000000000000000000000000000001",
    },
    "0x8b6246059679e4be5bd511845230cdf62a9094d5",
    "0x36e59c310000000000000000000000002be8020eb1afee72383783c9ed1f83402086cf640000000000000000000000000000000000000000000000000000000005f5e100",
    { value: etherValue }
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
