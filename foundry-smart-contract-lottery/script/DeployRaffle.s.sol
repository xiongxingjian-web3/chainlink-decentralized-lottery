// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumner} from "./Interactions.s.sol";
contract DeployRaffle is Script {
    function run() public {
        deployContract();
    }
    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        if (config._subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (
                config._subscriptionId,
                config._vrfCoordinator
            ) = createSubscription.createSubscription(
                config._vrfCoordinator,
                config._account
            );
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config._vrfCoordinator,
                config._subscriptionId,
                config._link,
                config._account
            );
        }

        vm.startBroadcast(config._account);
        Raffle raffle = new Raffle(
            config._entranceFee,
            config._interval,
            config._vrfCoordinator,
            config._gasLane,
            config._subscriptionId,
            config._callbackGasLimit
        );
        vm.stopBroadcast();
        AddConsumner addConsumner = new AddConsumner();
        addConsumner.addConsumner(
            address(raffle),
            config._vrfCoordinator,
            config._subscriptionId,
            config._account
        );
        return (raffle, helperConfig);
    }
}
