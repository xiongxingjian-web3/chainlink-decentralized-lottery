// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title 抽奖合同
 * @author Tiny熊
 * @notice 这个合同是一个简单的抽奖合同，用户可以购买抽奖票，然后在抽奖时间点，系统会随机选择一个用户作为奖品的获得者。
 * @dev Chainlink VRF 用于随机数生成
 */

contract Raffle is VRFConsumerBaseV2Plus {
    // 错误：用户支付的金额不足
    error Raffle_SendMoreToEnterRaffle();
    // 错误：没有玩家进入抽奖
    error Raffle_NoPlayersEntered();
    // 错误：未到抽奖时间点
    error Raffle_NotEnoughTimePassed();
    // 错误：无效的随机数
    error Raffle_InvalidRandomWords();
    // 错误：转账交易失败
    error Raffle_TransferFailed();
    // 错误：抽奖合同未开始
    error Raffle_RaffleNotOpen();
    // 错误：抽奖合同未到可抽奖状态
    error Raffle_UpkeepNotNeeded(
        uint256 balance,
        uint256 playersLength,
        uint256 raffleState
    );
    // 抽奖状态
    enum RaffleState {
        OPEN, // 抽奖合同未开始，用户可以进入抽奖
        CALCULATING // 抽奖合同已开始，用户不能进入抽奖，系统正在计算奖品获得者
    }
    // Chainlink VRF 请求确认数（等待 3 个区块后再处理）
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    // 抽奖合同的 VRF 数量
    uint16 private constant NUM_WORDS = 1;
    // 抽奖费用
    uint256 public immutable i_entranceFee;
    // 抽奖间隔时间
    uint256 public immutable i_interval;
    // 抽奖合同的 VRF 键哈希值
    bytes32 private immutable i_gasLane;
    // 抽奖合同的 VRF 订阅 ID
    uint256 private immutable i_subscriptionId;
    // 抽奖合同的 VRF 回调GasLimit
    uint32 private immutable i_callbackGasLimit;

    // 抽奖玩家列表
    address payable[] private s_players;
    // 上次抽奖时间戳
    uint256 private s_lastTimeStamp;
    // 最近的奖品获得者
    address payable private s_recentWinner;
    // 抽奖状态
    RaffleState private s_raffleState;
    // 最近的抽奖请求 ID
    uint256 public s_lastRequestId;
    // 抽奖事件：用户进入抽奖
    event Raffle_Entered(address indexed player);
    // 抽奖事件：奖品获得者
    event WinnerPicked(address indexed winner);
    // 抽奖事件：请求奖品获得者
    event RequestedRaffleWinner(
        uint256 indexed requestId,
        address indexed player
    );
    constructor(
        uint256 _entranceFee,
        uint256 _interval,
        address _vrfCoordinator,
        bytes32 _gasLane,
        uint256 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_entranceFee = _entranceFee;
        i_interval = _interval;
        s_lastTimeStamp = block.timestamp;
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    // 参与抽奖，支付抽奖费用
    function enterRaffle() public payable {
        require(msg.value >= i_entranceFee, Raffle_SendMoreToEnterRaffle());
        require(s_raffleState == RaffleState.OPEN, Raffle_RaffleNotOpen());
        s_players.push(payable(msg.sender));
        emit Raffle_Entered(msg.sender);
    }

    // 检查抽奖状态是否为可抽奖状态
    function checkUpkeep(
        bytes memory /* performData */
    ) public view returns (bool upkeepNeeded, bytes memory) {
        bool hasPlayers = s_players.length > 0;
        bool timePassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = (s_raffleState == RaffleState.OPEN);
        bool hasBalance = address(this).balance > 0;

        upkeepNeeded = hasPlayers && timePassed && isOpen && hasBalance;
        return (upkeepNeeded, "");
    }
    // 随机选择一个用户作为奖品的获得者
    function performUpkeep(bytes calldata /* performData */) public {
        (bool upkeepNeeded, ) = checkUpkeep("");
        require(
            upkeepNeeded,
            Raffle_UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            )
        );
        s_raffleState = RaffleState.CALCULATING;

        s_lastRequestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                ) // new parameter
            })
        );
        emit RequestedRaffleWinner(s_lastRequestId, msg.sender);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        require(randomWords.length == NUM_WORDS, Raffle_InvalidRandomWords());
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = s_recentWinner.call{value: address(this).balance}(
            ""
        );
        require(success, Raffle_TransferFailed());
        emit WinnerPicked(recentWinner);
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }
    function getPlayer(
        uint256 indexOfPlayer
    ) public view returns (address payable) {
        return s_players[indexOfPlayer];
    }
    function getLatestRequestId() public view returns (uint256) {
        return s_lastRequestId;
    }
    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }
    function getRecentWinner() public view returns (address payable) {
        return s_recentWinner;
    }
    // 参与人数列表
    function getPlayers() public view returns (address payable[] memory) {
        return s_players;
    }
    function emergencyReset() external onlyOwner {
        // 1. 先保存余额和玩家列表（如果需要）
        uint256 balance = address(this).balance;

        // 2. 立即重置状态（防止重入）
        s_players = new address payable[](0);
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;

        // 3. 最后转账（即使重入，状态已重置，不会重复执行）
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Transfer failed");
    }
}
