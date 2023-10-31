// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title Lottery Contract using chainlink VRF
 * @author Bashir Uddin
 * @notice this is a simple Lottery contract. It uses chainlink VRF to select a random winner.
 * @dev Implements Chainlink VRFv2
 */

contract Raffle is VRFConsumerBaseV2 {
    /**
     * Erros *
     */
    error Raffle__OnlyOwner();
    error Raffle__NotEnoughFee();
    error Raffle__EthSendFaild();
    error Raffle__RaffleNotOpen();
    error Raffle__NoUpkeepNeeded(
        uint256 balace,
        uint256 players,
        uint256 raffleState
    );

    /**
     * Type declarations *
     */

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /**
     * State Variables *
     */

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant NUM_WORDS = 1;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address private s_owner;
    uint256 private s_entranceFee;
    uint256 private s_lastTimestamp;
    address[] private s_players;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /**
     * Events*
     */
    event EnteredRaffle(address indexed player);
    event WinnerPicked(address indexed player);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_interval = interval;
        i_gasLane = gasLane;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_owner = msg.sender;
        s_entranceFee = entranceFee;
        s_lastTimestamp = block.timestamp;

        s_raffleState = RaffleState.OPEN;
    }

    modifier onlyOwner() {
        if (msg.sender != s_owner) revert Raffle__OnlyOwner();
        _;
    }

    function enterRaffle() external payable {
        if (msg.value < s_entranceFee) revert Raffle__NotEnoughFee();
        if (s_raffleState != RaffleState.OPEN) revert Raffle__RaffleNotOpen();

        s_players.push(msg.sender);

        emit EnteredRaffle(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasTimePassed = (block.timestamp - s_lastTimestamp) >= i_interval;
        bool hasETH = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        upkeepNeeded = isOpen && hasTimePassed && hasPlayers && hasETH;

        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert Raffle__NoUpkeepNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;

        i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    // CEI: Checks , Effects, Interactions
    function fulfillRandomWords(
        uint256,
        /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        uint256 index = randomWords[0] % s_players.length;
        address winner = s_players[index];
        s_recentWinner = winner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address[](0);
        s_lastTimestamp = block.timestamp;
        emit WinnerPicked(winner);

        (bool s, ) = payable(winner).call{value: address(this).balance}("");
        if (!s) revert Raffle__EthSendFaild();
    }

    // Setters

    function setEntranceFee(uint256 entranceFee) external onlyOwner {
        s_entranceFee = entranceFee;
    }

    // View + pure functions

    function getEntranceFee() external view returns (uint256) {
        return s_entranceFee;
    }

    function getOwner() external view returns (address) {
        return s_owner;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayerAddress(
        uint256 indexOfPlayer
    ) external view returns (address) {
        return s_players[indexOfPlayer];
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLengthOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    function getLastTimestamp() external view returns (uint256) {
        return s_lastTimestamp;
    }
}
