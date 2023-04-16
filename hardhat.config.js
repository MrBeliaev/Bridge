require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  defaultNetwork: "hardhat",
  networks: {
    ganache: {
      url: "127.0.0.1:8545",
      chainId: 1337,
    }
  }
};
