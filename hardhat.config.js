require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();

module.exports = {

  defaultNetwork: "hardhat",
    networks: {
        rinkeby: {
          url: 'https://rinkeby.infura.io/v3/6a02522ec0a54544997b4e0bcbab5bb8',
          accounts: [process.env.PRIVATE_KEY],
          gas: 12000000,
          blockGasLimit: 0x1fffffffffffff,
          allowUnlimitedContractSize: true,
          timeout: 1800000,
        },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY
  },
  solidity: {
    compilers: [
      {
          version: "0.8.4",
          settings: {
              optimizer: {
                  enabled: true,
                  runs: 200
              }
          }
      }
  ],
  },
};
