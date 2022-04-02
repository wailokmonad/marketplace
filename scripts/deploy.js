
const hre = require("hardhat");

async function main() {

  console.log("starting...");

  const Marketplace = await hre.ethers.getContractFactory("Marketplace");
  const contract = await Marketplace.deploy();

  await contract.deployed();

  console.log("Marketplace deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
