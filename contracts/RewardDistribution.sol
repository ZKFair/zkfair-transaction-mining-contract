// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../interfaces/IERC20Burnable.sol";

contract RewardDistribution is OwnableUpgradeable {
    uint public totalOutput; //Total Mining.
    uint public firstStartTime; // first start time
    uint public claimStartTime; // claim start time
    uint public claimEndInterval; // claim end interval

    address public zkfTokenAddress;
    uint public totalDistributedReward; // total Distributed Reward

    // history
    address[] public allRewardsAddress;
    mapping(address => uint) public rewardHistory;

    // merkleRoot
    bytes32 public merkleRoot;
    bytes32 public pendingMerkleRoot;

    // admin address which can propose adding a new merkle root
    address public proposalAuthority;
    // admin address which approves or rejects a proposed merkle root
    address public reviewAuthority;

    event Claimed(
        uint256 index,
        address account,
        uint256 amount
    );

    event NewAddFeeRecordEvent(
        address indexed receiveAddress
    );

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    modifier onlyValidAddress(address addr) {
        require(addr != address(0), "Illegal address");
        _;
    }

    function initialize(
        address _initialOwner,
        address _zkfTokenAddress,
        address _proposalAuthority,
        address _reviewAuthority,
        uint256 _totalOutput,
        uint256 _claimEndInterval
    ) external onlyValidAddress(_initialOwner)
    onlyValidAddress(_zkfTokenAddress)
    onlyValidAddress(_proposalAuthority)
    onlyValidAddress(_reviewAuthority) virtual initializer {
        firstStartTime = block.timestamp;
        zkfTokenAddress = _zkfTokenAddress;
        proposalAuthority = _proposalAuthority;
        reviewAuthority = _reviewAuthority;
        totalOutput = _totalOutput;
        claimEndInterval = _claimEndInterval;
        // Initialize OZ contracts
        __Ownable_init_unchained(_initialOwner);
    }

    function setProposalAuthority(address _account) public onlyValidAddress(_account) {
        require(msg.sender == proposalAuthority);
        proposalAuthority = _account;
    }

    function setReviewAuthority(address _account) public onlyValidAddress(_account) {
        require(msg.sender == reviewAuthority);
        reviewAuthority = _account;
    }

    // Each week, the proposal authority calls to submit the merkle root for a new airdrop.
    function proposewMerkleRoot(bytes32 _merkleRoot) public {
        require(msg.sender == proposalAuthority);
        require(pendingMerkleRoot == 0x00);
        require(merkleRoot == 0x00);
        pendingMerkleRoot = _merkleRoot;
    }

    // After validating the correctness of the pending merkle root, the reviewing authority
    // calls to confirm it and the distribution may begin.
    function reviewPendingMerkleRoot(bool _approved) public {
        require(msg.sender == reviewAuthority);
        require(pendingMerkleRoot != 0x00);
        if (_approved) {
            merkleRoot = pendingMerkleRoot;
            claimStartTime = block.timestamp;
        }
        delete pendingMerkleRoot;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, uint256 amount, bytes32[] calldata merkleProof) public {
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');
        require(amount > 0 && amount <= totalOutput, 'Invalid parameter');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount));
        require(verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        require(claimStartTime + claimEndInterval >= block.timestamp, 'claim end');
        // Mark it claimed and send the token.
        _setClaimed(index);

        require(totalDistributedReward + amount <= totalOutput, 'Distribution has ended.');

        bool bResult = IERC20(zkfTokenAddress).transfer(msg.sender, amount);
        require(bResult, 'ZKF erc20 transfer failed.');

        if(rewardHistory[msg.sender] == 0) {
            allRewardsAddress.push(msg.sender);
            emit NewAddFeeRecordEvent(msg.sender);
        }
        rewardHistory[msg.sender] += amount;
        totalDistributedReward += amount;
        emit Claimed(index, msg.sender, amount);
    }

    function burnBalance() public {
        require(msg.sender == reviewAuthority);
        require(claimStartTime + claimEndInterval < block.timestamp, 'claim not end');
        uint balance = IERC20(zkfTokenAddress).balanceOf(address(this));
        IERC20Burnable(zkfTokenAddress).burn(balance);
    }

    function allRewardsAddressLength() public view returns(uint) {
        return allRewardsAddress.length;
    }

    function verify(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}