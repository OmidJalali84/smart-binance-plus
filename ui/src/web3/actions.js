import { contractAbi, contractAddress, usdtAddress, tokenAbi } from "./helper";
import { writeContract } from "wagmi/actions";
import { readContract } from "@wagmi/core";
import { useReadContract } from "wagmi";
import { config } from "./Web3Provider";
import { ethers } from "ethers";
import { parseEther, zeroAddress } from "viem";
import { getBalance } from "@wagmi/core";

export function approveUsdt(amount) {
  return writeContract(config, {
    abi: tokenAbi,
    address: usdtAddress,
    functionName: "approve",
    args: [contractAddress, amount],
  });
}

export function getAllUsers() {
  return useReadContract({
    abi: contractAbi,
    address: contractAddress,
    functionName: "fetchAllUsers",
    args: [],
  });
}

// Fetch a user's info
export  function getUserInfo(address) {
  return  useReadContract({
    abi: contractAbi,
    address: contractAddress,
    functionName: "getUser",
    args: [address],
  });
}

// Register a user
export async function registerUser(plan, referrer) {
  // plan: 0 or 1
  // referrer: address
  return await writeContract(config, {
    abi: contractAbi,
    address: contractAddress,
    functionName: "register",
    args: [plan, referrer],
  });
}

// Owner/Admin functions
export async function changeRewardCycle(newCycle) {
  return await writeContract(config, {
    abi: contractAbi,
    address: contractAddress,
    functionName: "changeRewardCycle",
    args: [newCycle],
  });
}

export async function withdrawEmergency() {
  return await writeContract(config, {
    abi: contractAbi,
    address: contractAddress,
    functionName: "withdrawEmergancy",
    args: [],
  });
}

export async function sendNewMessage(message) {
  return await writeContract( config, {
    abi: contractAbi,
    address: contractAddress,
    functionName: "sendNewMessage",
    args: [message],
  });
}

export async function distributeRewards() {
  return await writeContract(config, {
    abi: contractAbi,
    address: contractAddress,
    functionName: "distributeRewards",
    args: [],
  });
}


export function getOwnerMessage() {
  return useReadContract({
    abi: contractAbi,
    address: contractAddress,
    functionName: "ownerMessage",
    args: [],
  });
}

export function getRewardCycleDuration() {
  return useReadContract({
    abi: contractAbi,
    address: contractAddress,
    functionName: "REWARD_CYCLE_DURATION",
    args: [],
  });
}
