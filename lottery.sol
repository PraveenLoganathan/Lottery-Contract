// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase{

    // state variables
    address public owner;
    address payable[] public players;
    uint public lotteryID;
    mapping (uint => address payable) public lotteryHistory;
    bytes32 internal keyHash; // identifies which Chainlink Oracle to use
    uint internal fee; // fee to get random number
    uint public randomResult;

    constructor()
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK token address
            ) {
                keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
                fee = 0.1 * 10 ** 18; // 0.1 LINK
                 owner = msg.sender;
                 lotteryID = 1;
            }

    function enterLottery() public payable{
        require(msg.value > 0.1 ether, "Entry amount is 0.1 ether");
        players.push(payable(msg.sender));
    }

    function getLotteryBalance() public view returns (uint){
        return address(this).balance;
    }

    function getRandomNumber() public returns (bytes32 requestID){
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract");
        return requestRandomness(keyHash,fee);
    }

    function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
        randomResult = randomness;
    }


    function pickWinner() public {
        uint index = randomResult % players.length;
        players[index].transfer(address(this).balance);

        lotteryHistory[lotteryID] = players[index];
        lotteryID++;

        players = new address payable[](0);
    }

    function lookUpWinnerByLotteryID(uint lookUpID) public view returns (address payable){
        return lotteryHistory[lookUpID];
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner has access");
        _;
    }

    modifier checkMinPlayers(){
        require(players.length > 3, "There must be atleast 4 players");
        _;
    }

}

