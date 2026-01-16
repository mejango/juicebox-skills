// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {PaymentCapHook} from "../src/pay-hooks/PaymentCapHook.sol";

contract DeployPaymentCapHook is Script {
    function run() external returns (PaymentCapHook hook) {
        // Configuration
        uint256 defaultCap = 10 ether; // Default max payment of 10 ETH
        address owner = msg.sender;

        // Deploy
        vm.startBroadcast();

        hook = new PaymentCapHook(defaultCap, owner);

        vm.stopBroadcast();

        // Log deployment info
        console2.log("PaymentCapHook deployed at:", address(hook));
        console2.log("  Default cap:", defaultCap);
        console2.log("  Owner:", owner);

        return hook;
    }
}
