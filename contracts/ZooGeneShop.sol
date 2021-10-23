// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract ZooGeneShop is AccessControl, ERC721Holder, Initializable {

    

    function initialize(address _admin) initializer public {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }


}

