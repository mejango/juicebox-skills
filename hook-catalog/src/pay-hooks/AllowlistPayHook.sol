// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IJBRulesetDataHook} from "@bananapus/core/src/interfaces/IJBRulesetDataHook.sol";
import {JBBeforePayRecordedContext} from "@bananapus/core/src/structs/JBBeforePayRecordedContext.sol";
import {JBBeforeCashOutRecordedContext} from "@bananapus/core/src/structs/JBBeforeCashOutRecordedContext.sol";
import {JBPayHookSpecification} from "@bananapus/core/src/structs/JBPayHookSpecification.sol";
import {JBCashOutHookSpecification} from "@bananapus/core/src/structs/JBCashOutHookSpecification.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title AllowlistPayHook
/// @notice Restricts payments to allowlisted addresses only
/// @dev Useful for private sales, KYC requirements, or exclusive access
contract AllowlistPayHook is IJBRulesetDataHook, ERC165, Ownable {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotAllowlisted(address payer);
    error AllowlistNotEnabled(uint256 projectId);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event AllowlistUpdated(uint256 indexed projectId, address indexed account, bool allowed);
    event AllowlistEnabledUpdated(uint256 indexed projectId, bool enabled);
    event MerkleRootUpdated(uint256 indexed projectId, bytes32 oldRoot, bytes32 newRoot);

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Whether allowlist is enabled for a project
    mapping(uint256 projectId => bool) public allowlistEnabled;

    /// @notice Direct allowlist mapping
    mapping(uint256 projectId => mapping(address => bool)) public isAllowlisted;

    /// @notice Merkle root for larger allowlists (optional)
    mapping(uint256 projectId => bytes32) public merkleRootOf;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) Ownable(_owner) {}

    /*//////////////////////////////////////////////////////////////
                            CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Enable or disable allowlist for a project
    function setAllowlistEnabled(uint256 projectId, bool enabled) external onlyOwner {
        allowlistEnabled[projectId] = enabled;
        emit AllowlistEnabledUpdated(projectId, enabled);
    }

    /// @notice Add or remove addresses from allowlist
    function setAllowlisted(uint256 projectId, address[] calldata accounts, bool allowed) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            isAllowlisted[projectId][accounts[i]] = allowed;
            emit AllowlistUpdated(projectId, accounts[i], allowed);
        }
    }

    /// @notice Set merkle root for large allowlists
    function setMerkleRoot(uint256 projectId, bytes32 root) external onlyOwner {
        bytes32 oldRoot = merkleRootOf[projectId];
        merkleRootOf[projectId] = root;
        emit MerkleRootUpdated(projectId, oldRoot, root);
    }

    /*//////////////////////////////////////////////////////////////
                             DATA HOOK
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates payer is allowlisted
    function beforePayRecordedWith(JBBeforePayRecordedContext calldata context)
        external
        view
        override
        returns (uint256 weight, JBPayHookSpecification[] memory hookSpecifications)
    {
        // Skip check if allowlist not enabled
        if (!allowlistEnabled[context.projectId]) {
            return (context.weight, new JBPayHookSpecification[](0));
        }

        // Check direct allowlist first
        if (isAllowlisted[context.projectId][context.payer]) {
            return (context.weight, new JBPayHookSpecification[](0));
        }

        // Check merkle proof if provided in metadata
        if (merkleRootOf[context.projectId] != bytes32(0) && context.metadata.length > 0) {
            // Decode merkle proof from metadata
            // Format: [bytes4 hookId][bytes32[] proof]
            if (_verifyMerkleProof(context.projectId, context.payer, context.metadata)) {
                return (context.weight, new JBPayHookSpecification[](0));
            }
        }

        revert NotAllowlisted(context.payer);
    }

    /// @notice Pass through for cash outs
    function beforeCashOutRecordedWith(JBBeforeCashOutRecordedContext calldata context)
        external
        pure
        override
        returns (
            uint256 cashOutTaxRate,
            uint256 cashOutCount,
            uint256 totalSupply,
            JBCashOutHookSpecification[] memory hookSpecifications
        )
    {
        return (
            context.cashOutTaxRate,
            context.cashOutCount,
            context.totalSupply,
            new JBCashOutHookSpecification[](0)
        );
    }

    function hasMintPermissionFor(uint256) external pure override returns (bool) {
        return false;
    }

    /*//////////////////////////////////////////////////////////////
                           MERKLE VERIFICATION
    //////////////////////////////////////////////////////////////*/

    /// @dev Verify merkle proof from payment metadata
    function _verifyMerkleProof(uint256 projectId, address account, bytes calldata metadata)
        internal
        view
        returns (bool)
    {
        // Expected format: first 4 bytes = hook identifier, rest = proof
        if (metadata.length < 36) return false; // At least 4 + 32 bytes

        bytes4 hookId = bytes4(metadata[:4]);
        if (hookId != bytes4(keccak256("AllowlistPayHook"))) return false;

        // Extract proof
        bytes32[] memory proof = abi.decode(metadata[4:], (bytes32[]));

        // Verify
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return _verify(proof, merkleRootOf[projectId], leaf);
    }

    /// @dev Standard merkle proof verification
    function _verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == root;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IJBRulesetDataHook).interfaceId || super.supportsInterface(interfaceId);
    }
}
