// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MythicalCreatures is Ownable, ERC721URIStorage
{
    // token name and symbol
    constructor() ERC721("MythicalCreatures", "MYTH") Ownable(msg.sender)
    {}

    // User Counters library for efficient token ID generation
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Define the different rarity tiers (customizable)
    uint public constant MAX_SUPPLY = 100;
    uint public constant COMMON_MAX = 90;
    uint public constant RARE_MAX = COMMON_MAX + 9;
    uint public constant LEGENDARY_MAX = RARE_MAX + 1;

    // Track minted NFTs per rarity tier
    uint public commonMinted = 0;
    uint public rareMinted = 0;
    uint public legendaryMinted = 0;

    // Mapping to store the rarity tier for each token ID
    mapping(uint256 => uint) public tokenRarity;

    // Define probability ranges
    uint public constant COMMON_PROBABILITY = 90;
    uint public constant RARE_PROBABILITY = 9;
    uint public constant LEGENDARY_PROBABILITY = 1;

    // Function for manual minting with predefined rarity (1 by 1)
    function mintCreatureWithRarity(address to, uint rarityTier, string calldata tokenURI) public onlyOwner()
    {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < MAX_SUPPLY, "Minting limit reached");

        // Enforce rarity tier limits
        require(_checkRarityLimits(rarityTier), "Max supply for this rarity tier has been reached");

        // Mint the NFT with the specified tier
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        _setRarity(tokenId, rarityTier);

        _tokenIdCounter.increment();

        // Update minted counters for the tier
        _updateMintedCounters(rarityTier);
    }

    // Function for batch minting with probabilities
    function batchMintCreatures(address to, uint numToMint) public onlyOwner()
    {
        for(uint i=0; i<numToMint; i++)
        {
            uint256 tokenId = _tokenIdCounter.current();
            require(tokenId < MAX_SUPPLY, "Minting limit reached");

            uint rarityTier = getRamdonRarity();

            _safeMint(to, tokenId);
            _setRarity(tokenId, rarityTier);

            _tokenIdCounter.increment();
            _updateMintedCounters(rarityTier);
        }
    }

    // Calculate Probability
    function calculateProbability(uint randomNumber) internal pure returns (uint)
    {
        // Convert random number to a value between 0 and 1
        uint probability = randomNumber / (2**256 - 1);
        return probability;
    }

    // Function to assign rarity tier to a specific token (implementation still omitted)
    function _setRarity(uint256 tokenId, uint rarityTier) internal
    {
        tokenRarity[tokenId] = rarityTier;
    }

    // Simulate random rarity generation (replace with secure randomness source in production
    function getRamdonRarity() private view returns(uint)
    {
        uint randomNumber = uint(keccak256(abi.encodePacked(blockhash(block.number - 1))));
        uint probability = calculateProbability(randomNumber);

        // Define cumulative probabiliy thresholds
        uint cumulativeThreshold = 0;
        cumulativeThreshold += COMMON_PROBABILITY * 100;
        cumulativeThreshold += RARE_PROBABILITY * 100;

        // Determine rarity tier based on probability and thresholds
        if(probability < cumulativeThreshold + RARE_PROBABILITY * 100)
        {return 0;}
        else if(probability < (cumulativeThreshold + LEGENDARY_PROBABILITY * 100))
        {return 1;}
        else {return 2;}
    }

    function _checkRarityLimits(uint rarityTier) private view returns (bool)
    {
        if(rarityTier == 0)
        {return commonMinted < COMMON_MAX;}
        else if(rarityTier == 1)
        {return rareMinted < RARE_MAX;}
        else if(rarityTier == 2)
        {return legendaryMinted < LEGENDARY_MAX;}
        else {revert("Invalid rarity tier");}
    }

    // Internal function to update minted counters for each tier
    function _updateMintedCounters(uint rarityTier) private 
    {
        if(rarityTier == 0)
        {commonMinted++;}
        else if(rarityTier == 1)
        {rareMinted++;}
        else if(rarityTier == 2)
        {legendaryMinted++;}
    }
}