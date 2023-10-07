const { ethers, upgrades } = require("hardhat");

async function main() {
  const TWO_WEEKS_IN_SECS = 14 * 24 * 60 * 60;
  const timestamp = Math.floor(Date.now() / 1000)
  const deadline = timestamp + TWO_WEEKS_IN_SECS;
  console.log('deadline:', deadline)

  // Deploying
  const WorldCupv1 = await ethers.getContractFactory("WorldCupV1");
  const instance = await upgrades.deployProxy(WorldCupv1, [deadline]);
  await instance.deployed();
  console.log("WorldCupV1 address:", instance.address);
  console.log("deadline:", await instance.deadline())

  console.log('ready to upgrade to V2...');

}

main();