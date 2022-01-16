# Science Fund Token Minter App Frontend

# NextJS Frontend

## Deployment
- Staging app is deployed on [http://science-fund.herokuapp.com/](http://science-fund.herokuapp.com/)


- The contract is live on [Rinkeby]().
## Get Started

Go to your root directory and install dependencies

```shell
npm i
```

and run the development server:

```shell
npm run dev
```

Open http://localhost:3000 with your browser to see the result.

## After Updating Contracts
- **update the artefact folder** by copying and paste `./solidity/artifacts` to `./next-ui/artifacts`
 

## Edit the home page

You can start editing the homepage page by modifying <code>pages/index.js</code>. The page auto-updates as you edit the file.


## Edit the minter page

- this page can be accessed at route `./minter`, which can be linked through the brocure site.



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


