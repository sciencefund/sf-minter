/**
 * SPDX-License-Identifier: MIT
 */

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @dev External interface of Science Fund Pool
 */

interface ScienceFundPool is IERC721Enumerable {
    
    function donate() external payable;


    //getters
    function getCappedValue() external view; 
    function getImageURI() external view;

    //write on each token metadata
    function getStatus() external view;
    function getCurrentValue() external view;
    function getAllocationHash() external view;
    function getCompletionHash() external view;

    //claim NFT drops
    function claim(address _backerAddress) external;


 }