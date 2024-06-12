import { ethers, network } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import {
  HalvingProtocol,
  NonfungiblePositionManager,
  QuoterV2,
  SwapRouter,
  UNXToken,
  UNXwapV3Factory,
  UNXwapV3LmFactory,
  UNXwapV3LmPool,
  UNXwapV3Manager,
  UNXwapV3Pool,
  WETH9,
} from "../typechain-types";
import { ZeroAddress, formatEther, parseEther } from "ethers";
import { expect } from "chai";
import { mine } from "@nomicfoundation/hardhat-network-helpers";
import { Currency, Price, Token } from "@uniswap/sdk-core";
import JSBI from "jsbi";
import {
  encodeSqrtRatioX96,
  nearestUsableTick,
  priceToClosestTick,
  TickMath,
} from "@uniswap/v3-sdk";
import { bigint } from "hardhat/internal/core/params/argumentTypes";

enum FeeAmount {
  LOWEST = 100,
  LOW = 500,
  MEDIUM = 3000,
  HIGH = 10000,
}

const TICK_SPACINGS: { [amount in FeeAmount]: number } = {
  [FeeAmount.LOWEST]: 1,
  [FeeAmount.LOW]: 10,
  [FeeAmount.MEDIUM]: 60,
  [FeeAmount.HIGH]: 200,
};

const getMinTick = (tickSpacing: number) =>
  Math.ceil(-887272 / tickSpacing) * tickSpacing;
const getMaxTick = (tickSpacing: number) =>
  Math.floor(887272 / tickSpacing) * tickSpacing;

const genesisBlock = 1001;

interface _UNXToken extends UNXToken {
  address: string;
}
interface _WETH9 extends WETH9 {
  address: string;
}

let unx: _UNXToken;
let sampleERC20: _UNXToken;
let wETH9: _WETH9;
let halving: HalvingProtocol;
let v3Manager: UNXwapV3Manager;
let v3Factory: UNXwapV3Factory;
let lmFactory: UNXwapV3LmFactory;
let nfpManager: NonfungiblePositionManager;
let xRouter: SwapRouter;
let xQuoterV2: QuoterV2;

let owner: HardhatEthersSigner;
let executor: HardhatEthersSigner;
let user: HardhatEthersSigner;
let other: HardhatEthersSigner;

let deadline = 0;
let tokenId = 0;

