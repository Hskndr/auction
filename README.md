# 🛒 Solidity Auction Contract

A secure and transparent auction contract built in Solidity for a single-item bidding system, with commission handling, time extension mechanics, and participant refund logic.

## 📜 Overview

This smart contract enables a seller to host a time-bound auction where multiple participants can place bids on a single item. The auction includes:

- **Minimum entry bid** required to participate.
- **Time extension** if bids are made near the end.
- **5% increment rule** over the current highest bid.
- **Refunds** for non-winning bidders (with 2% commission).
- **Partial refund** during the auction.
- **Separate withdrawals** for seller earnings and developer commissions.

## ✨ Features

- 2% commission retained from all refunds and seller payout.
- Seller and developer roles separated.
- `claimDeposit()` for refunds after the auction.
- `partialClaim()` during the auction for unused bid portions.
- Safe fund handling via modifiers and logic separation.
- Event logging for all key actions.
- Reentrancy-resistant logic pattern.

## ⚙️ Constructor Parameters

```solidity
constructor(uint256 _duration, uint256 _entryBid)

    _duration: Auction duration in seconds.

    _entryBid: Minimum amount in wei to enter the auction.

Example (for testing)

_duration: 120
_entryBid: 1000000000000000000 (1 ETH)

🚀 Deployment

You can deploy the contract using Remix, Hardhat, or Foundry.
Remix (Quick Test)

    Open Remix IDE

    Paste the contract code into a new .sol file.

    Compile the contract using the Solidity compiler (v0.8+).

    Deploy the contract using the Deploy panel:

        Provide _duration and _entryBid (in wei).

        The deploying address becomes both the seller and developer.

🧠 Core Functions
Function	Description
setBid()	Place a new bid. Must be at least 5% higher than the current highest bid.
claimDeposit()	Refund for non-winners after the auction ends (98% returned).
partialClaim()	Withdraw unused funds during the auction.
claimProduct()	Winner claims the product after auction ends.
withdrawSellerFunds()	Seller withdraws winning bid amount (98%).
withdrawSafeBox()	Developer withdraws accumulated commissions (2% from each refund/sale).
showWinner()	Emits event with winner address and amount after the auction ends.
showAllBids()	View all current bidders and their total bids.
getBuyerInfo(address)	View details for a specific participant.
getBuyerAddresses()	Retrieve list of all participant addresses.

⏳ Auction Lifecycle

    Deployment: Seller deploys contract with defined duration and entry bid.

    Bidding Phase: Participants place bids ≥ entry bid and ≥ 5% more than highest.

    Time Extension: If a bid is placed within last 10 minutes, auction extends.

    Closure: Once time ends, no new bids accepted.

    Settlement:

        Winner can claimProduct.

        Non-winners use claimDeposit.

        Seller withdraws earnings.

        Developer withdraws commissions.

🧪 Events
Event	Description
NewBidEvent(bidder, amount)	Emitted on new valid bid.
AuctionExtended(newEndTime)	When time is extended.
WinnerAnnounced(winner, amount)	Once winner is declared.
AuctionFinished(winner, amount)	Final auction result.
ProductClaimed(winner)	When product is claimed.
PartialClaimEvent(user, amount)	When user partially withdraws during auction.
DebugLog(...) & DebugClaim(...)	Internal tracking logs (optional).

🔐 Security & Assumptions

    No reentrancy vulnerabilities due to safe order of state changes and transfers.

    Seller and developer are the same on deployment but can be separated in future versions.

    Assumes use on EVM-compatible chain (e.g., Ethereum, Polygon, etc.).

📁 File Structure

```
Auction.sol
README.md
```

👨‍💻 Author

Hiskander Aguillon
Feel free to contribute or reach out with improvements, suggestions, or bug reports.