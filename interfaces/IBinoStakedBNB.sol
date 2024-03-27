// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title binoStakedBNB interface
interface IBinoStakedBNB is IERC20Upgradeable {
    function initialize(address _manager) external;

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function setStakeManager(address _address) external;

    event SetStakeManager(address indexed _address);
}