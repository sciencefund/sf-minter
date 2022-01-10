// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ScienceFundReceiptBase.sol";

/**
 * @title Science Fund
 *
 * @notice this is the science fund contract that
 *      - permanently stores donation value, donation pool on chain on minting
 *      - returns a dynamically generated receipt in tokenURI
 *      - allows update to allocation and completion hash later by owner
 *      - reflects the updates in tokenURI
 *
 * @author uranutan
 */

contract ScienceFundReceipt is ScienceFundReceiptBase {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    constructor() ScienceFundReceiptBase("ScienceFundReceipt", "SFR") {}

    /**
     * @notice donate function to mint a sftoken receipt
     *
     * @dev this function triggers a SFTokenMinted event
     *
     * @param - the account from which the donation is from
     * @param - the amount donated
     */
    function donate(address _from, string memory _selectedPool)
        public
        payable
        returns (uint256)
    {
        require(
            msg.value > 1 * 10**15,
            "ScienceFund: minimum value of 0.001ETH is required"
        );

        /// generate a new tokenID
        _tokenIds.increment();
        uint256 newTokenID = _tokenIds.current();

        // mint
        _safeMint(_from, newTokenID);

        // update SFTokens
        _setSFToken(
            newTokenID,
            SFtoken(
                newTokenID,
                msg.value,
                _selectedPool,
                getStage(Stage.AwaitAllocation),
                getStage(Stage.AwaitAllocation)
            )
        );

        //emit a donated event
        emit SFTokenMinted(newTokenID, msg.value, _selectedPool);
        return newTokenID;
    }

    /**
     * @dev call allocate() after the token has been allocated to update allocation hash
     */

    function allocate(uint256 _tokenId, string memory _allocationHash)
        public
        onlyOwner
    {
        _updateStage(_tokenId, Stage.AwaitAllocation, _allocationHash);

        /// @notice Emit Event TokenAllocated()
        emit SFTokenAllocated(_tokenId, _allocationHash);
    }

    /**
     * @dev call complete() after the token has been allocated to update complete hash
     */

    function complete(uint256 _tokenId, string memory _completeHash)
        public
        onlyOwner
    {
        _updateStage(_tokenId, Stage.AwaitCompletion, _completeHash);

        /// @notice Emit Event SFTokenComplete()
        emit SFTokenCompleted(_tokenId, _completeHash);
    }

    /**
     * @dev this helper function helps update the allocation/completion stage using a tokenID
     */
    function _updateStage(
        uint256 _tokenId,
        Stage _oldStage,
        string memory _newHash
    ) internal virtual {
        require(
            _exists(_tokenId),
            "ScienceFund: Token needs to be minted first"
        );

        SFtoken memory token = getSFToken(_tokenId);

        if (_oldStage == Stage.AwaitAllocation) {
            require(
                keccak256(bytes(token.alloHash)) ==
                    keccak256(bytes(getStage(_oldStage))),
                "ScienceFund: the token need not been allocated yet"
            );

            token.alloHash = _newHash;
            token.completeHash = getStage(Stage.AwaitCompletion);
        }

        if (_oldStage == Stage.AwaitCompletion) {
            require(
                keccak256(bytes(token.completeHash)) ==
                    keccak256(bytes(getStage(Stage.AwaitCompletion))),
                "ScienceFund: the token needs to be allocated and yet not been completed "
            );

            token.completeHash = _newHash;
        }

        _setSFToken(_tokenId, token);
    }

    function withdraw() public onlyOwner {
        // TODO: withdraw with respect to funding pool?
    }
}
