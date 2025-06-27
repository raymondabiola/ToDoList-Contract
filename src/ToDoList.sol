// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {AccessControl} from "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

contract ToDoList is AccessControl{

struct Task{
    uint256 id;
    string description;
    bool isCompleted;
}
    
address[] internal users;
bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
uint256 private newTaskId;

mapping(address => Task[]) internal userTasks;
mapping (address => bool) internal isUser;
mapping(address => bool) internal isBanned;

event UserBanned(address indexed addr);
event UserUnbanned(address indexed addr);

error InvalidIndex();
error InvalidAddress();
error InvalidDescription();
error  RestrictedUser();
error TaskIsCompleted();
error NoTaskFound();
error IndexNotFound();
error NotYetUser();
error ForbiddenUseChangeOwnerFunction();

constructor(){
newTaskId = 1;
_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
_grantRole(ADMIN_ROLE, msg.sender);
}

modifier validIndex(uint256 _index){
    require(_index<userTasks[msg.sender].length, InvalidIndex());
    _;
}

modifier validDescription(string memory _description){
    require(bytes(_description).length>0, InvalidDescription());
    _;
}

modifier notCompleted(uint256 _index){
       require(!userTasks[msg.sender][_index].isCompleted, TaskIsCompleted());
       _;
}

modifier validAddress(address _addr){
    if(_addr == address(0)) revert InvalidAddress(); //If statements are preferred for reverts like this when testing with foundry
    _;
}

function stripCurrentOwnerRights()internal{
    _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
_revokeRole(ADMIN_ROLE, msg.sender);
}

function grantNewOwnerRights(address _addr)internal validAddress(_addr){
    _grantRole(DEFAULT_ADMIN_ROLE, _addr);
    _grantRole(ADMIN_ROLE, _addr);
}

function changeOwner(address _addr)external validAddress(_addr) onlyRole(DEFAULT_ADMIN_ROLE){
stripCurrentOwnerRights();
grantNewOwnerRights(_addr);
}

function assignRole(bytes32 role, address addr)public validAddress(addr){
    grantRole(role, addr);
}
                         
function revokeRoleOfAdmin(bytes32 role, address addr) public validAddress(addr){
revokeRole(role, addr);
}

function renounceMyRole(bytes32 role)public{
    require(role!=DEFAULT_ADMIN_ROLE, ForbiddenUseChangeOwnerFunction());
renounceRole(role, msg.sender);
}

// This function helps users add new tasks.
function addTask(string memory _description)public validDescription(_description){
    require(!isBanned[msg.sender], RestrictedUser());
    Task memory newTask = Task({
        id: newTaskId,
        description: _description,
        isCompleted: false
    });
    userTasks[msg.sender].push(newTask);
    newTaskId++;

    if(!isUser[msg.sender]){
        users.push(msg.sender);
        isUser[msg.sender] = true;
    }
}

// This function helps users to edit their task
function editTask(string memory _description, uint256 _index)public validIndex(_index) validDescription(_description) notCompleted(_index){
userTasks[msg.sender][_index].description = _description;
}

// This function helps to mark a task complete
function markTaskCompleted (uint256 _index) public validIndex(_index) notCompleted(_index){
    Task[] storage tasks = userTasks [msg.sender];
    tasks[_index].isCompleted = true;
}

// This function allows users to delete their task
function delTask(uint256 _index)public validIndex(_index){
    Task[] storage tasks = userTasks[msg.sender];
    require (tasks.length!=0, NoTaskFound());
for(uint256 i=_index; i<tasks.length-1; i++){
tasks[i] = tasks[i+1];
    }
     tasks.pop();
    }
//Internal function to get the index of an address in users array
function getAddressIndex(address targetValue)internal view returns(uint256){
for(uint256 i=0; i<users.length; i++){
    if(users[i]==targetValue){
        return i;
    }
}
 revert IndexNotFound();
}

//Function to ban a user from this contract.
function banUser(address _addr)public onlyRole(ADMIN_ROLE) {
    require(isUser[_addr] == true, NotYetUser());
    require(!isBanned[_addr], RestrictedUser());
uint256 addressIndex = getAddressIndex(_addr);
for(uint256 i=addressIndex; i<users.length-1;i++){
        users[i] = users[i+1];
    }
    users.pop();
    delete userTasks[_addr];
    isUser[_addr] = false;
    isBanned[_addr] = true;

    emit UserBanned(_addr);
}

//This function is used by the admins to unban a user
function unBanUser(address _addr)public onlyRole(ADMIN_ROLE) validAddress(_addr){
    isBanned[_addr] = false;
      emit UserUnbanned(_addr);
}

// This function is used by the admins to check the ban status of a user
function checkUserBanStatus(address _addr)public onlyRole(ADMIN_ROLE) validAddress(_addr) view returns(bool) {
    return isBanned[_addr];
}

// This function is used by the admins to check the user status of an address
function checkIsUserStatus(address _addr)public onlyRole(ADMIN_ROLE) validAddress(_addr) view returns(bool) {
    return isUser[_addr];
}

// This function helps to get the information of a specific task a user created
function getTaskInfo(uint256 _index)public view validIndex(_index) returns(uint256, string memory, bool){
   Task memory task = userTasks[msg.sender][_index];
   return (task.id, task.description, task.isCompleted);
}

// This function helps users to know all their current tasks
function getAllMyTasks()public view returns(Task[] memory){
return userTasks[msg.sender];
}

// Allows Only admins to get all tasks by a user
function getUserAllTasks(address _address)public view onlyRole(ADMIN_ROLE) validAddress(_address) returns(Task[] memory){
    return userTasks[_address];
}

//Function to get addresses of all users by only admins
function getAllUsersAddress()public view onlyRole(ADMIN_ROLE) returns(address[] memory){
return users;
}

function getAllUsersAddressCount()public view onlyRole(ADMIN_ROLE)returns(uint256){
    return users.length;
}

// This function returns the total amount of tasks a user has created
function getMyTasksCount()public view returns(uint256){
    return userTasks[msg.sender].length;
}

function getTotalAvailableTasks()public view onlyRole(DEFAULT_ADMIN_ROLE) returns(uint256){
     uint256 totalTasks = 0;
for(uint256 i=0; i<users.length; i++){
 totalTasks += userTasks[users[i]].length;
}
return totalTasks;
}
}