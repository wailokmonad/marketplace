// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract Token721 is ERC721, ERC721Enumerable, Ownable, AccessControl {

    using Counters for Counters.Counter;

    uint public constant MAX_BATCH_MINTING = 100;

    Counters.Counter private _tokenIdTracker;

    mapping(uint256 => string) private _tokenURI;

    event tokenMinted(address indexed _receiver, uint256 indexed _tokenId, string indexed _url);
    
   /**
    * @dev Restricted to members of the admin role.
    */
    modifier onlyMinter() {
        require(isAdmin(_msgSender()), "Token721::onlyMinter: Restricted to admins.");
        _;
    }
    
    constructor(
        string memory _name, 
        string memory _ticker
    ) ERC721(_name, _ticker) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }


    /**
    * @dev mint a single token to a received with its _uri
    * @param _uri of the token in string comma separated
    * @param _receiver address of the receiver
    */  
    function mintTo(string memory _uri, address _receiver) external onlyMinter {
        _mintTo(_uri, _receiver);
    }
    

   /**
    * @dev mint a batch of token to many different users
    * @param _uris of the tokens in string comma separated organized sequencially an array list
    * @param _receivers address of the receivers in an array list
    */  
    function batchMintTo (string[] memory _uris, address[] memory _receivers) external onlyMinter {
        require(_uris.length == _receivers.length, "Token721::batchMintTo: invalid parameters length (they should be all same)");
        require(_uris.length <= MAX_BATCH_MINTING, "Token721::batchMintTo: Quantity cannot be bigger than MAX_BATCH_MINTING.");

        for (uint i = 0; i < _receivers.length; i++) {
            _mintTo(_uris[i], _receivers[i]);
        }
    }

    /**
    * @dev mint a token and assign the uris, emits an tokenMinted event every time is called
    * @param _uri of the token in ipfs
    * @param _receiver address of the receiver
    */  
    function _mintTo(string memory _uri, address _receiver) internal {
        _tokenIdTracker.increment();
        uint256 mintIndex = _tokenIdTracker.current();
        _safeMint(_receiver, mintIndex);
        _setTokenURI(mintIndex, _uri);
        emit tokenMinted(_receiver, mintIndex, _uri);
    }


    /**
     * @dev set _tokenURI.
     * @param _tokenId token Id 
     * @param _url the url string
     */
    function _setTokenURI(uint256 _tokenId, string memory _url) internal virtual {
        require(_exists(_tokenId), "Token721::_setTokenURI: URI set of nonexistent token");
        _tokenURI[_tokenId] = _url;
    }


    /**
     * @dev get _tokenIdTracker.
     */
    function getTokenIdTracker() public view returns (uint) {
        return _tokenIdTracker.current();
    }


    /**
     * @dev get the tokenURI from the Id.
     * @param _tokenId token Id 
     */
    function tokenURI(uint256 _tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(_tokenId), "Token721::tokenURI: URI set of nonexistent token");
        return _tokenURI[_tokenId];
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
    

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