describe("Unchain Swap", () => {
  beforeEach(async () => {
    // Reset hardhat network
    await network.provider.send("hardhat_reset");

    // Set signer
    const signer = await ethers.getSigners();
    owner = signer[0];
    executor = signer[1];
    user = signer[2];
    other = signer[3];

    // Deploy contracts and initialize for test
    const UNX = await ethers.getContractFactory("UNXToken");
    unx = (await UNX.deploy(
      "Unchain X",
      "UNX",
      parseEther("10000000000")
    )) as _UNXToken;
    unx.address = await unx.getAddress();

    sampleERC20 = (await UNX.deploy(
      "Sample ERC20",
      "SERC",
      parseEther("10000000000")
    )) as _UNXToken;
    sampleERC20.address = await sampleERC20.getAddress();

    const Halving = await ethers.getContractFactory("HalvingProtocol");
    halving = await Halving.deploy({
      token: await unx.getAddress(),
      genesisBlock: genesisBlock,
      totalNum: 5,
      halvingInterval: 28800,
      initReward: parseEther("300000"),
      totalSupply: parseEther("9550000000"),
    });

    await unx.transfer(await halving.getAddress(), parseEther("9550000000"));

    const V3Manager = await ethers.getContractFactory("UNXwapV3Manager");
    v3Manager = await V3Manager.deploy();
    v3Factory = await ethers.getContractAt(
      "UNXwapV3Factory",
      await v3Manager.factory()
    );

    const WETH9 = await ethers.getContractFactory("WETH9");
    wETH9 = (await WETH9.deploy()) as _WETH9;
    wETH9.address = await wETH9.getAddress();

    const NftDescriptorLib = await ethers.getContractFactory("NFTDescriptor");
    const nftDescriptorLib = await NftDescriptorLib.deploy();
    const NFPDescriptor = await ethers.getContractFactory(
      "NonfungibleTokenPositionDescriptor",
      {
        libraries: { NFTDescriptor: await nftDescriptorLib.getAddress() },
      }
    );
    const nftDescriptor = await NFPDescriptor.deploy(
      await wETH9.getAddress(),
      asciiStringToBytes32("BNB")
    );

    const NFPManager = await ethers.getContractFactory(
      "NonfungiblePositionManager"
    );
    nfpManager = await NFPManager.deploy(
      await v3Factory.getAddress(),
      await wETH9.getAddress(),
      await nftDescriptor.getAddress()
    );

    const LMFactory = await ethers.getContractFactory("UNXwapV3LmFactory");
    lmFactory = await LMFactory.deploy(
      await halving.getAddress(),
      await nfpManager.getAddress(),
      await v3Manager.getAddress()
    );

    await v3Manager.setLmFactory(await lmFactory.getAddress());
    await halving.setOperator(await lmFactory.getAddress());

    const XRouter = await ethers.getContractFactory("SwapRouter");
    xRouter = await XRouter.deploy(
      await v3Manager.factory(),
      await wETH9.getAddress()
    );

    const XQuoterV2 = await ethers.getContractFactory("QuoterV2");
    xQuoterV2 = await XQuoterV2.deploy(
      await v3Manager.factory(),
      await wETH9.getAddress()
    );

    const currentBlockNumber = await ethers.provider.getBlockNumber();
    const currentBlock = await ethers.provider.getBlock(currentBlockNumber);
    const now = currentBlock?.timestamp || 0;

    deadline = now + 3000;
    tokenId = 0;
  });

  
  describe("V3 Manager", () => {
    describe("Create Pool", () => {
      it("Only execute owner or executor when not deployable", async () => {
        const tokenA = await unx.getAddress();
        const tokenB = await wETH9.getAddress();
        await v3Manager.setExecutor(executor.address);

        await expect(
          v3Manager.connect(user).createPool(tokenA, tokenB, ZeroAddress,3000)
        ).to.be.revertedWith("Caller is unauthorized");
        await expect(v3Manager.connect(owner).createPool(tokenA, tokenB, ZeroAddress, 3000))
          .to.not.be.reverted;
        await expect(
          v3Manager.connect(executor).createPool(tokenA, tokenB, ZeroAddress, 10000)
        ).to.not.be.reverted;
      });

      it("Does not operate deploy fee protocol when deploy fee is ZERO", async () => {
        const tokenA = await unx.getAddress();
        const tokenB = await wETH9.getAddress();

        await v3Manager.setDeployable(true);
        await expect(v3Manager.connect(user).createPool(tokenA, tokenB, user.address, 3000))
          .to.not.be.reverted;
      });

      it("Operate deploy fee protocol when deploy fee is greater than ZERO", async () => {
        const tokenA = await unx.getAddress();
        const tokenB = await wETH9.getAddress();
        const deployFee = parseEther("100");

        await v3Manager.setDeployable(true);
        await v3Manager.setDeployFee(deployFee);
        await v3Manager.setDeployFeeCollector(other.address);
        await v3Manager.setDeployFeeToken(await unx.getAddress());

        // failure
        await expect(v3Manager.connect(user).createPool(tokenA, tokenB, user.address, 3000))
          .to.be.reverted;

        // success
        await unx.transfer(user.address, deployFee);
        await unx
          .connect(user)
          .approve(await v3Manager.getAddress(), deployFee);

        await expect(v3Manager.connect(user).createPool(tokenA, tokenB, user.address, 3000))
          .to.not.be.reverted;
        expect(await unx.balanceOf(user.address)).to.be.equal(0);
        expect(await unx.balanceOf(other.address)).to.be.equal(deployFee);
      });
    });

    describe("Liquidity Mining", () => {
      let v3Pool: UNXwapV3Pool;
      let v3PoolCA: string;
      let lmPool: UNXwapV3LmPool;
      let lmPoolCA: string;
      let tokenA: string;
      let tokenB: string;

      beforeEach(async () => {
        tokenA = await unx.getAddress();
        tokenB = await wETH9.getAddress();
        v3PoolCA = computePoolAddress(
          await v3Factory.getAddress(),
          [tokenA, tokenB],
          3000
        );

        await v3Manager.createPool(tokenA, tokenB, ZeroAddress, 3000);
        v3Pool = await ethers.getContractAt("UNXwapV3Pool", v3PoolCA);

        lmPoolCA = await v3Pool.lmPool();
        lmPool = await ethers.getContractAt("UNXwapV3LmPool", lmPoolCA);
      });

      describe("Listing", () => {
        it("Only execute V3 Manager", async () => {
          await expect(
            lmFactory.connect(owner).list(v3PoolCA)
          ).to.be.revertedWith("Caller is unauthorized");
          await expect(v3Manager.connect(owner).list(v3PoolCA)).to.not.be
            .reverted;
          expect(await lmPool.actived()).to.be.equal(true);
        });
      });

      describe("Delisting", () => {
        it("Only execute V3 Manager", async () => {
          await v3Manager.connect(owner).list(v3PoolCA);
          await expect(
            lmFactory.connect(owner).delist(v3PoolCA)
          ).to.be.revertedWith("Caller is unauthorized");
          await expect(v3Manager.connect(owner).delist(v3PoolCA)).to.not.be
            .reverted;
          expect(await lmPool.actived()).to.be.equal(false);
        });

        it("Other pools should share the allocation of the delisted pool", async () => {
            const poolList: any[] = [];
            for (let i = 0; i < 100; i++) {
                const NewToken = await ethers.getContractFactory('ERC20');
                const newToken = await NewToken.deploy(`TOKEN ${i}`, `T${i}`);
                const tokenCA = await newToken.getAddress();

                await v3Manager.connect(owner).createPool(await unx.getAddress(), tokenCA, ZeroAddress, 3000);
                const poolCA = await v3Factory.getPool(await unx.getAddress(), tokenCA, 3000);
                poolList.push({v3Pool: poolCA, allocation: 100});
                await v3Manager.connect(owner).list(poolCA);
            }

            await v3Manager.connect(owner).allocate(poolList);
            await v3Manager.connect(owner).delist(poolList[0].v3Pool);

            for (let i = 1; i < 100; i++) {
                expect(await lmFactory.allocationOf(await lmFactory.lmPools(poolList[i].v3Pool))).to.be.equal(101);
            }

        })
      });

      describe("Reward Protocol", () => {
        it("Case 1: 1 User adds liquidity to a 1 pool once.", async () => {
          const currentBlockNumber = await ethers.provider.getBlockNumber();
          const currentBlock = await ethers.provider.getBlock(
            currentBlockNumber
          );
          const now = currentBlock?.timestamp || 0;
          const deadline = now + 3000;

          await unx.transfer(user.address, parseEther("200"));
          await unx
            .connect(user)
            .approve(await nfpManager.getAddress(), parseEther("200"));

          if (genesisBlock > currentBlockNumber) {
            await mine(genesisBlock - currentBlockNumber);
          }

          await v3Pool.initialize(encodePriceSqrt(BigInt(1), BigInt(1)));
          await v3Manager.connect(owner).list(v3PoolCA);
          await v3Manager.connect(owner).allocate([
            {
              v3Pool: v3PoolCA,
              allocation: 10000,
            },
          ]);

          const addLiq = await nfpManager.connect(user).mint(
            {
              token0: tokenA,
              token1: tokenB,
              tickLower: getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
              tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
              amount0Desired: parseEther("100"),
              amount1Desired: parseEther("100"),
              amount0Min: 0,
              amount1Min: 0,
              recipient: user.address,
              deadline: deadline,
              fee: 3000,
            },
            {
              value: parseEther("100"),
            }
          );

          await mine(10);

          const startBlock = addLiq.blockNumber || 0;
          const bfBalance = await unx.balanceOf(user.address);

          const harvest = await nfpManager.connect(user).harvest({v3Pool: v3PoolCA, tokenId: 1});
          const afBalance = await unx.balanceOf(user.address);

          const endBlock = harvest.blockNumber || 0;
          const duration = endBlock - startBlock;
          const expectedValue = fixedBigInt(
            BigInt(duration) * (await lmPool.currentRewardPerBlock())
          );
          const reward = afBalance - bfBalance;

          expect(reward).to.be.equal(expectedValue);
        });

        it("Case 2: 2 Users add liquidity 1 LM Pool", async () => {
          const currentBlockNumber = await ethers.provider.getBlockNumber();
          const currentBlock = await ethers.provider.getBlock(
            currentBlockNumber
          );
          const now = currentBlock?.timestamp || 0;
          const deadline = now + 3000;

          if (genesisBlock > currentBlockNumber) {
            await mine(genesisBlock - currentBlockNumber);
          }

          await v3Pool.initialize(encodePriceSqrt(BigInt(1), BigInt(1)));
          await v3Manager.connect(owner).list(v3PoolCA);
          await v3Manager.connect(owner).allocate([
            {
              v3Pool: v3PoolCA,
              allocation: 10000,
            },
          ]);

          await unx.transfer(user.address, parseEther("200"));
          await unx
            .connect(user)
            .approve(await nfpManager.getAddress(), parseEther("200"));
          const userAddLiq = await nfpManager.connect(user).mint(
            {
              token0: tokenA,
              token1: tokenB,
              tickLower: getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
              tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
              amount0Desired: parseEther("100"),
              amount1Desired: parseEther("100"),
              amount0Min: 0,
              amount1Min: 0,
              recipient: user.address,
              deadline: deadline,
              fee: 3000,
            },
            {
              value: parseEther("100"),
            }
          );

          await mine(10);

          await unx.transfer(other.address, parseEther("200"));
          await unx
            .connect(other)
            .approve(await nfpManager.getAddress(), parseEther("200"));
          const otherAddLiq = await nfpManager.connect(other).mint(
            {
              token0: tokenA,
              token1: tokenB,
              tickLower: getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
              tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
              amount0Desired: parseEther("100"),
              amount1Desired: parseEther("100"),
              amount0Min: 0,
              amount1Min: 0,
              recipient: other.address,
              deadline: deadline,
              fee: 3000,
            },
            {
              value: parseEther("100"),
            }
          );

          await mine(10);

          const userReward = (
            await nfpManager.connect(user).harvest.staticCallResult({v3Pool: v3PoolCA, tokenId: 1})
          )[0];
          const otherReward = (
            await nfpManager.connect(other).harvest.staticCallResult({v3Pool: v3PoolCA, tokenId: 2})
          )[0];

          const userStartBlock = userAddLiq.blockNumber || 0;
          const otherStartBlock = otherAddLiq.blockNumber || 0;
          const endBlock = otherStartBlock + 10;

          const userExpectedValue =
            fixedBigInt(
              BigInt(otherStartBlock - userStartBlock) *
                (await lmPool.currentRewardPerBlock())
            ) +
            fixedBigInt(
              BigInt(endBlock - otherStartBlock) *
                ((await lmPool.currentRewardPerBlock()) / BigInt(2))
            );
          const otherExpectedValue = fixedBigInt(
            BigInt(endBlock - otherStartBlock) *
              ((await lmPool.currentRewardPerBlock()) / BigInt(2))
          );
          // const totalExpectedValue = fixedBigInt(BigInt(endBlock - userStartBlock) * await lmPool.currentRewardPerBlock());

          expect(userReward).to.be.equal(userExpectedValue);
          expect(otherReward).to.be.equal(otherExpectedValue);
          // expect(userReward + otherReward).to.be.equal(totalExpectedValue);
        });

        it("Case 3: Should be not accumulate when LM Pool inactive", async () => {
          const currentBlockNumber = await ethers.provider.getBlockNumber();
          const currentBlock = await ethers.provider.getBlock(
            currentBlockNumber
          );
          const now = currentBlock?.timestamp || 0;
          const deadline = now + 3000;

          if (genesisBlock > currentBlockNumber) {
            await mine(genesisBlock - currentBlockNumber);
          }

          await v3Pool.initialize(encodePriceSqrt(BigInt(1), BigInt(1)));
          await v3Manager.connect(owner).list(v3PoolCA);

          await unx.transfer(user.address, parseEther("200"));
          await unx
            .connect(user)
            .approve(await nfpManager.getAddress(), parseEther("200"));
          const userAddLiq = await nfpManager.connect(user).mint(
            {
              token0: tokenA,
              token1: tokenB,
              tickLower: getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
              tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
              amount0Desired: parseEther("100"),
              amount1Desired: parseEther("100"),
              amount0Min: 0,
              amount1Min: 0,
              recipient: user.address,
              deadline: deadline,
              fee: 3000,
            },
            {
              value: parseEther("100"),
            }
          );

          await mine(10);

          const bfReward = (
            await nfpManager.connect(user).harvest.staticCallResult({v3Pool: v3PoolCA, tokenId: 1})
          )[0];
          expect(bfReward).to.be.equal(0);

          const allocateReward = await v3Manager.connect(owner).allocate([
            {
              v3Pool: v3PoolCA,
              allocation: 10000,
            },
          ]);

          await mine(10);

          const startBlock = allocateReward.blockNumber || 0;
          const endBlock = startBlock + 10;
          const afReward = (
            await nfpManager.connect(user).harvest.staticCallResult({v3Pool: v3PoolCA, tokenId: 1})
          )[0];
          const userExpectedValue = fixedBigInt(
            BigInt(endBlock - startBlock) *
              (await lmPool.currentRewardPerBlock())
          );
          
          expect(afReward).to.be.equal(userExpectedValue);

          // Delist
          const rewardPerBlock = await lmPool.currentRewardPerBlock();
          const inactive = await v3Manager
            .connect(owner)
            .delist(await lmPool.v3Pool());
          const delistBlock = inactive.blockNumber || 0;
          await mine(10);
          const afDelistReward = (
            await nfpManager.connect(user).harvest.staticCallResult({v3Pool: v3PoolCA, tokenId: 1})
          )[0];
          const afDelistExpectedValue = fixedBigInt(
            BigInt(delistBlock - startBlock) * rewardPerBlock
          );

          
          expect(afDelistReward).to.be.equal(afDelistExpectedValue);

          // Re-list
          await v3Manager.connect(owner).list(v3PoolCA);
          const reAllocateReward = await v3Manager.connect(owner).allocate([
            {
              v3Pool: v3PoolCA,
              allocation: 10000,
            },
          ]);

          await mine(10);

          const reListBlock = reAllocateReward.blockNumber || 0;
          const lastBlock = reListBlock + 10;
          const fianlReward = (
            await nfpManager.connect(user).harvest.staticCallResult({v3Pool: v3PoolCA, tokenId: 1})
          )[0];
          const finalExpectedValue = fixedBigInt(
            BigInt(lastBlock - reListBlock + 1) *
              (await lmPool.currentRewardPerBlock())
          ) + fixedBigInt(
            BigInt(endBlock - startBlock) *
              (await lmPool.currentRewardPerBlock())
          );

          expect(fianlReward).to.be.equal(finalExpectedValue);

        });

        it("Case 4: Should be not accumulate when out of tick range", async () => {
          await unx
            .connect(owner)
            .approve(await nfpManager.getAddress(), parseEther("500"));
          await initAddLiquidity(
            { _token: unx, _decimal: 18, _amount: parseEther("500") },
            { _token: wETH9, _decimal: 18, _amount: parseEther("100") }
          );

          const network = await ethers.getDefaultProvider().getNetwork();
          const baseToken = new Token(
            Number(network.chainId),
            wETH9.address,
            18
          ) as Currency;
          const quoteToken = new Token(
            Number(network.chainId),
            unx.address,
            18
          ) as Currency;

          const currentBlockNumber = await ethers.provider.getBlockNumber();

          await unx.transfer(user.address, parseEther("1000"));
          await unx
            .connect(user)
            .approve(await nfpManager.getAddress(), parseEther("1000"));

          if (genesisBlock > currentBlockNumber) {
            await mine(genesisBlock - currentBlockNumber);
          }

          const { sqrtRatioX96, tick } = getTick(
            { baseToken, quoteToken },
            "5",
            FeeAmount.MEDIUM
          );

          console.log("sqrtRatioX96: ", sqrtRatioX96, tick);

          const _leftRangeValue = (5 * 90 / 100).toString(); // 90%
          const _rightRangeValue =  (5 * 110 / 100).toString(); // 110%

          const lowPrice = tryParsePrice(baseToken, quoteToken, _rightRangeValue);
          const highPrice = tryParsePrice(baseToken, quoteToken, _leftRangeValue);
          if (!lowPrice || !highPrice) throw new Error('fail get price');

          let lowTick = tryParseTick(baseToken, quoteToken, FeeAmount.MEDIUM, lowPrice.toSignificant(8)) || 0;
          let highTick = tryParseTick(baseToken, quoteToken, FeeAmount.MEDIUM, highPrice.toSignificant(8)) || 0;

          await addLiquidity(
            { currency: baseToken, amount: parseEther("0.895559435335869704") },
            { currency: quoteToken, amount: parseEther("4.895100000000000000") },
            {
              tickLower: lowTick,
              tickUpper: highTick,
              feeAmount: FeeAmount.MEDIUM,
              currentSqrt: sqrtRatioX96,
            },
            user
          );
          // await v3Pool.initialize(encodePriceSqrt(BigInt(1), BigInt(1)));
          await v3Manager.connect(owner).list(v3PoolCA);
          await v3Manager.connect(owner).allocate([
            {
              v3Pool: v3PoolCA,
              allocation: 10000,
            },
          ]);

          await mine(10);

          let path = encodePath([tokenA, tokenB], [FeeAmount.MEDIUM]);
          let inputAmount = parseEther("200");
          let outputAmount = await xQuoterV2.quoteExactInput.staticCall(
            path,
            inputAmount
          );

          console.log(
            "Before swap 1: ",
            formatEther((await nfpManager
                .connect(user)
                .harvest.staticCallResult({v3Pool: v3PoolCA, tokenId: tokenId}))[0].toString())
          );          
          console.log("bf UNX", formatEther(await unx.balanceOf(user.address)));
          console.log("bf wETH: ", formatEther(await wETH9.balanceOf(user.address)));
          
          await unx
            .connect(user)
            .approve(await xRouter.getAddress(), parseEther("200"));
          await xRouter.connect(user).exactInput({
            path,
            recipient: user.address,
            deadline,
            amountIn: inputAmount,
            amountOutMinimum: outputAmount.amountOut,
          });

          console.log("af UNX", formatEther(await unx.balanceOf(user.address)));
          console.log("af wETH: ", formatEther(await wETH9.balanceOf(user.address)));

          console.log(
            "after swap 1: ",
            formatEther((await nfpManager
              .connect(user)
              .harvest.staticCallResult({v3Pool: v3PoolCA, tokenId: tokenId}))[0].toString())
          );

          await mine(10);

          console.log(
            "after swap 2: ",
            formatEther((await nfpManager
              .connect(user)
              .harvest.staticCallResult({v3Pool: v3PoolCA, tokenId: tokenId}))[0].toString())
          );

          path = encodePath([tokenB, tokenA], [FeeAmount.MEDIUM]);
          inputAmount = parseEther("28.922626175148534256");
          outputAmount = await xQuoterV2.quoteExactInput.staticCall(
            path,
            inputAmount
          );

          await xRouter.connect(user).exactInput({
            path,
            recipient: user.address,
            deadline,
            amountIn: inputAmount,
            amountOutMinimum: outputAmount.amountOut,
          }, { value: parseEther("28.922626175148534256")});

          await mine(10);

          console.log(
            "after swap 3: ",
            formatEther((await nfpManager
              .connect(user)
              .harvest.staticCallResult({v3Pool: v3PoolCA, tokenId: tokenId}))[0].toString())
          );

        });

        it("Case 5: Should be decrease reward per block with each halving", async () => {
          const currentBlockNumber = await ethers.provider.getBlockNumber();
          const currentBlock = await ethers.provider.getBlock(
            currentBlockNumber
          );
          const now = currentBlock?.timestamp || 0;
          const deadline = now + 3000;

          await unx.transfer(user.address, parseEther("200"));
          await unx
            .connect(user)
            .approve(await nfpManager.getAddress(), parseEther("200"));

          if (genesisBlock > currentBlockNumber) {
            await mine(genesisBlock - currentBlockNumber);
          }

          await v3Pool.initialize(encodePriceSqrt(BigInt(1), BigInt(1)));
          await v3Manager.connect(owner).list(v3PoolCA);
          await v3Manager.connect(owner).allocate([
            {
              v3Pool: v3PoolCA,
              allocation: 10000,
            },
          ]);

          const addLiq = await nfpManager.connect(user).mint(
            {
              token0: tokenA,
              token1: tokenB,
              tickLower: getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
              tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
              amount0Desired: parseEther("100"),
              amount1Desired: parseEther("100"),
              amount0Min: 0,
              amount1Min: 0,
              recipient: user.address,
              deadline: deadline,
              fee: 3000,
            },
            {
              value: parseEther("100"),
            }
          );

          const halvingBlocks = await halving.halvingBlocks();
          const startBlock = addLiq.blockNumber || 0;

          let expectedValue: bigint = BigInt(0);
          let i = 0;
          for await (const halvingBlock of halvingBlocks) {
            const targetBlock = Number(halvingBlock);
            console.log("target:", targetBlock);
            const preHalvingBlock =
              i > 0 ? Number(halvingBlocks[i - 1]) : startBlock;
            console.log("start:", preHalvingBlock);
            const minedBlocks =
              i > 0
                ? targetBlock - preHalvingBlock
                : targetBlock - preHalvingBlock + 1;
            console.log("mined:", minedBlocks);
            await mine(minedBlocks);

            const userReward = (
              await nfpManager.connect(user).harvest.staticCallResult({v3Pool: v3PoolCA, tokenId: 1})
            )[0];
            const period =
              i > 0
                ? targetBlock - preHalvingBlock - 1
                : targetBlock - preHalvingBlock;

            expectedValue += fixedBigInt(
              BigInt(period) * (await lmPool.rewardPerBlockOf(i))
            );

            console.log(
              `${i + 1} halving\n${formatEther(userReward)} : ${formatEther(
                expectedValue
              )}`
            );
            i++;
          }
        });

        it("Case 6: Should be update reward per block when update allocation", async () => {
            const currentBlockNumber = await ethers.provider.getBlockNumber();
            const currentBlock = await ethers.provider.getBlock(
              currentBlockNumber
            );
            const now = currentBlock?.timestamp || 0;
            const deadline = now + 3000;
  
            await unx.transfer(user.address, parseEther("200"));
            await unx
              .connect(user)
              .approve(await nfpManager.getAddress(), parseEther("200"));
  
            if (genesisBlock > currentBlockNumber) {
              await mine(genesisBlock - currentBlockNumber);
            }
  
            await v3Pool.initialize(encodePriceSqrt(BigInt(1), BigInt(1)));
            await v3Manager.connect(owner).list(v3PoolCA);
            await v3Manager.connect(owner).allocate([
              {
                v3Pool: v3PoolCA,
                allocation: 10000,
              },
            ]);
  
            const addLiq = await nfpManager.connect(user).mint(
              {
                token0: tokenA,
                token1: tokenB,
                tickLower: getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
                tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
                amount0Desired: parseEther("100"),
                amount1Desired: parseEther("100"),
                amount0Min: 0,
                amount1Min: 0,
                recipient: user.address,
                deadline: deadline,
                fee: 3000,
              },
              {
                value: parseEther("100"),
              }
            );
  
            await mine(10);
  
            const harvest = await nfpManager.connect(user).harvest.staticCallResult({v3Pool: v3PoolCA, tokenId: 1});

            const startBlock = addLiq.blockNumber || 0;
            const endBlock = startBlock + 10;
            const duration = endBlock - startBlock;
            const expectedValue = fixedBigInt(
              BigInt(duration) * (await lmPool.currentRewardPerBlock())
            );
  
            expect(harvest[0]).to.be.equal(expectedValue);

            const preAlloc = await lmPool.currentRewardPerBlock();
            const modifyAlloc = await v3Manager.connect(owner).allocate([
                {
                  v3Pool: v3PoolCA,
                  allocation: 1000,
                },
            ]);

            await mine(10);

            const afHarvest = await nfpManager.connect(user).harvest.staticCallResult({v3Pool: v3PoolCA, tokenId: 1});

            const afStartBlock = modifyAlloc.blockNumber || 0;
            const afEndBlock = afStartBlock + 10;
            const afDuration = afEndBlock - afStartBlock;
            const afExpectedValue = fixedBigInt(BigInt(duration + 1) * preAlloc)
                + fixedBigInt(BigInt(afDuration) * (await lmPool.currentRewardPerBlock()));
  
            expect(afHarvest[0]).to.be.equal(afExpectedValue);
        });

      });
    });
  });
  

  describe("Integration Test", () => {
    const sqrtPriceX96 = encodePriceSqrt(BigInt(1), BigInt(1));
    let token0: any, token1: any;
    let token0Amount: bigint = BigInt(0);
    let token1Amount: bigint = BigInt(0);

    describe('Create Pool', () => {
      beforeEach(async () => {
        [token0, token1] = sortedTokens(unx, wETH9);
      });

      describe('Create Pool by Admin/Executor', () => {
        it('Create pool by Admin', async () => {
          await expect(v3Manager.createPool(unx.address, wETH9.address, ZeroAddress, FeeAmount.MEDIUM)).to.be.not.reverted;
        });

        it('Create pool by Executor', async () => {
          await v3Manager.setExecutor(executor.address);
          await expect(v3Manager.connect(executor).createPool(unx.address, wETH9.address, ZeroAddress, FeeAmount.MEDIUM)).to.be.not.reverted;
        });

        it('Should be revert when caller is not Admin or Excutor', async () => {
          await v3Manager.setExecutor(executor.address);
          await expect(v3Manager.connect(other).createPool(unx.address, wETH9.address, ZeroAddress, FeeAmount.MEDIUM)).to.be.revertedWith('Caller is unauthorized')
        });
      });

      describe('Create Pool by User', () => {
        let data: string[] = [];

        beforeEach(async () => {
          await unx.transfer(user.address, parseEther("10000"));
          await unx.connect(user).approve(nfpManager, parseEther("100"));
          token0Amount = parseEther("1");
          token1Amount = parseEther("1");

          const createAndInitializePoolIfNecessary = nfpManager.interface.encodeFunctionData('createAndInitializePoolIfNecessary', [
            token0.address,
            token1.address,
            FeeAmount.MEDIUM,
            sqrtPriceX96
          ]);
          const mint = nfpManager.interface.encodeFunctionData('mint', [
            {
                token0: token0.address,
                token1: token1.address,
                tickLower: getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
                tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
                fee: FeeAmount.MEDIUM,
                recipient: user.address,
                amount0Desired: token0Amount,
                amount1Desired: token1Amount,
                amount0Min: 0,
                amount1Min: 0,
                deadline
            },
          ]);

          const refundETH = nfpManager.interface.encodeFunctionData('refundETH');

          data = [createAndInitializePoolIfNecessary, mint, refundETH];
        });

        it('Create pool by multicall', async () => {
          await v3Manager.setDeployable(true);
          await expect(nfpManager.connect(user).multicall(data, { value: parseEther('1') })).to.be.not.reverted;
        });

        it('Create pool by multicall with deployment fee', async () => {
          await v3Manager.setDeployable(true);
          await v3Manager.setDeployFeeToken(unx.address);
          await v3Manager.setDeployFeeCollector(owner.address);
          await v3Manager.setDeployFee(parseEther('100'));
          await unx.connect(user).approve(await v3Manager.getAddress(), parseEther('100'));

          await expect(nfpManager.connect(user).multicall(data, { value: parseEther('1') })).to.be.not.reverted;
        });

        it('Should be revert when not deployable', async () => {
          await expect(nfpManager.connect(user).multicall(data, { value: parseEther('1') })).to.be.revertedWith('Caller is unauthorized');
        });

        it('Should be revert when insufficient deploy fee', async () => {
          await v3Manager.setDeployable(true);
          await v3Manager.setDeployFeeToken(unx.address);
          await v3Manager.setDeployFeeCollector(owner.address);
          await v3Manager.setDeployFee(parseEther('100000'));

          await expect(nfpManager.connect(user).multicall(data, { value: parseEther('1') })).to.be.revertedWith('pay for deployement fee failed');
        });
      });
    });

    describe('BNB/ERC20 Pair', () => {
      let data: string[] = [];
      let v3Pool: string;
      let lmPool: string;
      let createAndInitializePoolIfNecessary: string, mint: string, refundETH: string,
        increaseLiq: string, decreaseLiq: string, collect: string, unwrapWETH9: string, sweepToken: string, harvest: string;

      beforeEach(async () => {
        [token0, token1] = sortedTokens(unx, wETH9);
        await v3Manager.createPool(unx.address, wETH9.address, ZeroAddress, FeeAmount.MEDIUM);
        v3Pool = await v3Factory.getPool(unx.address, wETH9.address, FeeAmount.MEDIUM);
        lmPool = await (await ethers.getContractAt('UNXwapV3Pool', v3Pool)).lmPool();
        await v3Manager.list(v3Pool);
        await v3Manager.allocate([{ v3Pool: v3Pool, allocation: 1000 }]);
        
        await unx.transfer(user.address, parseEther("10000"));
        await unx.connect(user).approve(nfpManager, parseEther("100"));
        token0Amount = parseEther("1");
        token1Amount = parseEther("1");

        createAndInitializePoolIfNecessary = nfpManager.interface.encodeFunctionData('createAndInitializePoolIfNecessary', [
          token0.address,
          token1.address,
          FeeAmount.MEDIUM,
          sqrtPriceX96
        ]);
        mint = nfpManager.interface.encodeFunctionData('mint', [
          {
              token0: token0.address,
              token1: token1.address,
              tickLower: getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
              tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
              fee: FeeAmount.MEDIUM,
              recipient: user.address,
              amount0Desired: token0Amount,
              amount1Desired: token1Amount,
              amount0Min: 0,
              amount1Min: 0,
              deadline
          },
        ]);

        refundETH = nfpManager.interface.encodeFunctionData('refundETH');

        await mine(genesisBlock - await ethers.provider.getBlockNumber());
      });

      it('Add Liquidity with initialization', async () => {
        const bfUNXBalance = await unx.balanceOf(user.address);
        const bfBNBBalance = await ethers.provider.getBalance(user.address);

        data = [createAndInitializePoolIfNecessary, mint, refundETH];
        const tx = await nfpManager.connect(user).multicall(data, { value: token1Amount });
        const receipt = await tx.wait();
        const gasFee = receipt?.fee || BigInt(0);

        const afUNXBalance = await unx.balanceOf(user.address);
        const afBNBBalance = await ethers.provider.getBalance(user.address);

        expect(bfUNXBalance - afUNXBalance).to.be.equal(token0Amount);
        expect(bfBNBBalance - afBNBBalance - gasFee).to.be.equal(token1Amount);
      });

      it('Add Liquidity', async () => {
        const bfUNXBalance = await unx.balanceOf(user.address);
        const bfBNBBalance = await ethers.provider.getBalance(user.address);

        data = [createAndInitializePoolIfNecessary, mint, refundETH];
        const tx1 = await nfpManager.connect(user).multicall(data, { value: token1Amount });
        const receipt1 = await tx1.wait();
        const gasFee1 = receipt1?.fee || BigInt(0);

        data = [mint, refundETH];
        const tx2 = await nfpManager.connect(user).multicall(data, { value: token1Amount });
        const receipt2 = await tx2.wait();
        const gasFee2 = receipt2?.fee || BigInt(0);

        const afUNXBalance = await unx.balanceOf(user.address);
        const afBNBBalance = await ethers.provider.getBalance(user.address);

        expect(bfUNXBalance - afUNXBalance).to.be.equal(token0Amount * BigInt(2));
        expect(bfBNBBalance - afBNBBalance - gasFee1 - gasFee2).to.be.equal(token1Amount * BigInt(2));
      });

      it('Increase Liquidity', async () => {
        const bfUNXBalance = await unx.balanceOf(user.address);
        const bfBNBBalance = await ethers.provider.getBalance(user.address);

        data = [createAndInitializePoolIfNecessary, mint, refundETH];
        const tx1 = await nfpManager.connect(user).multicall(data, { value: token1Amount });
        const receipt1 = await tx1.wait();
        const gasFee1 = receipt1?.fee || BigInt(0);

        // Increase
        increaseLiq = nfpManager.interface.encodeFunctionData('increaseLiquidity', [{
          tokenId: 1,
          amount0Desired: token0Amount,
          amount1Desired: token1Amount,
          amount0Min: 0,
          amount1Min: 0,
          deadline ,
        }]);

        data = [increaseLiq, refundETH];
        const tx2 = await nfpManager.connect(user).multicall(data, { value: token1Amount });
        const receipt2 = await tx2.wait();
        const gasFee2 = receipt2?.fee || BigInt(0);

        const afUNXBalance = await unx.balanceOf(user.address);
        const afBNBBalance = await ethers.provider.getBalance(user.address);

        expect(bfUNXBalance - afUNXBalance).to.be.equal(token0Amount * BigInt(2));
        expect(bfBNBBalance - afBNBBalance - gasFee1 - gasFee2).to.be.equal(token1Amount * BigInt(2));
      });

      it('Decrease Liquidity', async () => {
        const bfUNXBalance = await unx.balanceOf(user.address);
        const bfBNBBalance = await ethers.provider.getBalance(user.address);

        data = [createAndInitializePoolIfNecessary, mint, refundETH];
        const tx1 = await nfpManager.connect(user).multicall(data, { value: token1Amount });
        const receipt1 = await tx1.wait();
        const gasFee1 = receipt1?.fee || BigInt(0);

        // Decrease
        const { liquidity } = await nfpManager.positions(1);
        const subLiq = liquidity / BigInt(2);
        decreaseLiq = nfpManager.interface.encodeFunctionData('decreaseLiquidity', [{
          tokenId: 1,
          liquidity: subLiq,
          amount0Min: 0,
          amount1Min: 0,
          deadline,
        }]);

        // collect
        const uint128Max = BigInt(2 ** 64 - 1);
        collect = nfpManager.interface.encodeFunctionData('collect', [{
          tokenId: 1,
          recipient: await nfpManager.getAddress(),
          amount0Max: uint128Max,
          amount1Max: uint128Max,
        }]);
        
        harvest = nfpManager.interface.encodeFunctionData('harvest', [{ v3Pool: v3Pool, tokenId: 1 }]);
        unwrapWETH9 = nfpManager.interface.encodeFunctionData('unwrapWETH9', [0, user.address]);
        sweepToken = nfpManager.interface.encodeFunctionData('sweepToken', [unx.address, 0, user.address])

        const reward = fixedBigInt(await (await ethers.getContractAt('UNXwapV3LmPool', lmPool)).currentRewardPerBlock());
        const refund = await nfpManager.connect(user).decreaseLiquidity.staticCall({
          tokenId: 1,
          liquidity: subLiq,
          amount0Min: 0,
          amount1Min: 0,
          deadline,
        });

        data = [harvest, decreaseLiq, collect, unwrapWETH9, sweepToken];
        const tx2 = await nfpManager.connect(user).multicall(data);
        const receipt2 = await tx2.wait();
        const gasFee2 = receipt2?.fee || BigInt(0);

        const afUNXBalance = await unx.balanceOf(user.address);
        const afBNBBalance = await ethers.provider.getBalance(user.address);

        expect(afUNXBalance).to.be.equal(bfUNXBalance - token0Amount + refund.amount0 + reward);
        expect(afBNBBalance).to.be.equal(bfBNBBalance - token1Amount - gasFee1 - gasFee2 + refund.amount1);
      });

    });

    
    describe('ERC20/ERC20 Pair', () => {
      let data: string[] = [];
      let v3Pool: string;
      let lmPool: string;
      let createAndInitializePoolIfNecessary: string, mint: string, increaseLiq: string, decreaseLiq: string, collect: string, harvest: string;

      beforeEach(async () => {
        [token0, token1] = sortedTokens(unx, sampleERC20);
        await v3Manager.createPool(unx.address, sampleERC20.address, ZeroAddress, FeeAmount.MEDIUM);
        v3Pool = await v3Factory.getPool(unx.address, sampleERC20.address, FeeAmount.MEDIUM);
        lmPool = await (await ethers.getContractAt('UNXwapV3Pool', v3Pool)).lmPool();
        await v3Manager.list(v3Pool);
        await v3Manager.allocate([{ v3Pool: v3Pool, allocation: 1000 }]);
        
        await unx.transfer(user.address, parseEther("10000"));
        await unx.connect(user).approve(nfpManager, parseEther("100"));
        await sampleERC20.transfer(user.address, parseEther("10000"));
        await sampleERC20.connect(user).approve(nfpManager, parseEther("100"));
        token0Amount = parseEther("1");
        token1Amount = parseEther("1");

        createAndInitializePoolIfNecessary = nfpManager.interface.encodeFunctionData('createAndInitializePoolIfNecessary', [
          token0.address,
          token1.address,
          FeeAmount.MEDIUM,
          sqrtPriceX96
        ]);
        mint = nfpManager.interface.encodeFunctionData('mint', [
          {
              token0: token0.address,
              token1: token1.address,
              tickLower: getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
              tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
              fee: FeeAmount.MEDIUM,
              recipient: user.address,
              amount0Desired: token0Amount,
              amount1Desired: token1Amount,
              amount0Min: 0,
              amount1Min: 0,
              deadline
          },
        ]);

        await mine(genesisBlock - await ethers.provider.getBlockNumber());
      });

      it('Add Liquidity with initialization', async () => {
        const bfUNXBalance = await unx.balanceOf(user.address);
        const bfOtherBalance = await sampleERC20.balanceOf(user.address);

        data = [createAndInitializePoolIfNecessary, mint];
        await nfpManager.connect(user).multicall(data, { value: token1Amount });

        const afUNXBalance = await unx.balanceOf(user.address);
        const afOtherBalance = await sampleERC20.balanceOf(user.address);

        expect(bfUNXBalance - afUNXBalance).to.be.equal(token0Amount);
        expect(bfOtherBalance - afOtherBalance).to.be.equal(token1Amount);
      });

      it('Add Liquidity', async () => {
        const bfUNXBalance = await unx.balanceOf(user.address);
        const bfOtherBalance = await sampleERC20.balanceOf(user.address);

        data = [createAndInitializePoolIfNecessary, mint];
        await nfpManager.connect(user).multicall(data, { value: token1Amount });

        await nfpManager.connect(user).mint({
          token0: token0.address,
          token1: token1.address,
          tickLower: getMinTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
          tickUpper: getMaxTick(TICK_SPACINGS[FeeAmount.MEDIUM]),
          fee: FeeAmount.MEDIUM,
          recipient: user.address,
          amount0Desired: token0Amount,
          amount1Desired: token1Amount,
          amount0Min: 0,
          amount1Min: 0,
          deadline
        },
        {
          value: token1Amount 
        });

        const afUNXBalance = await unx.balanceOf(user.address);
        const afOtherBalance = await sampleERC20.balanceOf(user.address);

        expect(bfUNXBalance - afUNXBalance).to.be.equal(token0Amount * BigInt(2));
        expect(bfOtherBalance - afOtherBalance).to.be.equal(token1Amount * BigInt(2));
      });

      it('Increase Liquidity', async () => {
        const bfUNXBalance = await unx.balanceOf(user.address);
        const bfOtherBalance = await sampleERC20.balanceOf(user.address);

        data = [createAndInitializePoolIfNecessary, mint];
        await nfpManager.connect(user).multicall(data, { value: token1Amount });

        // Increase
        await nfpManager.connect(user).increaseLiquidity({
          tokenId: 1,
          amount0Desired: token0Amount,
          amount1Desired: token1Amount,
          amount0Min: 0,
          amount1Min: 0,
          deadline ,
        },
        {
          value: token1Amount
        });

        const afUNXBalance = await unx.balanceOf(user.address);
        const afOtherBalance = await sampleERC20.balanceOf(user.address);

        expect(bfUNXBalance - afUNXBalance).to.be.equal(token0Amount * BigInt(2));
        expect(bfOtherBalance - afOtherBalance).to.be.equal(token1Amount * BigInt(2));
      });

      it('Decrease Liquidity', async () => {
        const bfUNXBalance = await unx.balanceOf(user.address);
        const bfOtherBalance = await sampleERC20.balanceOf(user.address);

        data = [createAndInitializePoolIfNecessary, mint];
        await nfpManager.connect(user).multicall(data, { value: token1Amount });

        // Decrease
        const { liquidity } = await nfpManager.positions(1);
        const subLiq = liquidity / BigInt(2);
        decreaseLiq = nfpManager.interface.encodeFunctionData('decreaseLiquidity', [{
          tokenId: 1,
          liquidity: subLiq,
          amount0Min: 0,
          amount1Min: 0,
          deadline,
        }]);

        // collect
        const uint128Max = BigInt(2 ** 64 - 1);
        collect = nfpManager.interface.encodeFunctionData('collect', [{
          tokenId: 1,
          recipient: user.address,
          amount0Max: uint128Max,
          amount1Max: uint128Max,
        }]);
        
        harvest = nfpManager.interface.encodeFunctionData('harvest', [{ v3Pool: v3Pool, tokenId: 1 }]);

        const reward = fixedBigInt(await (await ethers.getContractAt('UNXwapV3LmPool', lmPool)).currentRewardPerBlock());
        const refund = await nfpManager.connect(user).decreaseLiquidity.staticCall({
          tokenId: 1,
          liquidity: subLiq,
          amount0Min: 0,
          amount1Min: 0,
          deadline,
        });

        data = [harvest, decreaseLiq, collect];
        await nfpManager.connect(user).multicall(data);

        const afUNXBalance = await unx.balanceOf(user.address);
        const afOtherBalance = await sampleERC20.balanceOf(user.address);

        expect(afUNXBalance).to.be.equal(bfUNXBalance - token0Amount + refund.amount0 + reward);
        expect(afOtherBalance).to.be.equal(bfOtherBalance - token1Amount + refund.amount1);
      });

    });
    

  });

});

