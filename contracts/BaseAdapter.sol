// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./lib/SafeERC20.sol";
import "./lib/Maintainable.sol";

abstract contract BaseAdapter is Maintainable {
    using SafeERC20 for IERC20;

    uint256 internal constant UINT_MAX = type(uint256).max;
    uint256 public swapGasEstimate;
    string public name;

    event BaseAdapterSwap(
        address indexed _tokenFrom,
        address indexed _tokenTo,
        uint256 _amountIn,
        uint256 _amountOut
    );
    event UpdatedGasEstimate(address indexed _adapter, uint256 _newEstimate);
    event Recovered(address indexed _asset, uint256 amount);

    constructor(string memory _name, uint256 _gasEstimate) {
        setName(_name);
        setSwapGasEstimate(_gasEstimate);
    }

    receive() external payable {}

    function revokeAllowance(address _token, address _spender)
        external
        onlyMaintainer
    {
        require(_token != address(0), "BaseAdapter: Invalid token address");
        IERC20(_token).safeApprove(_spender, 0);
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyMaintainer
    {
        require(
            _tokenAddress != address(0),
            "BaseAdapter: Invalid token address"
        );
        require(_tokenAmount > 0, "BaseAdapter: Nothing to recover");
        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    function recoverETH(uint256 _amount) external onlyMaintainer {
        require(_amount > 0, "BaseAdapter: Nothing to recover");
        payable(msg.sender).transfer(_amount);
        emit Recovered(address(0), _amount);
    }

    function swap(
        uint256 _amountIn,
        uint256 _amountOut,
        address _fromToken,
        address _toToken,
        address _to
    ) external {
        require(
            _fromToken != address(0),
            "BaseAdapter: Invalid fromToken address"
        );
        require(
            _fromToken != address(0),
            "BaseAdapter: Invalid toToken address"
        );
        require(_amountIn > 0, "BaseAdapter: Invalid amountIn");
        uint256 toBal0 = IERC20(_toToken).balanceOf(_to);
        _swap(_amountIn, _amountOut, _fromToken, _toToken, _to);
        uint256 diff = IERC20(_toToken).balanceOf(_to) - toBal0;
        require(diff >= _amountOut, "Insufficient amount-out");
        emit BaseAdapterSwap(_fromToken, _toToken, _amountIn, _amountOut);
    }

    function query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) external view returns (uint256) {
        return _query(_amountIn, _tokenIn, _tokenOut);
    }

    function setSwapGasEstimate(uint256 _estimate) public onlyMaintainer {
        require(_estimate != 0, "Invalid gas-estimate");
        swapGasEstimate = _estimate;
        emit UpdatedGasEstimate(address(this), _estimate);
    }

    function setName(string memory _name) internal {
        require(bytes(_name).length != 0, "Invalid adapter name");
        name = _name;
    }

    function _returnTo(
        address _token,
        uint256 _amount,
        address _to
    ) internal {
        if (address(this) != _to) IERC20(_token).safeTransfer(_to, _amount);
    }

    function _swap(
        uint256 _amountIn,
        uint256 _amountOut,
        address _fromToken,
        address _toToken,
        address _to
    ) internal virtual;

    function _query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) internal view virtual returns (uint256);
}
