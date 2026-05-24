"use client";

import {
  useAccount,
  useReadContracts,
  useBalance,
  useWriteContract,
} from "wagmi";
import { contractAddress, raffleAbi } from "../constants/index.js";
import { parseEther } from "viem";
export function useLottery() {
  const { isConnected, address } = useAccount();

  // 读取钱包余额
  const { data: walletBalance } = useBalance({ address });

  // 读取合约余额
  const { data: contractBalance } = useBalance({ address: contractAddress });
  const { writeContract } = useWriteContract();

  // 批量读取合约数据
  const { data: raffleData, refetch } = useReadContracts({
    contracts: [
      {
        address: contractAddress,
        abi: raffleAbi,
        functionName: "i_entranceFee",
      },
      {
        address: contractAddress,
        abi: raffleAbi,
        functionName: "i_interval",
      },
      {
        address: contractAddress,
        abi: raffleAbi,
        functionName: "getRaffleState",
      },
      {
        address: contractAddress,
        abi: raffleAbi,
        functionName: "getPlayers",
      },
      {
        address: contractAddress,
        abi: raffleAbi,
        functionName: "getLastTimeStamp",
      },
      {
        address: contractAddress,
        abi: raffleAbi,
        functionName: "getRecentWinner",
      },
      {
        address: contractAddress,
        abi: raffleAbi,
        functionName: "getLatestRequestId",
      },
      {
        address: contractAddress,
        abi: raffleAbi,
        functionName: "checkUpkeep",
        args: ["0x"],
      },
      {
        address: contractAddress,
        abi: raffleAbi,
        functionName: "owner",
      },
    ],
  });
  const handleEnter = () => {
    writeContract({
      address: contractAddress,
      abi: raffleAbi,
      functionName: "enterRaffle",
      value: parseEther("0.01"),
    });
  };

  const handlePerform = () => {
    const upkeepNeeded = raffleData?.[7]?.result?.[0];
    const owner = raffleData?.[8]?.result;

    if (upkeepNeeded === undefined || owner === undefined) return;

    if (!upkeepNeeded) {
      alert("条件不满足，无法开奖");
      return;
    }
    if (owner !== address) {
      alert("当前用户不是合约所有者，无法执行开奖");
      return;
    }

    writeContract({
      address: contractAddress,
      abi: raffleAbi,
      functionName: "performUpkeep",
      args: ["0x"],
    });
  };

  const emergencyReset = () => {
    const owner = raffleData?.[8]?.result;
    if (owner !== address) {
      alert("当前用户不是合约所有者，无法执行重置");
      return;
    }
    if (contractBalance?.formatted === "0") {
      alert("合约余额为0，无法执行重置");
      return;
    }
    console.log("重置合约前余额", contractBalance?.formatted);
    writeContract({
      address: contractAddress,
      abi: raffleAbi,
      functionName: "emergencyReset",
    });
    console.log("重置合约后余额", contractBalance?.formatted);
  };
  const copyToClipboard = () => {
    console.log("recentWinner", raffleData?.[5]?.result);
    console.log("合约余额", contractBalance?.formatted);
  };

  return {
    isConnected,
    address,
    walletBalance,
    contractBalance,
    entranceFee: raffleData?.[0]?.result,
    interval: raffleData?.[1]?.result,
    raffleState: raffleData?.[2]?.result,
    players: raffleData?.[3]?.result,
    latestTimestamp: raffleData?.[4]?.result,
    recentWinner: raffleData?.[5]?.result,
    latestRequestId: raffleData?.[6]?.result,
    contractAddress,

    refetch,
    handleEnter,
    handlePerform,
    copyToClipboard,
    emergencyReset,
  };
}
