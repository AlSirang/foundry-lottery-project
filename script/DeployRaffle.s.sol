// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";

contract DeployRaffle is Script {
    function run() public returns (Raffle raffle) {
        vm.startBroadcast();

        raffle = new Raffle();
        vm.stopBroadcast();
    }
}
