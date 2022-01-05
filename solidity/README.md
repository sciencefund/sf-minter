# Science Fund Token contracts

## Get Started

Go to your root directory and install dependencies

```shell
npm i
```

# HardHat

### **install hardhat shorthand**

### **run test**

```shell
cd solidity
npm run clean
npm run compile
hh test
```

### **Deploy on local network**

```
npx hardhat node
npx hardhat deploy --network localhost
```

### **Run Hardhat tasks**

## **Interacting with the contract from browser on local hardhat nextwork**

- **Local Faucet**

  Tap into local faucet to receive 999 ETH by updating your address in `LOCAL_USER_WALLET` in `.env` and run

  ```shell
  npx hardhat faucet --network localhost
  ```

- **Network**

  As of the time of writing, there is some [metamask issue](https://github.com/MetaMask/metamask-extension/issues/10290) on localnetwork. One can resolve it by adding custom RPC in your metamask browser extension with chainID 31337 default in hardhat network.

- **Contract address**

  Update the localhost contract address in `.env` after deployment.

# NFT metadata

#### metadata standard

[EIP-1155] (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md#erc-1155-metadata-uri-json-schema)

#### deploy metadata file on arweave

follow the instructions [here](https://docs.arweave.org/developers/tools/textury-arkb)
