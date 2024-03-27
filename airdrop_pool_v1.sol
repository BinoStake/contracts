//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./contracts-upgradeable/proxy/utils/Initializable.sol";
import "./contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./contracts-upgradeable/utils/AddressUpgradeable.sol";

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

/**
 * @title Stake Manager Contract
 * @dev Handles Staking of BNB on BSC
 */
contract AirdropPool is
    Initializable,
    AccessControlUpgradeable
{
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public bsBnb;

    address public  manager;
    address public feeAddress;

    struct UserInfo {
        uint256 amount; // User deposit amount.
        uint256 rewardDebt; // Reward debt.
    }

    // Info of each pool.
    struct PoolInfo {
        address token; // staked BNB token contract.
        uint256 allocPoint; // Allocation point for each pools.
        uint256 lastRewardTime; // Last time of bsBNB distribution.
        uint256 accBsBNBPerToken; // Accumulated bsBNB per Token.
        bool isStarted;
        uint256 depositFee;
        uint256 totalSupply;
    }

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    uint256 public totalAllocPoint;

    uint256 public poolStartTime;
    uint256 public poolEndTime;
    
    uint256 public bsBnbPerSecond;
    uint256 public runningTime;
    uint256 public constant TOTAL_REWARDS = 43.2 ether; // total priovided bsBNB amount - 43.2 bsBNB

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @param _bsBnb - Address of BsBnb Token on Binance Smart Chai
     * @param _manager - Address of the manager
     * @param _feeAddress - Revenue pool to receive fees
     * @param _poolStartTime - Airdrop Pool start time
     */
    function initialize(
        address _bsBnb, 
        address _manager,
        address _feeAddress,
        uint256 _poolStartTime
    ) external initializer {
        __AccessControl_init();

        require(
            ((_bsBnb != address(0)) &&
                (_manager != address(0)) &&
                (_feeAddress != address(0))),
            "zero address provided"
        );

        bsBnb = _bsBnb;
        manager = _manager;
        feeAddress = _feeAddress;
        bsBnbPerSecond = 0.00001 ether; // bsBNB reward amount persecodn - 0.00001 bsBNB
        poolStartTime = _poolStartTime;
        runningTime = 50 days; // Pool running time - 50 days
        poolEndTime = poolStartTime + runningTime;
    }

    /**
     * @dev Check duplication of pools
     */
    function checkPoolDuplicate(address _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "Existing pool");
        }
    }

    /**
     * @dev Add new token to the pool. It has own allocation and deposit fee
     */
    function addPool(
        uint256 _allocPoint,
        address _token,
        bool _withUpdate,
        uint256 _lastRewardTime,
        uint256 _depositFee
    ) public onlyManager {
        require(_depositFee <= 100, "add: invalid deposit fee basis points");
        checkPoolDuplicate(_token);
        if (_withUpdate) {
            massUpdatePools();
        }
        if (block.timestamp < poolStartTime) {
            // chef is sleeping
            if (_lastRewardTime == 0) {
                _lastRewardTime = poolStartTime;
            } else {
                if (_lastRewardTime < poolStartTime) {
                    _lastRewardTime = poolStartTime;
                }
            }
        } else {
            // chef is cooking
            if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) {
                _lastRewardTime = block.timestamp;
            }
        }
        bool _isStarted =
        (_lastRewardTime <= poolStartTime) ||
        (_lastRewardTime <= block.timestamp);
        poolInfo.push(PoolInfo({
            token : _token,
            allocPoint : _allocPoint,
            lastRewardTime : _lastRewardTime,
            accBsBNBPerToken : 0,
            isStarted : _isStarted,
            depositFee: _depositFee,
            totalSupply: 0
            }));
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }

    /**
     * @dev Update the given pool's allocation point and deposit fee. Can only be called by the manager.
     */
    function set(uint256 _pid, uint256 _allocPoint, uint256 _depositFee) public onlyManager {
        require(_depositFee <= 100, "set: invalid deposit fee basis points");
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(
                _allocPoint
            );
        }
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFee = _depositFee;
    }

    /**
     * @return amount - accumulate rewards over the given _from to _to block.
     */
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) internal view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) return poolEndTime.sub(poolStartTime).mul(bsBnbPerSecond);
            return poolEndTime.sub(_fromTime).mul(bsBnbPerSecond);
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) return _toTime.sub(poolStartTime).mul(bsBnbPerSecond);
            return _toTime.sub(_fromTime).mul(bsBnbPerSecond);
        }
    }

    /**
     * @dev View pending reward amount which users can receive
     * @return amount - amount of reward pool
     */
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBsBNBPerToken = pool.accBsBNBPerToken;
        uint256 tokenSupply = pool.totalSupply;
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _bsBnbReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            accBsBNBPerToken = accBsBNBPerToken.add(_bsBnbReward.mul(1e18).div(tokenSupply));
        }
        return user.amount.mul(accBsBNBPerToken).div(1e18).sub(user.rewardDebt);
    }

    /**
     * @dev Update all pools
     */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 tokenSupply = pool.totalSupply;
        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
        }
        if (totalAllocPoint > 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _bsBnbReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accBsBNBPerToken = pool.accBsBNBPerToken.add(_bsBnbReward.mul(1e18).div(tokenSupply));
        }
        pool.lastRewardTime = block.timestamp;
    }

    /**
     * @dev Deposit tokens to the airdrop pool
     */
    function deposit(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = user.amount.mul(pool.accBsBNBPerToken).div(1e18).sub(user.rewardDebt);
            if (_pending > 0) {
                safeBsBnbTransfer(_sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        }
        if (_amount > 0) {
            IERC20Upgradeable(pool.token).safeTransferFrom(_sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
            pool.totalSupply = pool.totalSupply.add(_amount);

            if(pool.depositFee > 0){
                uint256 depositFee = _amount.mul(pool.depositFee).div(10000);
                IERC20Upgradeable(pool.token).safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.sub(depositFee);
                pool.totalSupply = pool.totalSupply.sub(depositFee);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accBsBNBPerToken).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }

    /**
     * @dev Withdraw tokens from the airdrop pool
     */
    function withdraw(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "not enough amount");
        updatePool(_pid);
        uint256 _pending = user.amount.mul(pool.accBsBNBPerToken).div(1e18).sub(user.rewardDebt);
        if (_pending > 0) {
            safeBsBnbTransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            IERC20Upgradeable(pool.token).safeTransfer(_sender, _amount);
            pool.totalSupply = pool.totalSupply.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBsBNBPerToken).div(1e18);
        emit Withdraw(_sender, _pid, _amount);
    }

    /**
     * @dev bsBNB transfer
     */
    function safeBsBnbTransfer(address _to, uint256 _amount) internal {
        uint256 _bsBnbBalance = IERC20Upgradeable(bsBnb).balanceOf(address(this));
        if (_bsBnbBalance > 0) {
            if (_amount > _bsBnbBalance) {
                IERC20Upgradeable(bsBnb).safeTransfer(_to, _bsBnbBalance);
            } else {
                IERC20Upgradeable(bsBnb).safeTransfer(_to, _amount);
            }
        }
    }

    /**
     * @dev Set manager and fee address address
     */
    function setManager(address _manager, address _feeAddress) external onlyManager {
        manager = _manager;
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Accessible only by Manager");
        _;
    }
}
