import { artifacts, ethers, waffle, network } from "hardhat";
import type { Artifact } from "hardhat/types";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";

import type { DEX } from "../src/types/DEX";
import type { Rewards } from "../src/types/Rewards";

import { expect } from "chai";
import { BigNumber } from "ethers";

const { utils } = ethers;
const { parseEther } = utils;
const { provider } = waffle;

const PERIOD_LENGTH = 1000 * 60 * 60 * 30; // 30 days
const ZERO_ETH = BigNumber.from(0);
const ONE_ETH = parseEther("1");
const TWO_ETH = parseEther("2");

describe("Unit Tests", () => {
  let dex: DEX;
  let signers: SignerWithAddress[];
  let [admin, account1, account2, account3]: SignerWithAddress[] = [];

  const jumpPeriods = async (n: number) => {
    for (let i = 0; i < n; i++) {
      await network.provider.send("evm_increaseTime", [PERIOD_LENGTH]);
    }
  };

  const openPosition = async (accounts: SignerWithAddress[], amounts: BigNumber[]) => {
    for (let i = 0; i < accounts.length; i++) {
      await dex.connect(accounts[i]).openPosition(0, { value: amounts[i] });
    }
  };

  const closePosition = async (accounts: SignerWithAddress[], amounts: BigNumber[]) => {
    for (let i = 0; i < accounts.length; i++) {
      await dex.connect(accounts[i]).closePosition(0, amounts[i]);
    }
  };

  before(async () => {
    signers = await ethers.getSigners();
    [admin, account1, account2, account3] = signers;
    signers = signers.slice(1);
  });

  describe("DEX", () => {
    beforeEach(async () => {
      const dexArtifact: Artifact = await artifacts.readArtifact("DEX");
      dex = <DEX>await waffle.deployContract(admin, dexArtifact, ["StripsRewards", "SPR"]);
    });

    describe("redeemRewards", async () => {
      it("Should redeem rewards", async () => {
        // open position x 3
        await openPosition(signers.slice(0, 3), [ONE_ETH, ONE_ETH, TWO_ETH]);

        // jump to next period
        await jumpPeriods(1);

        // open position x 5

        await openPosition(signers.slice(0, 5), [ONE_ETH, ONE_ETH, TWO_ETH, TWO_ETH, TWO_ETH]);

        // jump to next period
        await jumpPeriods(1);

        await openPosition([account2, account3], [ONE_ETH, ONE_ETH]);

        // close position
        await closePosition([account1], [TWO_ETH]);

        // jump to next period

        await jumpPeriods(1);

        // get periods where account1 executed a trade
        const rewardsContractAddress = await dex.rewardsContract();
        const contract = await ethers.getContractFactory("Rewards");
        const rewards = contract.attach(rewardsContractAddress);

        // redeem rewards
        await dex.connect(account1).redeem();
        console.log("REWARDS BAL: ", (await rewards.balanceOf(account1.address)).toString());
        //   dex.connect(account1).redeemRewards([]);
      });
    });
  });
});
