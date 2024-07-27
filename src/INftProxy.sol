// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INftProxy {
    // Events
    event Staked(address indexed user, uint256 indexed tokenId);
    event Unstaked(address indexed user, uint256 indexed tokenId);
    event RewardsClaimed(address indexed user, uint256 amount);

    // Structs
    struct NFTStaking {
        uint256 stakedAt;
        uint256 unbondedAt;
    }

    // Errors
    error NotAdmin();
    error NotStaked(uint256 tokenId);
    error AlreadyUnstaked(uint256 tokenId);
    error UnbondingPeriodNotOver(uint256 tokenId);
    error ClaimDelayPeriodNotOver();

    // Functions
    function initialize(
        IERC721 _nft,
        IERC20 _rewardToken,
        uint256 _rewardRate,
        uint256 _delayPeriod,
        uint256 _unbondingPeriod,
        address newAdmin
    ) external;

    function getImplementation() external view returns (address);

    function upgradeContract(address newImplementation) external;

    function getAdmin() external view returns (address);

    function transferOwnership(address newAdmin) external;

    function stakeNfts(uint256[] calldata tokenIds) external;

    function unstakeNfts(uint256[] calldata tokenIds) external;

    function withdrawNfts(uint256[] calldata tokenIds) external;

    function claimRewards(uint256[] calldata tokenIds) external;

    function calculateRewards(
        uint256[] calldata tokenIds
    ) external view returns (uint256);

    function setRewardRate(uint256 _rewardRate) external;

    function pause() external;

    function unpause() external;
    function nftStakes(
        address user,
        uint256 tokenId
    ) external view returns (NFTStaking memory);
    function rewardRate() external view returns (uint256);
    function paused() external view returns (bool);
}
