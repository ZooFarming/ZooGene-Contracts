// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

interface IOracle {
    function getValue(bytes32 key) external view returns(uint);
}

contract ZooGeneShop is AccessControl, ERC721Holder, Initializable {

    struct NftPhaseInfo {
        uint maxCount;
        uint soldCount;
        uint usdPrice;
    }

    mapping(uint=>NftPhaseInfo) public phaseInfo;

    address public priceOracle;

    uint public currentPhase;

    event BuyZooGene(address indexed _user, uint256 priceInUsd, uint256 priceInWan);

    function initialize(address _admin, address _priceOracle) initializer public {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        priceOracle = _priceOracle;

        phaseInfo[0] = NftPhaseInfo({
            maxCount: 5000,
            soldCount: 0,
            usdPrice: 60 ether
        });

        phaseInfo[1] = NftPhaseInfo({
            maxCount: 3000,
            soldCount: 0,
            usdPrice: 100 ether
        });

        phaseInfo[2] = NftPhaseInfo({
            maxCount: 2000,
            soldCount: 0,
            usdPrice: 120 ether
        });
    }

    function buy() external payable {
        NftPhaseInfo storage info = phaseInfo[currentPhase];
        uint wanNeed = getWanPriceByUSD(info.usdPrice);
        require(msg.value >= wanNeed, "WAN not enough");
        require(info.soldCount + 1 <= info.maxCount, "sold out");
        if (msg.value > wanNeed) {
            payable(msg.sender).transfer(msg.value - wanNeed);
        }
        info.soldCount++;
        emit BuyZooGene(msg.sender, info.usdPrice, wanNeed);
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
}

