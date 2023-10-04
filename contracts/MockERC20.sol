// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockERC20 is ERC20, Ownable {
    bool _isMintable = false;

    constructor() ERC20("Lockon Token", "LOCKON") {
        _mint(msg.sender, 100_000_000 * 10 ** 18);
    }

    modifier isMintable() {
        require(_isMintable, "Token: It's not mintable");
        _;
    }

    function setIsMintable(bool mintable) external onlyOwner {
        _isMintable = mintable;
    }

    function mint(address to, uint256 _amount) public isMintable {
        _mint(to, _amount);
    }

    function getMintFunctionSelector(
        address to,
        uint256 _amount
    ) public pure returns (bytes memory) {
        bytes4 functionSelector = bytes4(
            keccak256(bytes("mint(address, uint256)"))
        );
        return abi.encodeWithSelector(functionSelector, to, _amount);
    }
}
