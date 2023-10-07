const { ethers, upgrades } = require("hardhat");

async function main() {
  // const TWO_WEEKS_IN_SECS = 14 * 24 * 60 * 60;
  // const timestamp = Math.floor(Date.now() / 1000)
  // const deadline = timestamp + TWO_WEEKS_IN_SECS;
  // console.log('deadline:', deadline)

  // Upgrading to v2
  const proxy = '0x705c8Cb3bf93c48E375296134e65e6F677fAB494' //代理合约地址（这个是永不变的）
  const WorldCupV2 = await ethers.getContractFactory("WorldCupV2");
  const upgraded = await upgrades.upgradeProxy(proxy, WorldCupV2); //把proxy合约指向WorldCupV2
  console.log("WorldCupV2 address:", upgraded.address);

  // await upgraded.changeDeadline(deadline + 100)
  // console.log("deadline2:", await upgraded.deadline())
}

main();