// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";

/**
 * @title Science Fund Receipt Base
 *
 * @dev Science Fund Receipt is an ERC721- compliant token that tracks the stages of a science fund donation life cycle.
 * @author uranutan
 */

contract ScienceFundReceiptBase is ERC721Enumerable, Ownable {
    using Strings for uint256;

    constructor(string memory _name, string memory _symbol) {
        ERC721(_name, _symbol);
    }

    struct ReceiptToken {
        uint256 tokenId;
        uint256 value;
        string pool;
        string alloHash;
        string completeHash;
    }

    //mapping from tokenId to sfToken
    mapping(uint256 => ReceiptToken) private _receiptTokens;

    /**
     * @notice this generates a dynamic sftoken receipt for the donation and this receipt will update the allocation and completion status accordingly
     *
     * @dev input is a tokenID
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

        return _constructTokenURImetadata(getSFToken(_tokenId));
    }

    /**
     * @dev this function returns Enums to strings
     */
    function getStage(Stage stageEnum) public pure returns (string memory) {
        if (stageEnum == Stage.AwaitAllocation) {
            return "Awaiting Allocation";
        } else if (stageEnum == Stage.AwaitCompletion) {
            return "Awaiting Completion";
        } else {
            return "Completed";
        }
    }

    /**
     * @dev this function returns an SFToken from a tokenID
     */
    function getSFToken(uint256 _tokenID)
        public
        view
        returns (ReceiptToken memory)
    {
        return _receiptTokens[_tokenID];
    }

    /**
     * @dev this function set an SFToken using a tokenID
     */
    function _setSFToken(uint256 _tokenID, ReceiptToken memory _sft)
        internal
        virtual
    {
        _receiptTokens[_tokenID] = _sft;
    }

    /**
     * @dev this function put together the dynamically generated token metadata for tokenURI
     */
    function _constructTokenURImetadata(ReceiptToken memory _params)
        internal
        pure
        virtual
        returns (string memory)
    {
        string memory tokenIDstring = _params.tokenId.toString();

        /**
        @dev how to convert from WEI to ETH with all decimals, this only saves to 1dp
         */

        string memory value1 = (_params.value / 1e18).toString();
        string memory value2 = ((_params.value / 1e17) % 10).toString();
        string memory tokenValueString = string(
            abi.encodePacked(value1, ".", value2)
        );

        string memory name = string(
            abi.encodePacked("Science Fund Token - #", tokenIDstring)
        );

        string memory description = string(
            abi.encodePacked(
                "This NFT represents a permanent receipt to your donation of ",
                tokenValueString,
                " Wei to Science Fund - ",
                _params.pool,
                " funding pool. This token connects your donation to the recepient and the impact it enables for generations to come."
            )
        );

        return
            string(
                abi.encodePacked(
                    'data:application/json, {"name": "',
                    name,
                    '", "description":"',
                    description,
                    '", "image":"',
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        bytes(
                            ReceiptImage(
                                tokenIDstring,
                                tokenValueString,
                                _params.pool,
                                _params.alloHash,
                                _params.completeHash
                            )
                        )
                    ),
                    '"}'
                )
            );
    }

    /**
     * @dev this implements the actual graphic with SFT parameters
     */
    function ReceiptImage(
        string memory _id,
        string memory _amount,
        string memory _pool,
        string memory _alloHash,
        string memory _completeHash
    ) internal pure virtual returns (string memory svg) {
        // add randomness here for visual enhancement
        uint256 r = uint256(keccak256(bytes(_id))) % 255;
        uint256 g = uint256(keccak256(bytes(_amount))) % 255;
        uint256 b = uint256(keccak256(bytes(_pool))) % 255;

        string memory color = string(
            abi.encodePacked(
                '"rgb(',
                r.toString(),
                ",",
                g.toString(),
                ",",
                b.toString(),
                ')"'
            )
        );

        svg = string(
            abi.encodePacked(
                '<svg version="1.1" viewBox="0 0 331 426" width="331" height="426" preserveAspectRatio="xMidYMin" xmlns="http://www.w3.org/2000/svg"><rect width="100%" height="100%" fill="#FFFFFF" /><text x="165" y="60" font-size="45" text-anchor="middle" fill="black" font-weight="normal">SFT-',
                _id,
                '</text><text x="165" y="90" font-size="12" text-anchor="middle" fill="black" font-weight="noraml" font-style="italic">Reimagine Scientific Discovery</text><filter id="insetshadow"><feOffset in="SourceGraphic" dx="0" dy="20" result="offOut" /><feGaussianBlur in="offOut" stdDeviation="20" result="offset-blur"/><feComposite operator="out" in="SourceGraphic" in2="offset-blur" result="inverse"/><feFlood flood-color=',
                color,
                ' flood-opacity=".35" result="color"/><feComposite operator="in" in="color" in2="inverse" result="shadow"/></filter><g filter="url(#insetshadow)"><circle cx="167" cy="212" r="100" fill="#FFFFFF" stroke="#F99500" stroke-width="5" /></g><circle cx="168" cy="167" r="15" fill="#FFFFFF" stroke="#F99500" stroke-width="4" /><circle cx="217" cy="208" r="15" fill="#FFFFFF" stroke="#F99500" stroke-width="4" /><circle cx="125" cy="241" r="15" fill="#FFFFFF" stroke="#F99500" stroke-width="4" /><line x1="168" y1="188" x2="168" y2="312" stroke="#068B0B" stroke-width="4" stroke-linecap="round" /><path d="M 168 312 Q 168 241, 198 218" stroke="#068B0B" stroke-width="4" fill="transparent" stroke-linecap="round" /><path d="M 168 312 Q 168 261, 144 249" stroke="#068B0B" stroke-width="4" fill="transparent" stroke-linecap="round" /><text x="165" y="344" font-size="12" text-anchor="middle" font-weight="normal" fill="black">',
                _amount,
                ' ETH </text><text x="165" y="362" font-size="10" text-anchor="middle" font-weight="normal" fill="black">Allocation Hash : ',
                _alloHash,
                '</text><text x="165" y="380" font-size="10" text-anchor="middle" font-weight="normal" fill="black">Completion Hash: ',
                _completeHash,
                '</text><text x="165" y="409" font-size="12" text-anchor="middle" font-weight="bold" fill="#F99500">',
                _pool,
                "</text></svg>"
            )
        );
    }
}
