// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {FudoKen} from "src/FudoKen.sol";
import {console} from "forge-std/console.sol";

import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployMerkleAirdrop} from "script/DeployMerkleAirdrop.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MerkleAirdropTest is Test, ZkSyncChainChecker {
    // Inside MerkleAirdropTest contract
    MerkleAirdrop public airdrop;
    FudoKen public token;

    // This ROOT value is derived from your Merkle tree generation script
    // It will be updated later in the process
    bytes32 public ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public AMOUNT_TO_CLAIM = 25 * 1e18; // Example claim amount for the test user
    uint256 public AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4; // Total tokens to fund the airdrop contract

    // User-specific data
    address user;
    uint256 userPrivKey; // Private key for the test user
    address gasPayer = makeAddr("gasPayer");

    // Merkle Proof for the test user
    // The structure (e.g., bytes32[2]) depends on your Merkle tree's depth
    // These specific values will be populated from your Merkle tree output
    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proofOne, proofTwo];

    function setUp() external {
        if (!isZkSyncChain()) {
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (airdrop, token) = deployer.run();
        } else {
            token = new FudoKen();
            airdrop = new MerkleAirdrop(ROOT, token);
            token.mint(address(this), AMOUNT_TO_SEND);
            token.transfer(address(airdrop), AMOUNT_TO_SEND);
        }

        (user, userPrivKey) = makeAddrAndKey("user");
    }

    function testUserClaim() external {
        uint256 startingBalance = token.balanceOf(user);

        bytes32 digest = airdrop.getMessage(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey, digest);

        vm.startPrank(gasPayer);
        airdrop.claim(PROOF, AMOUNT_TO_CLAIM, user,v,r,s);
        uint256 endingBalance = token.balanceOf(user);

        console.log("Starting balance:", startingBalance);
        console.log("Ending balance:", endingBalance);

        assertEq(endingBalance, startingBalance + AMOUNT_TO_CLAIM, "User should receive the claimed amount");
        assertTrue(airdrop.isClaimed(user), "User should have claimed their tokens");
        vm.stopPrank();
    }
}
