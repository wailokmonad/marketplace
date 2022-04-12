// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';

interface IMarketplaceV2 {
    function offerMigrateFromV1 (address _owner, bool _isERC721, address _tokenAddress, uint _tokenId, uint _amount, uint _price ) external returns (uint);
}

contract Marketplace is Ownable, AccessControl, ReentrancyGuard, Pausable, ERC1155Holder, ERC721Holder {

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
	bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    uint public constant MAX_OFFER_SIZE = 50;

    uint public constant BASE = 100;

    uint public constant PLATFORM_COMMISSION = 1;

    struct Offer { 
        address owner;
        bool isERC721;
        address tokenAddress;
        uint tokenId;
        uint amount;
        uint price;
        bool sold;
    }

    Offer[] private _offer;

    event NewOfferAdded ( uint indexed id );
    event OfferCancelled ( uint indexed id );
    event Buy ( uint indexed id );
    event OfferEdited ( uint indexed id );

    /**
    * @dev Restricted to members of the admin role.
    */
    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Marketplace::onlyAdmin: Restricted to admins.");
        _;
    }

    /**
    * @dev Check if the address is zero
    */
    modifier notZeroAddress( address _tokenAddress ) {
        require( _tokenAddress != address(0) , "Marketplace::notZeroAddress: zero address is not allowed");
        _;
    }

    /**
    * @dev Check if the amount is zero
    */
    modifier notZeroAmount( uint _amount ) {
        require( _amount > 0 , "Marketplace::notZeroAmount: cannot be zero");
        _;
    }

    /**
    * @dev Check if this is a valid offer
    */
    modifier isValidOffer(uint _offerId) {
        require( _offerId >= 0 && _offerId < _offer.length , "Marketplace::isValidOffer: The offer doesn't exist");
        _;
    }

    constructor() { 
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }


    /**
     * @dev get the FULL offer object
     * @param _id the proposal id
     **/
    function offer ( uint _id ) 
        isValidOffer(_id)
        external virtual view returns ( Offer memory ) 
    {
        return _offer[_id];
    }


    /**
     * @dev get the number of total offers
     **/
    function numberOfOffer () external virtual view returns ( uint ) {
        return _offer.length;
    }


    /**
     * @dev batch get the FULL offer object
     * @param _startId the starting position
     * @param _endId the ending position
     **/
    function batchGetOffer( uint _startId, uint _endId ) 
        isValidOffer(_startId)
        isValidOffer(_endId)
        external virtual view returns ( Offer[] memory ) 
    {

        require( _endId > _startId, "Marketplace::batchGetOffer: endId should be larger than startId");
        require( _endId - _startId + 1 <= MAX_OFFER_SIZE, "Marketplace::batchGetOffer: Array too large");

        Offer[] memory result = new Offer[]( _endId - _startId + 1 );
        uint count = 0;

        for ( uint i = _startId; i < _endId + 1; i++ ) {
            result[count] = _offer[i];
            count++;
        }

        return result;

    }

    /**
     * @dev edit the offer
     * @param _offerId the offer Id
     **/
    function editOffer ( uint _offerId, uint _price ) external 
        isValidOffer(_offerId)
        notZeroAmount(_price)
        whenNotPaused
    { 
        Offer storage obj = _offer[_offerId];
        require(obj.owner == _msgSender(), "Marketplace::editOffer: Not the owner");
        require(obj.sold == false, "Marketplace::editOffer: Already sold");
        obj.price = _price;
        emit OfferEdited(_offerId);
    }


    


    /**
     * @dev offer the nft for sales
     * @param _tokenAddress token address
     * @param _tokenId the token Id
     * @param _amount the amount. It has to be 1 in the case of ERC721
     * @param _price the selling price
     **/
    function newOffer ( address _tokenAddress, uint _tokenId, uint _amount, uint _price ) external 
        notZeroAddress(_tokenAddress) 
        notZeroAmount(_amount)
        notZeroAmount(_price)
        nonReentrant
        whenNotPaused
        returns (uint)
    { 

        bool _isERC721 = IERC721(_tokenAddress).supportsInterface(_INTERFACE_ID_ERC721);
  
		if (_isERC721) {
            require( _amount == 1, "Marketplace::newOffer: amount must be 1 in the case of ERC721");
			IERC721(_tokenAddress).safeTransferFrom(_msgSender(), address(this), _tokenId);
		}  else  {
			IERC1155(_tokenAddress).safeTransferFrom(_msgSender(), address(this), _tokenId, _amount, '0x0');
		}
        
        _offer.push( Offer({
            owner: _msgSender(), 
            isERC721: _isERC721,
            tokenAddress: _tokenAddress,
            tokenId: _tokenId,
            amount: _amount,
            price: _price,
            sold: false
        }) );

        emit NewOfferAdded( _offer.length - 1 );

        return _offer.length - 1;

    }

    /**
     * @dev buy NFT
     * @param _offerId the offer Id
     **/
    function buy( uint _offerId ) external 
        isValidOffer(_offerId)
        nonReentrant
        whenNotPaused
        payable
    { 

        Offer storage obj = _offer[_offerId];

        require(obj.sold == false, "Marketplace::buy: Already sold");
        require( msg.value >= obj.price, "Marketplace::buy: The buying price is below the offer price");

        obj.sold = true;

        if (obj.isERC721) {
			IERC721(obj.tokenAddress).safeTransferFrom(address(this), _msgSender(), obj.tokenId);
		} else {
			IERC1155(obj.tokenAddress).safeTransferFrom(address(this), _msgSender(), obj.tokenId, obj.amount, '0x0');
		}

        payable(obj.owner).transfer( obj.price * (BASE - PLATFORM_COMMISSION) / BASE );


        emit Buy(_offerId);

    }

    /**
     * @dev cancel an offer
     * @param _offerId the offer Id
     **/
    function cancelOffer( uint _offerId ) external 
        isValidOffer(_offerId)
        nonReentrant
    { 

        Offer storage obj = _offer[_offerId];

        require(obj.owner == _msgSender(), "Marketplace::cancelOffer: Not the owner");
        require(obj.sold == false, "Marketplace::cancelOffer: Already sold");
  
        obj.sold = true;

        if (obj.isERC721) {
			IERC721(obj.tokenAddress).safeTransferFrom(address(this), _msgSender(), obj.tokenId);
		} else {
			IERC1155(obj.tokenAddress).safeTransferFrom(address(this), _msgSender(), obj.tokenId, obj.amount, '0x0');
		}

        emit OfferCancelled( _offerId );

    }


    /**
     * @dev For existing users to migrate the NFT and offer data to V2
     * @param _offerId the offer Id
     * @param _V2Address the V2 address
     **/
    function migrateToV2 ( uint _offerId, address _V2Address ) external 
        isValidOffer(_offerId)
        nonReentrant
        returns (uint)
    { 
        Offer storage obj = _offer[_offerId];

        require(obj.owner == _msgSender(), "Marketplace::migrateToV2: Not the owner");
        require(obj.sold == false, "Marketplace::migrateToV2: Already sold");

        obj.sold = true;

        if (obj.isERC721) {
			IERC721(obj.tokenAddress).safeTransferFrom(address(this), _V2Address, obj.tokenId);
		} else {
			IERC1155(obj.tokenAddress).safeTransferFrom(address(this), _V2Address, obj.tokenId, obj.amount, '0x0');
		}

        return IMarketplaceV2(_V2Address).offerMigrateFromV1(obj.owner, obj.isERC721, obj.tokenAddress, obj.tokenId, obj.amount, obj.price);

    }


    /**
     * @dev withdraw platform commission, callable only by admin
     **/
    function withdrawCommission() external onlyAdmin { 
        require( address(this).balance > 0, "Marketplace::withdrawCommission: No balance");
        payable(_msgSender()).transfer( address(this).balance );
    }

     /**
     * @dev return the current platform commission, callable only by admin
     **/
    function commission() external onlyAdmin virtual view returns (uint) { 
        return address(this).balance;
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
    function addAdmin(address _account) external virtual onlyOwner {
        grantRole(DEFAULT_ADMIN_ROLE, _account);
    }

   /**
    * @dev Remove an account from the admin role. Restricted to admins.
    * @param _account address from the account to add
    */  
    function removeAdmin(address _account) external virtual onlyOwner {
        revokeRole(DEFAULT_ADMIN_ROLE, _account);
    }

    /**
     * @dev Triggers stopped state.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     */
    function unpause() external onlyOwner {
        _unpause();
    }


    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}