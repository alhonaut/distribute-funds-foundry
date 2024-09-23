// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract SendERC {
    using SafeERC20 for IERC20; // use safe transfer to avoid DOS attacks with specific types of ERC tokens
    error InvalidList();
    error TransferFailed();
    error NotEnoughMoney();

    mapping(address => uint256) public balances;

    function distributeWithPercentages(
        address[] calldata list,
        uint256[] calldata percentage,
        address token
    ) public payable {
        uint256 listLength = list.length; // avoid multiple reading from storage and save gas
        if (listLength != percentage.length) {
            revert InvalidList();
        }
        IERC20 ercToken;
        uint256 balance;

        if (token != address(0)) {
            ercToken = IERC20(token);
            balance = ercToken.balanceOf(address(this));
        }

        uint256 totalValue = token == address(0) ? msg.value : balance; // to not iterate in loop

        for (uint256 i = 0; i < listLength; ) {
            uint256 amount = (totalValue * percentage[i]) / 100;

            if (token == address(0)) {
                (bool succ, ) = payable(list[i]).call{value: amount}("");
                if (!succ) revert TransferFailed();
            } else {
                ercToken.safeTransfer(list[i], amount);
            }

            unchecked {
                ++i;
            }
        }
    }

    function distributeWithAmounts(
        address[] calldata list,
        uint256[] calldata amounts,
        address token
    ) public payable {
        uint256 listLength = list.length; // avoid multiple reading from storage and save gas
        if (listLength != amounts.length) {
            revert InvalidList();
        }
        IERC20 ercToken;
        uint256 balance;

        if (token != address(0)) {
            ercToken = IERC20(token);
            balance = ercToken.balanceOf(address(this));
        }

        uint256 totalValue = token == address(0) ? msg.value : balance; // to not iterate in loop

        for (uint256 i = 0; i < listLength; ) {
            if (totalValue < amounts[i]) revert NotEnoughMoney();

            if (token == address(0)) {
                (bool succ, ) = payable(list[i]).call{
                    value: amounts[i] * 1 ether
                }("");
                if (!succ) revert TransferFailed();
            } else {
                ercToken.safeTransfer(list[i], amounts[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    function collectWithPercentage(
        address[] calldata senders,
        uint256[] calldata percentage,
        address token,
        address receiver
    ) public {
        uint256 senderLength = senders.length;
        IERC20 ercToken = IERC20(token);

        for (uint256 i = 0; i < senderLength; ) {
            if (token == address(0)) {
                uint256 amount = (balances[senders[i]] * percentage[i]) / 100;
                (bool succ, ) = payable(receiver).call{value: amount}("");
                if (!succ) revert TransferFailed();
            } else {
                uint256 amount = (ercToken.balanceOf(senders[i]) *
                    percentage[i]) / 100;
                ercToken.safeTransferFrom(senders[i], receiver, amount);
            }

            unchecked {
                ++i;
            }
        }
    }

    function collectWithAmount(
        address[] calldata senders,
        uint256[] calldata amounts,
        address token,
        address receiver
    ) public {
        uint256 senderLength = senders.length;
        IERC20 ercToken = IERC20(token);

        for (uint256 i = 0; i < senderLength; ) {
            if (token == address(0)) {
                if (balances[senders[i]] < amounts[i] * 1 ether)
                    revert NotEnoughMoney();
                (bool succ, ) = payable(receiver).call{
                    value: amounts[i] * 1 ether
                }("");
                if (!succ) revert TransferFailed();
            } else {
                if (ercToken.balanceOf(senders[i]) < amounts[i])
                    revert NotEnoughMoney();
                ercToken.safeTransferFrom(senders[i], receiver, amounts[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    receive() external payable {
        balances[msg.sender] = msg.value;
    }
}
