# TransferSafe Router Contract

[![Test Router Contract](https://github.com/Transfer-Safe/TransferSafe-Router-Contract/actions/workflows/test-contract.yml/badge.svg)](https://github.com/Transfer-Safe/TransferSafe-Router-Contract/actions/workflows/test-contract.yml)

## How to deploy it

Create `.env` file with folowing content:
```env
# RPC URL to connect to blockchain network (you can get one on Alchemy, for example)
API_URL=
# Private key from yout deploying account (it's better not to use personal account keys here)
PRIVATE_KEY=
# Etherscan api key to verify contracts on Etherscan
ETHERSCAN_API_KEY=
```

## How to use is
### Install package 
Install package from Gitub package repository:
`npm install @transfer-safe/router@0.0.24`

### Use it with your favourite framework
Using with Ethers.js:
```typescript
import { TransferSafeRouter__factory } from '@transfer-safe/router';
import { ethers } from 'ethers';

const chainId = 80001;

export const loadInvoice = async (invoiceId: string,) => {
  const provider = new ethers.providers.AlchemyProvider(
    ethers.providers.getNetwork(chainId),
    process.env.ALCHEMY_APIKEY,
  );
  // Use real contract address here
  const address = '0x0';
  const routerContract = TransferSafeRouter__factory.connect(address, provider);
  const invoiceData = await routerContract.getInvoice(invoiceId);
  return invoiceData;
};
```
