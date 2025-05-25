// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {console} from "forge-std/console.sol";

contract ClaimAirdrop is Script {
    error __ClaimAirdropScript__InvaldidSignatureLength();

    address CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Example address to claim
    uint256 amountToClaim = 25 * 1e18; // Example claim amount
    bytes32 proofOne = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes private signature =
        hex"b4f3b01da6662e20e9b699c362ec34d32b656eb05f13ae2ed0d60c378aaabadb6af8de518a49e779b76ff7fa604b111e7ad2d1c51927c3ac0cae28385efeb2a41b";
    bytes32[] PROOF = new bytes32[](2);

    function run() external {
        address mostrecentlydeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostrecentlydeployed);
    }

    function claimAirdrop(address airdropAddress) public {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        PROOF[0] = proofOne;
        PROOF[1] = proofTwo;
        vm.startBroadcast();
        MerkleAirdrop(airdropAddress).claim(PROOF, amountToClaim, CLAIMING_ADDRESS, v, r, s);
        vm.stopPrank();
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        if (sig.length != 65) {
            revert __ClaimAirdropScript__InvaldidSignatureLength();
        }
        assembly {
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
            v := byte(0, mload(add(sig, 0x60)))
        }
    }
}
