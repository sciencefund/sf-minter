/**
 * SPDX-License-Identifier: MIT
 */

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @dev External interface of Science Fund Pool
 */

interface IScienceFundPool is IERC721Enumerable {
    
    
    /**
     * @dev this enum represents the life cycle of a particular pool, which can be referenced from each token. This assumes that all tokens in the same pool are in sync with each other, following the same update.
     */
    
    enum PoolStatus {
        Registering,
        Open,
        Closed,
        Active,
        AssessingImpact,
        Complete
    }


    /**
     * @dev Emitted when `tokenId` token is minted by calling donate() function.
     */
    event DonationReceived(address indexed _from, uint256 indexed _amount, uint256 indexed _tokenId);

    event PoolStatusUpdated(address indexed _from, PoolStatus  _oldStatus, PoolStatus  _newStatus);

    event FundAllocated(address indexed _recepient, uint256 indexed _grantValue);

    event RecipientAddressUpdated(address indexed _oldRecipientAddress, address indexed _newAddress);

    //admin functions
    function changePoolStatus(PoolStatus _newStatus) external;

    function allocateFund(
        address _recipientAddress,
        string memory _profileHash,
        uint256 _grantValue
    ) external;

    function updateRecipientAddress(address _oldRecipientAddress, address _newAddress) external;

    // //user functions
    function donate(address _to, uint256 _amount) external;



    // //getters
    // function getCappedValue() external view; 
    // function getImageURI() external view;

    // //write on each token metadata
    // function getStatus() external view;
    // function getCurrentValue() external view;
    // function getAllocationHash() external view;
    // function getCompletionHash() external view;

    // //claim NFT drops
    // function claim(address _backerAddress) external;


 }