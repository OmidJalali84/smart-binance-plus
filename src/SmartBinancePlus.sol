// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DrCat} from "./DrCat.sol";
import {console} from "forge-std/console.sol";

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
    address[] public pureBinaryUsers;

    address public admin;

    uint256 public constant ENTRANCE = 100 ether;
    uint256 public constant OWNER_SHARE = 10 ether;
    uint256 public constant POOL_SHARE = 90 ether;

    uint256 public REWARD_CYCLE_DURATION = 1 hours;
    address public immutable ROOT;
    IERC20 public dai;
    uint256 public contractStartTime;
    uint256 public totalCyclePoolAmount;
    uint256 public totalCyclePoints;
    uint256 public lastDistributionTime;

    uint256 public cycleTimeChangeRequestTime; //@
    address public cycleTimeChangeRequester; //@
    uint256 public withdrawRequestTime;
    address public withdrawRequester;

    DrCat public immutable drCat;

    string public ownerMessage;

    modifier preChecks(Plan plan, address referrer) {
        require(plan == Plan.Binary || plan == Plan.InOrder, "Invalid plan");
        require(userInfo[referrer].active, "Referrer is not active");
        require(!userInfo[msg.sender].active, "User is already active");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    constructor(address _initialOwner, address _initialAdmin, address _dai, address _root) Ownable(_initialOwner) {
        admin = _initialAdmin;
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

        drCat = new DrCat(_initialOwner);
    }

    function changeRewardCycle(uint256 newCycle) external {
        require(msg.sender == owner() || msg.sender == admin, "Only owner or admin can call this function");
        if (cycleTimeChangeRequestTime + 1 hours > block.timestamp) {
            require(cycleTimeChangeRequester != msg.sender, "Request should be accepted from other author");
            REWARD_CYCLE_DURATION = newCycle;
            cycleTimeChangeRequester = address(0);
            cycleTimeChangeRequestTime = 0;
        } else {
            cycleTimeChangeRequester = msg.sender;
            cycleTimeChangeRequestTime = block.timestamp;
        }
    }

    function withdrawEmergancy() external {
        require(msg.sender == owner() || msg.sender == admin, "Only owner or admin can call this function");
        if (withdrawRequestTime + 1 hours > block.timestamp) {
            require(withdrawRequester != msg.sender, "Request should be accepted from other author");
            dai.transfer(owner(), dai.balanceOf(address(this)));
            withdrawRequester = address(0);
            withdrawRequestTime = 0;
        } else {
            withdrawRequester = msg.sender;
            withdrawRequestTime = block.timestamp;
        }
    }

    function sendNewMessage(string memory newMessage) external {
        ownerMessage = newMessage;
    }

    function register(Plan plan, address referrer) external preChecks(plan, referrer) {
        dai.transferFrom(msg.sender, address(this), ENTRANCE);
        dai.transfer(owner(), OWNER_SHARE);
        totalCyclePoolAmount += POOL_SHARE;

        if (userInfo[referrer].plan == Plan.Binary) {
            if (userInfo[referrer].left != address(0) && userInfo[userInfo[referrer].left].plan == Plan.InOrder) {
                require(plan == Plan.Binary, "Referrer is in binary plan and has an in-order hand");
            }
            _connectToBinaryReferrer(referrer);
        } else {
            // InOrder plan: find empty spot using BFS
            address emptySpot = _findEmptySpotBFS(ROOT);
            require(emptySpot != address(0), "No empty spot found");
            _connectToInOrderSpot(emptySpot);
        }

        // Activate the user
        userInfo[msg.sender].active = true;
        userInfo[msg.sender].plan = plan;
        allUsers.push(msg.sender);
        if (drCat.balanceOf(address(drCat)) >= 500e18) drCat.transferFrom(address(drCat), msg.sender, 500e18);

        _updateVolumeAndBalancePoints(msg.sender);
        // After connecting, check if referrer now qualifies as pure binary
        if (_isPureBinaryUser(referrer)) {
            // Only add if not already present
            bool alreadyAdded = false;
            for (uint256 i = 0; i < pureBinaryUsers.length; i++) {
                if (pureBinaryUsers[i] == referrer) {
                    alreadyAdded = true;
                    break;
                }
            }
            if (!alreadyAdded) {
                pureBinaryUsers.push(referrer);
            }
        }
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

        // Always start from ROOT to find the first available empty spot in the entire tree
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
                return currentNode;
            }

            if (userInfo[currentNode].right == address(0)) {
                if (
                    userInfo[currentNode].plan == Plan.InOrder
                        || userInfo[userInfo[currentNode].left].plan == Plan.Binary
                ) {
                    return currentNode;
                }
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
        uint256 remainingAmounts;
        for (uint256 i = 0; i < allUsers.length; i++) {
            address userAddr = allUsers[i];
            User storage user = userInfo[userAddr];
            if (user.active) {
                if (user.balancePoints > 0) {
                    uint256 pointsToSend = user.balancePoints >= 10 ? 10 : user.balancePoints;
                    uint256 diffPoints = user.balancePoints - pointsToSend;
                    remainingAmounts += diffPoints * getPointWorth();
                    uint256 pureReward = pointsToSend * getPointWorth();
                    uint256 rewardToSend;
                    if (user.plan == Plan.InOrder) {
                        rewardToSend = pureReward * 50 / 100;
                    } else if (userInfo[user.left].plan == Plan.Binary && userInfo[user.right].plan == Plan.Binary) {
                        rewardToSend = pureReward;
                    } else {
                        rewardToSend = pureReward * 75 / 100;
                    }
                    user.totalEarnings += rewardToSend;
                    dai.transfer(userAddr, rewardToSend);

                    remainingAmounts += pureReward - rewardToSend;
                }
                uint256 weakLeg =
                    user.currentLeftVolume < user.currentRightVolume ? user.currentLeftVolume : user.currentRightVolume;
                user.currentLeftVolume -= weakLeg;
                user.currentRightVolume -= weakLeg;
                user.balancePoints = 0;
            }
        }
        // Distribute remainingAmounts among all pureBinaryUsers
        uint256 numPureBinary = pureBinaryUsers.length;
        if (remainingAmounts > 0 && numPureBinary > 0) {
            uint256 share = remainingAmounts / numPureBinary;
            console.log(share);
            for (uint256 i = 0; i < numPureBinary; i++) {
                address userAddr = pureBinaryUsers[i];
                if (userInfo[userAddr].active) {
                    userInfo[userAddr].totalEarnings += share;
                    dai.transfer(userAddr, share);
                }
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

    function _isPureBinaryUser(address user) internal view returns (bool) {
        if (userInfo[user].plan != Plan.Binary) return false;
        address left = userInfo[user].left;
        address right = userInfo[user].right;
        if (left == address(0) || right == address(0)) return false;
        return userInfo[left].plan == Plan.Binary && userInfo[right].plan == Plan.Binary;
    }
}
