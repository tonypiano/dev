// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "../Dependencies/console.sol";


contract NonPayable {
    bool isPayable;

    function setPayable(bool _isPayable) external {
        isPayable = _isPayable;
    }

    function forward(address _dest, bytes calldata _data) external payable {
        console.log("start in NonPayable::forward");
        (bool success, bytes memory returnData) = _dest.call{ value: msg.value, gas: 1000000 }(_data);        
         console.log("end in NonPayable::forward, result: ", success);
        require(success, string(returnData));        
    }

    receive() external payable {
        require(isPayable, "asdlkfasdjkf");
    }
}
