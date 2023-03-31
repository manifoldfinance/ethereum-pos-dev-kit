# Ethereum Proof of Stake Dev Kit

This repository provides a fully-functional, local development network for Ethereum with proof-of-stake enabled. This configuration uses [Prysm](https://github.com/prysmaticlabs/prysm) as a consensus client and [Geth](https://github.com/ethereum/go-ethereum) for execution.

This sets up a single node development network with 64 deterministically-generated validator keys to drive the creation of blocks in an Ethereum proof-of-stake chain. Here's how it works:

1. We initialize a `Geth`, proof-of-work development node from a genesis config.
2. We initialize a `Prysm` beacon chain, proof-of-stake development node from a genesis config.
3. We then start mining in `Geth` proof-of-work, and concurrently run proof-of-stake using `Prysm`.
4. Once the mining difficulty of the `Geth` node reaches `50`, the node switches to proof-of-stake mode by letting `Prysm` drive the consensus of blocks.

The development net is fully functional and allows for the deployment of smart contracts and all the features that also come with the `Prysm` consensus client such as its rich set of APIs for retrieving data from the blockchain. This development net is a great way to understand the internals of Ethereum proof-of-stake and to mess around with the different settings that make the system possible.

## TODO

- [ ] Add support for more clients (e.g: `lodestar`, `lighthouse` & friends)
- [ ] Integrate directly the generation of configs inside package derivations (also consider creating custom `flake-parts` module)
- [ ] Include support for extra ancilliary like `Vouch` and `Dirk`
- [ ] Include support for tx spammer

## Requirements

To make the most of this repo you should have the following installed:

- [Nix](https://nixos.org/)
- [Direnv](https://direnv.net/)

## Getting started

When prompted run `direnv allow`.

You will then be met with the following prompt:

```terminal
🔨 Welcome to ethereum-pos-dev-kit

[Ethereum Dev Kit]

  clean - Removes unnecessary files
  init  - Create the genesis configuration for the consensus and beacon chain clients
  up    - Start the Ethereum PoS dev environment

[Formatting & Linting]

  fmt   - Format the source tree

[general commands]

  menu  - prints this menu
```

## Available Features

- The network launches with a [Validator Deposit Contract](https://github.com/ethereum/consensus-specs/blob/dev/solidity_deposit_contract/deposit_contract.sol) deployed at address `0x4242424242424242424242424242424242424242`. This can be used to onboard new validators into the network by depositing 32 ETH into the contract.
- The default account used in the go-ethereum node is address `0x123463a4b065722e99115d6c222f267d9cabb524` which comes seeded with ETH for use in the network. This can be used to send transactions, deploy contracts, and more.
- The default account, `0x123463a4b065722e99115d6c222f267d9cabb524` is also set as the fee recipient for transaction fees proposed validators in Prysm. This address will be receiving the fees of all proposer activity.
- The go-ethereum JSON-RPC API is available at `http://localhost:8545`.
- The Prysm client's REST APIs are available at `http://localhost:3500`. For more info on what these APIs are, see [here](https://ethereum.github.io/beacon-APIs/).
- The Prysm client also exposes a gRPC API at `http://localhost:4000`.

## Acknowledgements

This repository is based on Raul Jordan's work: [`eth-pos-devnet`](https://github.com/rauljordan/eth-pos-devnet).
