// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @dev this is the interface of science fund token
 */

interface IBaseReceipt is IERC721Enumerable {
    // Enums representing the life cycle of each token
    enum Stage {
        AwaitAllocation,
        AwaitCompletion,
        Completed
    }

    // Events emitted related to SFT
    event SFTokenMinted(uint256 id, uint256 value, string pool);
    event SFTokenAllocated(uint256 id, string allocationHash);
    event SFTokenCompleted(uint256 id, string completeHash);

    function getStage(Stage stageEnum) public pure returns (string memory);

    function getSFToken(uint256 _tokenID) public view returns (SFtoken memory);
}
