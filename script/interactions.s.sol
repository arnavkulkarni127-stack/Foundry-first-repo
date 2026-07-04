// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/fundme.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract FundFundMe is Script {
    function run() external {
        address recentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        fundFundMe(recentlyDeployed);
        // call fundFundMe(...)
    }

    uint256 public constant SEND_VALUE = 0.009 ether;

    function fundFundMe(address recentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(recentlyDeployed)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
    }
}

contract WithdrawFundMe is Script {
    function run() external {
        address recentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        withdrawFundMe(recentlyDeployed);
    }

    function withdrawFundMe(address recentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(recentlyDeployed)).withdraw();
        vm.stopBroadcast();
    }
}
