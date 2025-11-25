# Harberger Tax NFT

An ERC721 implementation with Harberger Tax logic (Partial Common Ownership).

## Features

- **Self-Assessed Pricing**: Owners set their own price.
- **Continuous Tax**: 10% annual tax on the self-assessed price.
- **Foreclosure**: Tokens with insufficient tax deposits are seized by the protocol.

## Installation

```bash
forge install
```

## Compilation

```bash
forge build
```

## Testing

Run the comprehensive test suite:

```bash
forge test
```

## Design

See [DESIGN.md](./DESIGN.md) for details on the tax model and trade-offs.

## Foundry Documentation

https://book.getfoundry.sh/

## Usage

### Install dependencies

```shell
$ forge soldeer install
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
