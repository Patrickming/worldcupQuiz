import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("WorldCup", function () {
  //我们在这写的所有的相当于全局变量的作用是我们测试拿数据
  enum Country {//这里方便后面测试拿数据
    GERMANY,
    FRANCH,
    CHINA,
    BRAZIL,
    KOREA
  }
  const ONE_GWEI = 1_000_000_000;


  async function deployWorldCupFixture() {
    const TWO_WEEKS_IN_SECS = 14 * 24 * 60 * 60; //两周的秒数
    const timestamp = Math.floor(Date.now() / 1000)
    const deadline = timestamp + TWO_WEEKS_IN_SECS; //ddl时间为两周后

    //这个就是npx harhdat node里内存模拟的生成的虚拟账户 然后默认第一个就是部署地址
    const [admin, otherAccount1, otherAccount2] = await ethers.getSigners();

    // console.log("admin:", admin.address);
    // console.log("otherAccount:", otherAccount.address);
    // console.log("otherAccount1:", otherAccount2.address);

    //为什么要await 因为这是链上的交易操作不管是写还是读 肯定不是同步的而是异步的
    const WorldCup = await ethers.getContractFactory("WorldCup");
    const worldcup = await WorldCup.deploy(deadline);

    //这里相当于我传进来的数抛出去给下面的方法使用
    return { worldcup, deadline, admin, otherAccount1 };
  }

  describe("Deployment WorldCup", function () {
    it("Should set the right deadline", async function () {
      //loadFixture 方法如其名 加载Fixture里面抛出的内容
      const { worldcup, deadline, admin } = await loadFixture(deployWorldCupFixture);
      //这里deadline在合约里是public的 所以相当于直接worldcup.deadline()调用get函数
      //检查传进来的deadline是否和合约里的一致
      expect(await worldcup.deadline()).to.equal(deadline);
    });

    it("Should set the right admin", async function () {
      const { worldcup, admin } = await loadFixture(deployWorldCupFixture);
      expect(await worldcup.admin()).to.equal(admin.address);//像这里的admin是对象 我们比较的是叫admin的地址 而不是admin对象所以要admin.address
    });
  });

  //主要也就检查三类
  //equal 数据对不对
  //revertedWith 该抛的异常抛出了没有
  //emit Even  事件抛没抛
  describe("Play", function () {

    //revertedWith：require(msg.value == 1 gwei, "invalid funds provided!");
    it("Should failed without 1gwei", async () => {
      // 获取合约实例
      const { worldcup, admin } = await loadFixture(deployWorldCupFixture);

      // 调用合约
      // 对应合约：function play(Country _selected) public payable {}
      /* 1 如果给的值不对ONE_GWEI * 2 那就会抛异常 如果想要测试不终止的话 这个地方要捕获异常expect()
       * 2 如果是捕获异常 await 要放在expect外面 其他就是在里面
        */

      await expect(worldcup.play(Country.CHINA, {
        value: ONE_GWEI * 2
      })).to.revertedWith("invalid funds provided!")

    });

    //equal：require(msg.value == 1 gwei, "invalid funds provided!");
    it("should getbalance correct", async function () {
      // 获取合约实例
      const { worldcup, admin } = await loadFixture(deployWorldCupFixture);

      // 对应合约：function play(Country _selected) public payable {}
      await worldcup.play(Country.CHINA, {
        value: ONE_GWEI
      })

      // 校验金额是不是1gwei
      let bal = await worldcup.getVaultBalance()
      console.log("bal:", bal);
      console.log("bal.toString():", bal.toString());

      expect(bal).to.equal(ONE_GWEI)
      //所有数据返回都是bignumber类型 
      // let num = 1000000000000000000000
      // let bigNum = ethers.BigNumber.from(num) //"1000000000000000000000"
    });

    // emit Play(currRound, msg.sender, _selected);
    it("Should emit Event Play", async function () {
      const { worldcup, admin } = await loadFixture(deployWorldCupFixture);
      await expect(worldcup.play(Country.BRAZIL, {
        value: ONE_GWEI
      })).to.emit(worldcup, "Play").withArgs(0, admin.address, Country.BRAZIL)// emit Play(currRound, msg.sender, _selected);
    })
  });


  describe("Finalize", function () {
    // function finialize(Country _country) external onlyAdmin 
    it("Should failed when called by other account", async function () {
      const { worldcup ,otherAccount1} = await loadFixture(deployWorldCupFixture);
      
      //演示非admin账户调用Finalize的拦截情况
      //如果要用别的账户调用的话 就connect
      await expect(worldcup.connect(otherAccount1).finialize(Country.BRAZIL)).to.
      revertedWith("not authorized!")
    });

  });

  describe("ClaimReward", function () {

  });

});