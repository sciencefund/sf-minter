// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//function ordering : constructor, fallback, external, public, internal, private
contract ScienceFundRegistry is Ownable {

    /**
     * @notice this enum represents the life cycle of a particular pool, which can be referenced from each token. This assumes that all tokens in the same pool are in sync with each other, following the same update. 
     */


    event NewPoolAdded();
    event PoolRemoved();
    event PoolMaxAmountReached();
    event PoolValueIncreased();


    // state variables
    struct Pool {
        string name;
        uint256 cappedValue; // in USD using stablecoin
        uint256 currentValue;
        string imageURI;
    }

    Pool[] SFPools;
    // address set of all deployed address 

    //external function
    function deployNewPool(string memory _name, uint cappedValue) external onlyOwner {
        // 
        // deploy a new pool contract
        // new SFPool()
    } 

    

}

