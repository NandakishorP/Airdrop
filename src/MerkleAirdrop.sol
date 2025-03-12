// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;
    error MerkleProof__InvalidProof();
    error MerkleAirdrop__RewardAlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();
    // address[] claimers;
    mapping(address claimer => bool claimed) private s_hasClaimed;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;

    constructor(
        bytes32 merkleRoot,
        IERC20 airdropToken
    ) EIP712("MerkeAirdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    bytes32 private constant MESSAGE_TYPEHASH =
        keccak256("AirdropClaim(address account,uint256 amount)");

    event Claim(address indexed account, uint256 amount);
    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    function getMessageHash(
        address account,
        uint256 amount
    ) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        MESSAGE_TYPEHASH,
                        AirdropClaim({account: account, amount: amount})
                    )
                )
            );
    }

    function _isValidSignature(
        address account,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
        (address actualSigner, , ) = ECDSA.tryRecover(digest, v, r, s);
        return actualSigner == account;
    }

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 endingBalance) {
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__RewardAlreadyClaimed();
        }
        if (
            !_isValidSignature(
                account,
                getMessageHash(account, amount),
                v,
                r,
                s
            )
        ) {
            revert MerkleAirdrop__InvalidSignature();
        }

        // using the account and the amount
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(account, amount)))
        ); // its standerd to do it twice to avoid any duplicate hash production,
        //its just a saftey measure and the concat is effectively converting the hash into a converted bytes32 array and it gets hashed again]
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleProof__InvalidProof();
        }
        s_hasClaimed[account] = true;
        emit Claim(account, amount);
        i_airdropToken.safeTransfer(account, amount);
        endingBalance = i_airdropToken.balanceOf(account);
    }

    function getMerkleRoot() external view returns (bytes32) {}

    function getAirdropToken() external view returns (IERC20) {}
}
