// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IJBSplitHook} from "@bananapus/core/src/interfaces/IJBSplitHook.sol";
import {JBSplitHookContext} from "@bananapus/core/src/structs/JBSplitHookContext.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title MultiRecipientSplitHook
/// @notice Splits incoming funds among multiple recipients with configurable shares
/// @dev Useful for further distributing a single split among multiple wallets
contract MultiRecipientSplitHook is IJBSplitHook, ERC165, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidRecipient();
    error InvalidShares();
    error TransferFailed();
    error NoRecipients();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event RecipientAdded(address indexed recipient, uint256 share);
    event RecipientRemoved(address indexed recipient);
    event RecipientUpdated(address indexed recipient, uint256 oldShare, uint256 newShare);
    event FundsDistributed(uint256 indexed projectId, address token, uint256 totalAmount);
    event RecipientPaid(address indexed recipient, address token, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct Recipient {
        address payable addr;
        uint256 share;    // Share out of TOTAL_SHARES
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant TOTAL_SHARES = 10000; // 100% = 10000

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Array of recipients
    Recipient[] public recipients;

    /// @notice Mapping for quick lookup
    mapping(address => uint256) public shareOf;

    /// @notice Total allocated shares (should not exceed TOTAL_SHARES)
    uint256 public totalAllocatedShares;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param _recipients Initial recipient addresses
    /// @param _shares Corresponding shares (must sum to TOTAL_SHARES or less)
    /// @param _owner Contract owner for configuration
    constructor(
        address payable[] memory _recipients,
        uint256[] memory _shares,
        address _owner
    ) Ownable(_owner) {
        require(_recipients.length == _shares.length, "Length mismatch");

        for (uint256 i; i < _recipients.length; i++) {
            _addRecipient(_recipients[i], _shares[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Add a new recipient
    /// @param recipient Recipient address
    /// @param share Share amount (out of TOTAL_SHARES)
    function addRecipient(address payable recipient, uint256 share) external onlyOwner {
        _addRecipient(recipient, share);
    }

    /// @notice Update an existing recipient's share
    /// @param recipient Recipient address
    /// @param newShare New share amount
    function updateRecipient(address recipient, uint256 newShare) external onlyOwner {
        uint256 oldShare = shareOf[recipient];
        if (oldShare == 0) revert InvalidRecipient();

        totalAllocatedShares = totalAllocatedShares - oldShare + newShare;
        if (totalAllocatedShares > TOTAL_SHARES) revert InvalidShares();

        shareOf[recipient] = newShare;

        // Update in array
        for (uint256 i; i < recipients.length; i++) {
            if (recipients[i].addr == recipient) {
                recipients[i].share = newShare;
                break;
            }
        }

        emit RecipientUpdated(recipient, oldShare, newShare);
    }

    /// @notice Remove a recipient
    /// @param recipient Recipient address to remove
    function removeRecipient(address recipient) external onlyOwner {
        uint256 share = shareOf[recipient];
        if (share == 0) revert InvalidRecipient();

        totalAllocatedShares -= share;
        delete shareOf[recipient];

        // Remove from array
        for (uint256 i; i < recipients.length; i++) {
            if (recipients[i].addr == recipient) {
                recipients[i] = recipients[recipients.length - 1];
                recipients.pop();
                break;
            }
        }

        emit RecipientRemoved(recipient);
    }

    /*//////////////////////////////////////////////////////////////
                            SPLIT HOOK
    //////////////////////////////////////////////////////////////*/

    /// @notice Process split funds and distribute to all recipients
    /// @param context Split context from terminal
    function processSplitWith(JBSplitHookContext calldata context) external payable override nonReentrant {
        if (recipients.length == 0) revert NoRecipients();

        uint256 totalAmount;

        if (context.token == address(0)) {
            // Native ETH
            totalAmount = address(this).balance;
        } else {
            // ERC20 token
            totalAmount = IERC20(context.token).balanceOf(address(this));
        }

        if (totalAmount == 0) return;

        // Distribute to each recipient
        uint256 distributed;
        for (uint256 i; i < recipients.length; i++) {
            Recipient memory r = recipients[i];

            // Calculate share (last recipient gets remainder to handle rounding)
            uint256 amount;
            if (i == recipients.length - 1) {
                amount = totalAmount - distributed;
            } else {
                amount = (totalAmount * r.share) / totalAllocatedShares;
            }

            if (amount == 0) continue;

            distributed += amount;

            if (context.token == address(0)) {
                // Send ETH
                (bool success,) = r.addr.call{value: amount}("");
                if (!success) revert TransferFailed();
            } else {
                // Send ERC20
                IERC20(context.token).safeTransfer(r.addr, amount);
            }

            emit RecipientPaid(r.addr, context.token, amount);
        }

        emit FundsDistributed(context.projectId, context.token, totalAmount);
    }

    /*//////////////////////////////////////////////////////////////
                               VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get all recipients
    function getRecipients() external view returns (Recipient[] memory) {
        return recipients;
    }

    /// @notice Get number of recipients
    function recipientCount() external view returns (uint256) {
        return recipients.length;
    }

    /// @notice Calculate expected distribution for a given amount
    /// @param amount Total amount to distribute
    /// @return amounts Array of amounts each recipient would receive
    function previewDistribution(uint256 amount) external view returns (uint256[] memory amounts) {
        amounts = new uint256[](recipients.length);

        uint256 distributed;
        for (uint256 i; i < recipients.length; i++) {
            if (i == recipients.length - 1) {
                amounts[i] = amount - distributed;
            } else {
                amounts[i] = (amount * recipients[i].share) / totalAllocatedShares;
                distributed += amounts[i];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _addRecipient(address payable recipient, uint256 share) internal {
        if (recipient == address(0)) revert InvalidRecipient();
        if (shareOf[recipient] > 0) revert InvalidRecipient(); // Already exists

        totalAllocatedShares += share;
        if (totalAllocatedShares > TOTAL_SHARES) revert InvalidShares();

        recipients.push(Recipient({addr: recipient, share: share}));
        shareOf[recipient] = share;

        emit RecipientAdded(recipient, share);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IJBSplitHook).interfaceId || super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                              RECEIVE
    //////////////////////////////////////////////////////////////*/

    receive() external payable {}
}
