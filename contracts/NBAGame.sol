pragma solidity ^0.5.0;
contract NBAGame {
    address public owner;
    uint8 start;
    uint8 end;
    uint256 public minBet;
    uint256 public betsT1; //total bets on Team 1
    uint256 public betsT2; //total bets on Team 2
    
    address payable[] public players;
    
    struct Player {
        uint256 bet; //amount of bets
        bytes32 betTeam; //which team bets
    }

    struct Team {
        bytes32 name;
        uint256 odds;
        uint256 score;
    }
    // odds = realodds * 1000,
    // ex: 
    //    Rocket: Thunder = 1.218: 2.311
    //    t1Odds = 1218, t2Odds = 2311

    mapping(address => Player) public playerInfo;
    Team [2] teams;

    //fallback function
    function () external payable {}

    constructor() public payable {
        owner = msg.sender;
        minBet = 100000000000000;
        start = 0;
        end = 0;
        teams[0].name = "";
        teams[0].odds = 0;
        teams[0].score = 0;
        teams[1].name = "";
        teams[1].odds = 0;
        teams[1].score = 0;
    }

    function kill() public payable {
        if (msg.sender == owner) selfdestruct(msg.sender);
    }

    function checkPlayerExist(address player) public returns(bool) {
        for (uint256 i = 0;i < players.length; i++) {
            if (players[i] == player) return true;
        }
        return false;
    }

    function setDataName(bytes32 n1, bytes32 n2) public {
        require(msg.sender == owner, "Error, not admin.");
        require(start == 0, "Error, game started.");
        teams[0].name = n1;
        teams[1].name = n2;
    }

    function getDataName() public returns(bytes32 n1, bytes32 n2) {
        return (teams[0].name, teams[1].name);
    }

    function setDataOdds(uint256 o1, uint256 o2) public {
        require(msg.sender == owner, "Error, not admin.");
        require(start == 0, "Error, game started.");
        teams[0].odds = o1;
        teams[1].odds = o2;
    }

    function getDataOdds() public returns(uint256 t1, uint256 t2) {
        return (teams[0].odds, teams[1].odds);
    }

    function setDataScores(uint256 s1, uint256 s2) public {
        require(msg.sender == owner, "Error, not admin.");
        require(start == 1, "Error, game not start.");
        end = 1;
        teams[0].score = s1;
        teams[1].score = s2;
    }

    function getDataScores() public returns(uint256 a, uint256 b) {
        return (teams[0].score, teams[1].score);
    }

    // game start. stop betting
    function gameStart() public {
        require(msg.sender == owner, "Error, not admin.");
        require(teams[0].name != "", "Error, TeamName not set");
        require(teams[1].name != "", "Error, TeamName not set");
        require(teams[0].odds != 0, "Error, odds not set");
        require(teams[1].odds != 0, "Error, odds not set");
        start = 1;
    }

    function bet(bytes32 team) public payable {
        //One person can only bet 1 time;
        require(teams[0].name != "", "Error, TeamName not set");
        require(teams[1].name != "", "Error, TeamName not set");
        require(team == teams[0].name || team == teams[1].name, "Error, unrecognized team.");
        require(!checkPlayerExist(msg.sender), "Error, player already bet");
        require(msg.value >= minBet, "Error, bet too less");
        require(start == 0, "Error, game started.");

        playerInfo[msg.sender].bet = msg.value;
        playerInfo[msg.sender].betTeam = team;

        players.push(msg.sender);

        // 奖池比例分钱玩法
        // if (team == 1)
        //     betsT1 += msg.value;
        // else
        //     betsT2 += msg.value;
    }
    

    // 输赢盘赔率玩法
    function getResult() public payable {
        require(msg.sender == owner, "Error, not admin.");
        require(end == 1, "Error, game not end.");

        address payable winner;
        Team memory winTeam;
        Team memory loseTeam;
        uint256 winBet;

        if (teams[0].score > teams[1].score) {
            winTeam = teams[0];
            loseTeam = teams[1];
        }
        else {
            winTeam = teams[1];
            loseTeam = teams[0];
        }

        for (uint256 i; i < players.length ; i++) {
            winner = players[i];
            if (playerInfo[winner].betTeam == loseTeam.name) continue;
            winBet = playerInfo[winner].bet * winTeam.odds / 1000;
            delete playerInfo[winner];
            winner.transfer(winBet);
        }

        // clean all data
        delete players;
        delete winTeam;
        delete loseTeam;

        betsT1 = 0;
        betsT2 = 0; 
        winBet = 0;
        start = 0;
        end = 0;
    }

    // 庄家取余额
    function payBalance(address payable addr, uint256 amount) public payable {
        require(msg.sender == owner, "Error, not admin.");
        addr.transfer(amount);
    }
}