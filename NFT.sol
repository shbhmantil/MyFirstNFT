// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title MyFirstNFT
 * @dev ERC721 contract, NFTs with role-based access control
 */
contract MyFirstNFT is ERC721, ERC721URIStorage, AccessControl {
    using Strings for uint256;

    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // State variables
    uint256 private _tokenIds;
    string private _baseMetadataURI;
    bool private _mintingPaused;
    
    // Events
    event Minted(
        uint256 indexed tokenId,
        address indexed to,
        uint256 timestamp
    );

    /**
     * @dev Constructor sets up the contract with initial admin
     * @param name Token name
     * @param symbol Token symbol
     * @param initialAdmin Address of the initial admin
     */
    constructor(
        string memory name,
        string memory symbol,
        address initialAdmin
    ) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(ADMIN_ROLE, initialAdmin);
        _grantRole(MINTER_ROLE, initialAdmin);
    }

    /**
     * @dev Mints a new NFT
     * @param to Address to mint the NFT to
     * @return tokenId The ID of the newly minted token
     */
    function mint(address to) external onlyRole(MINTER_ROLE) returns (uint256) {
        require(!_mintingPaused, "Minting is paused");
        require(to != address(0), "Cannot mint to zero address");

        _tokenIds++;
        uint256 newTokenId = _tokenIds;

        _safeMint(to, newTokenId);

        emit Minted(newTokenId, to, block.timestamp);
        
        return newTokenId;
    }

    /**
     * @dev Batch mints multiple NFTs
     * @param recipients Array of recipient addresses
     * @return tokenIds Array of minted token IDs
     */
    function batchMint(
        address[] memory recipients
    ) external onlyRole(MINTER_ROLE) returns (uint256[] memory) {
        require(!_mintingPaused, "Minting is paused");
        require(recipients.length > 0, "Recipients array cannot be empty");

        uint256[] memory tokenIds = new uint256[](recipients.length);

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Cannot mint to zero address");
            
            _tokenIds++;
            uint256 newTokenId = _tokenIds;

            _safeMint(recipients[i], newTokenId);
            tokenIds[i] = newTokenId;

            emit Minted(newTokenId, recipients[i], block.timestamp);
        }

        return tokenIds;
    }

    /**
     * @dev Gets all tokens owned by an address
     * @param owner The address to query
     * @return tokenIds Array of token IDs owned by the address
     */
    function getTokensByOwner(address owner) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);
        
        uint256 index = 0;
        for (uint256 i = 1; i <= _tokenIds && index < balance; i++) {
            if (ownerOf(i) == owner) {
                tokenIds[index] = i;
                index++;
            }
        }
        
        return tokenIds;
    }

    /**
     * @dev Gets total number of tokens minted
     * @return Total token count
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIds;
    }

    /**
     * @dev Set the base metadata URI for dynamic token URIs
     * @param baseURI The base URI
     */
    function setBaseMetadataURI(string memory baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseMetadataURI = baseURI;
    }
    
    /**
     * @dev Get the base metadata URI
     * @return The base metadata URI
     */
    function getBaseMetadataURI() external view returns (string memory) {
        return _baseMetadataURI;
    }
    
    /**
     * @dev Override tokenURI to use dynamic base URI
     * @param tokenId The token ID
     * @return The token URI
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        
        // If base metadata URI is set, use dynamic URI
        if (bytes(_baseMetadataURI).length > 0) {
            return string(abi.encodePacked(_baseMetadataURI, tokenId.toString(), ".json"));
        }
        
        // Otherwise, use the stored token URI
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Emergency function to pause minting (only for extreme cases)
     * @param paused Whether to pause or unpause
     */
    function setMintingPaused(bool paused) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mintingPaused = paused;
    }

    /**
     * @dev Check if minting is paused
     * @return bool True if minting is paused
     */
    function isMintingPaused() external view returns (bool) {
        return _mintingPaused;
    }

    /**
     * @dev Override required by Solidity
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
