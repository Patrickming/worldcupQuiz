// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "hardhat/console.sol";

contract WorldCup {

// 1. 状态变量：管理员、当前期数、参赛球队（国家）、每期的玩家、每期国家的下注情况、玩家累计可领的奖金
    address public admin;
    uint8 public currRound;
    string[] public countries = ["GERMANY", "FRANCH", "CHINA", "BRIZAL", "KOREA"];
    // mapping (期数 => mapping (玩家地址 => 玩家详情结构体数据)) 
    mapping (uint8 => mapping (address => Player)) players;
    // mapping (期数 => mapping (国家 => 下注的玩家)) 
    mapping (uint8 => mapping (Country => address[])) public countryToPlayers;
    // mapping (玩家地址 => 可领的奖金)
    mapping (address => uint256) public winnerVaults;
    //因为是根据总数计算份额来分奖金 所以在算完一期所有人该分走的应减去这部分 防止玩家没有及时取走影响下一期开奖的奖金计算
    uint256 public lockedAmts;


    struct Player {
        bool isSet;
        mapping (Country => uint) counts;//记录玩家对每个国家的下注的次数（后续计算份额）
    }
    enum Country {//下标从0开始
        GERMANY, 
        FRANCH, 
        CHINA, 
        BRIZAL,
        KOREA
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "not authorized!");
        _;
    }

    //一般在写入（修改）数据的时候要设置一个事件 因为这样链下就知道发生了什么
    event TransferMgr(address _prev, address _newMgr);
    event Play(uint8 _currRound, address _player, Country _selected);
    event Finialize(uint8 _currRound, uint256 _country);
    event ClaimReward(address _claimer, uint256 _amt);

    constructor () {
        //交易的发起人是msg.sender
        admin = msg.sender;
    }
    /*转移管理员*/
    function transferMgr(address _newMgr) public onlyAdmin{
            address prev = admin;
            admin = _newMgr;
            emit TransferMgr(prev, admin);
        }

 // 2. 核心方法：下注、开奖、领奖

    /*玩家下注*/
    function play(Country _selected) public payable {
        // 金额校验 一次下注是1 gwei
        require(msg.value == 1 gwei, "invalid funds provided!");
        // 更新每期国家的下注情况（添加下注人（一个人可重复下注一个国家））
        countryToPlayers[currRound][_selected].push(msg.sender);

        // 更新每期玩家的下注结果
        //获取到玩家本人player结构
        Player storage player = players[currRound][msg.sender];
        player.counts[_selected] += 1;

        emit Play(currRound, msg.sender, _selected);
    }


    /*管理员设计国家开奖*/
    function finialize(Country _country) external onlyAdmin  {
        // 找到当前期数所有的赢家winners   因为只需要读这个数据不需要改 所以定义为memory取出
        address[] memory winners = countryToPlayers[currRound][_country];

       //查看当前奖金池（合约里）有多少钱 要减去往期开奖计算的钱
        uint256 currAvalBalance = getVaultBalance() - lockedAmts;

        // 平均分配奖金 计算每个人奖励多少
        for (uint i = 0; i < winners.length; i++) {
            address currWinner = winners[i];

            // 获取每个地址应该得到的份额 获取当前winner在下了多少注
            Player storage winner = players[currRound][currWinner];
            uint currCounts = winner.counts[_country];

            // 计算当前winner分得的奖励=（本期总奖励 / 总参与人数）* 当前地址持有份额
            uint amt = (currAvalBalance / countryToPlayers[currRound][_country].length) * currCounts;
            winnerVaults[currWinner] += amt;//增加当前winner可领奖金数
            lockedAmts += amt;
        }

        emit Finialize(currRound++, uint256(_country));
    }

    /*玩家领奖*/
    function claimReward() external {
        //查看自己可领取的金额
        uint256 rewards = winnerVaults[msg.sender];
        require(rewards > 0, "nothing to claim!");
        //开始转钱
        winnerVaults[msg.sender] = 0;
        lockedAmts -= rewards;
        payable(msg.sender).transfer(rewards);

        emit ClaimReward(msg.sender, rewards);
    }

        /*查看合约余额*/
     function getVaultBalance() public view returns (uint256 bal) {
        bal = address(this).balance;
    }
}

    