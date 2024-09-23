// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SendERC} from "../src/Test.sol";
import {MockERC20} from "./mock/MockERC20.sol";

contract SendERCTest is Test {
    SendERC public sendErc;
    MockERC20 public mockErc;
    address public wallet1;
    address public wallet2;
    address public wallet3;
    address receiver; // test only for percentages
    address receiver1; // test only for amounts

    address[] public addressList;
    uint256[] public percentageList;
    uint256[] public amountsList;

    function setUp() public {
        sendErc = new SendERC();
        mockErc = new MockERC20("Test Token", "TST", 10_000_000);

        wallet1 = vm.addr(1);
        addressList.push(wallet1);
        wallet2 = vm.addr(2);
        addressList.push(wallet2);
        wallet3 = vm.addr(3);
        addressList.push(wallet3);

        percentageList.push(15);
        percentageList.push(35);
        percentageList.push(50);

        amountsList.push(5);
        amountsList.push(5);
        amountsList.push(5);

        receiver = vm.addr(69);
        receiver1 = vm.addr(666);

        mockErc.mint(address(sendErc), 1000_000);
    }

    function test_distributeTokensWithPercentages() public {
        sendErc.distributeWithPercentages(
            addressList,
            percentageList,
            address(mockErc)
        );

        assertEq(
            mockErc.balanceOf(wallet1),
            150_000,
            "wallet1 should have 300,000 TST"
        );
        assertEq(
            mockErc.balanceOf(wallet2),
            350_000,
            "wallet1 should have 350,000 TST"
        );
        assertEq(
            mockErc.balanceOf(wallet3),
            500_000,
            "wallet1 should have 500,000 TST"
        );
    }

    function test_distributeEthersWithPercentages() public {
        sendErc.distributeWithPercentages{value: 1000 ether}(
            addressList,
            percentageList,
            address(0)
        );

        assertEq(wallet1.balance, 150 ether, "wallet1 should have 150 ETH");
        assertEq(wallet2.balance, 350 ether, "wallet2 should have 350 ETH");
        assertEq(wallet3.balance, 500 ether, "wallet3 should have 500 ETH");
    }

    function test_distributeTokensWithAmounts() public {
        sendErc.distributeWithPercentages(
            addressList,
            amountsList,
            address(mockErc)
        );

        assertEq(mockErc.balanceOf(wallet1), 50_000);
        assertEq(mockErc.balanceOf(wallet2), 50_000);
        assertEq(mockErc.balanceOf(wallet3), 50_000);
    }

    function test_distributeEthersWithAmounts() public {
        sendErc.distributeWithAmounts{value: 1000 ether}(
            addressList,
            amountsList,
            address(0)
        );

        assertEq(wallet1.balance, 5 ether, "wallet1 should have 5 ETH");
        assertEq(wallet2.balance, 5 ether, "wallet2 should have 5 ETH");
        assertEq(wallet3.balance, 5 ether, "wallet3 should have 5S ETH");
    }

    function test_collectTokensWithPercentages() public {
        mockErc.mint(wallet1, 1000_000);
        vm.prank(wallet1);
        mockErc.approve(address(sendErc), type(uint256).max);

        mockErc.mint(wallet2, 1000_000);
        vm.prank(wallet2);
        mockErc.approve(address(sendErc), type(uint256).max);

        mockErc.mint(wallet3, 1000_000);
        vm.prank(wallet3);
        mockErc.approve(address(sendErc), type(uint256).max);

        sendErc.collectWithPercentage(
            addressList,
            percentageList,
            address(mockErc),
            receiver
        );
        uint256 balance = mockErc.balanceOf(receiver);
        assertEq(balance, 1000_000);
    }

    function test_collectEthersViaPercentages() public {
        vm.deal(wallet1, 100 ether);
        vm.prank(wallet1);
        (bool success, ) = address(address(sendErc)).call{value: 100 ether}("");
        require(success, "Transfer failed");

        vm.deal(wallet2, 100 ether);
        vm.prank(wallet2);
        (bool success1, ) = address(address(sendErc)).call{value: 100 ether}(
            ""
        );
        require(success1, "Transfer failed");

        vm.deal(wallet3, 100 ether);
        vm.prank(wallet3);
        (bool success2, ) = address(address(sendErc)).call{value: 100 ether}(
            ""
        );
        require(success2, "Transfer failed");

        sendErc.collectWithPercentage(
            addressList,
            percentageList,
            address(0),
            receiver
        );
        assertEq(receiver.balance, 100 ether);
    }

    function test_collectTokensWithAmounts() public {
        mockErc.mint(wallet1, 1000_000);
        vm.prank(wallet1);
        mockErc.approve(address(sendErc), type(uint256).max);

        mockErc.mint(wallet2, 1000_000);
        vm.prank(wallet2);
        mockErc.approve(address(sendErc), type(uint256).max);

        mockErc.mint(wallet3, 1000_000);
        vm.prank(wallet3);
        mockErc.approve(address(sendErc), type(uint256).max);

        sendErc.collectWithAmount(
            addressList,
            amountsList,
            address(mockErc),
            receiver1
        );
        uint256 balance = mockErc.balanceOf(receiver1);
        assertEq(balance, 15);
    }

    function test_collectEthersViaAmount() public {
        vm.deal(wallet1, 100 ether);
        vm.prank(wallet1);
        (bool success, ) = address(sendErc).call{value: 100 ether}("");
        require(success, "Transfer failed");

        vm.deal(wallet2, 100 ether);
        vm.prank(wallet2);
        (bool success1, ) = address(sendErc).call{value: 100 ether}("");
        require(success1, "Transfer failed");

        vm.deal(wallet3, 100 ether);
        vm.prank(wallet3);
        (bool success2, ) = address(address(sendErc)).call{value: 100 ether}(
            ""
        );
        require(success2, "Transfer failed");

        sendErc.collectWithAmount(
            addressList,
            amountsList,
            address(0),
            receiver1
        );
        assertEq(receiver1.balance, 15 ether);
    }
}
