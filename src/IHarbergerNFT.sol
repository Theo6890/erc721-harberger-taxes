// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

// @notice The tax rate in basis points per second.
uint256 constant TAX_RATE_BPS = 1000; // 10%
uint256 constant BASIS_POINTS = 10_000;
// @dev Seconds in year = 60 * 60 * 24 * 365 = 31,536,000.
uint256 constant SECONDS_PER_YEAR = 31_536_000;

interface IHarbergerNFT {
    /////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////// ERROS /////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////

    error AssetForeclosed();
    error InsufficientPayment();
    error NotForeclosed();
    error NotTokenOwner();
    error Only2StepOwnershipTransfer();
    error PriceCannotBeZero();
    error TaxDepositTooLow();
    error TokenForeclosed();
    error TransferFailed();
    error UnableToPayTax();

    ////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////// EVENTS ////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    event DepositAdded(uint256 indexed tokenId, uint256 amount);
    event Foreclosed(uint256 indexed tokenId, address previousOwner, uint256 debt);
    event PriceUpdated(uint256 indexed tokenId, uint256 newPrice);
    event TaxPaid(uint256 indexed tokenId, uint256 amount);
    event TokenBought(uint256 indexed tokenId, address indexed buyer, uint256 price);
}