function fixedBigInt(value: bigint): bigint {
  return (value / BigInt(1e12)) * BigInt(1e12);
}

function isAscii(str: string): boolean {
  // eslint-disable-next-line no-control-regex
  return /^[\x00-\x7F]*$/.test(str);
}

function asciiStringToBytes32(str: string): string {
  if (str.length > 32 || !isAscii(str)) {
    throw new Error("Invalid label, must be less than 32 characters");
  }

  return "0x" + Buffer.from(str, "ascii").toString("hex").padEnd(64, "0");
}

function computePoolAddress(
  factoryAddress: string,
  [tokenA, tokenB]: [string, string],
  fee: number
): string {
  const {
    bytecode,
  } = require("../artifacts/contracts/core/UNXwapV3Pool.sol/UNXwapV3Pool.json");
  const POOL_BYTECODE_HASH = ethers.keccak256(bytecode);
  // console.log('POOL_BYTECODE_HASH: ', POOL_BYTECODE_HASH);

  const [token0, token1] =
    tokenA.toLowerCase() < tokenB.toLowerCase()
      ? [tokenA, tokenB]
      : [tokenB, tokenA];
  const constructorArgumentsEncoded = new ethers.AbiCoder().encode(
    ["address", "address", "uint24"],
    [token0, token1, fee]
  );
  const create2Inputs = [
    "0xff",
    factoryAddress,
    // salt
    ethers.keccak256(constructorArgumentsEncoded),
    // init code hash
    POOL_BYTECODE_HASH,
  ];
  const sanitizedInputs = `0x${create2Inputs.map((i) => i.slice(2)).join("")}`;
  return ethers.getAddress(`0x${ethers.keccak256(sanitizedInputs).slice(-40)}`);
}

