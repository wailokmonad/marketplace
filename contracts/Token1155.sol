// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Token1155 is ERC1155, Ownable, AccessControl {

    /**
    * @dev Restricted to members of the admin role.
    */
    modifier onlyMinter() {
        require(isAdmin(_msgSender()), "Token1155::onlyMinter: Restricted to admins.");
        _;
    }


    constructor() ERC1155("https://testing/item/") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }


    /**
    * @dev mint a single token to a receiver
    * @param _id token ID
    * @param _receiver address of the receiver
    * @param _amount the amount of token to be minted
    */  
    function mintTo(uint _id, address _receiver, uint _amount) public onlyMinter {
        _mint(_receiver, _id, _amount, "");
    }


    /**
    * @dev batch mint multiple token to a receiver 
    * @param _ids the array of token ID
    * @param _receiver address of the receiver
    * @param _amounts the array of amount of token to be minted
    */  
    function batchMintTo(address _receiver, uint256[] memory _ids, uint256[] memory _amounts) public onlyMinter {
        _mintBatch(_receiver, _ids, _amounts, "");
    }


    /**
     * @dev get the url from the Id.
     * @param _id token Id 
     */
    function uri(uint _id) public view virtual override(ERC1155) returns (string memory) {
        return bytes( super.uri(_id) ).length > 0 ? string( abi.encodePacked( super.uri(_id), Strings.toString(_id), ".json" ) ) : "";
    }


    /**
     * @dev set the url
     * @param _newuri the url string
     */
    function setURI(string memory _newuri) public onlyMinter {
        _setURI(_newuri);
    }

    /**
    * @dev returns `true` if the account belongs to the admin role.
    * @param _account address from the account to check
    */  
    function isAdmin(address _account) public virtual view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _account);
    }

    /**
    * @dev Add an account to the admin role. Restricted to admins.
    * @param _account address from the account to add
    */   
    function addAdmin(address _account) public virtual onlyOwner {
        grantRole(DEFAULT_ADMIN_ROLE, _account);
    }

   /**
    * @dev Remove an account from the admin role. Restricted to admins.
    * @param _account address from the account to add
    */  
    function removeAdmin(address _account) public virtual onlyOwner {
        revokeRole(DEFAULT_ADMIN_ROLE, _account);
    }

    
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}