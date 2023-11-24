require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
require('hardhat-dependency-compiler');
require('hardhat-contract-sizer');
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          evmVersion: 'paris',
          optimizer: {
            enabled: true,
            runs: 999999
          }
        }
      }
    ]
  },
  networks: {
    lumozL1Devnet: {
      url: 'https://rpc.ankr.com/eth_sepolia',
      chainId: 11155111,
      accounts: ["0x"],
      timeout: 2000000,
    },
  }
};
