// SPDX-License-Identifier: MIT
pragma solidity  ^0.8;

/// @title Auction contract for one article
/// @author Hiskander Aguillon
/// @notice This contract implements a secure auction with bid management and partial refunds
/// @dev Includes bid extensions, 2% commission, and event logging
/// @dev For quick deploy test use 120,1000000000000000000 and change EXTENSION_TIME to 120
/// @dev For Test - Times
            // 1 hour - 3600
            // 1 day - 86400
            // 1 week - 604800
/// @dev When auction is closed, use showWinner to emit final result

contract Auction {
    // Minimum entry bid
    uint256 public entryBid = 1000000000000000000; 

    /// @notice Address of the current highest bidder
    address public highestBidder;

    /// @notice Value of the highest bid submitted
    uint256 public highestBid;

    /// @notice Seller's wallet address
    address public seller;
    address private developer;
    bool private sellerPaid = false;
    
    struct Buyer {
        string nombre;
        uint256 totalBid;          ///< Total deposited by the buyer
        uint256 lastValidBid;      ///< Last valid bid counted in the auction
        bool claimed;              ///< Whether the user has claimed refund or not
        bool productClaimed;        ///< Whether the user is winner and claimed the product
    }

    /// @notice Mapping of buyers by address
    mapping(address => Buyer) private buyers;

    /// @notice List of all bidder addresses
    address[] private buyerAddresses; 

    /// @notice Timestamp when the auction started
    uint256 private startAuctionTimestamp;

    /// @notice Timestamp when the auction ends
    uint256 public auctionEndTime;

    /// @notice Duration added when bids are placed in the last 10 minutes
    uint256 constant EXTENSION_TIME = 600;

    /// @notice Tracks whether the winner was already announced
    bool public winnerAnnounced = false;

    /// @notice Accumulated commission from refunds (2%)
    uint256 private safeBox = 0;


    /// @notice Initializes the auction parameters
    /// @param _duration Duration of the auction in seconds
    /// @param _entryBid Minimum bid to enter the auction
    constructor (uint256 _duration, uint256 _entryBid) {

        require(_entryBid >= entryBid, "Bid too low"); ///< Check min bid
        entryBid = _entryBid; 
        seller = msg.sender; ///< Address who deployed is the seller
        developer = msg.sender; ///< Developer and Seller are the same for now
        startAuctionTimestamp = block.timestamp; ///< Start auction time
        auctionEndTime = block.timestamp + _duration; ///< Define auction duration

    }

    /// @notice Returns the remaining time for the auction
    /// @return Seconds remaining until the auction ends
    function getTimeRemaining() public view returns (uint256) {
        if (block.timestamp >= auctionEndTime) {
            return 0;
        } else {
            return auctionEndTime - block.timestamp;
        }
    }

    /// @notice Allows a participant to place a bid
    /// @dev Requires 5% increment over highest bid and may extend time
    function setBid( ) external payable whileAuctionOpen {

        // Checking the seller can't set a Bid
        require(msg.sender != seller, "Seller cannot bid");
        require(msg.value > 0, "Must send ETH to bid");

        uint256 newDeposit = msg.value;
        Buyer storage buyer = buyers[msg.sender];

        // New Bidder
        if (buyer.totalBid == 0) {
            buyerAddresses.push(msg.sender);
        }
        buyer.totalBid += newDeposit;
        
        // Find the Last Valid Bid
        uint256 proposedBid = newDeposit;
        uint256 minRequired = highestBid == 0 ? entryBid : highestBid + (highestBid * 5) / 100;

        require(proposedBid >= minRequired, "Bid must exceed highest by 5%");

        // Update the Last Valid Bid
        buyer.lastValidBid = proposedBid;
        highestBid = proposedBid;
        highestBidder = msg.sender;

        // Auction time extension  of 10 minutes
        if (auctionEndTime - block.timestamp <= EXTENSION_TIME) {
            auctionEndTime = block.timestamp + EXTENSION_TIME;
            emit AuctionExtended(auctionEndTime);
        }

        emit NewBidEvent(msg.sender, buyer.totalBid);
        emit DebugLog("New highestBidder", highestBidder, highestBid);

    }

    /// @notice Displays the winner of the auction after it ends
    function showWinner () external whenAuctionClosed {
        require(!winnerAnnounced, "Winner already announced");

        emit WinnerAnnounced(highestBidder, highestBid);
        winnerAnnounced = true;

        emit AuctionFinished(highestBidder, highestBid);

    }
  
    /// @notice Returns a list of all bidders and their total bid amounts
    /// @return Array of bidder addresses and their bid values
    function showAllBids () public view whileAuctionOpen returns(address[] memory, uint256[] memory) {
        uint256[] memory amounts = new uint256[](buyerAddresses.length);
        for (uint i = 0; i < buyerAddresses.length; i++) {
            amounts[i] = buyers[buyerAddresses[i]].totalBid;
        }
        return (buyerAddresses, amounts);
    }

    /// @notice Allows losing bidders to claim their deposit after auction ends
    /// @dev Refund is 98% of the total bid (2% commission retained)
    function claimDeposit () external whenAuctionClosed {
        Buyer storage buyer = buyers[msg.sender];                               // Getting buyer
        require(msg.sender != highestBidder, "Winner cannot claim deposit");    // Revert if winner try to calimDeposit
        require(buyer.totalBid > 0, "No deposit to claim");
        require(!buyer.claimed, "Deposit already claimed");                     // Checking the reclaimer

        uint256 refundAmount = (buyer.totalBid * 98) / 100;                     // Calculate 2%
        buyer.claimed = true;                                                   // Mark as Claimed
        payable(msg.sender).transfer(refundAmount);                             // Send refundAmount to claimer

        uint256 commission = buyer.totalBid - refundAmount;                     // Add comission in safebox
        safeBox += commission;
    }

    /// @notice Allows participants to claim their excess funds during the auction without commission
    /// @dev Excess is the portion of total bid not used in last valid bid
    function partialClaim () external whileAuctionOpen {
        Buyer storage buyer = buyers[msg.sender];                               // Getting buyer
        require(buyer.totalBid > 0, "No funds to claim");                       // Checking if buyer have funds to claim
        
        uint256 excessAmount;                                                    

        if (msg.sender == highestBidder) {
            require(buyer.totalBid >= buyer.lastValidBid, "Cannot affect winning bid");
            require(buyer.lastValidBid == highestBid,"Mismatch with highestBid");

            excessAmount = buyer.totalBid - buyer.lastValidBid;                     // Calculate excessAmount
            require(excessAmount > 0, "No withdrawable excess");                    // Checking excessAmount

            buyer.totalBid -= excessAmount;

        } else {
            excessAmount = buyer.totalBid;
            buyer.totalBid = 0;
            buyer.lastValidBid = 0;
        }

        payable(msg.sender).transfer(excessAmount);                             // Transfer to buyer

        emit PartialClaimEvent(msg.sender, excessAmount);
        emit DebugClaim(msg.sender, buyer.totalBid, buyer.lastValidBid, highestBidder, highestBid);

    }

    /// @notice Allows to winner to claim their product after auction ends
    function claimProduct () external whenAuctionClosed {
        require(msg.sender != seller, "Seller cannot claim the product");           // Prevent seller
        require(msg.sender == highestBidder, "Only winner can claim product");      // Ensure only winner

        Buyer storage buyer = buyers[msg.sender];
        require(!buyer.productClaimed, "Product already claimed");                  // Avoid double claim

        buyer.productClaimed = true;

        emit ProductClaimed(msg.sender);
    }

    /// @notice Allows the developer to withdraw accumulated commissions
    function withdrawSafeBox() external whenAuctionClosed {
        require(msg.sender == developer, "Only developer can withdraw commissions");
        require(safeBox > 0, "No funds to withdraw"); // Protect empty transfer.

        uint256 amount = safeBox;
        safeBox = 0; // Protect reentrancy before transfer.
        payable(msg.sender).transfer(amount); // Send amount to seller.

    }

    /// @notice Allows the seller to withdraw the value of the sold product.
    function withdrawSellerFunds() external whenAuctionClosed {
        require(msg.sender == seller, "Only seller can withdraw");
        require(!sellerPaid, "Funds already withdrawn by seller");
        require(highestBid > 0, "No winning bid");

        uint256 payout = (highestBid * 98) / 100;
        sellerPaid = true;
        payable(seller).transfer(payout);

        uint256 commission = highestBid - payout;
        safeBox += commission;

    }

    /// @notice Allows get buyer info.
    function getBuyerInfo(address user) external view returns (
        string memory, uint256, uint256, bool, bool
    ) {
        Buyer memory b = buyers[user];
        return (b.nombre, b.totalBid, b.lastValidBid, b.claimed, b.productClaimed);
    }

    /// @notice Allows get Buyer address
    function getBuyerAddresses() external view returns (address[] memory) {
        return buyerAddresses;
    }

    /// @notice Ensures the function can only be called while the auction is open
    /// @dev Reverts if current block timestamp is after the auction end time
    modifier whileAuctionOpen () {
        require(block.timestamp < auctionEndTime, "Auction is Closed");
        _;
    }

    /// @notice Ensures the function can only be called after the auction has ended
    /// @dev Reverts if the auction is still active
    modifier whenAuctionClosed () {
        require(block.timestamp >= auctionEndTime, "Auction is still active");
        _;
    }

    /// @notice Emitted when a new valid bid is placed
    /// @param bidder Address of the bidder
    /// @param amount Total bid amount by the bidder
    event NewBidEvent (address indexed bidder, uint256 amount);

    /// @notice Emitted when the auction ends
    /// @param winner Address of the winning bidder
    /// @param amount Amount of the winning bid
    event AuctionFinished(address winner, uint256 amount);

    /// @notice Emitted when the winner is officially announced
    /// @param winner Address of the winning bidder
    /// @param amount Final highest bid
    event WinnerAnnounced(address winner, uint256 amount);

    /// @notice Emitted when a partial refund is claimed
    /// @param user Address of the claimant
    /// @param amount Amount refunded
    event PartialClaimEvent(address indexed user, uint256 amount);

    /// @notice Emitted when auction time is extended
    /// @param newEndTime New end time of the auction
    event AuctionExtended(uint256 newEndTime);

    /// @notice Emitted when the product is claimed
    // @param address Final highest bid
    event ProductClaimed(address winner);

    /// @dev Debug log for internal testing
    event DebugLog(string mensaje, address bidder, uint256 bid);

    /// @dev Debug log for claim information
    event DebugClaim(address claimant, uint256 totalBid, uint256 lastValidBid, address highestBidder, uint256 highestBid);
}