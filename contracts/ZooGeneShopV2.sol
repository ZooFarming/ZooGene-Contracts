// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ZooGeneShop.sol";

contract ZooGeneShopV2 is ZooGeneShop {

    mapping(address=>uint) public banned;

    mapping(address=>string) public userRecaptcha;

    address public bannedNftMintTo;

    event Banned(address indexed _user, string recaptcha);

    function buy(string calldata _recaptcha) external whenNotPaused payable {
        require(banned[msg.sender] == 0, "User was banned");
        userRecaptcha[msg.sender] = _recaptcha;
        super.buy();
    }

    function ban(string calldata uri) external onlyRole(MINTER_ROLE) {
        uint totalSupply = IZooGene(zooGene).totalSupply();
        if (mintQueue.length <= totalSupply) {
            return;
        }

        address user = mintQueue[totalSupply];
        banned[user]++;
        emit Banned(user, userRecaptcha[user]);
        IZooGene(zooGene).safeMint(bannedNftMintTo, uri);
        emit MintFinish(user, uri, userInQueue[user]);
        userInQueue[user] = 0;
    }

    function configBannedMintTo(address _mintTo) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bannedNftMintTo = _mintTo;
    }

    function getNextUser() public view returns(address) {
        uint totalSupply = IZooGene(zooGene).totalSupply();
        if (mintQueue.length <= totalSupply) {
            return address(0);
        }

        return mintQueue[totalSupply];
    }
}
