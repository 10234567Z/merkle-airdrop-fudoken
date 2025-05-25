// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {console} from "forge-std/console.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    event Claimed(address indexed account, uint256 amount);

    bytes32 private constant MESSAGE_TYPEHASH = 0x810786b83997ad50983567660c1d9050f79500bb7c2470579e75690d45184163;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_baseToken;
    mapping(address account => bool claimed) private s_claimed;

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    constructor(bytes32 merkleRoot, IERC20 baseToken) EIP712("MerkleAirdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_baseToken = baseToken;
    }

    function claim(bytes32[] calldata merkleProof, uint256 amount, address account, uint8 v, bytes32 r, bytes32 s)
        external
    {
        if (s_claimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        bytes32 digest = getMessage(account, amount);
        if (!_isValidSignature(account, digest, v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        s_claimed[account] = true;
        emit Claimed(account, amount);
        i_baseToken.safeTransfer(account, amount);
    }


    function _isValidSignature(address expecedAccount, bytes32 digest, uint8 v, bytes32 r, bytes32 s) internal pure returns(bool) {
        (address recoveredAddress,,) = ECDSA.tryRecover(digest,v,r,s);
        return recoveredAddress != address(0) && recoveredAddress == expecedAccount;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getBaseToken() external view returns (IERC20) {
        return i_baseToken;
    }

    function isClaimed(address account) external view returns (bool) {
        return s_claimed[account];
    }

    function getMessage(address account, uint256 amount) public view returns (bytes32 digest) {
        bytes32 structhash = keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount})));
        digest = _hashTypedDataV4(structhash);
    }
}
