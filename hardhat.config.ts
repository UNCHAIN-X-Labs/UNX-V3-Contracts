import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from 'dotenv';
import { SolcConfig } from "hardhat/types";
import 'solidity-docgen';
import 'hardhat-gas-reporter';
import "@nomicfoundation/hardhat-ledger";

dotenv.config();

const CompilerSettings = {
  optimizer: {
      enabled: true,
      runs: 20,
  },
};

const CompilerVersions = ['0.7.6'];

const _compilers: SolcConfig[] = CompilerVersions.map((item) => {
  return {
      version: item,
      settings: CompilerSettings,
  };
});

const config: HardhatUserConfig = {
  solidity: {
    compilers: _compilers
  },
  networks: {
      bnb: {
        url: process.env.BNB_MAINNET_URL,
        // accounts: [process.env.PRIVATE_KEY || ''],
        chainId: 56,
      },
      bnbtest: {
        url: process.env.BNB_TESTNET_URL,
        accounts: [process.env.PRIVATE_KEY || ''],
        chainId: 97
      },
      // arbitrum: {
      //   url: process.env.ARB_MAINNET_URL,
      //   // accounts: [process.env.PRIVATE_KEY || ""],
      //   chainId: 42161
      // },
      // sepolia: {
      //   url: process.env.ETH_SEPOLIA_URL,
      //   accounts: [process.env.PRIVATE_KEY || ""],
      //   chainId: 11155111
      // }
  },
  mocha: {
      timeout: 10 * 60 * 1000
  },
  docgen: {
    outputDir: './docs',
    pages: 'files'
  },
  gasReporter: {
      enabled: true,
      currency: 'USD',
      token: 'BNB',
      coinmarketcap: process.env.API_COINMARKETCAP,
      gasPriceApi: process.env.API_BNB_SCAN,
  },
  etherscan: {
    apiKey: {
      etherum: process.env.API_ETHER_SCAN || "",
      goerli: process.env.API_ETHER_SCAN || "",
      arbitrumOne: process.env.API_ARB_SCAN || ""
    }
  }
};

export default config;
