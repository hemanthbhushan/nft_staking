# NFT Staking and Rewarding Smart Contract

This repository contains the smart contracts and tests for a decentralized application (dApp) that allows users to stake NFTs and earn ERC20 token rewards. The core contracts include `NftStakingAndRewarding`, `NftProxy`, and relevant interfaces and mocks for testing purposes.

## Contracts

### NftStakingAndRewarding

The `NftStakingAndRewarding` contract allows users to stake their NFTs, earn rewards in ERC20 tokens, and withdraw their staked NFTs after an unbonding period. The contract supports upgradeability and ownership transfer.

#### Features

- **Stake NFTs**: Users can stake their NFTs to start earning rewards.
- **Unstake NFTs**: Users can initiate the unstaking process, starting an unbonding period.
- **Withdraw NFTs**: After the unbonding period, users can withdraw their NFTs.
- **Claim Rewards**: Users can claim accumulated rewards in ERC20 tokens.
- **Upgradeability**: The contract can be upgraded to a new implementation.
- **Ownership Transfer**: Ownership can be transferred to a new admin.
- **Pause/Unpause**: The contract can be paused and unpaused by the owner.

### NftProxy

The `NftProxy` contract is a proxy contract that delegates calls to the implementation contract. It supports upgradeability and ownership transfer.

### Interfaces and Mocks

- **INftProxy**: Interface for the proxy contract.
- **mockNft**: Mock ERC721 contract for testing.
- **mockErc20**: Mock ERC20 contract for testing.

## Usage

### Deployment

1. Deploy the `NftStakingAndRewarding` implementation contract.
2. Deploy the `NftProxy` contract, pointing to the implementation contract.
3. Initialize the proxy contract with the necessary parameters.

### Functions

#### NftStakingAndRewarding

- `initialize(IERC721 _nft, IERC20 _rewardToken, uint256 _rewardRate, uint256 _delayPeriod, uint256 _unbondingPeriod, address newAdmin)`: Initializes the contract.
- `stakeNfts(uint256[] calldata tokenIds)`: Stakes the specified NFTs.
- `unstakeNfts(uint256[] calldata tokenIds)`: Unstakes the specified NFTs.
- `withdrawNfts(uint256[] calldata tokenIds)`: Withdraws the specified NFTs after the unbonding period.
- `claimRewards(uint256[] calldata tokenIds)`: Claims the rewards for the specified NFTs.
- `setRewardRate(uint256 _rewardRate)`: Sets the reward rate for staked NFTs.
- `pause()`: Pauses the contract.
- `unpause()`: Unpauses the contract.
- `transferOwnership(address newAdmin)`: Transfers ownership to a new admin.
- `upgradeContract(address newImplementation)`: Upgrades the contract to a new implementation.

### Events

- `Staked(address indexed user, uint256 indexed tokenId)`: Emitted when an NFT is staked.
- `Unstaked(address indexed user, uint256 indexed tokenId)`: Emitted when an NFT is unstaked.
- `RewardsClaimed(address indexed user, uint256 amount)`: Emitted when rewards are claimed.

### Error Handling

- `NotAdmin()`: Thrown when a non-admin attempts an admin-only function.
- `NotStaked(uint256 tokenId)`: Thrown when an unstaked token is unstaked or withdrawn.
- `AlreadyUnstaked(uint256 tokenId)`: Thrown when an already unstaked token is unstaked.
- `UnbondingPeriodNotOver(uint256 tokenId)`: Thrown when attempting to withdraw before the unbonding period is over.
- `ClaimDelayPeriodNotOver()`: Thrown when attempting to claim rewards before the delay period is over.

## Testing

The repository includes a comprehensive test suite using Forge to ensure full coverage of the contract functionality.

### Test Setup

1. Install [Foundry](https://book.getfoundry.sh/getting-started/installation).
2. Clone the repository.
3. Run `forge install` to install dependencies.
4. Run `forge test` to execute the test suite.

### Test Cases

The test suite includes the following tests:

- Basic functionality tests for staking, unstaking, withdrawing, and claiming rewards.
- Edge case tests for error handling and invalid operations.
- Admin functionality tests for setting reward rates, pausing/unpausing, ownership transfer, and contract upgrade.

