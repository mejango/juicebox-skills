// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IJBSplitHook} from "@bananapus/core/src/interfaces/IJBSplitHook.sol";
import {JBSplitHookContext} from "@bananapus/core/src/structs/JBSplitHookContext.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title VestingSplitHook
/// @notice Routes split funds to a vesting contract for team/contributor compensation
/// @dev Implements linear vesting with configurable duration and cliff
contract VestingSplitHook is IJBSplitHook, ERC165, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotWhitelisted(address account);
    error NothingToClaim();
    error VestingNotStarted();
    error TransferFailed();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event FundsReceived(uint256 indexed projectId, address token, uint256 amount);
    event VestingStarted(uint256 timestamp);
    event Claimed(address indexed beneficiary, address token, uint256 amount);
    event BeneficiaryUpdated(address indexed account, uint256 share);

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct Beneficiary {
        uint256 share;           // Share out of TOTAL_SHARES
        uint256 claimedETH;      // ETH already claimed
        mapping(address => uint256) claimedTokens; // ERC20 tokens claimed
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant TOTAL_SHARES = 10000; // 100% = 10000

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Vesting duration in seconds (e.g., 365 days)
    uint256 public immutable vestingDuration;

    /// @notice Cliff duration in seconds (e.g., 90 days)
    uint256 public immutable cliffDuration;

    /// @notice When vesting starts (0 if not started)
    uint256 public vestingStart;

    /// @notice Total ETH received for vesting
    uint256 public totalETHReceived;

    /// @notice Total tokens received for vesting (per token)
    mapping(address token => uint256) public totalTokensReceived;

    /// @notice Beneficiary configurations
    mapping(address => Beneficiary) public beneficiaries;

    /// @notice List of beneficiary addresses
    address[] public beneficiaryList;

    /// @notice Admin address for configuration
    address public immutable admin;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param _vestingDuration Total vesting period in seconds
    /// @param _cliffDuration Cliff period in seconds
    /// @param _beneficiaryAddresses Initial beneficiary addresses
    /// @param _shares Corresponding shares (must sum to TOTAL_SHARES or less)
    constructor(
        uint256 _vestingDuration,
        uint256 _cliffDuration,
        address[] memory _beneficiaryAddresses,
        uint256[] memory _shares
    ) {
        require(_cliffDuration <= _vestingDuration, "Cliff > vesting");
        require(_beneficiaryAddresses.length == _shares.length, "Length mismatch");

        vestingDuration = _vestingDuration;
        cliffDuration = _cliffDuration;
        admin = msg.sender;

        uint256 totalShares;
        for (uint256 i; i < _beneficiaryAddresses.length; i++) {
            beneficiaries[_beneficiaryAddresses[i]].share = _shares[i];
            beneficiaryList.push(_beneficiaryAddresses[i]);
            totalShares += _shares[i];
            emit BeneficiaryUpdated(_beneficiaryAddresses[i], _shares[i]);
        }

        require(totalShares <= TOTAL_SHARES, "Shares exceed 100%");
    }

    /*//////////////////////////////////////////////////////////////
                            SPLIT HOOK
    //////////////////////////////////////////////////////////////*/

    /// @notice Process split funds - adds to vesting pool
    /// @param context Split context from terminal
    function processSplitWith(JBSplitHookContext calldata context) external payable override nonReentrant {
        // Start vesting on first deposit
        if (vestingStart == 0) {
            vestingStart = block.timestamp;
            emit VestingStarted(vestingStart);
        }

        if (context.token == address(0)) {
            // Native ETH
            totalETHReceived += msg.value;
            emit FundsReceived(context.projectId, address(0), msg.value);
        } else {
            // ERC20 token
            uint256 balance = IERC20(context.token).balanceOf(address(this));
            // Funds were optimistically transferred, track the new balance
            uint256 received = balance - _getTotalUnclaimedTokens(context.token);
            totalTokensReceived[context.token] += received;
            emit FundsReceived(context.projectId, context.token, received);
        }
    }

    /*//////////////////////////////////////////////////////////////
                              CLAIMING
    //////////////////////////////////////////////////////////////*/

    /// @notice Claim vested ETH
    function claimETH() external nonReentrant {
        if (vestingStart == 0) revert VestingNotStarted();

        Beneficiary storage b = beneficiaries[msg.sender];
        if (b.share == 0) revert NotWhitelisted(msg.sender);

        uint256 vested = _vestedAmount(totalETHReceived, b.share);
        uint256 claimable = vested - b.claimedETH;

        if (claimable == 0) revert NothingToClaim();

        b.claimedETH += claimable;

        (bool success,) = msg.sender.call{value: claimable}("");
        if (!success) revert TransferFailed();

        emit Claimed(msg.sender, address(0), claimable);
    }

    /// @notice Claim vested ERC20 tokens
    /// @param token The token to claim
    function claimToken(address token) external nonReentrant {
        if (vestingStart == 0) revert VestingNotStarted();

        Beneficiary storage b = beneficiaries[msg.sender];
        if (b.share == 0) revert NotWhitelisted(msg.sender);

        uint256 vested = _vestedAmount(totalTokensReceived[token], b.share);
        uint256 claimable = vested - b.claimedTokens[token];

        if (claimable == 0) revert NothingToClaim();

        b.claimedTokens[token] += claimable;

        IERC20(token).safeTransfer(msg.sender, claimable);

        emit Claimed(msg.sender, token, claimable);
    }

    /*//////////////////////////////////////////////////////////////
                               VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get claimable ETH for a beneficiary
    function getClaimableETH(address account) external view returns (uint256) {
        if (vestingStart == 0) return 0;

        Beneficiary storage b = beneficiaries[account];
        uint256 vested = _vestedAmount(totalETHReceived, b.share);
        return vested > b.claimedETH ? vested - b.claimedETH : 0;
    }

    /// @notice Get claimable tokens for a beneficiary
    function getClaimableTokens(address account, address token) external view returns (uint256) {
        if (vestingStart == 0) return 0;

        Beneficiary storage b = beneficiaries[account];
        uint256 vested = _vestedAmount(totalTokensReceived[token], b.share);
        return vested > b.claimedTokens[token] ? vested - b.claimedTokens[token] : 0;
    }

    /// @notice Get vesting progress (0-10000 representing 0-100%)
    function getVestingProgress() external view returns (uint256) {
        if (vestingStart == 0) return 0;

        uint256 elapsed = block.timestamp - vestingStart;
        if (elapsed < cliffDuration) return 0;
        if (elapsed >= vestingDuration) return TOTAL_SHARES;

        return (elapsed * TOTAL_SHARES) / vestingDuration;
    }

    /// @notice Get beneficiary info
    function getBeneficiaryInfo(address account)
        external
        view
        returns (uint256 share, uint256 claimedETH)
    {
        Beneficiary storage b = beneficiaries[account];
        return (b.share, b.claimedETH);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @dev Calculate vested amount based on time elapsed
    function _vestedAmount(uint256 totalAmount, uint256 share) internal view returns (uint256) {
        uint256 elapsed = block.timestamp - vestingStart;

        // Before cliff
        if (elapsed < cliffDuration) return 0;

        // After full vesting
        if (elapsed >= vestingDuration) {
            return (totalAmount * share) / TOTAL_SHARES;
        }

        // During vesting
        uint256 totalEntitlement = (totalAmount * share) / TOTAL_SHARES;
        return (totalEntitlement * elapsed) / vestingDuration;
    }

    /// @dev Calculate total unclaimed tokens (for balance tracking)
    function _getTotalUnclaimedTokens(address token) internal view returns (uint256) {
        uint256 total;
        for (uint256 i; i < beneficiaryList.length; i++) {
            total += beneficiaries[beneficiaryList[i]].claimedTokens[token];
        }
        return totalTokensReceived[token] - total;
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
