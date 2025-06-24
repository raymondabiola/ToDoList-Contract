// solhint-disable func-visibility, state-mutability
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "forge-std/Test.sol";
import "../src/ToDoList.sol";

contract ToDoListTest is Test{
    ToDoList public todo;
    address public owner;
    address public zeroAddress;
    address public user1;
    address public user2;
    address public user3;

    function setUp() public{
        owner = address(this);
        zeroAddress = address(0);
        user1 = makeAddr('user1');
        user2 = makeAddr('user2');
        user3 = makeAddr('user3');
        todo = new ToDoList();
    }

// solhint-disable-next-line state-mutability
    function testDeployerIsOwnerAndHaveRoles()public {
        // checks if owner is deployer
        assertEq(todo.owner(), owner);

        // checks that deployer has Default admin role
        bytes32 defaultAdmin = todo.DEFAULT_ADMIN_ROLE();
        assertTrue(todo.hasRole(defaultAdmin, owner));

        //  checks that deployer has admin role
        bytes32 adminRole = todo.ADMIN_ROLE();
        assertTrue(todo.hasRole(adminRole, owner));
    }

    function testChangeOwner()public{
     bytes32 defaultAdmin = todo.DEFAULT_ADMIN_ROLE();  
     bytes32 adminRole = todo.ADMIN_ROLE();
     assertTrue(todo.hasRole(defaultAdmin, owner));
     assertTrue(todo.hasRole(adminRole, owner));

     vm.expectRevert(ToDoList.InvalidAddress.selector);
     todo.changeOwner(zeroAddress);
        
     todo.changeOwner(user2);
     assertFalse(todo.hasRole(defaultAdmin, owner));
     assertFalse(todo.hasRole(adminRole, owner));
     assertTrue(todo.hasRole(defaultAdmin, user2));
     assertTrue(todo.hasRole(adminRole, user2));
    }

    function testAssignRole()public{
    bytes32 role = todo.ADMIN_ROLE();

    todo.assignRole(role, user1);
    assertTrue(todo.hasRole(role, user1));

    vm.expectRevert(ToDoList.InvalidAddress.selector);
    todo.assignRole(role, zeroAddress);

    vm.startPrank(user1);
    vm.expectRevert();
    todo.assignRole(role, user1);
}

function testRevokeRole()public{
    bytes32 defaultAdmin = todo.DEFAULT_ADMIN_ROLE();
    bytes32 role = todo.ADMIN_ROLE();
    todo.assignRole(role, user1);
    assertTrue(todo.hasRole(role, user1));
    todo.revokeRoleOfAdmin(role, user1);
    assertFalse(todo.hasRole(role, user1));

    vm.startPrank(user1);
    vm.expectRevert();
    todo.revokeRoleOfAdmin(defaultAdmin, owner);
}

function testRenounceMyRole()public{
bytes32 defaultAdmin = todo.DEFAULT_ADMIN_ROLE();
bytes32 role = todo.ADMIN_ROLE();
    todo.assignRole(role, user1);
    assertTrue(todo.hasRole(role, user1));

    vm.startPrank(user1);
    todo.renounceMyRole(role);
    assertFalse(todo.hasRole(role, user1));
    vm.stopPrank();

    vm.expectRevert(ToDoList.ForbiddenUseChangeOwnerFunction.selector);
    todo.renounceMyRole(defaultAdmin);
}

    function testAddTask()public{
        string memory description = "learning foundry";
        string memory desc1 = "";
        string memory desc2 = "Play Chess";
        todo.addTask(description);

        (uint id, string memory desc, bool isCompleted) = todo.getTaskInfo(0);

        assertEq(id, 1);
        assertEq(desc, description);
        assertEq(isCompleted, false);
        assertTrue(todo.checkIsUserStatus(owner));

    vm.expectRevert(ToDoList.InvalidDescription.selector);
    todo.addTask(desc1);

     vm.prank(user1);
    todo.addTask(desc2);
    todo.banUser(user1);
    vm.expectRevert(ToDoList.RestrictedUser.selector);
    vm.prank(user1);
    todo.addTask(desc2);
    }

    function testEditTask()public{
        string memory desc1 = "Do Chores";
        string memory desc2 = "Play Games";
        string memory desc3 = "Play Music";
        string memory desc4 = "";

        todo.addTask(desc1);
        todo.addTask(desc2);
        todo.editTask(desc3, 1);
        (uint id, string memory description, bool isCompleted) = todo.getTaskInfo(1);
        assertEq(id, 2);
        assertEq(description, desc3);
        assertEq(isCompleted, false);

        vm.expectRevert(ToDoList.InvalidIndex.selector);
        todo.editTask(desc2, 2);
        vm.expectRevert(ToDoList.InvalidDescription.selector);
        todo.editTask(desc4, 1);
        todo.markTaskCompleted(1);
        vm.expectRevert(ToDoList.TaskIsCompleted.selector);
        todo.editTask(desc3, 1);
    }

    function testMarkTaskCompleted()public{
     string memory desc1 = "Do Chores";

        todo.addTask(desc1);
        todo.markTaskCompleted(0);
        (,,bool isCompleted) = todo.getTaskInfo(0);
        assertEq(isCompleted, true);
        vm.expectRevert(ToDoList.TaskIsCompleted.selector);
        todo.markTaskCompleted(0);
        vm.expectRevert(ToDoList.InvalidIndex.selector);
        todo.markTaskCompleted(1);
}

    function testDeleteTask()public{
     string memory desc1 = "Do Chores";
     string memory desc2 = "Play Games";
     string memory desc3 = "Work";
        todo.addTask(desc1);
        todo.addTask(desc2);
        todo.addTask(desc3);
        assertEq(todo.getMyTasksCount(), 3);
        todo.delTask(0);
        (,string memory description,) = todo.getTaskInfo(0);
        (,string memory description2,) = todo.getTaskInfo(1);
        assertEq(todo.getMyTasksCount(), 2);
        assertEq(description, desc2);
        assertEq(description2, desc3);

        vm.expectRevert(ToDoList.InvalidIndex.selector);
        todo.delTask(3);
}

function testBanUser()public{
    string memory desc1 = "Do Chores";
     string memory desc2 = "Play Games";
    vm.prank(user1);
    todo.addTask(desc1);
    todo.banUser(user1);
    vm.prank(user1);
    vm.expectRevert(ToDoList.RestrictedUser.selector);
    todo.addTask(desc2);

    vm.expectRevert(ToDoList.NotYetUser.selector);
    todo.banUser(user2);

    vm.prank(user2);
    todo.addTask(desc2);
    vm.expectRevert();
    vm.prank(user1);
    todo.banUser(user2);
}

function testUnbanUser()public{
     string memory desc1 = "Do Chores";
     string memory desc2 = "Play Games";
     string memory desc3 = "Read";
    vm.startPrank(user1);
    todo.addTask(desc1);
    assertEq(todo.getMyTasksCount(), 1);
    vm.stopPrank();
    todo.banUser(user1);
    vm.prank(user1);
    vm.expectRevert(ToDoList.RestrictedUser.selector);
    todo.addTask(desc2);
    todo.unBanUser(user1);
    vm.startPrank(user1);
    todo.addTask(desc2);
    todo.addTask(desc3);
    assertEq(todo.getMyTasksCount(), 2);
    vm.stopPrank();

    vm.prank(user2);
    todo.addTask(desc1);
    todo.banUser(user2);
    vm.expectRevert();
    vm.prank(user1);
    todo.unBanUser(user2);

    vm.expectRevert(ToDoList.InvalidAddress.selector);
    todo.unBanUser(zeroAddress);
}

function testCheckUserBanStatus()public{
    string memory desc1 = "Do Chores";
    vm.prank(user1);
    todo.addTask(desc1);
    assertFalse(todo.checkUserBanStatus(user1));
    todo.banUser(user1);
    assertTrue(todo.checkUserBanStatus(user1));
}

function testCheckIsUserStatus()public{
    string memory desc1 = "Do Chores";
   assertFalse(todo.checkIsUserStatus(user1));
   vm.prank(user1);
   todo.addTask(desc1);
   assertTrue(todo.checkIsUserStatus(user1)); 
}

function testGetTaskInfo()public{
    string memory desc1 = "Do Chores";
    vm.startPrank(user1);
    todo.addTask(desc1);
    (uint id, string memory desc, bool isCompleted) = todo.getTaskInfo(0);
    assertEq(id, 1);
    assertEq(desc, desc1);
    assertEq(isCompleted, false);
    todo.markTaskCompleted(0);
    (,, bool isComplete) = todo.getTaskInfo(0);
    assertEq(isComplete, true);

    vm.expectRevert(ToDoList.InvalidIndex.selector);
    todo.getTaskInfo(1);
}

function testGetAllMyTasks()public{
    string memory desc1 = "Do Chores";
     string memory desc2 = "Play Games";
     vm.startPrank(user1);
    todo.addTask(desc1);
    todo.addTask(desc2);
  ToDoList.Task[] memory tasks = todo.getAllMyTasks();
assertEq(tasks.length, 2);
assertEq(tasks[0].description, desc1);
assertEq(tasks[1].description, desc2);
}

function testGetUserAllTasks()public{
    string memory desc1 = "Do Chores";
     string memory desc2 = "Play Games";
     vm.startPrank(user1);
    todo.addTask(desc1);
    todo.addTask(desc2);
    vm.stopPrank();
  ToDoList.Task[] memory tasks = todo.getUserAllTasks(user1);
assertEq(tasks.length, 2);
assertEq(tasks[0].description, desc1);
assertEq(tasks[1].description, desc2);

vm.expectRevert(ToDoList.InvalidAddress.selector);
todo.getUserAllTasks(zeroAddress);
}

function testGetAllUsersAddress()public{
 string memory desc1 = "Do Chores";
     string memory desc2 = "Play Games";
     string memory desc3 = "Read";
    vm.prank(user1);
    todo.addTask(desc1);
    vm.prank(user2);
    todo.addTask(desc2);
    vm.prank(user3);
    todo.addTask(desc3);
    assertEq((todo.getAllUsersAddress()).length,3);
    todo.banUser(user2);
    assertEq((todo.getAllUsersAddress()).length, 2);
}

function testGetAllUsersAddressCount()public{
    string memory desc1 = "Do Chores";
     string memory desc2 = "Play Games";
     string memory desc3 = "Read";
     vm.prank(user1);
    todo.addTask(desc1);
    vm.prank(user2);
    todo.addTask(desc2);
    vm.prank(user3);
    todo.addTask(desc3);
    assertEq(todo.getAllUsersAddressCount(), 3);
    todo.banUser(user2);
    assertEq(todo.getAllUsersAddressCount(), 2);
}

function testGetMyTasksCount()public{
      string memory desc1 = "Do Chores";
     string memory desc2 = "Play Games";
     string memory desc3 = "Watch Ithachi";
     vm.startPrank(user1);
    todo.addTask(desc1);
    todo.addTask(desc2);
    todo.addTask(desc3);
    assertEq(todo.getMyTasksCount(), 3);
    todo.delTask(1);
    assertEq(todo.getMyTasksCount(), 2);
}

function testGetTotalAvailableTasks()public{
    string memory desc1 = "Do Chores";
     string memory desc2 = "Play Games";
     string memory desc3 = "Watch Ithachi";
     string memory desc4 = "Play football";
     string memory desc5 = "Take Coffee";
     vm.startPrank(user1);
    todo.addTask(desc1);
    todo.addTask(desc2);
    todo.addTask(desc3);
    vm.stopPrank();
    vm.prank(user2);
    todo.addTask(desc4);
    vm.prank(user3);
    todo.addTask(desc5);
    assertEq(todo.getTotalAvailableTasks(), 5);
    vm.prank(user1);
    todo.delTask(0);
todo.banUser(user2);
assertEq(todo.getTotalAvailableTasks(), 3);
}
}