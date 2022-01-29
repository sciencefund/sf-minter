# Science Fund Receipt (SFR) Token Design Specification

This documents specifies the design considerations of Science Fund Receipt Token (SFR). SFR is an ERC721-compatible token that is issued and generated on the fly as a receipt for donations. 

This token serves as a window for backers to trace their donation impact through eternity.



## **Information Associated with each SFR**



Here are the properties that we'd like to associate with each SFR with consideration for future features.

```
//TODO: do we want each token to be burnable?
```
**Donation Pool**

Each donation pool has its own story. Each pool represents a theme and needs to be operated in a cycle on its own. It provides the eventual allocation hash, completion hash common to all the SFRs generated through each donation cycle. 

- capped amount for each pool


- total amount of tokens in the pool can be withdrawn by authorised persons, somehow unified for each acceptible IERC20 type.

- has its own allocation page once allocated : this can be then the allocation hash on the token

    
- stages and time limits (on-chain activities) 

    1.  `Registering` : marketing for the pool, telling the stories of this pool 
    
    2.  `Open`: accepting donations and allows minting of SFRs
    
    3. `Closed`: allocating tokens receipted and updating the allocation hash on each SFR 

    4. `Active`: the period when the grants are actively used for research related activities

    5. `AssessingImpact` : accessing impacts from the research activities 
    
    6. `Complete`: updating impact report hash to each SFR in the pool.  

    7. (`future upgrade` when DeSci is more mature and interconnected) track citations of papers generated in this pool as a whole 


**IERC20-type Accepted Tokens +  Amount**

We should be able to accept donations in stablecoins for each administering, reporting and dispersing. This is a good bridge for us to get adoption from insitutions. 
For simplicity, we should accept tokens and also give away tokens in 

- USDC
- USDT

Depending on the network, I need to work out how to do gasless/batch transactions to make it easy to donate only with stablecoins.

- ETH
- MATIC - if we deploy on Polygon

`future upgrade` : 
 - add more tokens 
 - gasless transactions

**Token Metadata - TokenURI**

The metadata changes during the cycle includes

- all the on-chain informations
- can be traded on major NFT market places: OpenSea, Zora, Rarible etc.
- on a web2 server? otherwise will change three times based on the content


**Token Format**

Note an ERC721-compatible token does not have to be an image. The whole purpose of this receipt is to be able to trace the donation. I imagine something that the owner of the SFR to tap on the SFR to get to where the money associated with the token has gone to; another tap on a different area of the SFR, we get to the completion report. Hence it would be 

- an `<iframe>` with clickable areas
- with background image as Receipt Image
- top-half clickable when allocations completed
- bottom-half clickable when completed with impact report


**Receipt Image**

This is a branding image administered by Science Fund to make SFR more appealing. This could be pool-specific and allows to be updated through different donation cycles.


 - once generated in an SFR, it should stay the same
   
 - can be updated for different donation pools
    
 - can be udpated for future mints

**Allocation Hash**



**Completion Hash**

- when it is completed, it should lock changes to key variables

- but leave it open for future potential integration with citation tracing




## **Acccess Control**

Here are some access control mechanisms for token transfer (when allocating fund) and emergency responses as well as future planning.

**Who can withdraw**

- give allowance to receipients to call `withdraw` function to claim the associated amount and token?

- centrally handled by SF team?


**In case of being hacked**


- should be able to pause the contract and stops all token transfers

- in case of compromised keys: what's our emergency response?

- multisig deployment (integration with gnosis safe?)


**Upgradeable**

