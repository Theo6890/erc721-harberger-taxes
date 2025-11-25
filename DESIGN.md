# Harberger Tax NFT Design

## Overview

This project implements an ERC721 token with a Harberger Tax mechanism. The core principle is **Partial Common Ownership**: owners self-assess the value of their assets, pay a continuous tax on that value, and must sell to anyone willing to pay that value.

## Tax Model

- **Rate**: Fixed at 10% per year (1000 basis points).
- **Basis**: The tax is calculated on the self-assessed price set by the owner.
- **Accrual**: Continuous (per second).
- **Formula**: `Tax = (Price * Rate * TimeElapsed) / (YearSeconds * BasisPoints)`
- **Settlement**: Taxes are settled lazily whenever the token state changes (transfer, price update, deposit) or manually via `foreclose()`.

## Payment Mechanism

- **Deposit Pattern**: Each token has a dedicated ETH deposit balance stored in the contract.
- **Deduction**: Accrued taxes are deducted from this deposit.
- **Top-up**: Owners (or anyone) can top up the deposit at any time via `deposit()`.
- **Refund**: When a token is sold, the remaining deposit is refunded to the seller.

## Foreclosure

- **Trigger**: If `TaxDue > Deposit`, the token is insolvent.
- **Consequence**:
  1. The remaining deposit is seized as tax.
  2. The token ownership is transferred to the contract (`address(this)`).
  3. The price is reset to 0.
- **Recovery**: The owner must relist the foreclosed asset to allow new owner to buy.

## Trade-offs & Simplifications

- **Per-Token Deposit**: We chose per-token deposits over per-user balances for clearer isolation and simpler foreclosure logic. This prevents one "bad" asset from draining a user's funds for other assets.
- **Foreclosure to Contract**: Admin which handles the tax treasury must relist the token to be able to buy. We could aslo do an auction like in real world cases.
- **Global Tax Rate**: The rate is hardcoded for simplicity but could be made governance-adjustable.

## Security Considerations

- **Reentrancy**: We follow the Checks-Effects-Interactions pattern. Transfers (which can trigger hooks) happen after state updates.
- **Solvency Check**: We check solvency before allowing price updates or transfers to prevent gaming the system (e.g., lowering price right before a tax tick).

- **Test Coverage**: Incomplete test case, not all branches are covered yet.
