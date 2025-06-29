// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "forge-std/Script.sol";
import "../src/ToDoList.sol";

contract DeployToDoList is Script {
function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerPrivateKey);
    ToDoList todo = new ToDoList();
    vm.stopBroadcast();
    
    console.log("ToDoList contract deployed at", address(todo));
}
}