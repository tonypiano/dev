import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Ext is IERC20 {
    
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}