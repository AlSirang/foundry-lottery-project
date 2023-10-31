# Raffle Contract with Chainlink VRF

Lottery Contract project for **Blockchain Developer, Smart Contract, & Solidity Course - Powered By AI - Beginner to Expert Course | Foundry Edition 2023 |**.

This project uses Foundry, Solidity and Chainlink VRF and automation contracts. VRF provides capabilities to create random numbers on blockchain.

## Deployed Contract on Sepolia Testnet

<a href="https://sepolia.etherscan.io/address/0xf3c39f16e0106903a525a08bc4b16cc9743e799b#code" target="_blank">
0xf3c39f16e0106903a525a08bc4b16cc9743e799b
</a>

## Usage

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

# Notes

- test events `vm.expectEmit`

  E.g.

  ```solidity
   function testRaffleEmitsEventOnPlayerEnterRaffle() public {
        vm.prank(player);
        // true if there is topic else false
        vm.expectEmit(true, false, false, false, address(raffle));
        // emit event declared in test file
        emit EnteredRaffle(player);
        // call function which will emit event
        raffle.enterRaffle{value: entranceFee}();
    }
  ```

- change block.timestamp `vm.warp` or `vm.roll`

  - `vm.warp` takes time in seconds
  - `vm.roll` takes block number

  E.g.

  ```solidity
  vm.warp(10000); // sets block.timestamp to 10000
  ```

  ```solidity
  vm.roll(10); // sets block.number to 10
  ```

- Create report with information about lines which are not tested

  ```shell
  forge coverage --report debug
  ```

  or save report in a file with

  ```shell
  forge coverage --report debug > coverage.txt
  ```

# Acknowledgments

This project is part of **Blockchain Developer, Smart Contract, & Solidity Course - Powered By AI - Beginner to Expert Course | Foundry Edition 2023 |**.

Thank you Patrick Collins for your awesome course.
