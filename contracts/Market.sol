// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract Market is Ownable2Step, Pausable, ReentrancyGuard, IERC721Receiver {
    enum ListingStatus {
        Active,
        Cancelled,
        Sold
    }

    struct Listing {
        address nft;
        address seller;
        uint256 tokenId;
        uint256 price;
        ListingStatus status;
    }

    uint256 public nextListingId = 1;
    uint256 public totalPendingProceeds;
    mapping(uint256 listingId => Listing) public listings;
    mapping(address seller => uint256) public pendingProceeds;

    uint256 private _pendingListingId;
    address private _pendingNft;
    address private _pendingSeller;
    uint256 private _pendingTokenId;

    error InvalidPrice();
    error InvalidListing();
    error NotTokenOwner();
    error NotERC721();
    error NFTApprovalRequired();
    error NotSeller();
    error IncorrectPayment();
    error CannotBuyOwnListing();
    error UnexpectedERC721Transfer();
    error NoProceeds();
    error PaymentTransferFailed();
    error DirectPaymentNotAccepted();

    event Listed(
        uint256 indexed listingId,
        address indexed nft,
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );
    event ListingCancelled(uint256 indexed listingId, address indexed seller);
    event Sold(
        uint256 indexed listingId,
        address indexed buyer,
        address indexed seller,
        uint256 price
    );
    event ProceedsWithdrawn(address indexed seller, uint256 amount);

    constructor() Ownable(msg.sender) { }

    function list(address nft, uint256 tokenId, uint256 price)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 listingId)
    {
        if (price == 0) revert InvalidPrice();
        if (!IERC165(nft).supportsInterface(type(IERC721).interfaceId)) revert NotERC721();
        if (IERC721(nft).ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        if (
            IERC721(nft).getApproved(tokenId) != address(this) &&
            !IERC721(nft).isApprovedForAll(msg.sender, address(this))
        ) revert NFTApprovalRequired();

        listingId = nextListingId++;
        _pendingListingId = listingId;
        _pendingNft = nft;
        _pendingSeller = msg.sender;
        _pendingTokenId = tokenId;

        IERC721(nft).safeTransferFrom(msg.sender, address(this), tokenId);

        delete _pendingListingId;
        delete _pendingNft;
        delete _pendingSeller;
        delete _pendingTokenId;

        listings[listingId] = Listing({
            nft: nft,
            seller: msg.sender,
            tokenId: tokenId,
            price: price,
            status: ListingStatus.Active
        });

        emit Listed(listingId, nft, tokenId, msg.sender, price);
    }

    function cancelListing(uint256 listingId) external whenNotPaused nonReentrant {
        Listing storage listing = listings[listingId];
        if (listing.status != ListingStatus.Active) revert InvalidListing();
        if (listing.seller != msg.sender) revert NotSeller();

        listing.status = ListingStatus.Cancelled;
        IERC721(listing.nft).safeTransferFrom(address(this), listing.seller, listing.tokenId);

        emit ListingCancelled(listingId, msg.sender);
    }

    function buy(uint256 listingId) external payable whenNotPaused nonReentrant {
        Listing storage listing = listings[listingId];
        if (listing.status != ListingStatus.Active) revert InvalidListing();
        if (msg.sender == listing.seller) revert CannotBuyOwnListing();
        if (msg.value != listing.price) revert IncorrectPayment();

        listing.status = ListingStatus.Sold;
        pendingProceeds[listing.seller] += msg.value;
        totalPendingProceeds += msg.value;

        IERC721(listing.nft).safeTransferFrom(address(this), msg.sender, listing.tokenId);

        emit Sold(listingId, msg.sender, listing.seller, msg.value);
    }

    function withdrawProceeds() external nonReentrant {
        uint256 amount = pendingProceeds[msg.sender];
        if (amount == 0) revert NoProceeds();

        pendingProceeds[msg.sender] = 0;
        totalPendingProceeds -= amount;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert PaymentTransferFailed();

        emit ProceedsWithdrawn(msg.sender, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata)
        external
        view
        returns (bytes4)
    {
        if (
            _pendingListingId == 0 ||
            msg.sender != _pendingNft ||
            from != _pendingSeller ||
            tokenId != _pendingTokenId
        ) revert UnexpectedERC721Transfer();

        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {
        revert DirectPaymentNotAccepted();
    }

    fallback() external payable {
        revert DirectPaymentNotAccepted();
    }
}