function tryParseTick(
  baseToken?: Currency,
  quoteToken?: Currency,
  feeAmount?: FeeAmount,
  value?: string
): number | undefined {
  if (!baseToken || !quoteToken || !feeAmount || !value) {
    return undefined;
  }

  const price = tryParsePrice(baseToken, quoteToken, value);

  if (!price) {
    return undefined;
  }

  let tick: number;

  // check price is within min/max bounds, if outside return min/max
  const sqrtRatioX96 = encodeSqrtRatioX96(price.numerator, price.denominator);

  if (JSBI.greaterThanOrEqual(sqrtRatioX96, TickMath.MAX_SQRT_RATIO)) {
    tick = TickMath.MAX_TICK;
  } else if (JSBI.lessThanOrEqual(sqrtRatioX96, TickMath.MIN_SQRT_RATIO)) {
    tick = TickMath.MIN_TICK;
  } else {
    // this function is agnostic to the base, will always return the correct tick
    // @ts-ignore
    tick = priceToClosestTick(price);
  }

  return nearestUsableTick(tick, TICK_SPACINGS[feeAmount]);
}

function tryParsePrice(
  baseToken?: Currency,
  quoteToken?: Currency,
  value?: string
) {
  if (!baseToken || !quoteToken || !value) {
    return undefined;
  }

  if (!value.match(/^\d*\.?\d+$/)) {
    return undefined;
  }

  const [whole, fraction] = value.split(".");

  const decimals = fraction?.length ?? 0;
  const withoutDecimals = JSBI.BigInt((whole ?? "") + (fraction ?? ""));

  return new Price(
    baseToken,
    quoteToken,
    JSBI.multiply(
      JSBI.BigInt(10 ** decimals),
      JSBI.BigInt(10 ** baseToken.decimals)
    ),
    JSBI.multiply(withoutDecimals, JSBI.BigInt(10 ** quoteToken.decimals))
  );
}

