// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Nft is ERC721, ERC721URIStorage, ERC721Enumerable, ERC721Pausable, Ownable2Step {
    uint256 private _nextTokenId = 1;

    uint256 public constant MAX_URI_LENGTH = 2048;

    error InvalidTokenURI();

    event Minted(address indexed creator, uint256 indexed tokenId, string tokenURI);

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    { }

    /// @notice Anyone may mint one NFT to their own address without a protocol fee.
    function mint(string calldata uri) external whenNotPaused returns (uint256 tokenId) {
        if (!_isValidURI(uri)) revert InvalidTokenURI();

        tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);

        emit Minted(msg.sender, tokenId, uri);
    }

    function nextTokenId() external view returns (uint256) {
        return _nextTokenId;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _isValidURI(string calldata uri) private pure returns (bool) {
        bytes memory value = bytes(uri);
        if (value.length == 0 || value.length > MAX_URI_LENGTH) return false;

        return
            _hasContentWithPrefix(value, bytes("ipfs://")) ||
            _hasContentWithPrefix(value, bytes("ar://")) ||
            _hasContentWithPrefix(value, bytes("https://")) ||
            _hasContentWithPrefix(value, bytes("data:application/json"));
    }

    function _hasContentWithPrefix(bytes memory value, bytes memory prefix)
        private
        pure
        returns (bool)
    {
        if (value.length <= prefix.length) return false;
        for (uint256 i = 0; i < prefix.length; i++) {
            if (value[i] != prefix[i]) return false;
        }
        return true;
    }
}
