// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Ownable} from "solady/auth/Ownable.sol";
import {ERC721} from "solady/tokens/ERC721.sol";
import {ReentrancyGuard} from "solady/utils/ReentrancyGuard.sol";

import {BASIS_POINTS, IHarbergerNFT, SECONDS_PER_YEAR, TAX_RATE_BPS} from "./IHarbergerNFT.sol";

/**
 * @title Harberger Tax NFT
 * @notice An ERC721 implementation where owners self-assess value and pay a continuous tax. Owners
 *         can update their asset price, according to some rules.
 *         Token is always purchasable at the given price by anyone (excess refunded).
 * @dev Uses Solady for gas-optimized ERC721 implementation. Non-reentrant guards added to
 *      functions calling `_settleTax` as it contains external calls.
 */
abstract contract HarbergerNFT is IHarbergerNFT, ERC721, Ownable, ReentrancyGuard {
    /// @notice The treasury address where taxes are sent.
    address public treasury;

    struct TokenInfo {
        uint256 price;
        uint256 deposit;
        uint256 lastSettled;
        uint256 debt;
    }

    /// @notice Mapping from tokenId to its Harberger tax info.
    mapping(uint256 => TokenInfo) public tokenInfos;

    /// @notice Counter for token IDs.
    uint256 private _nextTokenId;

    constructor(address _treasury) {
        _initializeOwner(msg.sender);
        treasury = _treasury;
    }

    ////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////// EXTERNAL ///////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Buy the token at the current self-assessed price.
    function buy(uint256 tokenId) external payable nonReentrant {
        TokenInfo storage info = tokenInfos[tokenId];
        address seller = ownerOf(tokenId);

        uint256 taxDue = _settleTax(tokenId);

        if (ownerOf(tokenId) != seller) revert TokenForeclosed();

        uint256 price = info.price;
        if (msg.value < price) revert InsufficientPayment();

        uint256 surplus = msg.value - price;

        _transfer(seller, msg.sender, tokenId);

        uint256 sellerRefund = price + info.deposit - taxDue - surplus;

        info.deposit = 0;
        info.lastSettled = block.timestamp;

        if (surplus > 0) {
            (bool success,) = msg.sender.call{value: surplus}("");
            if (!success) revert TransferFailed();
        }

        (bool successSeller,) = seller.call{value: sellerRefund}("");
        if (!successSeller) revert TransferFailed();

        emit TokenBought(tokenId, msg.sender, price);
    }

    /// @notice Admin can relist foreclosed asset.
    function relistForeclosed(uint256 tokenId, uint256 initialPrice) external payable {
        /// TDB
    }

    /// @notice Adds funds to the tax deposit for a token.
    function deposit(uint256 tokenId) external payable nonReentrant {
        _settleTax(tokenId);
        tokenInfos[tokenId].deposit += msg.value;
        emit DepositAdded(tokenId, msg.value);
    }

    /// @notice Allows anyone to trigger tax settlement. If insolvent, forecloses the token.
    function settleTax(uint256 tokenId) external nonReentrant {
        _settleTax(tokenId);
    }

    /**
     * @notice Mints a new token.
     * @param initialPrice The self-assessed price of the token.
     * @dev Requires sending some ETH.ish to cover the initial tax deposit.
     */
    function mint(uint256 initialPrice) external payable {
        if (initialPrice == 0) revert PriceCannotBeZero();

        uint256 tokenId = ++_nextTokenId;

        tokenInfos[tokenId] =
            TokenInfo({price: initialPrice, deposit: msg.value, lastSettled: block.timestamp, debt: 0});

        _mint(msg.sender, tokenId);

        emit DepositAdded(tokenId, msg.value);
    }

    /**
     * @notice Updates the self-assessed price.
     * @dev Settles taxes before updating.
     */
    function setPrice(uint256 tokenId, uint256 newPrice) external nonReentrant {
        if (ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        if (newPrice == 0) revert PriceCannotBeZero();
        if (tokenInfos[tokenId].lastSettled == 0) revert AssetForeclosed();

        _settleTax(tokenId);

        if (ownerOf(tokenId) != msg.sender) revert TokenForeclosed();

        tokenInfos[tokenId].price = newPrice;
        emit PriceUpdated(tokenId, newPrice);
    }

    ////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////// INTERNAL ///////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    function _transferTax(uint256 taxDue, uint256 tokenId, TokenInfo storage info) internal {
        if (taxDue == 0) return;

        info.lastSettled = block.timestamp;
        info.deposit -= taxDue;

        (bool success,) = treasury.call{value: taxDue}("");
        if (!success) revert UnableToPayTax();

        emit TaxPaid(tokenId, taxDue);
    }

    /// @notice Calculates and processes tax. Triggers foreclosure if insolvent.
    function _settleTax(uint256 tokenId) internal returns (uint256 taxDue) {
        TokenInfo storage info = tokenInfos[tokenId];

        address currentOwner = _ownerOf(tokenId);
        if (currentOwner == address(this) || currentOwner == address(0)) return 0;

        taxDue = _taxDue(info.lastSettled, info.price);
        if (taxDue == 0) return 0;

        if (_shouldForeclose(taxDue, info.deposit)) {
            uint256 taxPaid = info.deposit;
            info.debt = taxDue - taxPaid;
            info.price = 0;

            _transferTax(taxPaid, tokenId, info);

            info.lastSettled = 0;

            _transfer(currentOwner, address(this), tokenId);
            emit Foreclosed(tokenId, currentOwner, info.debt);
        } else {
            _transferTax(taxDue, tokenId, info);
        }
    }

    //////// VIEW
    function _taxDue(uint256 lastSettled, uint256 price) internal view returns (uint256 taxDue) {
        uint256 timeElapsed = block.timestamp - lastSettled;
        if (timeElapsed == 0) return 0;

        taxDue = (price * TAX_RATE_BPS * timeElapsed) / (BASIS_POINTS * SECONDS_PER_YEAR);
    }

    //////// PURE
    function _shouldForeclose(uint256 taxDue, uint256 currentDeposit) internal pure returns (bool) {
        return taxDue > currentDeposit;
    }
}
