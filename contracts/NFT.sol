// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC721(_tokenName, _tokenSymbol) {}

    function mint(string calldata _tokenURI) public onlyOwner {
        _mintTo(_msgSender(), _tokenURI);
    }

    function mintTo(
        address _toAddress,
        string calldata _tokenURI
    ) public onlyOwner {
        _mintTo(_toAddress, _tokenURI);
    }

    function mintManyTo(
        address _toAddress,
        string[] calldata _tokenURIArray
    ) public onlyOwner {
        uint256 count = _tokenURIArray.length;
        for (uint256 i = 0; i < count; i++) {
            _mintTo(_toAddress, _tokenURIArray[i]);
        }
    }

    function multiTransferFrom(
        address _from,
        address[] calldata _adressess,
        uint256[] calldata _ids
    ) public {
        require(
            _adressess.length == _ids.length,
            "Expected arrays of the same length"
        );
        for (uint i = 0; i < _adressess.length; i++) {
            transferFrom(_from, _adressess[i], _ids[i]);
        }
    }

    function multiSafeTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids
    ) public {
        for (uint i = 0; i < _ids.length; i++) {
            safeTransferFrom(_from, _to, _ids[i]);
        }
    }

    function _mintTo(address _toAddress, string calldata _tokenURI) internal {
        _tokenIds.increment();
        uint256 _tokenId = _tokenIds.current();
        _safeMint(_toAddress, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
    }

    function getCurrentId() public view returns (uint256) {
        return _tokenIds.current();
    }
}
