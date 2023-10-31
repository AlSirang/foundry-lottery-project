# Raffle Contract with Chainlink VRF

## Documentation

https://book.getfoundry.sh/

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
