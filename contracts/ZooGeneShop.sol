// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


interface IOracle {
    function getValue(bytes32 key) external view returns(uint);
}

interface IZooGene {
    function safeMint(address to, string calldata uri) external;
    function totalSupply() external view returns (uint256);
}

contract ZooGeneShop is AccessControl, ERC721Holder, Initializable, Pausable {


    struct NftPhaseInfo {
        uint maxCount;
        uint soldCount;
        uint usdPrice;
    }

    mapping(uint=>NftPhaseInfo) public phaseInfo;

    address public priceOracle;

    uint public currentPhase;

    address[] public mintQueue;

    mapping(address => uint) public userInQueue;

    address public zooGene;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event BuyZooGene(address indexed _user, uint256 priceInUsd, uint256 priceInWan, uint256 tokenId);

    event MintFinish(address indexed _user, string uri, uint256 tokenId);

    function initialize(address _admin, address _priceOracle, address _zooGene) initializer public {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        priceOracle = _priceOracle;
        zooGene = _zooGene;

        phaseInfo[0] = NftPhaseInfo({
            maxCount: 4000,
            soldCount: 0,
            usdPrice: 60 ether
        });

        phaseInfo[1] = NftPhaseInfo({
            maxCount: 3000,
            soldCount: 0,
            usdPrice: 70 ether
        });

        phaseInfo[2] = NftPhaseInfo({
            maxCount: 3000,
            soldCount: 0,
            usdPrice: 80 ether
        });
        _pause();
    }

    function buy() internal whenNotPaused {
        require(tx.origin == msg.sender, "not allow sc call");
        require(userInQueue[msg.sender] == 0, "user already in queue");
        NftPhaseInfo storage info = phaseInfo[currentPhase];
        uint wanNeed = getWanPriceByUSD(info.usdPrice);
        require(msg.value >= wanNeed, "WAN not enough");
        require(info.soldCount + 1 <= info.maxCount, "sold out");
        if (msg.value > wanNeed) {
            payable(msg.sender).transfer(msg.value - wanNeed);
        }
        info.soldCount++;
        mintQueue.push(msg.sender);
        userInQueue[msg.sender] = mintQueue.length;
        emit BuyZooGene(msg.sender, info.usdPrice, wanNeed, mintQueue.length);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function updatePhaseInfo(uint _phase, uint _maxCount, uint _usdPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        phaseInfo[_phase].maxCount = _maxCount;
        phaseInfo[_phase].usdPrice = _usdPrice;
    }

    function updateCurrentPhase(uint _phase) external onlyRole(DEFAULT_ADMIN_ROLE) {
        currentPhase = _phase;
    }

    function getWanPriceByUSD(uint usd) public view returns (uint256) {
        uint price = IOracle(priceOracle).getValue(stringToBytes32("WAN"));
        return usd * 1 ether / price;
    }
    
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function redeem() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    function queueLength() public view returns(uint) {
        return mintQueue.length - IZooGene(zooGene).totalSupply();
    }

    function userQueuePosition(address user) public view returns(uint) {
        if (userInQueue[user] <= IZooGene(zooGene).totalSupply()) {
            return 0;
        }
        return userInQueue[user] - IZooGene(zooGene).totalSupply();
    }

    function addMinterRole(address _minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(MINTER_ROLE, _minter);
    }

    function configZooGene(address _zooGene) external onlyRole(DEFAULT_ADMIN_ROLE) {
        zooGene = _zooGene;
    }

    function getNextId() public view returns (uint) {
        return IZooGene(zooGene).totalSupply() + 1;
    }

    function mint(string calldata uri) external onlyRole(MINTER_ROLE) {
        uint totalSupply = IZooGene(zooGene).totalSupply();
        if (mintQueue.length <= totalSupply) {
            return;
        }

        address user = mintQueue[totalSupply];
        IZooGene(zooGene).safeMint(user, uri);
        emit MintFinish(user, uri, userInQueue[user]);
        userInQueue[user] = 0;
    } 
}

