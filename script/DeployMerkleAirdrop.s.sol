// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {FudoKen} from "src/FudoKen.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 private constant ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 private constant AMOUNT_TO_CLAIM = 25 * 1e18; // Example claim amount for the test user
    uint256 private constant AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4; // Total tokens to fund the airdrop contract

    function run() external returns (MerkleAirdrop airdrop, FudoKen token) {
        vm.startBroadcast();
        token = new FudoKen();
        airdrop = new MerkleAirdrop(ROOT, IERC20(address(token)));
        token.mint(token.owner(), AMOUNT_TO_SEND);
        token.transfer(address(airdrop), AMOUNT_TO_SEND);
        vm.stopBroadcast();

    }
}