function encodePriceSqrt(reserve1: bigint, reserve0: bigint) {
  // 소수 제곱근을 계산하기 위해 float으로 계산하고 다시 bigint로 변환
  const priceRatio = Number(reserve1) / Number(reserve0);
  const sqrtPrice = Math.sqrt(priceRatio);
  const fixedPointAdjustment = 2n ** 96n;

  // 소수를 고정 소수점 수로 변환하여 bigint 처리
  return BigInt(Math.floor(sqrtPrice * Number(fixedPointAdjustment)));
}

export function encodePath(path: string[], fees: FeeAmount[]): string {
  const FEE_SIZE = 3;
  if (path.length !== fees.length + 1) {
    throw new Error("path/fee lengths do not match");
  }

  let encoded = "0x";
  for (let i = 0; i < fees.length; i++) {
    // 20 byte encoding of the address
    encoded += path[i].slice(2);
    // 3 byte encoding of the fee
    encoded += fees[i].toString(16).padStart(2 * FEE_SIZE, "0");
  }
  // encode the final token
  encoded += path[path.length - 1].slice(2);

  return encoded.toLowerCase();
}

function compareToken(a: { address: string }, b: { address: string }): -1 | 1 {
  return a.address.toLowerCase() < b.address.toLowerCase() ? -1 : 1;
}

