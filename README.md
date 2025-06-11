# 🛒 Solidity Auction Contract with Refunds, Commissions, and Time Extensions

A secure and transparent auction contract built in Solidity for a single-item bidding system, with commission handling, time extension mechanics, and participant refund logic.

---

## 📜 Overview

This smart contract enables a seller to host a time-bound auction where multiple participants can place bids on a single item. The auction includes:

- **Minimum entry bid** required to participate.
- **Time extension** if bids are made near the end.
- **5% increment rule** over the current highest bid.
- **Refunds** for non-winning bidders (with 2% commission).
- **Partial refund** during the auction.
- **Separate withdrawals** for seller earnings and developer commissions.

> This version is intended for a one-time auction of a single item. For reusable or multi-item auctions, future versions may be developed.

---

## ✨ Features

- 2% commission retained from all refunds and seller payout.
- `distributeRefunds()` for refunds to all offers after the auction.
- `partialClaim()` during the auction for unused bid portions.
- `claimProduct()` the winner can claim the product when auction is closed.
- `withdrawSafeBox()` Developer can withdraw the commission.
- `withdrawSellerFunds()` The seller can withdraw the ETH earned in auction.
- Safe fund handling via access control modifiers and clearly separated logic.
- Event logging for all key actions.
- Reentrancy-resistant logic pattern.
- `emergencyWithdraw()` allows fallback recovery if needed after auction ends.

---

## ⚙️ Constructor Parameters

```solidity
constructor(uint256 _duration, uint256 _entryBid)

    _duration: Auction duration in seconds.

    _entryBid: Minimum bid in wei required to participate.

Example (for testing):

    _duration: 120 (seconds)

    _entryBid: 1 ETH → 1000000000000000000
```
🚀 Deployment

You can deploy the contract using Remix, Hardhat, or Foundry.
Remix (Quick Test)

    Open Remix IDE

    Paste the contract code into a new .sol file.

    Compile the contract using the Solidity compiler (v0.8+).

    Deploy the contract via the Deploy panel:

        Provide _duration and _entryBid (in wei).

        The deploying address initially acts as both seller and developer.

    ⚠️ Ensure the deploying account is trusted, as it will control both withdrawals.

🧠 Core Functions
Function	Description
setBid()	Place a new bid ≥ 5% higher than current highest bid.
claimDeposit()	Refund for non-winners after auction ends (98% returned).
partialClaim()	Withdraw unused bid amount during the auction.
claimProduct()	Winner claims product after auction ends.
withdrawSellerFunds()	Seller withdraws 98% of winning bid.
withdrawSafeBox()	Developer withdraws 2% commissions from refunds/sales.
showWinner()	Emit event with winner address and amount.
showAllBids()	List all current bidders and their total bids.
getBuyerInfo(address)	View bidding details of a specific participant.
getBuyerAddresses()	Retrieve full list of participating addresses.
emergencyWithdraw()	Owner fallback withdrawal after auction is finalized (safety mechanism).

⏳ Auction Lifecycle

    Deployment: Seller deploys the contract with a defined duration and entry bid.

    Bidding Phase: Participants place bids ≥ entry bid and ≥ 5% more than the highest.

    Time Extension: If a bid is placed within the last 10 minutes, the auction extends.

    Closure: Once time ends, no new bids are accepted.

    Settlement Phase:

        Winner calls claimProduct().

        Non-winners call claimDeposit().

        Seller calls withdrawSellerFunds().

        Developer calls withdrawSafeBox().

🧪 Events
Event	Description
NewBidEvent(bidder, amount)	Emitted on new valid bid.
AuctionExtended(newEndTime)	Emitted when the auction time is extended.
WinnerAnnounced(winner, amount)	Emitted when the winner is declared.
AuctionFinished(winner, amount)	Emitted when the auction ends.
ProductClaimed(winner)	Emitted when the product is claimed.
PartialClaimEvent(user, amount)	Emitted when a user withdraws unused bid portions.

🧪 Debugging Events (for development only)

    DebugLog(...)

    DebugClaim(...)

🔐 Security & Assumptions

    No reentrancy vulnerabilities due to safe ordering of state changes and transfers.

    All fund transfers occur only after internal state updates.

    The contract assumes seller and developer are the same address upon deployment. This can be decoupled in future versions with role-based access control.


📁 File Structure

Auction.sol
README.md

👨‍💻 Author

Hiskander Aguillon  
[GitHub](https://github.com/Hskndr) • [LinkedIn](https://www.linkedin.com/in/hiskander-aguillon/)

Feel free to contribute or reach out with improvements, suggestions, or bug reports.

