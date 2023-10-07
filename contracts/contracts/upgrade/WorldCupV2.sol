// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "hardhat/console.sol";

contract WorldCupV2 is Initializable {
    address public admin;
    uint8 public currRound;
    // string[] public countries = ["GERMANY", "FRANCH", "CHINA", "BRIZAL", "KOREA"];

    mapping(uint8 => mapping(address => Player)) players;

    mapping(uint8 => mapping(Country => address[])) public countryToPlayers;

    mapping(address => uint256) public winnerVaults;
    //因为immutable是不可变的所以要在constructor里定义 但现在constructor没了 就去掉immutable
    uint256 public  deadline;

    uint256 public lockedAmts;
    // upgrade V2
    uint256 public changeCount;

    enum Country {
        GERMANY,
        FRANCH,
        CHINA,
        BRIZAL,
        KOREA
    }
    event TransferMgr(address _prev, address _newMgr);
    event Play(uint8 _currRound, address _player, Country _selected);
    event Finialize(uint8 _currRound, uint256 _country);
    event ClaimReward(address _claimer, uint256 _amt);
    // upgrade V2
    event ChangeDeadline(uint256 _prev, uint256 _newDeadline);

    modifier onlyAdmin() {
        require(msg.sender == admin, "not authorized!");
        _;
    }

    struct Player {
        bool isSet;
        mapping(Country => uint) counts;
    }

    // constructor(uint256 _deadline) 将构造函数替换为初始化函数
    function initialize(uint256 _deadline) public initializer {
        admin = msg.sender;
        require(
            _deadline > block.timestamp,
            "WorldCupLottery: invalid deadline!"
        );
        deadline = _deadline;
    }

    /*转移管理员*/
    function transferMgr(address _newMgr) public onlyAdmin {
        address prev = admin;
        admin = _newMgr;
        emit TransferMgr(prev, admin);
    }

    // 2. 核心方法：下注、开奖、领奖

    /*玩家下注*/
    function play(Country _selected) public payable {
        require(block.timestamp < deadline, "watch the time,it's all over!");

        require(msg.value == 1 gwei, "invalid funds provided!");

        countryToPlayers[currRound][_selected].push(msg.sender);

        Player storage player = players[currRound][msg.sender];
        player.counts[_selected] += 1;

        emit Play(currRound, msg.sender, _selected);
    }

    /*管理员设计国家开奖*/
    function finialize(Country _country) external onlyAdmin {
        address[] memory winners = countryToPlayers[currRound][_country];
        uint256 distributeAmt; /**新增 */

        uint256 currAvalBalance = getVaultBalance() - lockedAmts;
        /**新增 */
        console.log(
            "currAvalBalance:",
            currAvalBalance,
            "winners count:",
            winners.length
        );

        // 平均分配奖金 计算每个人奖励多少
        for (uint256 i = 0; i < winners.length; i++) {
            address currWinner = winners[i];

            // 获取每个地址应该得到的份额 获取当前winner在下了多少注
            Player storage winner = players[currRound][currWinner];
            /**新增 */
            if (winner.isSet) {
                console.log(
                    "this winner has been set already, will be skipped!"
                );
                continue;
            }

            winner.isSet = true;

            uint256 currCounts = winner.counts[_country];

            // 计算当前winner分得的奖励
            uint256 amt = (currAvalBalance /
                countryToPlayers[currRound][_country].length) * currCounts;

            winnerVaults[currWinner] += amt;
            distributeAmt += amt; /**新增 */
            lockedAmts += amt;
            /**新增 */
            console.log("winner:", currWinner, "currCounts:", currCounts);
            console.log(
                "reward amt curr:",
                amt,
                "total:",
                winnerVaults[currWinner]
            );
        }
        /**新增 */
        uint256 giftAmt = currAvalBalance - distributeAmt;
        if (giftAmt > 0) {
            winnerVaults[admin] += giftAmt;
        }

        emit Finialize(currRound++, uint256(_country));
    }

    /*玩家领奖*/
    function claimReward() external {
        uint256 rewards = winnerVaults[msg.sender];
        require(rewards > 0, "nothing to claim!");

        winnerVaults[msg.sender] = 0;
        lockedAmts -= rewards;
        /**新增 */
        (bool succeed, ) = msg.sender.call{value: rewards}("");
        require(succeed, "claim reward failed!");

        console.log("rewards:", rewards);
        // payable(msg.sender).transfer(rewards);

        emit ClaimReward(msg.sender, rewards);
    }

    // upgrade V2
    function changeDeadline(uint256 _newDeadline) external {
      require(_newDeadline > block.timestamp, "invalid timestamp!");

      emit ChangeDeadline(deadline, _newDeadline);
      changeCount++;
      deadline = _newDeadline;
    }

 //////////////////////////////////////////////////// getter functions ////////////////////////////////////////////////
    function getVaultBalance() public view returns (uint256 bal) {
        bal = address(this).balance;
    }

    function getCountryPlayters(
        uint8 _round,
        Country _country
    ) external view returns (uint256) {
        return countryToPlayers[_round][_country].length;
    }

    function getPlayerInfo(
        uint8 _round,
        address _player,
        Country _country
    ) external view returns (uint256 _counts) {
        return players[_round][_player].counts[_country];
    }
}
