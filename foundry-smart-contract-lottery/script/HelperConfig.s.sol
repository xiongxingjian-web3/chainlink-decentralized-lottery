// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint96 public constant MOCK_BASE_FEE = 0.25 ether; // 保持原值
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9; // 保持原值
    int256 public constant MOCK_WEI_PER_UINT_LINK = 4e15; // 使用官方推荐值
}
contract HelperConfig is Script, CodeConstants {
    error HelperConfig_InvalidChainId(uint256 chainId);
    struct NetworkConfig {
        uint256 _entranceFee;
        uint256 _interval;
        address _vrfCoordinator;
        bytes32 _gasLane;
        uint256 _subscriptionId;
        uint32 _callbackGasLimit;
        address _link;
        address _account;
    }
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;
    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId]._vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig_InvalidChainId(chainId);
        }
    }
    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }
    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                _entranceFee: 0.01 ether,
                _interval: 30 seconds,
                _vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                _gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                _subscriptionId: 0, // 0 时由 DeployRaffle 自动创建并充值 VRF 订阅
                _callbackGasLimit: 100000,
                _link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                _account: address(0) // address(0) 时使用 .env 中 PRIVATE_KEY 对应账户广播
            });
    }
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig._vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UINT_LINK
        );
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();
        return
            localNetworkConfig = NetworkConfig({
                _entranceFee: 0.01 ether,
                _interval: 30 seconds,
                _vrfCoordinator: address(vrfCoordinator),
                _gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                _subscriptionId: 0,
                _callbackGasLimit: 100000,
                _link: address(linkToken),
                _account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
            });
    }
}
//
