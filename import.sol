// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./contracts-upgradeable/proxy/beacon/BeaconProxy.sol";
import "./contracts-upgradeable/proxy/beacon/UpgradeableBeacon.sol";
import "./contracts-upgradeable/proxy/ERC1967/ERC1967Proxy.sol";
import "./contracts-upgradeable/proxy/transparent/TransparentUpgradeableProxy.sol";
import "./contracts-upgradeable/proxy/transparent/ProxyAdmin.sol";

// Kept for backwards compatibility with older versions of Hardhat and Truffle plugins.
contract AdminUpgradeabilityProxy is TransparentUpgradeableProxy {
    constructor(address logic, address admin, bytes memory data) payable TransparentUpgradeableProxy(logic, admin, data) {}
}
