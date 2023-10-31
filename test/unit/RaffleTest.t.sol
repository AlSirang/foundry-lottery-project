// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";

contract RaffleTest is Test {
    // Events

    event EnteredRaffle(address indexed player);

    // State
    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address linkToken;

    uint256 constant USER_INITIAL_BALANCE = 10 ether;
    address public player = makeAddr("player 1");

    modifier enterRaffle() {
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();

        _;
    }

    modifier completeRaffleTime() {
        vm.warp(block.timestamp + interval + 1); // increase block timestamp
        vm.roll(block.number + 1); // create a new block

        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) return;

        _;
    }

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();

        (raffle, helperConfig) = deployer.run();

        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            linkToken,

        ) = helperConfig.activeConfig();

        vm.deal(player, USER_INITIAL_BALANCE);
    }

    function testRaffleInitialState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleEnterRaffleFailsOnNoEthSend() public {
        vm.prank(player);

        // expect the next call to fail;
        vm.expectRevert(Raffle.Raffle__NotEnoughFee.selector);

        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayer() public enterRaffle {
        assert(raffle.getPlayerAddress(0) == player);
    }

    function testRaffleEmitsEventOnPlayerEnterRaffle() public {
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(player);

        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testRaffleEmitsEventWithCorrectDataOnPlayerEnterRaffle() public {
        vm.recordLogs();
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();

        Vm.Log[] memory entries = vm.getRecordedLogs();

        address emittedPlayer = address(uint160(uint256(entries[0].topics[1])));

        assert(player == emittedPlayer);
    }

    function testRevertOnEnterRaffleWhenCalculating()
        public
        enterRaffle
        completeRaffleTime
    {
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCheckUpkeepReturnsFalseIfContractHasNoBalance()
        public
        completeRaffleTime
    {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfTimeHasNotPassed()
        public
        enterRaffle
    {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleNotOpen()
        public
        enterRaffle
        completeRaffleTime
    {
        raffle.performUpkeep("");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueIfConditionsAreGood()
        public
        enterRaffle
        completeRaffleTime
    {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }

    function testPerformUpkeepRevertsWhenUpkeepIsNotNeeded() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 players = 0;
        uint256 raffleState = uint256(raffle.getRaffleState());

        bytes memory CUSTOM_ERROR_WITH_PARAMS = abi.encodeWithSelector(
            Raffle.Raffle__NoUpkeepNeeded.selector,
            currentBalance,
            players,
            raffleState
        );
        // Act / Assert
        vm.expectRevert(CUSTOM_ERROR_WITH_PARAMS);
        raffle.performUpkeep("");
    }

    function testSetEntranceFeeUpdatesWhenCallerIsOwner() public {
        vm.prank(raffle.getOwner());
        raffle.setEntranceFee(10 ether);

        assert(raffle.getEntranceFee() == 10 ether);
    }

    function testSetEntranceFeeRevertsWhenCallerIsNotOwner() public {
        vm.expectRevert(Raffle.Raffle__OnlyOwner.selector);

        raffle.setEntranceFee(10 ether);
    }

    function testFulfillRandomWordsCanBeOnlyCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public enterRaffle completeRaffleTime skipFork {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function getRequestId() internal returns (uint256) {
        vm.recordLogs();

        raffle.performUpkeep("");
        // performUpkeep (calls) ->requestRandomWords (emits) -> RandomWordsRequested
        // event RandomWordsRequested(
        //     bytes32 indexed keyHash,
        //     uint256 requestId,
        //     uint256 preSeed,
        //     uint64 indexed subId,
        //     uint16 minimumRequestConfirmations,
        //     uint32 callbackGasLimit,
        //     uint32 numWords,
        //     address indexed sender
        // );

        Vm.Log[] memory entries = vm.getRecordedLogs();

        // access requestId topic
        return uint256(entries[0].topics[2]);
    }

    function testFulfillRandomWordsPicksWinnerAndSendFunds()
        public
        enterRaffle
        completeRaffleTime
        skipFork
    {
        uint256 players = 5;

        for (uint256 i = 0; i < players; i++) {
            address _player = address(uint160(i));
            hoax(_player, USER_INITIAL_BALANCE);

            raffle.enterRaffle{value: entranceFee}();
        }
        uint256 prize = entranceFee * (players + 1);
        uint256 requestId = getRequestId();
        uint256 previousTimestamp = raffle.getLastTimestamp();

        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            requestId,
            address(raffle)
        );

        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        assert(raffle.getLengthOfPlayers() == 0);
        assert(raffle.getLastTimestamp() > previousTimestamp);

        assert(
            raffle.getRecentWinner().balance ==
                (USER_INITIAL_BALANCE + prize) - entranceFee
        );
    }
}
