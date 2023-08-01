// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";

contract Flashloan is Ownable {
    ILendingPoolAddressesProvider public addressesProvider;
    ILendingPool public lendingPool;

    constructor(address _addressProvider) public {
        addressesProvider = ILendingPoolAddressesProvider(_addressProvider);
        lendingPool = ILendingPool(addressesProvider.getLendingPool());
    }

    function startFlashLoan(uint256 amount, address _asset) public onlyOwner {
        address receiverAddress = address(this);

        // This is the amount of the loan
        uint256 amountOwing = amount;

        // 0 means that the loan doesn't have a specific use. You can specify a different number for protocol treasury fees
        uint16 referralCode = 0;

        // Here we're calling the actual function that performs the flash loan
        lendingPool.flashLoan(
            receiverAddress,
            _asset,
            amount,
            referralCode
        );

        // Make sure to have enough assets in the contract to repay the loan
        require(IERC20(_asset).balanceOf(address(this)) >= amountOwing, "Not enough assets to repay the loan!");
    }

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external {
        // This function is called after your contract has received the flash loaned amount

        // Your logic goes here.
        // !! Ensure that *this contract* has enough of `_reserve` funds to payback the `_fee` !!

        // At the end of this function, the loan *must* be paid back
        payBackFlashLoan(_reserve, _amount, _fee);
    }

    function payBackFlashLoan(address _reserve, uint256 _amount, uint256 _fee) internal {
        require(IERC20(_reserve).approve(address(lendingPool), _amount + _fee), "Could not approve repayment");

        // Transfer `_fee` assets to this contract to payback the flashloan
        IERC20(_reserve).transferFrom(msg.sender, address(this), _fee);
    }
}
