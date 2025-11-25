// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {HarbergerNFTView} from "src/HarbergerNFTView.sol";

contract HarbergerNFTView_Test is Test {
    HarbergerNFTView public nft;
    address public treasury;
    address public alice;
    address public bob;

    function setUp() public {
        treasury = makeAddr("treasury");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        nft = new HarbergerNFTView(treasury);

        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
    }

    function testMint() public {
        vm.prank(alice);
        nft.mint{value: 1 ether}(10 ether);

        assertEq(nft.ownerOf(1), alice);
        (uint256 price, uint256 deposit, , ) = nft.tokenInfos(1);
        assertEq(price, 10 ether);
        assertEq(deposit, 1 ether);
    }

    function testTaxAccrual() public {
        vm.prank(alice);
        nft.mint{value: 1 ether}(10 ether);

        vm.warp(block.timestamp + 365 days);

        vm.prank(alice);
        nft.deposit{value: 0.1 ether}(1);

        (, uint256 deposit, , ) = nft.tokenInfos(1);

        assertApproxEqAbs(deposit, 0.1 ether, 0.001 ether);

        assertEq(treasury.balance, 1 ether);
    }

    function testBuy() public {
        vm.prank(alice);
        nft.mint{value: 1 ether}(10 ether);

        vm.warp(block.timestamp + 182.5 days);

        vm.prank(bob);
        nft.buy{value: 10 ether}(1);

        assertEq(nft.ownerOf(1), bob);

        assertApproxEqAbs(alice.balance, 109.5 ether, 0.001 ether);

        assertApproxEqAbs(treasury.balance, 0.5 ether, 0.001 ether);
    }

    function test_settleTax() public {
        vm.prank(alice);
        nft.mint{value: 0.5 ether}(10 ether);

        vm.warp(block.timestamp + 365 days);

        nft.settleTax(1);

        assertEq(nft.ownerOf(1), address(nft));

        assertEq(treasury.balance, 0.5 ether);
    }
}
