//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC6551Registry.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract ShellBox is ERC721URIStorage, Ownable {
    using Strings for uint256;

    uint256 private _tokenIds;
    ERC6551Registry public registry;
    string public baseURI;
    address public erc6551AccountImplementation;

    event AccountCreated(uint256 tokenId, address newAccount);

    constructor(
        string memory name,
        string memory symbol,
        string memory _baseURI,
        address _registryAddress,
        address _erc6551AccountImplementation
    ) ERC721(name, symbol) {
        registry = ERC6551Registry(_registryAddress);
        erc6551AccountImplementation = _erc6551AccountImplementation;
        baseURI = _baseURI;
        _tokenIds = 0;
    }

    function mintWithAccount(address recipient) public onlyOwner returns (address)
    {
        _tokenIds += 1;
        uint256 newItemId = _tokenIds;
        string memory tokenURI = string(abi.encodePacked(baseURI, "#", newItemId.toString()));
        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        // Create an ERC6551 account for the new NFT
        uint256 salt = newItemId; // TODO:Using tokenId as salt for simplicity
        address newAccount = registry.createAccount(
            erc6551AccountImplementation,
            block.chainid,
            address(this),
            newItemId,
            salt,
            "" // No initialization data for the new account in this example
        );

        // Optionally, you can store the newAccount address in a mapping or emit an event
        emit AccountCreated(newItemId, newAccount);
        return newAccount;
    }
}
