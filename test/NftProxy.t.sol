// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {NftStakingAndRewarding} from "../src/NftStakingAndRewarding.sol";
import {NftProxy} from "../src/NftProxy.sol";
import {INftProxy} from "../src/INftProxy.sol";
import {mockNft} from "./mockNft.sol";
import {mockErc20} from "./mockErc20.sol";
import "./INft.sol";
import "./IRewardToken.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NftStakingAndRewardingTest is Test {
    NftStakingAndRewarding public implementation;
    NftProxy public nftProxy;
    INftProxy public nftProxytest;
    mockNft public mockNftTest;
    mockErc20 public mockErc20Test;
    IRewardToken public rewardToken;
    INft public mockErc721Test;
    address public user1;

    function setUp() public {
        implementation = new NftStakingAndRewarding();
        nftProxy = new NftProxy(address(implementation), "");
        nftProxytest = INftProxy(address(nftProxy));
        mockNftTest = new mockNft();
        mockErc721Test = INft(address(mockNftTest));
        mockErc20Test = new mockErc20();
        rewardToken = IRewardToken(address(mockErc20Test));
        rewardToken.mint(
            address(nftProxytest),
            10000000000000000000000000000000000000000
        );

        nftProxytest.initialize(
            mockNftTest,
            mockErc20Test,
            1,
            4,
            1,
            vm.addr(1)
        );
    }

    function test_Increment() public {
        address impl = nftProxytest.getImplementation();
        assertEq(impl, address(implementation));
    }

    function test_StakeNFT() public returns (uint256[] memory tokenIds) {
        uint256 tokenId = 1;
        mockErc721Test.safeMint(vm.addr(2), tokenId);
        vm.prank(vm.addr(2));
        mockErc721Test.approve(address(nftProxytest), tokenId);

        tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        vm.prank(vm.addr(2));

        nftProxytest.stakeNfts(tokenIds);

        INftProxy.NFTStaking memory x = nftProxytest.nftStakes(
            vm.addr(2),
            tokenId
        );
        console.log(x.stakedAt, "x.stakedAt");

        assertEq(x.stakedAt, block.number);
        assertEq(x.unbondedAt, 0);
    }

    function test_UnstakeNFT() public returns (uint256[] memory tokenIds) {
        tokenIds = test_StakeNFT();
        vm.prank(vm.addr(2));
        nftProxytest.unstakeNfts(tokenIds);

        INftProxy.NFTStaking memory x = nftProxytest.nftStakes(
            vm.addr(2),
            tokenIds[0]
        );
        assertEq(x.unbondedAt, block.number);
    }

    function test_WithdrawNFT() public {
        uint256[] memory tokenIds = test_UnstakeNFT();

        vm.roll(block.number + 2);
        vm.prank(vm.addr(2));
        nftProxytest.withdrawNfts(tokenIds);

        assertEq(mockErc721Test.ownerOf(tokenIds[0]), vm.addr(2));
    }

    function test_ClaimRewards() public {
        uint256[] memory tokenIds = test_StakeNFT();

        vm.roll(block.number + 10);
        vm.prank(vm.addr(2));
        nftProxytest.claimRewards(tokenIds);

        uint256 rewardBalance = mockErc20Test.balanceOf(vm.addr(2));
        assertEq(rewardBalance, 10);
    }

    function test_SetRewardRate() public {
        vm.prank(vm.addr(1));
        nftProxytest.setRewardRate(2);
        uint256 newRate = nftProxytest.rewardRate();
        assertEq(newRate, 2);
    }

    function test_PauseAndUnpause() public {
        vm.prank(vm.addr(1));
        nftProxytest.pause();
        assertTrue(nftProxytest.paused());
        vm.prank(vm.addr(1));

        nftProxytest.unpause();
        assertFalse(nftProxytest.paused());
    }

    function test_TransferOwnership() public {
        address newAdmin = vm.addr(2);
        vm.prank(vm.addr(1));
        nftProxytest.transferOwnership(newAdmin);

        address admin = nftProxytest.getAdmin();
        assertEq(admin, newAdmin);
    }

    function test_UpgradeContract() public {
        NftStakingAndRewarding newImplementation = new NftStakingAndRewarding();
        vm.prank(vm.addr(1));
        nftProxytest.upgradeContract(address(newImplementation));

        address impl = nftProxytest.getImplementation();
        assertEq(impl, address(newImplementation));
    }
    error NotStaked();

    function test_FailToUnstakeNotStakedNFT() public {
        uint256 tokenId = 1;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        vm.expectRevert(NotStaked.selector);
        nftProxytest.unstakeNfts(tokenIds);
    }

    function test_FailToWithdrawWithoutUnbonding() public {
        uint256 tokenId = 1;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        vm.prank(vm.addr(2));
        mockErc721Test.safeMint(vm.addr(2), tokenId);
        vm.prank(vm.addr(2));
        mockErc721Test.approve(address(nftProxytest), tokenId);
        vm.prank(vm.addr(2));
        nftProxytest.stakeNfts(tokenIds);

        vm.expectRevert(NotStaked.selector);
        vm.prank(vm.addr(2));
        nftProxytest.withdrawNfts(tokenIds);
    }
    error ClaimDelayPeriodNotOver();
    function test_FailToClaimRewardsDuringDelayPeriod() public {
        uint256[] memory tokenIds = test_StakeNFT();
        // vm.roll(block.number + 1);
        vm.prank(vm.addr(2));
        vm.expectRevert(ClaimDelayPeriodNotOver.selector);
        nftProxytest.claimRewards(tokenIds);
    }
    error AlreadyUnstaked();
    function test_FailToUnstakeAlreadyUnstakedNFT() public {
        uint256[] memory tokenIds = test_UnstakeNFT();
        vm.prank(vm.addr(2));
        vm.expectRevert(AlreadyUnstaked.selector);
        nftProxytest.unstakeNfts(tokenIds);
    }
    error UnbondingPeriodNotOver();
    function test_FailToWithdrawDuringUnbondingPeriod() public {
        uint256[] memory tokenIds = test_UnstakeNFT();
        // vm.roll(block.number + 1);
        vm.prank(vm.addr(2));
        vm.expectRevert(UnbondingPeriodNotOver.selector);
        nftProxytest.withdrawNfts(tokenIds);
    }

    function test_SetRewardRateAsNonOwner() public {
        vm.prank(vm.addr(2));
        vm.expectRevert("failllll");
        nftProxytest.setRewardRate(2);
    }

    function test_PauseAsNonOwner() public {
        vm.prank(vm.addr(2));
        vm.expectRevert("failllll");
        nftProxytest.pause();
    }

    function test_UnpauseAsNonOwner() public {
        vm.prank(vm.addr(1));
        nftProxytest.pause();
        vm.prank(vm.addr(2));
        vm.expectRevert("failllll");
        nftProxytest.unpause();
    }

    function test_TransferOwnershipAsNonOwner() public {
        address newAdmin = vm.addr(3);
        vm.prank(vm.addr(2));
        vm.expectRevert("failllll");
        nftProxytest.transferOwnership(newAdmin);
    }

    function test_UpgradeContractAsNonOwner() public {
        NftStakingAndRewarding newImplementation = new NftStakingAndRewarding();
        vm.prank(vm.addr(2));
        vm.expectRevert("failllll");
        nftProxytest.upgradeContract(address(newImplementation));
    }

    // Add more test cases as needed
}
