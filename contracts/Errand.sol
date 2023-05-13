//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";

contract Errand {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address escrowContractAddreas;
    address public inspector;
    bool errandCompleted;
    bool bidComplelted;

    enum ErrandStatus {
        Created,
        Pending,
        Accepted,
        Cancelled,
        InProgress,
        Success
    }

    struct ErrandStruct {
        string errandDetails;
        address errrandOwner;
        string errandTiltle;
        uint256 errandCost;
        string deliveryAddress;
        string category;
        string pickupAddress;
        ErrandStatus status;
        string errandImage;
        uint256 errandDeadline;
    }

    struct Bid {
        uint256 id;
        address bidder;
        uint256 amount;
        bool accepted;
    }

    ErrandStruct[] public errands;
    Bid[] public bids;

    mapping(uint256 => address) public errandToOwner;
    mapping(address => uint256) public ownerErrandCount;
    mapping(address => ErrandStruct) public ownerErrand;

    /**
     * @dev Create a new errand and also send the cost to the smart contract
     * @param errandDetails The details of the errand.
     * @param errandTitle The title of the errand.
     * @param errandCost The cost of the errand.
     * @param deliveryAddress The delivery address of the errand.
     * @param category The category of the errand.
     * @param pickupAddress The pickup address of the errand.
     * @param errandImage The image of the errand.
     * @param errandDeadline The deadline for the errand.
     */
    function createErrand(
        string memory _errandDetails,
        string memory _errandTitle,
        uint256 _errandCost,
        string memory _deliveryAddress,
        string memory _category,
        string memory _pickupAddress,
        string memory _errandImage,
        uint256 _errandDeadline
    ) public payable {
        require(_errandCost == msg.value, "wrong");
        payable(address(this)).transfer(_errandCost);
        ErrandStruct storage newErrand = ownerErrand[msg.sender];
        newErrand.category = _category;
        newErrand.deliveryAddress = _deliveryAddress;
        newErrand.errandCost = _errandCost;
        newErrand.errandDeadline = _errandDeadline;
        newErrand.errandDetails = _errandDetails;
        newErrand.errandImage= _errandImage;
        newErrand.errandTiltle = _errandTitle;
        newErrand.errrandOwner = msg.sender;
        newErrand.pickupAddress = _pickupAddress;
        newErrand.status = ErrandStatus.Created;
        errands.push(newErrand);
        uint256 newErrandId = errands.length - 1;
        errandToOwner[newErrandId] = msg.sender;
        ownerErrandCount[msg.sender]++;
        _tokenIds.increment();
    }

    /**
     * @dev Bid for an errand.
     * @param errandId The ID of the errand to bid for.
     * @param amount The amount of the bid.
     */
    function bidForErrand(uint256 errandId, uint256 amount) public {
        ErrandStruct storage errand = errands[errandId];
        require(
            errand.status == ErrandStatus.Created ||
                errand.status == ErrandStatus.Pending,
            "Errand is not available for bidding"
        );
        Bid memory newBid = Bid(bids.length, msg.sender, amount, false);
        bids.push(newBid);
    }

    /**
     * @dev Accept a bid for an errand.
     * @param errandId The ID of the errand to accept the bid for.
     * @param bidId The ID
     **/
    function acceptBid(uint256 errandId, uint256 bidId) public {
        ErrandStruct storage errand = errands[errandId];
        require(
            errand.errrandOwner == msg.sender,
            "Only the owner of the errand can accept a bid"
        );
        Bid storage bid = bids[bidId];
        require(!bid.accepted, "Bid has already been accepted");
        bid.accepted = true;
        errand.status = ErrandStatus.Accepted;
        errandToOwner[errandId] = bid.bidder;
        ownerErrandCount[msg.sender]--;
        ownerErrandCount[bid.bidder]++;
    }

 function setCompleted(uint256 errandId, uint256 bidId) external payable {
    ErrandStruct storage errand = errands[errandId];
    Bid storage bid = bids[bidId];
    require(errand.status == ErrandStatus.InProgress, "Errand hasn't started yet");
    require(errandCompleted == true, "Errand not completed");
    require(bidComplelted == true, "Bid not completed");
    require(errand.status != ErrandStatus.Success, "Errand is already a success");
    
    // Transfer the bid amount to the bidder
    payable(bid.bidder).transfer(bid.amount);
    
    // Update the status of the errand
    errand.status = ErrandStatus.Success;
}

     function setErrandCompleted(uint256 errandId) external  {
         ErrandStruct storage anErrand = errands[errandId];
         require(anErrand.status == Inprogress, "not being accpeted yet")
        errandCompleted = true;
     }

     function setBidCompleted(uint256 bidId) public  {
         Bid storage bid = bids[bidId];
        require(bid.accepted == true, "bid hasnt been accepeted");
        bidComplelted = true;
     }

    /**
     * @dev Deny a bid for an errand.
     * @param bidId The ID of the bid to deny.
     */
    function denyBid(uint256 bidId) public {
        Bid storage bid = bids[bidId];
        require(
            errands[0].errrandOwner == msg.sender,
            "Only the owner of the errand can deny a bid"
        );
        require(!bid.accepted, "Bid has already been accepted");
        delete bids[bidId];
    }

    function allErrand() external view returns(ErrandStruct[] memory) {
       return errands;
    }
}
