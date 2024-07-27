// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

contract NftStakingAndRewarding is Initializable, Pausable {
    IERC721 public nft;
    IERC20 public rewardToken;

    uint256 public rewardRate; // Tokens rewarded per block per NFT
    uint256 public delayPeriod; // Delay period for claiming rewards
    uint256 public unbondingPeriod; // Unbonding period for unstaking

    struct NFTStaking {
        uint256 stakedAt;
        uint256 unbondedAt;
    }

    mapping(address => mapping(uint256 => NFTStaking)) public nftStakes;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastClaimed;

    event Staked(address indexed user, uint256 indexed tokenId);
    event Unstaked(address indexed user, uint256 indexed tokenId);
    event RewardsClaimed(address indexed user, uint256 amount);

    error NotAdmin();
    error NotStaked();
    error AlreadyUnstaked();
    error UnbondingPeriodNotOver();
    error ClaimDelayPeriodNotOver();

    modifier onlyOwner() {
        require(getAdmin() == msg.sender, "failllll");
        _;
    }

    /**
     * @notice Initializes the contract with the given parameters.
     * @param _nft The address of the NFT contract.
     * @param _rewardToken The address of the reward token contract.
     * @param _rewardRate The rate of reward tokens per block per staked NFT.
     * @param _delayPeriod The delay period for claiming rewards.
     * @param _unbondingPeriod The unbonding period for unstaking NFTs.
     * @param newAdmin The address of the new admin.
     */
    function initialize(
        IERC721 _nft,
        IERC20 _rewardToken,
        uint256 _rewardRate,
        uint256 _delayPeriod,
        uint256 _unbondingPeriod,
        address newAdmin
    ) public initializer {
        nft = _nft;
        rewardToken = _rewardToken;
        rewardRate = _rewardRate;
        delayPeriod = _delayPeriod;
        unbondingPeriod = _unbondingPeriod;
        ERC1967Utils.changeAdmin(newAdmin);
    }

    /**
     * @notice Returns the address of the current implementation.
     * @return The address of the current implementation.
     */
    function getImplementation() public view returns (address) {
        return ERC1967Utils.getImplementation();
    }

    /**
     * @notice Upgrades the contract to a new implementation.
     * @param newImplementation The address of the new implementation.
     */
    function upgradeContract(address newImplementation) external onlyOwner {
        ERC1967Utils.upgradeToAndCall(newImplementation, "");
    }

    /**
     * @notice Returns the address of the current admin.
     * @return The address of the current admin.
     */
    function getAdmin() public view returns (address) {
        return ERC1967Utils.getAdmin();
    }

    /**
     * @notice Transfers the ownership to a new admin.
     * @param newAdmin The address of the new admin.
     */
    function transferOwnership(address newAdmin) external onlyOwner {
        ERC1967Utils.changeAdmin(newAdmin);
    }

    /**
     * @notice Stakes the specified NFTs.
     * @param tokenIds The array of token IDs to stake.
     */
    function stakeNfts(uint256[] calldata tokenIds) external whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            nft.transferFrom(msg.sender, address(this), tokenId);
            nftStakes[msg.sender][tokenId] = NFTStaking(block.number, 0);
            emit Staked(msg.sender, tokenId);
        }
    }

    /**
     * @notice Unstakes the specified NFTs.
     * @param tokenIds The array of token IDs to unstake.
     */
    function unstakeNfts(uint256[] calldata tokenIds) external whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            NFTStaking storage stakeInfo = nftStakes[msg.sender][tokenId];
            if (stakeInfo.stakedAt == 0) {
                revert NotStaked();
            }
            if (stakeInfo.unbondedAt != 0) {
                revert AlreadyUnstaked();
            }
            stakeInfo.unbondedAt = block.number;
            emit Unstaked(msg.sender, tokenId);
        }
    }

    /**
     * @notice Withdraws the specified NFTs after the unbonding period.
     * @param tokenIds The array of token IDs to withdraw.
     */
    function withdrawNfts(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            NFTStaking storage stakeInfo = nftStakes[msg.sender][tokenId];
            if (stakeInfo.unbondedAt == 0) {
                revert NotStaked();
            }
            if (block.number < stakeInfo.unbondedAt + unbondingPeriod) {
                revert UnbondingPeriodNotOver();
            }
            delete nftStakes[msg.sender][tokenId];
            nft.transferFrom(address(this), msg.sender, tokenId);
        }
    }

    /**
     * @notice Claims the rewards for the specified NFTs.
     * @param tokenIds The array of token IDs to claim rewards for.
     */
    function claimRewards(uint256[] calldata tokenIds) external {
        if (block.number < lastClaimed[msg.sender] + delayPeriod) {
            revert ClaimDelayPeriodNotOver();
        }
        uint256 reward = calculateRewards(tokenIds);
        rewards[msg.sender] = 0;
        lastClaimed[msg.sender] = block.number;
        rewardToken.transfer(msg.sender, reward);
        emit RewardsClaimed(msg.sender, reward);
    }

    /**
     * @notice Calculates the rewards for the specified NFTs.
     * @param tokenIds The array of token IDs to calculate rewards for.
     * @return The total calculated rewards.
     */
    function calculateRewards(
        uint256[] calldata tokenIds
    ) public view returns (uint256) {
        uint256 totalReward = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            NFTStaking memory stakeInfo = nftStakes[msg.sender][tokenIds[i]];

            if (stakeInfo.stakedAt != 0 && stakeInfo.unbondedAt == 0) {
                totalReward += (block.number - stakeInfo.stakedAt) * rewardRate;
            } else if (stakeInfo.unbondedAt != 0) {
                totalReward +=
                    (stakeInfo.unbondedAt - stakeInfo.stakedAt) *
                    rewardRate;
            }
        }

        return totalReward;
    }

    /**
     * @notice Sets the reward rate for staked NFTs.
     * @param _rewardRate The new reward rate.
     */
    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
    }

    /**
     * @notice Pauses the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
