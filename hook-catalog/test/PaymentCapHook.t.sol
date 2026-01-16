// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {PaymentCapHook} from "../src/pay-hooks/PaymentCapHook.sol";
import {JBBeforePayRecordedContext} from "@bananapus/core/src/structs/JBBeforePayRecordedContext.sol";
import {JBTokenAmount} from "@bananapus/core/src/structs/JBTokenAmount.sol";
import {JBRuleset} from "@bananapus/core/src/structs/JBRuleset.sol";

contract PaymentCapHookTest is Test {
    PaymentCapHook public hook;

    address owner = address(0x1);
    address payer = address(0x2);

    uint256 constant DEFAULT_CAP = 10 ether;
    uint256 constant PROJECT_ID = 1;

    function setUp() public {
        hook = new PaymentCapHook(DEFAULT_CAP, owner);
    }

    function test_initialState() public view {
        assertEq(hook.defaultCap(), DEFAULT_CAP);
        assertEq(hook.owner(), owner);
    }

    function test_paymentUnderCap() public view {
        JBBeforePayRecordedContext memory context = _createContext(5 ether);

        (uint256 weight,) = hook.beforePayRecordedWith(context);

        assertEq(weight, context.weight);
    }

    function test_paymentAtCap() public view {
        JBBeforePayRecordedContext memory context = _createContext(DEFAULT_CAP);

        (uint256 weight,) = hook.beforePayRecordedWith(context);

        assertEq(weight, context.weight);
    }

    function test_paymentOverCap_reverts() public {
        JBBeforePayRecordedContext memory context = _createContext(DEFAULT_CAP + 1);

        vm.expectRevert(
            abi.encodeWithSelector(PaymentCapHook.PaymentExceedsCap.selector, DEFAULT_CAP + 1, DEFAULT_CAP)
        );
        hook.beforePayRecordedWith(context);
    }

    function test_setCapFor() public {
        uint256 newCap = 5 ether;

        vm.prank(owner);
        hook.setCapFor(PROJECT_ID, newCap);

        assertEq(hook.capOf(PROJECT_ID), newCap);
        assertEq(hook.getEffectiveCap(PROJECT_ID), newCap);
    }

    function test_setCapFor_onlyOwner() public {
        vm.prank(payer);
        vm.expectRevert();
        hook.setCapFor(PROJECT_ID, 5 ether);
    }

    function test_projectSpecificCap() public {
        uint256 projectCap = 2 ether;

        vm.prank(owner);
        hook.setCapFor(PROJECT_ID, projectCap);

        // Payment at project cap should succeed
        JBBeforePayRecordedContext memory context = _createContext(projectCap);
        (uint256 weight,) = hook.beforePayRecordedWith(context);
        assertEq(weight, context.weight);

        // Payment over project cap should fail
        context = _createContext(projectCap + 1);
        vm.expectRevert();
        hook.beforePayRecordedWith(context);
    }

    function test_zeroProjectCap_usesDefault() public {
        // Set and then clear project cap
        vm.startPrank(owner);
        hook.setCapFor(PROJECT_ID, 5 ether);
        hook.setCapFor(PROJECT_ID, 0);
        vm.stopPrank();

        assertEq(hook.getEffectiveCap(PROJECT_ID), DEFAULT_CAP);
    }

    function testFuzz_paymentUnderCap(uint256 amount) public view {
        vm.assume(amount <= DEFAULT_CAP);
        vm.assume(amount > 0);

        JBBeforePayRecordedContext memory context = _createContext(amount);
        (uint256 weight,) = hook.beforePayRecordedWith(context);

        assertEq(weight, context.weight);
    }

    function _createContext(uint256 amount) internal view returns (JBBeforePayRecordedContext memory) {
        return JBBeforePayRecordedContext({
            terminal: address(0),
            payer: payer,
            amount: JBTokenAmount({
                token: address(0),
                value: amount,
                decimals: 18,
                currency: 0
            }),
            projectId: PROJECT_ID,
            rulesetId: 1,
            beneficiary: payer,
            weight: 1e18,
            reservedRate: 0,
            metadata: ""
        });
    }
}
