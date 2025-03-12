// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";

contract MerkleAirdropTest is Test {
    MerkleAirdrop public airdrop;
    BagelToken public token;
    uint256 public AMOUNT_TO_MINT = 4;
    bytes32 proofOne =
        0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo =
        0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    uint256 public AMOUNT = 25 * 1e18;
    uint256 AMOUNT_TO_CLAIM = AMOUNT * AMOUNT_TO_MINT;
    bytes32[] public proof = [proofOne, proofTwo];
    bytes32 public root =
        0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    address user;
    uint256 userPrivKey;
    address public gasPayer;

    function setUp() public {
        token = new BagelToken();
        airdrop = new MerkleAirdrop(root, token);
        token.mint(token.owner(), AMOUNT * AMOUNT_TO_MINT);
        token.transfer(address(airdrop), AMOUNT * AMOUNT_TO_MINT);
        (user, userPrivKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
    }

    function testUsersCanClaim() public {
        uint256 startingBalance = token.balanceOf(user);
        bytes32 digest = airdrop.getMessageHash(user, AMOUNT);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey, digest);
        uint256 endingBalance = airdrop.claim(user, AMOUNT, proof, v, r, s);
        assertEq(endingBalance - startingBalance, AMOUNT);
    }
}
