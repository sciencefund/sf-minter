// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


/**
 * @title Science Fund
 *
 * @notice this is the science fund contract that
 *      - permanently stores donation value, donation pool on chain on minting
 *      - returns a dynamically generated receipt in tokenURI
 *      - allows update to allocation and completion hash later by owner
 *      - reflects the updates in tokenURI metadata
 * 
 * 
 */

//function ordering : constructor, fallback, external, public, internal, private
contract ScienceFundPool is
    Ownable,
    Pausable,
    ERC721Enumerable
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeERC20 for IERC20;
    Counters.Counter private _tokenIdCounter;

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

    // state variables
    string public imageURI;
    PoolStatus public status;
    //TODO: a set of accepted tokens

    //TODO: initiate with USDC, USDT etc.
    mapping (address => string) acceptedERC20Coins;
    //TODO: recipients address set, allow them to claim donation
    //TODO: each recipient could have two hash with before and after, how much they received,

    // tokenID -> amount in USDC
    mapping (uint256 => uint256) internal tokenValue;
    mapping (uint256 => string) internal tokenCoin;
    
    //constructor
    constructor(string memory _name, string memory _symbol, string memory _imageURI)
        ERC721(_name, _symbol)
    {
        imageURI = _imageURI;
        status = PoolStatus.Registering;
    }   

    fallback() external payable{}
    receive() external payable {
        // emit Received(msg.sender, msg.value);
    }
    //external function
    function changePoolStatus(PoolStatus _newStatus) external onlyOwner {
        status = _newStatus;
    }


    /**
    *    @notice mint a receipt NFT to the _to address  
    *     with donation amount _amount in stablecoin _token 
    *   
    *   @param _to address to mint to
    *   @param _assetAddress accepted token address 
    *   @param _amount in that token
    *   
    *   @dev how to make sure the type of IERC20 tokens we accept ? 
    *   @dev how to keep track of the total amount of tokens we accepted ?
    */
    function donate(address _to, address _assetAddress, uint256 _amount) external onlyWhenStatus(PoolStatus.Open) {

        // require token to be part of the accepted set
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
        
        tokenCoin[tokenId] = acceptedERC20Coins[_assetAddress];
        tokenValue[tokenId] = _amount;
        //TODO:  emit Donation event 
        IERC20(_assetAddress).safeTransfer(address(this), _amount);
        }
  
  
    /**
     * @notice this generates a dynamic metadata as a  receipt for the donation and this receipt will update the allocation and completion status accordingly in the medadata
     *
     * @param _tokenId is the pool specific tokenID
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _tokenId <= totalSupply(),
            "ScienceFund: Token needs to be minted first"
        );

// _receiptMetadata(uint256 _amount, address _assetAddress, uint256 _tokenId)
        return _receiptMetadata(tokenValue[_tokenId], tokenCoin[_tokenId], _tokenId);
    }



    //public function
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    // internal functions
    modifier onlyWhenStatus(PoolStatus _status) {
        require(status == _status, "ScienceFundPool: wrong pool status");
        _;
    }
    /**
     * @notice this function dynamically generates token metadata given the donation information
     * @param  _amount donated amount for this token
     * @param _coinName  ERC20 token name; denomination of the donation
     * @param _tokenId this tokenId
     * @return json output of metadata of this token 
     */
     
    function _receiptMetadata(uint256 _amount, string memory _coinName, uint256 _tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        //TODO: how to format the value ????
        string memory tokenValueString = _amount.toString(); 
    
        string memory heading = string(
            abi.encodePacked("Science Fund ", name()," - #", _tokenId.toString())
        );
         string memory description = string(
            abi.encodePacked(
                "This NFT represents a permanent receipt to your donation of ",
                tokenValueString, 
                _coinName,
                "to Science Fund - ",
                name(),
                "This token connects your donation to the selected recipients and tracks the impact it enables for generations to come."
            )
        );
        return
            string(
                abi.encodePacked(
                    'data:application/json, {"name": "',
                    heading,
                    '", "description":"',
                    description,
                    '", "image":"',
                    "data:image/svg+xml;base64,",
                    imageURI,
                    '"}'
                )
            );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    //private functions


    
    // The following functions are overrides required by Solidity.

    // function supportsInterface(bytes4 interfaceId)
    //     public
    //     view
    //     override(ERC721Enumerable)
    //     returns (bool)
    // {
    //     return super.supportsInterface(interfaceId);
    // }
}