function sortedTokens(
  a: { address: string },
  b: { address: string }
): [typeof a, typeof b] | [typeof b, typeof a] {
  return compareToken(a, b) < 0 ? [a, b] : [b, a];
}

const _initAddLiquidity = async (
  _token0: { _token: _UNXToken | _WETH9; _decimal: number; _amount: bigint },
  _token1: { _token: _UNXToken | _WETH9; _decimal: number; _amount: bigint },
  _sqrtRatioX96: bigint,
  _tick?: { tickLower: number; tickUpper: number; feeAmount: FeeAmount }
) => {
  let token0Amount: bigint;
  let token1Amount: bigint;
  let value;
  const feeAmount = _tick ? _tick.feeAmount : FeeAmount.MEDIUM;

  const [token0, token1] = sortedTokens(_token0._token, _token1._token);
  const expectedPoolAddress = computePoolAddress(
    await v3Factory.getAddress(),
    [token0.address, token1.address],
    feeAmount
  );

  if (token0.address === _token0._token.address) {
    token0Amount = _token0._amount;
    token1Amount = _token1._amount;
  } else {
    token0Amount = _token1._amount;
    token1Amount = _token0._amount;
  }

  if (token0.address === wETH9.address) {
    value = token0Amount;
  } else if (token1.address === wETH9.address) {
    value = token1Amount;
  }

  const price = (_sqrtRatioX96 / BigInt(2) ** BigInt(96)) ** BigInt(2);
  if (_token0._decimal !== _token1._decimal) {
    const adjPrice =
      _token0._decimal > _token1._decimal
        ? (price * BigInt(10) ** BigInt(_token1._decimal)) /
          BigInt(10) ** BigInt(_token0._decimal)
        : (price * BigInt(10) ** BigInt(_token0._decimal)) /
          BigInt(10) ** BigInt(_token1._decimal);
    console.log("adjPrice: ", adjPrice.toString());
  } else {
    console.log("price: ", price);
  }

  const createAndInitializeData = nfpManager.interface.encodeFunctionData(
    "createAndInitializePoolIfNecessary",
    [token0.address, token1.address, feeAmount, _sqrtRatioX96]
  );

  const mintData = nfpManager.interface.encodeFunctionData("mint", [
    {
      token0: token0.address,
      token1: token1.address,
      tickLower: _tick ? _tick.tickLower : getMinTick(TICK_SPACINGS[feeAmount]),
      tickUpper: _tick ? _tick.tickUpper : getMaxTick(TICK_SPACINGS[feeAmount]),
      fee: feeAmount,
      recipient: owner.address,
      amount0Desired: token0Amount,
      amount1Desired: token1Amount,
      amount0Min: 0,
      amount1Min: 0,
      deadline,
    },
  ]);

  const refundETHData = nfpManager.interface.encodeFunctionData("refundETH");

  await nfpManager
    .connect(owner)
    .multicall([createAndInitializeData, mintData, refundETHData], {
      value,
    });
  tokenId++;

  const {
    fee: _fee,
    token0: tokenZero,
    token1: tokenOne,
    tickLower,
    tickUpper,
    liquidity,
    tokensOwed0,
    tokensOwed1,
    feeGrowthInside0LastX128,
    feeGrowthInside1LastX128,
  } = await nfpManager.positions(tokenId);
  expect(tokenZero).to.equal(token0.address);
  expect(tokenOne).to.equal(token1.address);
  expect(_fee).to.equal(feeAmount);
};

