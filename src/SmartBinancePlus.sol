// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SmartBinancePlus is Ownable {
    enum Plan {
        Binary,
        InOrder
    }

    struct User {
        address referrer;
        Plan plan;
        uint256 totalEarnings;
        uint256 directs;
        address left;
        address right;
        uint256 currentLeftVolume;
        uint256 currentRightVolume;
        uint256 totalLeftVolume;
        uint256 totalRightVolume;
        uint256 balancePoints;
        bool active;
    }

    mapping(address => User) private userInfo;
    address[] public allUsers;
    // Remove all cycle-related mappings and variables
    // mapping(uint256 => uint256) public cycleRewards;
    // mapping(uint256 => uint256) public cycleTotalPoints;
    // mapping(uint256 => uint256) public cyclePointValue;
    // mapping(uint256 => bool) public cycleCalculated;

    uint256 public constant ENTRANCE = 100 ether;
    uint256 public constant OWNER_SHARE = 10 ether;
    uint256 public constant POOL_SHARE = 90 ether;

    uint256 public constant REWARD_CYCLE_DURATION = 1 hours;
    address public immutable ROOT;
    IERC20 public dai;
    uint256 public contractStartTime;
    uint256 public totalCyclePoolAmount;
    uint256 public totalCyclePoints;
    uint256 public lastDistributionTime;

    modifier preChecks(Plan plan, address referrer) {
        require(plan == Plan.Binary || plan == Plan.InOrder, "Invalid plan");
        require(userInfo[referrer].active, "Referrer is not active");
        require(!userInfo[msg.sender].active, "User is already active");
        _;
    }

    constructor(address initialOwner, address _dai, address _root) Ownable(initialOwner) {
        dai = IERC20(_dai);
        ROOT = _root;
        contractStartTime = block.timestamp;
        userInfo[ROOT] = User({
            referrer: address(0),
            plan: Plan.Binary,
            totalEarnings: 0,
            directs: 0,
            left: address(0),
            right: address(0),
            currentLeftVolume: 0,
            currentRightVolume: 0,
            totalLeftVolume: 0,
            totalRightVolume: 0,
            balancePoints: 0,
            // lastRewardCycle: 0,
            active: true
        });
        allUsers.push(ROOT);
    }

    function register(Plan plan, address referrer) external preChecks(plan, referrer) {
        dai.transferFrom(msg.sender, address(this), ENTRANCE);
        dai.transfer(owner(), OWNER_SHARE);
        totalCyclePoolAmount += POOL_SHARE;

        if (plan == Plan.Binary) {
            // Binary plan: user connects directly to their referrer
            _connectToBinaryReferrer(referrer);
        } else {
            // InOrder plan: find empty spot using BFS
            address emptySpot = _findEmptySpotBFS(referrer);
            require(emptySpot != address(0), "No empty spot found");
            _connectToInOrderSpot(emptySpot);
        }

        // Activate the user
        userInfo[msg.sender].active = true;
        userInfo[msg.sender].plan = plan;
        allUsers.push(msg.sender);

        _updateVolumeAndBalancePoints(msg.sender);
    }

    function _connectToBinaryReferrer(address referrer) internal {
        // Check if referrer has empty spots first
        if (userInfo[referrer].left == address(0)) {
            userInfo[msg.sender].referrer = referrer;
            userInfo[referrer].left = msg.sender;
            userInfo[referrer].directs++;
        } else if (userInfo[referrer].right == address(0)) {
            userInfo[msg.sender].referrer = referrer;
            userInfo[referrer].right = msg.sender;
            userInfo[referrer].directs++;
        } else {
            // Referrer already has 2 directs, find empty spot in their subtree using BFS
            address emptySpot = _findEmptySpotBFS(referrer);
            require(emptySpot != address(0), "No empty spot found in referrer's tree");
            _connectToInOrderSpot(emptySpot);
        }
    }

    function _connectToInOrderSpot(address parent) internal {
        userInfo[msg.sender].referrer = parent;

        // Connect to parent's tree
        if (userInfo[parent].left == address(0)) {
            userInfo[parent].left = msg.sender;
        } else {
            userInfo[parent].right = msg.sender;
        }

        userInfo[parent].directs++;
    }

    function _findEmptySpotBFS(address startNode) internal view returns (address) {
        // BFS requires a queue - we'll use a fixed-size array to simulate it
        // This limits the search depth but prevents infinite gas usage
        address[100] memory queue;
        uint256 front = 0;
        uint256 rear = 0;

        // Add starting node to queue
        queue[rear] = startNode;
        rear++;

        // BFS traversal
        while (front < rear && front < 100) {
            address currentNode = queue[front];
            front++;

            // Skip if node doesn't exist or is not active
            if (currentNode == address(0) || !userInfo[currentNode].active) {
                continue;
            }

            // Check if current node has empty spots (left first, then right)
            if (userInfo[currentNode].left == address(0)) {
                // TODO: Add exception checks here
                // if (_isValidSpot(currentNode, true)) {
                return currentNode;
                // }
            }

            if (userInfo[currentNode].right == address(0)) {
                // TODO: Add exception checks here
                // if (_isValidSpot(currentNode, false)) {
                return currentNode;
                // }
            }

            // Add children to queue for next level processing
            if (userInfo[currentNode].left != address(0) && rear < 100) {
                queue[rear] = userInfo[currentNode].left;
                rear++;
            }

            if (userInfo[currentNode].right != address(0) && rear < 100) {
                queue[rear] = userInfo[currentNode].right;
                rear++;
            }
        }

        // No empty spots found
        return address(0);
    }

    // TODO: Implement this function to add your exception logic
    // function _isValidSpot(address parentNode, bool isLeftSpot) internal view returns (bool) {
    //     // Add your exception logic here
    //     // Return false if the spot is not valid according to your rules
    //     return true;
    // }

    // Helper function to get user tree structure (for testing/debugging)
    function getUserTree(address user)
        external
        view
        returns (address referrer, address left, address right, uint256 directs, bool active)
    {
        User memory userData = userInfo[user];
        return (userData.referrer, userData.left, userData.right, userData.directs, userData.active);
    }

    // Remove getCurrentCycle, calculateCycleRewards, getCycleInfo, and any other cycle-related functions

    function _updateVolumeAndBalancePoints(address newUser) internal {
        address currentRef = userInfo[newUser].referrer;
        address currentUser = newUser;

        while (currentRef != address(0)) {
            if (currentUser == userInfo[currentRef].left) {
                userInfo[currentRef].currentLeftVolume += POOL_SHARE;
                userInfo[currentRef].totalLeftVolume += POOL_SHARE;
            } else {
                userInfo[currentRef].currentRightVolume += POOL_SHARE;
                userInfo[currentRef].totalRightVolume += POOL_SHARE;
            }

            uint256 newBalancePoints = _calculateBalancePoints(currentRef); // This line is removed

            if (newBalancePoints > userInfo[currentRef].balancePoints) {
                // This line is removed
                uint256 earnedPoints = newBalancePoints - userInfo[currentRef].balancePoints; // This line is removed
                userInfo[currentRef].balancePoints = newBalancePoints; // This line is removed

                // Add to current cycle total points // This line is removed
                totalCyclePoints += earnedPoints; // This line is removed
            } // This line is removed
            currentUser = currentRef;
            currentRef = userInfo[currentRef].referrer;
        }
    }

    function _calculateBalancePoints(address user) internal view returns (uint256) {
        uint256 leftVol = userInfo[user].currentLeftVolume;
        uint256 rightVol = userInfo[user].currentRightVolume;
        return (leftVol < rightVol ? leftVol : rightVol) / POOL_SHARE; // min(leftVolume, rightVolume)
    }

    function distributeRewards() external {
        require(
            block.timestamp >= lastDistributionTime + REWARD_CYCLE_DURATION, "Not enough time since last distribution"
        );
        require(totalCyclePoints > 0, "No points to distribute");
        for (uint256 i = 0; i < allUsers.length; i++) {
            address userAddr = allUsers[i];
            User storage user = userInfo[userAddr];
            if (user.active) {
                if (user.balancePoints > 0) {
                    uint256 reward = user.balancePoints * getPointWorth();
                    user.totalEarnings += reward;
                    dai.transfer(userAddr, reward);
                }
                uint256 weakLeg =
                    user.currentLeftVolume < user.currentRightVolume ? user.currentLeftVolume : user.currentRightVolume;
                user.currentLeftVolume -= weakLeg;
                user.currentRightVolume -= weakLeg;
            }
        }
        totalCyclePoolAmount = 0;
        totalCyclePoints = 0;
        lastDistributionTime = block.timestamp;
    }

    function getUser(address user) public view returns (User memory) {
        return userInfo[user];
    }

    function getPointWorth() public view returns (uint256) {
        return totalCyclePoolAmount / totalCyclePoints;
    }
}
