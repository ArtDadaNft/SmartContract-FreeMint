//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";



contract GEOM is Ownable, ERC721A {
    uint256 constant public maxSupply = 20;
    uint256 public teamMaxMint = 2;
    uint256 public publicPrice = 0.01 ether;
    uint256 public maxFreeMint = 1;
    uint256 constant public limitAmountPerTx = 5;
    uint256 constant public limitAmountPerWallet = 10;

    uint256 public totalTeamSupply;

    string public revealedURI = "ipfs:// ----IFPS---/";

    bool public paused = true;

    bool public freeSale = true;
    bool public publicSale = true;

    address constant internal uglyAddy = 0x6371F793946831E5dD7cc51E16C46E985A7dbB0F;
    address public teamWallet = 0xB7512F2c78aA0189f0f1d6F617525825b2c274d9;

    mapping(address => bool) public userMintedFree;
    mapping(address => uint256) public mintedWallets;

    constructor(
    string memory revealedURI
    ) ERC721A("geom", "GEOM") { }

    
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function teamMint(uint256 quantity) public payable mintCompliance(quantity) {
        require(msg.sender == teamWallet, "Team minting only");
        require(totalTeamSupply + quantity <= teamMaxMint, "No team mints left");

        totalTeamSupply += quantity;

        _safeMint(msg.sender, quantity);
    }
    
    function freeMint(uint256 quantity) external payable mintCompliance(quantity) {
        require(freeSale, "Free sale inactive");
        require(msg.value == 0, "This phase is free");
        require(quantity == 1, "Only 1 free");
        require(mintedWallets[msg.sender] < 1, "exceed max free mint");
        require(!userMintedFree[msg.sender], "User max free limit");
        require(maxSupply > totalSupply(), "sold out");

        mintedWallets[msg.sender]++;

        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable mintCompliance(quantity) {
        require(publicSale, "Public sale inactive");
        require(msg.value == quantity * publicPrice, "give me more money");
        require(quantity <= limitAmountPerTx, "Quantity too high");

        uint256 currMints = mintedWallets[msg.sender];
                
        require(currMints + quantity <= limitAmountPerWallet, "u wanna mint too many");

        mintedWallets[msg.sender] = (currMints + quantity);

        _safeMint(msg.sender, quantity);
    }


    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

        currentTokenId++;
        }

        return ownedTokenIds;
    }

      string private _baseTokenUri;

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenUri;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        _baseTokenUri = _baseUri;
    }


    function contractURI() public view returns (string memory) {
        return revealedURI;
    }


    function setTeamMintMax(uint256 _teamMintMax) public onlyOwner {
        teamMaxMint = _teamMintMax;
    }

    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        revealedURI = _baseUri;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        revealedURI = _contractURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        // Note: You don't REALLY need this require statement since nothing should be querying for non-existing tokens after reveal.
            // That said, it's a public view method so gas efficiency shouldn't come into play.
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        return string(abi.encodePacked(revealedURI, Strings.toString(_tokenId), ".json"));
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setPublicEnabled(bool _state) public onlyOwner {
        publicSale = _state;
        freeSale = !_state;
    }
    function setFreeEnabled(bool _state) public onlyOwner {
        freeSale = _state;
        publicSale = !_state;
    }

    function setTeamWalletAddress(address _teamWallet) public onlyOwner {
        teamWallet = _teamWallet;
    }

    function mintToUser(uint256 quantity, address receiver) public onlyOwner mintCompliance(quantity) {
        _safeMint(receiver, quantity);
    }

     function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
        (bool success, ) =_address.call{value: amount}("");
        require(success, "Transfer failed.");
    }



    modifier mintCompliance(uint256 quantity) {
        require(!paused, "Contract is paused");
        require(totalSupply() + quantity <= maxSupply, "you cant become ugly anymore");
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }
}
