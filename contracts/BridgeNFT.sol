// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

contract BridgeNFT is ERC721URIStorageUpgradeable {
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(address => bool) public admins;

    event SetAdmin(address admin, bool status);

    function initialize(
        string memory _name,
        string memory _symbol,
        address[] calldata _admins
    ) public initializer {
        __ERC721_init(_name, _symbol);
        for (uint256 i = 0; i < _admins.length; i++) {
            admins[_admins[i]] = true;
        }
    }

    function mint(
        address to,
        uint256 tokenId,
        string calldata uri
    ) external onlyAdmin {
        uint256 _index = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][_index] = tokenId;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function getUserNFT(
        address _owner
    ) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) public view returns (uint256) {
        require(
            index < ERC721Upgradeable.balanceOf(owner),
            "Owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    function setAdmin(address _admin, bool _status) external onlyAdmin {
        admins[_admin] = _status;
        emit SetAdmin(_admin, _status);
    }

    modifier onlyAdmin() {
        require(admins[_msgSender()], "Only admin");
        _;
    }
}
