## Provide fair reward distribution for the ZKFair economic model

```shell
yarn install
npm run compile
npm run deploy
```

Deployment steps

1. Deploy ZKF Token contract
2. Deploy RewardDistribution (e.g. 0x90DE61B6F65a29d510f56b6A31A18d9D7cc838EC)
   3.initialize
   1. _initialOwner // e.g. 0x6BC0E9C6a939f8f6d3413091738665aD1D7d2776
   2. _zkfTokenAddress // zkf contract address (e.g. 0x17ACbC4c57115300816Fb8960011534670C52E12)
   3. _proposalAuthority // proposal authority address (e.g. 0x6BC0E9C6a939f8f6d3413091738665aD1D7d2776)
   4. _reviewAuthority // review authority address (e.g. 0x5f4e46D298eb177216B0BeD04e9fD5BF9E73726B)
   5. _totalMonthOutput // Total reward amount
3. Transfer _totalMonthOutput ZKF to RewardDistribution
4. The proposer summarizes and calculates off-chain services and obtains new merkleRoot1
5. The proposal authority address submits new merkleRoot to the contract through proposewMerkleRoot.
6. Review party’s off-chain services are summarized and calculated to obtain new merkleRoot2
7. When the two merkleRoots are consistent, the review permission address approves the previous submission through reviewPendingMerkleRoot.
8. Corresponding to the address being counted, obtain the parameters required to execute the claim according to the corresponding front end/api, and execute it

```
claim(uint256 index, uint256 amount, bytes32[] calldata merkleProof)
```

```
{
    "inputs": [
      {
        "internalType": "uint256",
        "name": "index",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      },
      {
        "internalType": "bytes32[]",
        "name": "merkleProof",
        "type": "bytes32[]"
      }
    ],
    "name": "claim",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
```

Front-end collection

| Collection method | abi method | Parameters |
| --- | --- | --- |
| single | claim | uint256 index, uint256 amount, bytes32[] calldata merkleProof |

Note: The maximum number of batch tasks can be determined by actual measurement of the optimal upper limit and limited by the front end.

data query

- totalDistributedReward() The total historical mined reward of the entire network
- rewardHistory(address) Query the total mined rewards of the specified address
