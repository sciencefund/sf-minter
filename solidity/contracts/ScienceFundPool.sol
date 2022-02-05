// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//inherited
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IScienceFundPool.sol";
import "./IScienceFundRegistry.sol";

//imported standard
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
contract ScienceFundPool is Ownable, Pausable, ERC721Enumerable, IScienceFundPool {

    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    //Constants bytes for not applicable etc.


    // state variables for the pool
    string public imageURI;
    IScienceFundRegistry public registry;
    PoolStatus public status;
    // restricted to one accpeted Token for now. choice depends on big donor preference
    IERC20 private poolTxToken;
    uint256 public totalUnallocatedFund;
    
    //@dev capped amount???
    Counters.Counter private _tokenIdCounter;

    // tokenID -> amount in USDC donated
    mapping(uint256 => uint256) internal tokenIdValue;

    // @dev logic: should this be representatives of the pool of applicants or the
    bytes32 public constant TO_BE_ASSIGNED= keccak256("TO_BE_ASSIGNED");
    bytes32 public constant REMOVED = keccak256("REMOVED");
    

    struct Recipient {
        uint256 grantValue;
        address recipientAddress;
        bytes32 profileHash;
        bytes32 impactHash;
    }   

    mapping(address => Recipient) grantRecipients;


    //constructor
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _imageURI,
        address _acceptedTokenAddress
    ) ERC721(_name, _symbol) {
        imageURI = _imageURI;
        status = PoolStatus.Registering;
        poolTxToken = IERC20(_acceptedTokenAddress);
        totalUnallocatedFund = 0;
        registry = IScienceFundRegistry(msg.sender);
        //setup role ?
    }

    fallback() external payable {}

    receive() external payable {
        // emit Received(msg.sender, msg.value);
    }

    //external functions
    /**
     * emit event PoolStatusUpdated
     *  @param _newStatus the next status to be udpated too.
     *   
     *  Requirement:
     *      - only Admin can call this function
     *      - when the status is Complete, no more change is allowed.
     *
     * @dev should we allow the status to be changed back and forth? or only progression?
     */
    function changePoolStatus(PoolStatus _newStatus) external override onlyOwner {
        PoolStatus _oldStatus = status;
        require(
            status != PoolStatus.Complete,
            "Pool Status can't be changed after Complete."
        );
        status = _newStatus;
        emit PoolStatusUpdated(msg.sender, _oldStatus, _newStatus);
    }

    /**
     *   @notice mint a receipt NFT to the _to address
     *     with donation amount _amount in stablecoin _token;
     *  5% processing fees are transferred to the registry contract.
     *
     *   @param _to address to mint to
     *   @param _amount in that token
     *
     *   Requirements:
     *          - the pool status needs to be open to accept donations
     *          
     *   @dev may expand to other tokens.
     *   TODO: question should we donate to the pool or donate to potential recipients
     */
    function donate(address _to, uint256 _amount)
        external override
        onlyWhenStatus(PoolStatus.Open)
    {
        require(_to!=address(0), "zero address");
        require(_amount > 0.000001 ether, "donation amount smaller than minimum unit");
        // check decimal() of the IERC20 token

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
        
        //fees  TODO: add fee percentage as variable;
        uint256 fees = _amount * 0.05;
        uint256 donatedAmount = _amount * 0.95;

        
        tokenIdValue[tokenId] = donatedAmount;
        totalUnallocatedFund += donatedAmount;
        emit DonationReceived(msg.sender, donatedAmount, tokenId);


        poolTxToken.safeTransfer(address(this), _amount);
        // sciencefundtreasury
        poolTxToken.safeTransfer(address(registry), fees);
    }

    /**
     *  @notice assign grant value value in one go.
     *  @dev A batch version to assign by percent 
     *
     *  Requirements: 
     *  - should be only called once to assign a big batch;
     *  - there could be leftovers from the fund;
     *  
     * 
     * TODO: question 
     *     - two stage allocation: 
     *              - first: add recipient info (one by one)
     *              - second: assign value jointly with all recipients: 
     *     - advantage: keeping track of total value, could assign by percentage
     *     - disadvantage: more gas, less flexibility; pool closed; one extra
     *     - how much to allocate depends on 
     *          - how much is asked by the applicant?
     *          - how much is available to be assigned?
     *          - how much is worth: evaluated by someone or committee?
     */

    function batchAssignGrantByValue(
        address[] calldata _addresses,
        uint256[] calldata _grantValues
    ) external override onlyOwner onlyWhenStatus(PoolStatus.Closed) {
        //TODO: check how calldata work
        //TODO: check curve: keep track of total number of recipients;
        require(_addresses.length == _grantValues.length, "");
        require(_addresses.length <= 50, "exceeds maximum recipient number in this batch");

        //TODO: the sum of total grant values add up to the unAllocated values;
        uint assignedValue = 0;
        for (uint256 i = 0; i < addresses.length; i++){
            assignedValues+=_grantValue[i];
        }
        require(assignedValues <= totalUnallocatedFund, "exceeds total fund");


        for (uint256 i = 0; i < addresses.length; i++) {
            assignValue(_addresses[i], _grantValue[i]);
        }  
    }

    /**
     *  @dev question are we too strict with the status in terms of function calls?
     *  - does it create more txs and unnecessary restraints without security benefits?
     *  - what are the pool stages for? 
     *          - inform users or restrain function calls?
     */
    function assignValue(address _address, uint256 _value) public onlyOwner onlyWhenStatus(PoolStatus.Closed){
        require (_address != address(0), "zero address as recipient");
        // think: is it possible to have different, non-zero addresses?
        require (grantRecipients[_address].address == _address, "recipient does not exists");

        // reset instead of adding on; should check if previous value is zero? 
        require(grantRecipients[_address].grantValue == 0, "recipient value not reset to zero");
        grantRecipients[_address].grantValue = _value;

        require(_value > 0, "zero value in grant");
        require(_value <= totalUnallocatedFund, "exceeds total fund");
        totalUnallocatedFund -= _value;

        // before - after state change
        // emit unlocated fund change
        // emit recipient before and after change
        emit FundAllocated(_address, _value);
    }
    

    /**
     * Update Reciepient Info : address or profile only;
     */
    function updateRecipientInfo(address _oldAddress, address _newAddress, string memory _newProfile) public onlyOwner {
        require(_oldAddress != address(0), "Address cannot be zero");
        require(_newAddress != address(0), "Address cannot be zero");

        // this is only for address
        bool success = removeRecipient(_oldAddress);  
        if(success){
            addRecipientInfo(_newAddress,  _newProfile);
        }       
    }


    /**
     * @notice add recipient for the first time during allocation stage, without the amount
     * 
     */
    function addRecipientInfo(address _address, string memory _profile) public onlyOwner {
        //TODO: how to validate profile?
        require(_address != address(0), "Address cannot be zero");
        Recipient storage thisRecipient = grantRecipients[_address];
        require(thisRecipient.address == address(0), "Recipient already exists");
        grantRecipients[_address] = Recipient(0, _address, keccak256(_profile), TO_BE_ASSIGNED);
        // emit events on added recipient
    }


    /**
     * Remove Reciepient Info , reset all values
     */
    function removeRecipient(address _address) public onlyOwner returns(bool) {
        Recipient storage thisRecipient = grantRecipients[_address];

        require(thisRecipient.address == _address, "Recipient does not exist");
        grantRecipients[_address].address == address(0);
        grantRecipients[_address].profileHash == REMOVED;
        grantRecipients[_address].grantValue == 0;
        grantRecipients[_address].impactHash == REMOVED;

        return true;
        //emit event
    }


    // Internal functions
    /**
     *  @dev remove recipient should be allowed if anything has happened to the account or the recipient.
     *
     */
    function _resetGrantValue(address _address) internal onlyOwner {
        //check 
        require(_address != address(0), "address is zero");
        require(grantRecipients[_address].address == _address, "address exists");
        
        uint256 _oldValue =  grantRecipients[_recipientAddress].grantValue;
        require(_oldValue > 0, "Already reset to zero");
        totalUnallocatedFund += _oldValue;

        grantRecipients[_recipientAddress].grantValue = 0;
        //emit event
    }

    






    /**
     * @dev do we want the recepient to interact with this contract only once? or collect a small on the go until they exhaust their funds. they can even put in a phrase or two on the intent of the usage; we can set categories in advance;
     * @dev one possible compilcation could be that the recipient has compromised private key etc. 
     * @dev how to make sure recipient claims this money: what if they don't want it, not bothering doing it.
     //TODO: maybe onlyOwner? allow admin to withdraw grant for recipient if needed
     */
    function claimGrant(uint256 _amount)
        external
        onlyRecipient(msg.sender)
        onlyWhenStatus(PoolStatus.Active)
    {
        require(
            _amount <= recipientValue[msg.sender],
            "ScienceFundPool: not enough grant to withdraw"
        );
        recipientValue[msg.sender] -= _amount;
        poolTxToken.safeTransfer(msg.sender, _amount);
        //TODO: emit grant claiming event
    }

    /**
     * @dev how to make sure recipients report back - somebody has to work with them
     * //TODO: onlyOwner do it?
     */
    function reportImpact(string memory _reportHash)
        external
        onlyRecipient(msg.sender)
        onlyWhenStatus(PoolStatus.AssessingImpact)
    {
        recipientImpactReport[msg.sender] = _reportHash;
        //TODO: emit events
    }

    /**
     * @notice admin withdraws leftover unclaimed funds after the status is complete
     *
     */
    function withdraw() external onlyOwner onlyWhenStatus(PoolStatus.Complete) {
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

    modifier onlyRecipient(address _address) {
        require(
            grantRecipients.contains(_address),
            "ScienceFundPool: Not A Grant Recipient"
        );
        _;
    }

    modifier beforeComplete() {
        require(status != PoolStatus.Complete, "ScienceFundPool: no more change after completion");
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
            abi.encodePacked(
                "Science Fund ",
                name(),
                " - #",
                _tokenId.toString()
            )
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
