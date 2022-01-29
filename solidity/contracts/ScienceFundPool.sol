// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//inherited
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

//imported
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//library
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


/**
 * @title Science Fund Pool
 *
 * @notice  Science Fund Pool is an ERC721-compliant contract that mints ERC721 tokens 
 * that are traceable receipts for each donation.  This contract is pauseable and ownable.
 *
 *
 * When the donation pool is open, one can mint a token with its donation amount, donation domination
 * written in the metadata. This information will be permanently stored on chain in this contract.
 * 
 * When the pool is closed for allocation, a set of recipients will be added to the contract and they  
 * can withdraw its corresponding funding by calling the claimGrant() function. Grant allocation 
 * information will be updated on chain and also reflected in the metadata of each minted tokens.
 * 
 * After the fund has been allocated, the status of the pool will be set to ACTIVE, 
 * this is when active research activities are conducted off line.
 *
 * Once the grant period runs out, the status of the pool will be set to AssessingImpact, and
 * 
 *
 * @dev ownable gives access to the factory contract directly. AccessControl assigns roles for recipients.
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
    using EnumerableSet for EnumerableSet.AddressSet;


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

    // state variables for the pool
    string public imageURI;
    PoolStatus public status;
    // restricted to one accpeted Token for now. choice depends on big donor preference  
    IERC20 private poolTxToken; 
    uint256 public totalGrantRaised;
    
    //@dev capped amount???
    Counters.Counter private _tokenIdCounter;
    EnumerableSet.AddressSet private grantRecipients;


    // tokenID -> amount in USDC
    mapping (uint256 => uint256) internal tokenIdValue;
    // @recipient -> value granted 
    // @dev depending on the withdrawal machanism: it could be value left;
    mapping (address => uint256) private recipientValue;
    //@recipient -> 
    // @dev logic: should this be representatives of the pool of applicants or the 
    // @dev this should be enumerable? all on metadata for all coins?
    mapping (address => string) public recipientProfile;
    mapping (address => string) public recipientImpactReport;

    
    //constructor
    constructor(string memory _name, string memory _symbol, string memory _imageURI, address _acceptedTokenAddress)
        ERC721(_name, _symbol)
    {
        imageURI = _imageURI;
        status = PoolStatus.Registering;
        poolTxToken = IERC20(_acceptedTokenAddress);
    }   

    fallback() external payable{}
    receive() external payable {
        // emit Received(msg.sender, msg.value);
    }

    //external function
    /**
     *  @dev  make sure complete is the absorbing state
     *  @dev should we allow the status to be changed back and forth? or only progression?
     */
    function changePoolStatus(PoolStatus _newStatus) external onlyOwner {
        require(status != PoolStatus.Complete, "Pool Status can't be changed after Complete.");
        status = _newStatus;
    }

    /**
     *   @notice mint a receipt NFT to the _to address  
     *     with donation amount _amount in stablecoin _token 
     *   
     *   @param _to address to mint to
     *   @param _amount in that token
     *   
     *   @dev how to make sure the type of IERC20 tokens we accept ? 
     *   @dev how to keep track of the total amount of tokens we accepted ?
    */
    function donate(address _to, uint256 _amount) external onlyWhenStatus(PoolStatus.Open) {

        // require token to be part of the accepted set
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
        tokenIdValue[tokenId] = _amount;
        totalGrantRaised += _amount;
        //TODO:  emit Donation event 
        poolTxToken.safeTransfer(address(this), _amount);
        }

    /**
     *  @dev taken out 10% for processing to ScienceFund account??
     * 
     */
    function allocateFund(address _recipientAddress, string memory _profileHash, uint256 _grantValue) external onlyOwner onlyWhenStatus(PoolStatus.Closed){
            grantRecipients.add(_recipientAddress);
            recipientValue[_recipientAddress] = _grantValue;
            recipientProfile[_recipientAddress] = _profileHash;            
    } 

    /**
     * @dev do we want the recepient to interact with this contract only once? or collect a small on the go until they exhaust their funds. they can even put in a phrase or two on the intent of the usage; we can set categories in advance;
     * @dev one possible compilcation could be that the recipient has compromised private key etc. 
     * @dev how to make sure recipient claims this money: what if they don't want it, not bothering doing it.
     */
    function claimGrant(uint256 _amount) external onlyRecipient(msg.sender) onlyWhenStatus(PoolStatus.Active){ 
            require(_amount <= recipientValue[msg.sender], "ScienceFundPool: not enough grant to withdraw");
            recipientValue[msg.sender] -= _amount; 
            poolTxToken.safeTransfer(msg.sender, _amount);
            //TODO: emit grant claiming event
    }

    /**
     * @dev how to make sure recipients report back - somebody has to work with them
     */
    function reportImpact(string _reportHash) external onlyRecipient(msg.sender) onlyWhenStatus(PoolStatus.AssessingImpact){        
        recipientImpactReport[msg.sender] = _reportHash;
        //TODO: emit events
    }
    /**
     * @notice admin withdraws leftover unclaimed funds after the status is complete
     *
     */
    function withdraw() external onlyOwner onlyWhenStatus(PoolStatus.Complete){
        uint256 leftOverBalance = poolTxToken.balanceOf(address(this));
        poolTxToken.safeTransfer(msg.sender, leftOverBalance);
        //TODO: emit events
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

        return _receiptMetadata(tokenIdValue[_tokenId], _tokenId);
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


    modifier onlyRecipient(address _address){
        require(grantRecipients.contains(_address), "ScienceFundPool: Not A Grant Recipient");
        _;
    }

    /**
     * @notice this function dynamically generates token metadata given the donation information
     * @param  _amount donated amount for this token
     * @param _tokenId this tokenId
     * @return json output of metadata of this token 
     */

    function _receiptMetadata(uint256 _amount, uint256 _tokenId)
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
                "USD",
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


    //private functions

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

}