const initAddLiquidity = async (
  _token0: { _token: _UNXToken | _WETH9; _decimal: number; _amount: bigint },
  _token1: { _token: _UNXToken | _WETH9; _decimal: number; _amount: bigint },
  _tick?: { tickLower: number; tickUpper: number; feeAmount: FeeAmount }
) => {
  const [token0, token1] = sortedTokens(_token0._token, _token1._token);

  const sqrtRatioX96 =
    token0.address === _token0._token.address
      ? encodePriceSqrt(_token1._amount, _token0._amount)
      : encodePriceSqrt(_token0._amount, _token1._amount);

  await _initAddLiquidity(
    token0.address === _token0._token.address ? _token0 : _token1,
    token0.address === _token0._token.address ? _token1 : _token0,
    sqrtRatioX96,
    _tick
  );
};

const addLiquidity = async (
  token0: { currency: Currency; amount: bigint },
  token1: { currency: Currency; amount: bigint },
  _tick: {
    tickLower: number;
    tickUpper: number;
    feeAmount: FeeAmount;
    currentSqrt: JSBI;
  },
  signer: HardhatEthersSigner
): Promise<bigint> => {
  let value = "0";
  const txs = [];

  const isSorted: boolean =
    sortedTokens(token0.currency.wrapped, token1.currency.wrapped)[0]
      .address === token0.currency.wrapped.address;

  const [_token0, _token1] = isSorted ? [token0, token1] : [token1, token0];

  if (_token0.currency.wrapped.address === wETH9.address) {
    value = _token0.amount.toString();
  } else if (_token1.currency.wrapped.address === wETH9.address) {
    value = _token1.amount.toString();
  }

  const expectedPoolAddress = computePoolAddress(
    await v3Factory.getAddress(),
    [_token0.currency.wrapped.address, _token1.currency.wrapped.address],
    _tick.feeAmount
  );

  const code = await ethers.provider.getCode(expectedPoolAddress);
  if (code === "0x") {
    const createAndInitializeData = nfpManager.interface.encodeFunctionData(
      "createAndInitializePoolIfNecessary",
      [
        _token0.currency.wrapped.address,
        _token1.currency.wrapped.address,
        _tick.feeAmount,
        _tick.currentSqrt.toString(),
      ]
    );
    txs.push(createAndInitializeData);
  }

  const mintData = nfpManager.interface.encodeFunctionData("mint", [
    {
      token0: _token0.currency.wrapped.address,
      token1: _token1.currency.wrapped.address,
      fee: _tick.feeAmount,
      tickLower: _tick.tickLower,
      tickUpper: _tick.tickUpper,
      amount0Desired: _token0.amount,
      amount1Desired: _token1.amount,
      amount0Min: (_token0.amount * BigInt(999)) / BigInt(1000),
      amount1Min: (_token1.amount * BigInt(999)) / BigInt(1000),
      recipient: signer.address,
      deadline,
    },
  ]);

  txs.push(mintData);

  if (value !== "0") {
    const refundETHData = nfpManager.interface.encodeFunctionData("refundETH");
    txs.push(refundETHData);
  }

  const tx = await nfpManager.connect(signer).multicall(txs, {
    value,
  });
  const receipt = await tx.wait();

  // const used = receipt?.gasUsed.mul(receipt.effectiveGasPrice);
  //
  // const afterCode = await ethers.provider.getCode(expectedPoolAddress);
  // expect(afterCode).to.be.not.equal("0x");
  tokenId++;

  // return used;

  return 0n;
};

const getTick = (
  token: { baseToken: Currency; quoteToken: Currency },
  value: string,
  feeAmount: FeeAmount
) => {
  const price = tryParsePrice(token.baseToken, token.quoteToken, value);
  if (!price) throw new Error("fail get price");
  const tick = tryParseTick(
    token.baseToken,
    token.quoteToken,
    feeAmount,
    price.toSignificant(8)
  );
  if (!tick) throw new Error("fail get tick");
  const sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

  return { sqrtRatioX96, tick };
};
