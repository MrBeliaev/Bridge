// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BridgeNFT.sol";

contract Bridge is IERC721Receiver, ReentrancyGuard, Ownable {
    using Clones for BridgeNFT;

    address immutable implementation;
    uint256 public commissionERC20;
    uint256 public commissionCoin;
    mapping(address => bool) public admins;
    mapping(address => address) public nfts;
    address[] public bridgeNFTs;

    event NFTChanged(
        address holder,
        address tokenAddress,
        uint256 tokenId,
        string uri
    );
    event NewNFT(address tokenAddress, address tokenAddressAnotherBC);
    event NFTSended(address holder, address tokenAddress, uint256 tokenId);
    event CommissionChanged(uint256 commissionERC20, uint256 commissionCoin);
    event SetAdmin(address admin, bool status);

    IERC20 payToken;

    constructor(
        IERC20 _payToken,
        uint256 _commissionERC20,
        uint256 _commissionCoin
    ) {
        implementation = address(new BridgeNFT());
        payToken = _payToken;
        commissionERC20 = _commissionERC20;
        commissionCoin = _commissionCoin;
        admins[_msgSender()] = true;
    }

    function changePayERC20(
        address _tokenAddress,
        uint256 _tokenId
    ) external nonReentrant {
        if (commissionERC20 > 0) {
            payToken.transferFrom(_msgSender(), address(this), commissionERC20);
        }
        change(_tokenAddress, _tokenId);
    }

    function changePayCoin(
        address _tokenAddress,
        uint256 _tokenId
    ) external payable nonReentrant {
        if (commissionCoin > 0) {
            payable(address(this)).transfer(commissionCoin);
        }
        change(_tokenAddress, _tokenId);
    }

    function sendNFT(
        address _holderAddress,
        address _tokenAddress,
        uint256 _tokenId
    ) external onlyAdmin {
        IERC721MetadataUpgradeable(_tokenAddress).transferFrom(
            address(this),
            _holderAddress,
            _tokenId
        );
        emit NFTSended(_holderAddress, _tokenAddress, _tokenId);
    }

    function newNFT(
        string memory _name,
        string memory _symbol,
        address _nftAnotherBC
    ) external onlyAdmin {
        BridgeNFT newBridgeNFT = BridgeNFT(Clones.clone(implementation));
        address[] memory _admins = new address[](2);
        _admins[0] = address(this);
        _admins[1] = owner();
        newBridgeNFT.initialize(_name, _symbol, _admins);
        nfts[_nftAnotherBC] = address(newBridgeNFT);
        nfts[address(newBridgeNFT)] = _nftAnotherBC;
        bridgeNFTs.push(address(newBridgeNFT));
        emit NewNFT(address(newBridgeNFT), _nftAnotherBC);
    }

    function change(address _tokenAddress, uint256 _tokenId) internal {
        IERC721MetadataUpgradeable(_tokenAddress).transferFrom(
            _msgSender(),
            address(this),
            _tokenId
        );
        string memory _uri = IERC721MetadataUpgradeable(_tokenAddress).tokenURI(
            _tokenId
        );
        emit NFTChanged(_msgSender(), _tokenAddress, _tokenId, _uri);
    }

    function withdrawERC20() external payable onlyOwner {
        payToken.transfer(_msgSender(), payToken.balanceOf(address(this)));
    }

    function withdrawCoin() external payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

    function changeCommissions(
        uint256 _commissionERC20,
        uint256 _commissionCoin
    ) external onlyAdmin {
        commissionERC20 = _commissionERC20;
        commissionCoin = _commissionCoin;
        emit CommissionChanged(_commissionERC20, _commissionCoin);
    }

    function setAdmin(address _admin, bool _status) external onlyAdmin {
        admins[_admin] = _status;
        emit SetAdmin(_admin, _status);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert("Cannot Receive NFTs Directly");
    }

    modifier onlyAdmin() {
        require(admins[_msgSender()], "Only admin");
        _;
    }
}
