// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {LibString} from "solady/utils/LibString.sol";

import {HarbergerNFT} from "./HarbergerNFT.sol";

/**
 * @title Harberger NFT View
 * @notice Instantiable HarbergerNFT contract which adds read only functions.
 * @dev Split storage update and read only for maintainability.
 */
contract HarbergerNFTView is HarbergerNFT {
    using LibString for uint256;

    constructor(address _treasury) HarbergerNFT(_treasury) {}

    function transferOwnership(address) public payable override {
        revert Only2StepOwnershipTransfer();
    }

    function name() public pure override returns (string memory) {
        return "HarbergerNFT";
    }

    function symbol() public pure override returns (string memory) {
        return "HBNFT";
    }

    /// @dev Centralised metadata hosting for simplicity.
    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        return string.concat(string.concat("https://example.com/harberger-nft-metadata/", tokenId.toString()), ".json");
    }
}
