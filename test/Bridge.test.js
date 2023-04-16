const { ethers, network } = require("hardhat");
const { assert, expect } = require("chai");
const c = console.log.bind()

let ganache = new ethers.providers.JsonRpcProvider("http://127.0.0.1:8545")
const hhChainId = "31337"
const ganacheChainId = "1337"
let BridgeNFT = require("../artifacts/contracts/BridgeNFT.sol/BridgeNFT.json")

let Bridge
let NFT
let Pay

let bridgeHH
let payHH
let nftHH
let bridgeGanache
let payGanache
let nftGanache
let signerHH
let signerGanache
let bridgeNFT

describe("Bridge", async function () {
  it('DeployHH', async () => {
    Bridge = await ethers.getContractFactory("Bridge")
    NFT = await ethers.getContractFactory("NFT")
    Pay = await ethers.getContractFactory("Pay")

    signerHH = await ethers.getSigner()
    payHH = await Pay.deploy('hhToken', 'HHT')
    bridgeHH = await Bridge.deploy(payHH.address, 1000000000000, 100000)
    nftHH = await NFT.deploy("nftHH", "nftHH")
    assert.equal(bridgeHH.deployTransaction.chainId, hhChainId)
    c("BridgeHH deployed to: ", bridgeHH.address)
  })
  it('DeployGanache', async () => {
    signerGanache = ganache.getSigner()
    payGanache = await Pay.connect(signerGanache).deploy('GanacheToken', 'GT')
    bridgeGanache = await Bridge.connect(signerGanache).deploy(payHH.address, 1000000000000, 100000)
    nftGanache = await NFT.connect(signerGanache).deploy("nftG", "nftG")
    assert.equal(bridgeGanache.deployTransaction.chainId, ganacheChainId)
    c("BridgeGanache deployed to: ", bridgeGanache.address)
  })
  it('mint approve', async () => {
    await nftHH.mint("MyHHNFT")
    await payHH.approve(bridgeHH.address, 1000000000000)
    await nftHH.approve(bridgeHH.address, 1)

    await nftGanache.connect(signerGanache).mint("MyGanacheNFT")
    await payGanache.connect(signerGanache).approve(bridgeHH.address, 1000000000000)
    await nftGanache.connect(signerGanache).approve(bridgeHH.address, 1)
  })
  it('setAdmin', async () => {
    SetAdmin = await bridgeGanache.connect(signerGanache).setAdmin(signerHH.address, true)
    tx = await SetAdmin.wait()
    assert.equal(tx.events[0].event, "SetAdmin")
    assert.equal(tx.events[0].args.admin, signerHH.address)
    assert.equal(tx.events[0].args.status, true)
  })
  it('changeERC20', async () => {
    NFTChanged = await bridgeHH.changePayERC20(nftHH.address, 1)
    let holder;
    let tokenAddress;
    let tokenId;
    let tokenURI;
    tx = await NFTChanged.wait()
    for (const event of tx.events) {
      if (event.event == "NFTChanged") {
        assert.equal(event.args.holder, signerHH.address)
        assert.equal(event.args.tokenAddress, nftHH.address)
        assert.equal(event.args.tokenId, 1)
        assert.equal(event.args.uri, "MyHHNFT")
        holder = event.args.holder
        tokenAddress = event.args.tokenAddress
        tokenId = Number(event.args.tokenId)
        tokenURI = event.args.uri
      }
    }
    NewNFT = await bridgeGanache.newNFT("nft", "nft", tokenAddress)
    tx = await NewNFT.wait()
    let newNFTaddr
    for (const event of tx.events) {
      if (event.event == "NewNFT") {
        assert.equal(event.args.tokenAddressAnotherBC, tokenAddress)
        newNFTaddr = event.args.tokenAddress
      }
    }
    bridgeNFT = new ethers.Contract(newNFTaddr, BridgeNFT.abi, signerGanache);
    await bridgeNFT.connect(signerGanache).mint(holder, tokenId, tokenURI)
    own = await bridgeNFT.ownerOf(tokenId)
    assert.equal(own, signerHH.address)
    uri = await bridgeNFT.tokenURI(tokenId)
    assert.equal(uri, tokenURI)
  })
})