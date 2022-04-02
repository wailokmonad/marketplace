// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Counters.sol";

contract NonERC721Token  {

    using Counters for Counters.Counter;

    string public name;

    string public symbol;

    Counters.Counter public tokenIdTracker;

    mapping(uint256 => address) public owners;

    mapping(address => uint256) public balances;


    constructor(string memory _name, string memory _symbol)  {
        name = _name;
        symbol = _symbol;
    }   


    function create(address to) external  {
        tokenIdTracker.increment();
        _mintTo(to, tokenIdTracker.current());
    }


    function _mintTo(address to, uint256 tokenId) internal  {
        require(to != address(0), "NonERC721Token: mint to the zero address");
        require(!_exists(tokenId), "NonERC721Token: token already minted");
        balances[to] += 1;
        owners[tokenId] = to;
    }


    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return owners[tokenId] != address(0);
    }


}