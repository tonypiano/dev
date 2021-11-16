// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;


contract ETHTransferScript {
    function transferETH(address _recipient, uint256 _amount) external returns (bool) {
        require(1 < 0, "asdf tranferETH!");
        (bool success, ) = _recipient.call{value: _amount}("");
        return success;
    }
}
