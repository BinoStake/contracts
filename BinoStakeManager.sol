//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./contracts-upgradeable/proxy/utils/Initializable.sol";
import "./contracts-upgradeable/security/PausableUpgradeable.sol";
import "./contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./contracts-upgradeable/utils/AddressUpgradeable.sol";

import {IStakeManager} from "./interfaces/IStakeManager.sol";
import {IBinoStakedBNB} from "./interfaces/IBinoStakedBNB.sol";
import {IStaking} from "./interfaces/INativeStaking.sol";

/**
 * @title Stake Manager Contract
 * @dev Handles Staking of BNB on BSC
 */
contract BinoStakeManager is
    IStakeManager,
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    
    uint256 public totalBsBnbToBurn;

    uint256 public totalDelegated; // total BNB delegated
    uint256 public amountToDelegate; // total BNB to delegate for next batch

    uint256 public nextUndelegateUUID;
    uint256 public confirmedUndelegatedUUID;

    uint256 public reserveAmount; // will be used to adjust minThreshold delegate/undelegate for natvie staking
    uint256 public totalReserveAmount;

    address private bsBnb;
    address private validator;

    mapping(uint256 => BotUndelegateRequest)
        private uuidToBotUndelegateRequestMap;
    mapping(address => WithdrawalRequest[]) private userWithdrawalRequests;

    uint256 public constant TEN_DECIMALS = 1e10;
    bytes32 public constant BOT = keccak256("BOT");

    address private manager;
    address private proposedManager;
    uint256 public bsFee; // range {0-10_000_000_000}

    address public revenuePool;
    address public redirectAddress;

    address private constant NATIVE_STAKING = 0x0000000000000000000000000000000000002001;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @param _bsBnb - Address of BsBnb Token on Binance Smart Chain
     * @param _admin - Address of the admin
     * @param _manager - Address of the manager
     * @param _bot - Address of the Bot
     * @param _bsFee - Rewards fee to revenue pool
     * @param _revenuePool - Revenue pool to receive rewards
     * @param _validator - Validator to delegate BNB
     */
    function initialize(
        address _bsBnb,
        address _admin,
        address _manager,
        address _bot,
        uint256 _bsFee,
        address _revenuePool,
        address _validator
    ) external override initializer {
        __AccessControl_init();
        __Pausable_init();

        require(
            ((_bsBnb != address(0)) &&
                (_admin != address(0)) &&
                (_manager != address(0)) &&
                (_validator != address(0)) &&
                (_revenuePool != address(0)) &&
                (_bot != address(0))),
            "zero address provided"
        );
        require(_bsFee <= TEN_DECIMALS, "_bsFee must not exceed (100%)");

        _setRoleAdmin(BOT, DEFAULT_ADMIN_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(BOT, _bot);

        manager = _manager;
        bsBnb = _bsBnb;
        validator = _validator;
        bsFee = _bsFee;
        revenuePool = _revenuePool;

        emit SetManager(_manager);
        emit SetValidator(validator);
        emit SetRevenuePool(revenuePool);
        emit SetBsFee(_bsFee);
    }

    /**
     * @dev Allows user to deposit Bnb at BSC and mints BsBnb for the user
     */
    function deposit() external payable override whenNotPaused {
        uint256 amount = msg.value;
        require(amount > 0, "Invalid Amount");

        uint256 bsBnbToMint = convertBnbToBsBnb(amount);
        require(bsBnbToMint > 0, "Invalid BsBnb Amount");
        amountToDelegate += amount;

        IBinoStakedBNB(bsBnb).mint(msg.sender, bsBnbToMint);

        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Allows bot to delegate users' funds to native staking contract without reserved BNB
     * @return _amount - Amount of funds transferred for staking
     * @notice The amount should be greater than minimum delegation on native staking contract
     */
    function delegate()
        external
        payable
        override
        whenNotPaused
        onlyRole(BOT)
        returns (uint256 _amount)
    {
        uint256 relayFee = IStaking(NATIVE_STAKING).getRelayerFee();
        uint256 relayFeeReceived = msg.value;
        _amount = amountToDelegate - (amountToDelegate % TEN_DECIMALS);

        require(relayFeeReceived == relayFee, "Insufficient RelayFee");
        require(_amount >= IStaking(NATIVE_STAKING).getMinDelegation(), "Insufficient Deposit Amount");
        
        amountToDelegate = amountToDelegate - _amount;
        totalDelegated += _amount;
        
        // delegate through native staking contract
        IStaking(NATIVE_STAKING).delegate{value: _amount + msg.value}(validator, _amount);

        emit Delegate(_amount);
    }

    /**
     * @dev Allows bot to delegate users' funds + reserved BNB to native staking contract
     * @return _amount - Amount of funds transferred for staking
     * @notice The amount should be greater than minimum delegation on native staking contract
     */
    function delegateWithReserve()
        external
        payable
        override
        whenNotPaused
        onlyRole(BOT)
        returns (uint256 _amount)
    {
        uint256 relayFee = IStaking(NATIVE_STAKING).getRelayerFee();
        uint256 relayFeeReceived = msg.value;
        _amount = amountToDelegate - (amountToDelegate % TEN_DECIMALS);

        require(relayFeeReceived == relayFee, "Insufficient RelayFee");
        require(totalReserveAmount >= reserveAmount, "Insufficient Reserve Amount");
        require(_amount + reserveAmount >= IStaking(NATIVE_STAKING).getMinDelegation(), "Insufficient Deposit Amount");
        
        amountToDelegate = amountToDelegate - _amount;
        totalDelegated += _amount;
        
        // delegate through native staking contract
        IStaking(NATIVE_STAKING).delegate{value: _amount + msg.value + reserveAmount}(validator, _amount + reserveAmount);

        emit Delegate(_amount);
        emit DelegateReserve(reserveAmount);
    }

    function redelegate(address srcValidator, address dstValidator, uint256 amount)
        external
        payable
        override
        whenNotPaused
        onlyManager
        returns (uint256 _amount) 
    {
        uint256 relayFee = IStaking(NATIVE_STAKING).getRelayerFee();
        uint256 relayFeeReceived = msg.value;

        require(srcValidator != dstValidator, "Invalid Redelegation");
        require(relayFeeReceived == relayFee, "Insufficient RelayFee");
        require(amount >= IStaking(NATIVE_STAKING).getMinDelegation(), "Insufficient Deposit Amount");

        // redelegate through native staking contract
        IStaking(NATIVE_STAKING).redelegate{value: msg.value}(srcValidator, dstValidator, amount);

        emit ReDelegate(srcValidator, dstValidator, amount);
        
        return amount;
    }
    /**
     * @dev Allows bot to compound rewards
     */
    function compoundRewards()
        external
        override
        whenNotPaused
        onlyRole(BOT)
    {
        require(totalDelegated > 0, "No funds delegated");

        uint256 amount = IStaking(NATIVE_STAKING).claimReward();
        
        if (bsFee > 0) {
            uint256 fee = amount * bsFee / TEN_DECIMALS;
            require(revenuePool != address(0x0), "revenue pool not set");
            AddressUpgradeable.sendValue(payable(revenuePool), fee);
            amount -= fee;
        }

        amountToDelegate += amount;

        emit RewardsCompounded(amount);
    }

    /**
     * @dev Allows user to request for unstake/withdraw funds
     * @param _amountInBsBnb - Amount of BsBnb to swap for withdraw
     * @notice User must have approved this contract to spend BsBnb
     */
    function requestWithdraw(uint256 _amountInBsBnb)
        external
        override
        whenNotPaused
    {
        require(_amountInBsBnb > 0, "Invalid Amount");

        totalBsBnbToBurn += _amountInBsBnb;
        uint256 totalBnbToWithdraw = convertBsBnbToBnb(totalBsBnbToBurn);
        require(
            totalBnbToWithdraw <= totalDelegated + amountToDelegate,
            "Not enough BNB to withdraw"
        );

        userWithdrawalRequests[msg.sender].push(
            WithdrawalRequest({
                uuid: nextUndelegateUUID,
                amountInBsBnb: _amountInBsBnb,
                startTime: block.timestamp
            })
        );

        IERC20Upgradeable(bsBnb).safeTransferFrom(
            msg.sender,
            address(this),
            _amountInBsBnb
        );
        emit RequestWithdraw(msg.sender, _amountInBsBnb);
    }

    function claimWithdraw(uint256 _idx) external override whenNotPaused {
        address user = msg.sender;
        WithdrawalRequest[] storage userRequests = userWithdrawalRequests[user];

        require(_idx < userRequests.length, "Invalid index");

        WithdrawalRequest storage withdrawRequest = userRequests[_idx];
        uint256 uuid = withdrawRequest.uuid;
        uint256 amountInBsBnb = withdrawRequest.amountInBsBnb;

        BotUndelegateRequest
            storage botUndelegateRequest = uuidToBotUndelegateRequestMap[uuid];
        require(botUndelegateRequest.endTime != 0, "Not able to claim yet");
        userRequests[_idx] = userRequests[userRequests.length - 1];
        userRequests.pop();

        uint256 totalBnbToWithdraw_ = botUndelegateRequest.amount;
        uint256 totalBsBnbToBurn_ = botUndelegateRequest.amountInBsBnb;
        uint256 amount = (totalBnbToWithdraw_ * amountInBsBnb) /
            totalBsBnbToBurn_;

        AddressUpgradeable.sendValue(payable(user), amount);

        emit ClaimWithdrawal(user, _idx, amount);
    }

    /**
     * @dev Bot uses this function to get amount of BNB to withdraw
     * @return _uuid - unique id against which this Undelegation event was logged
     * @return _amount - Amount of funds required to Unstake
     */
    function undelegate()
        external
        payable
        override
        whenNotPaused
        onlyRole(BOT)
        returns (uint256 _uuid, uint256 _amount)
    {
        uint256 relayFee = IStaking(NATIVE_STAKING).getRelayerFee();
        uint256 relayFeeReceived = msg.value;

        require(relayFeeReceived == relayFee, "Insufficient RelayFee");

        _uuid = nextUndelegateUUID++; // post-increment : assigns the current value first and then increments
        uint256 totalBsBnbToBurn_ = totalBsBnbToBurn; // To avoid Reentrancy attack
        _amount = convertBsBnbToBnb(totalBsBnbToBurn_);
        _amount -= _amount % TEN_DECIMALS;

        require(
            _amount + reserveAmount >= IStaking(NATIVE_STAKING).getMinDelegation(),
            "Insufficient Withdraw Amount"
        );

        uuidToBotUndelegateRequestMap[_uuid] = BotUndelegateRequest({
            startTime: block.timestamp,
            endTime: 0,
            amount: _amount,
            amountInBsBnb: totalBsBnbToBurn_
        });

        totalDelegated -= _amount;
        totalBsBnbToBurn = 0;

        IBinoStakedBNB(bsBnb).burn(address(this), totalBsBnbToBurn_);

        // undelegate through native staking contract
        IStaking(NATIVE_STAKING).undelegate{value: msg.value}(validator, _amount + reserveAmount);
        
        emit UndelegateReserve(reserveAmount);
    }

    function claimUndelegated()
        external
        override
        whenNotPaused
        onlyRole(BOT)
        returns (uint256 _uuid, uint256 _amount) 
    {
        uint256 undelegatedAmount = IStaking(NATIVE_STAKING).claimUndelegated();
        require(undelegatedAmount > 0, "Nothing to undelegate");
        for (uint256 i = confirmedUndelegatedUUID; i <= nextUndelegateUUID - 1; i++) {
            BotUndelegateRequest
                storage botUndelegateRequest = uuidToBotUndelegateRequestMap[i];
            botUndelegateRequest.endTime = block.timestamp;
            confirmedUndelegatedUUID++;
        }
        _uuid = confirmedUndelegatedUUID;
        _amount = undelegatedAmount;

        emit ClaimUndelegated(_uuid, _amount);
    }

    function claimFailedDelegation(bool withReserve)
        external
        override
        whenNotPaused
        onlyRole(BOT)
        returns (uint256 _amount)
    {
        uint256 failedAmount = IStaking(NATIVE_STAKING).claimUndelegated();
        if (withReserve) {
            require(failedAmount >= reserveAmount, "Wrong reserve amount for delegation");
            amountToDelegate += failedAmount - reserveAmount;
            totalDelegated -= failedAmount -reserveAmount;
        } else {
            amountToDelegate += failedAmount;
            totalDelegated -= failedAmount;
        }

        emit ClaimFailedDelegation(failedAmount, withReserve);
        return failedAmount;
    }

    /**
     * @dev Deposit reserved funds to the contract
     */
    function depositReserve() external payable override whenNotPaused onlyRedirectAddress{
        uint256 amount = msg.value;
        require(amount > 0, "Invalid Amount");

        totalReserveAmount += amount;
    }

    function withdrawReserve(uint256 amount) external override whenNotPaused onlyRedirectAddress{
        require(amount <= totalReserveAmount, "Insufficient Balance");
        totalReserveAmount -= amount;
        AddressUpgradeable.sendValue(payable(msg.sender), amount);
    }

    function setReserveAmount(uint256 amount) external override onlyManager {
        reserveAmount = amount;
        emit SetReserveAmount(amount);
    }

    function proposeNewManager(address _address) external override onlyManager {
        require(manager != _address, "Old address == new address");
        require(_address != address(0), "zero address provided");

        proposedManager = _address;

        emit ProposeManager(_address);
    }

    function acceptNewManager() external override {
        require(
            msg.sender == proposedManager,
            "Accessible only by Proposed Manager"
        );

        manager = proposedManager;
        proposedManager = address(0);

        emit SetManager(manager);
    }

    function setBotRole(address _address) external override {
        require(_address != address(0), "zero address provided");

        grantRole(BOT, _address);

    }

    function revokeBotRole(address _address) external override {
        require(_address != address(0), "zero address provided");

        revokeRole(BOT, _address);

    }

    /// @param _address - Beck32 decoding of Address of Validator Wallet on Beacon Chain with `0x` prefix
    function setValidator(address _address)
        external
        override
        onlyManager
    {
        require(validator != _address, "Old address == new address");
        require(_address != address(0), "zero address provided");

        validator = _address;

        emit SetValidator(_address);
    }

    function setBsFee(uint256 _bsFee)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_bsFee <= TEN_DECIMALS, "_bsFee must not exceed 10000 (100%)");

        bsFee = _bsFee;

        emit SetBsFee(_bsFee);
    }

    function setRedirectAddress(address _address)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(redirectAddress != _address, "Old address == new address");
        require(_address != address(0), "zero address provided");

        redirectAddress = _address;

        emit SetRedirectAddress(_address);
    }

    function setRevenuePool(address _address)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(revenuePool != _address, "Old address == new address");
        require(_address != address(0), "zero address provided");

        revenuePool = _address;

        emit SetRevenuePool(_address);
    }

    function getTotalPooledBnb() public view override returns (uint256) {
        return (amountToDelegate + totalDelegated);
    }

    function getContracts()
        external
        view
        override
        returns (
            address _manager,
            address _bsBnb,
            address _validator
        )
    {
        _manager = manager;
        _bsBnb = bsBnb;
        _validator = validator;
    }


    function getBotUndelegateRequest(uint256 _uuid)
        external
        view
        override
        returns (BotUndelegateRequest memory)
    {
        return uuidToBotUndelegateRequestMap[_uuid];
    }

    /**
     * @dev Retrieves all withdrawal requests initiated by the given address
     * @param _address - Address of an user
     * @return userWithdrawalRequests array of user withdrawal requests
     */
    function getUserWithdrawalRequests(address _address)
        external
        view
        override
        returns (WithdrawalRequest[] memory)
    {
        return userWithdrawalRequests[_address];
    }

    /**
     * @dev Checks if the withdrawRequest is ready to claim
     * @param _user - Address of the user who raised WithdrawRequest
     * @param _idx - index of request in UserWithdrawls Array
     * @return _isClaimable - if the withdraw is ready to claim yet
     * @return _amount - Amount of BNB user would receive on withdraw claim
     * @notice Use `getUserWithdrawalRequests` to get the userWithdrawlRequests Array
     */
    function getUserRequestStatus(address _user, uint256 _idx)
        external
        view
        override
        returns (bool _isClaimable, uint256 _amount)
    {
        WithdrawalRequest[] storage userRequests = userWithdrawalRequests[
            _user
        ];

        require(_idx < userRequests.length, "Invalid index");

        WithdrawalRequest storage withdrawRequest = userRequests[_idx];
        uint256 uuid = withdrawRequest.uuid;
        uint256 amountInBsBnb = withdrawRequest.amountInBsBnb;

        BotUndelegateRequest
            storage botUndelegateRequest = uuidToBotUndelegateRequestMap[uuid];

        // bot has triggered startUndelegation
        if (botUndelegateRequest.amount > 0) {
            uint256 totalBnbToWithdraw_ = botUndelegateRequest.amount;
            uint256 totalBsBnbToBurn_ = botUndelegateRequest.amountInBsBnb;
            _amount = (totalBnbToWithdraw_ * amountInBsBnb) / totalBsBnbToBurn_;
        }
        // bot has not triggered startUndelegation yet
        else {
            _amount = convertBsBnbToBnb(amountInBsBnb);
        }
        _isClaimable = (botUndelegateRequest.endTime != 0);
    }

    function getBsBnbWithdrawLimit()
        external
        view
        override
        returns (uint256 _bsBnbWithdrawLimit)
    {
        _bsBnbWithdrawLimit =
            convertBnbToBsBnb(totalDelegated) -
            totalBsBnbToBurn;
    }

    /**
     * @return relayFee required by TokenHub contract to transfer funds from BSC -> BC
     */
    function getTokenHubRelayFee() public view override returns (uint256) {
        return IStaking(NATIVE_STAKING).getRelayerFee();
    }

    /**
     * @dev Calculates amount of BsBnb for `_amount` Bnb
     */
    function convertBnbToBsBnb(uint256 _amount)
        public
        view
        override
        returns (uint256)
    {
        uint256 totalShares = IBinoStakedBNB(bsBnb).totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 totalPooledBnb = getTotalPooledBnb();
        totalPooledBnb = totalPooledBnb == 0 ? 1 : totalPooledBnb;

        uint256 amountInBsBnb = (_amount * totalShares) / totalPooledBnb;

        return amountInBsBnb;
    }

    /**
     * @dev Calculates amount of Bnb for `_amountInBsBnb` BsBnb
     */
    function convertBsBnbToBnb(uint256 _amountInBsBnb)
        public
        view
        override
        returns (uint256)
    {
        uint256 totalShares = IBinoStakedBNB(bsBnb).totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 totalPooledBnb = getTotalPooledBnb();
        totalPooledBnb = totalPooledBnb == 0 ? 1 : totalPooledBnb;

        uint256 amountInBnb = (_amountInBsBnb * totalPooledBnb) / totalShares;

        return amountInBnb;
    }

    /**
     * @dev Flips the pause state
     */
    function togglePause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        paused() ? _unpause() : _pause();
    }

    receive() external payable {
        if (msg.sender != NATIVE_STAKING && msg.sender != redirectAddress) {
            AddressUpgradeable.sendValue(payable(redirectAddress), msg.value);
        }
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Accessible only by Manager");
        _;
    }

    modifier onlyRedirectAddress() {
        require(msg.sender == redirectAddress, "Accessible only by RedirectAddress");
        _;
    }
}
