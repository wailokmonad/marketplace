# Marketplace Contract

This is a marketplace smart contract project that would allow people to buy/sell NFTs. The contract is expected to be deployed and run in EVM-based blockchains.

Rinkeby contract address: 0x27e38AE1685F510BA2B434826ffC2E2c743a27b0

<br />

### 1) Install the dependencies
```shell
npm i
```

<br />

### 2) Compile the contract
```shell
npx hardhat compile
```

<br />

### 3) Run the test cases to verify the contract functinalities
```shell
npx hardhat test
```
You should see a total of 27 test cases passed sucessfully

<br />

### 4) Set up the .env file based on env.sample
```
PRIVATE_KEY = "your private key"
ETHERSCAN_KEY = "etherscan key"
```
<br />

### 5) Deploy the rinkeby testnet
```shell
npx hardhat run scripts/deploy.js --network rinkeby
```

Then you should see something like this

```shell
Marketplace deployed to: {contract address}
```

<br />

### 6) Verify the contract
```shell
npx hardhat verify {contract address} --network rinkeby 
```

Then you should see something like this

```shell
Successfully verified contract Marketplace on Etherscan.
https://rinkeby.etherscan.io/address/{contract address}#code
```





