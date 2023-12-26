import { ethers, upgrades } from "hardhat";

require('dotenv').config();
const hre = require("hardhat");


async function main() {
  const contractName = "shell"
  const contractSymbol = "SHE"
  const lastIssueAmount = 10000
  const committee = process.env.COMMITTEE_ADDRESS
  const shellBoxAddress = process.env.SHELLBOX_ADDRESS
  const usdcTokenAddress = process.env.USDC_CONTRACT_ADDRESS
  const Shell = await ethers.getContractFactory("Shell")
  console.log("Deploying Shell...")
  const shell = await upgrades.deployProxy(Shell,[contractName, contractSymbol ,committee, lastIssueAmount, shellBoxAddress, usdcTokenAddress])
  const shellAddress = await shell.getAddress();
  console.log(shellAddress," shell(proxy) address")
  console.log(await upgrades.erc1967.getImplementationAddress(shellAddress)," getImplementationAddress")
  console.log(await upgrades.erc1967.getAdminAddress(shellAddress)," getAdminAddress")

  await verifyOnBlockscan(shellAddress, [contractName, contractSymbol ,committee, lastIssueAmount, shellBoxAddress, usdcTokenAddress])

}

async function verifyOnBlockscan(address:string, args:any[]) {
  let success = false;
  while (!success) {
      try {
          let params = {
              address: address,
              constructorArguments: args,
          };
          await hre.run("verify:verify", params);
          console.log("verify successfully");
          success = true;
      } catch (error) {
          console.log(`Script failed: ${error}`);
          console.log(`Trying again in 3 seconds...`);
          await new Promise((resolve) => setTimeout(resolve, 3000));
      }
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
