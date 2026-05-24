"use client";

import "./globals.css"
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useEffect, useState } from 'react';
import { useLottery } from '../hooks/useLottery.js';
import { formatEther } from 'viem';

export default function Home() {
  const [mounted, setMounted] = useState(false);
  useEffect(() => {
    setMounted(true);
  }, []);

  const {
    isConnected,
    contractAddress,
    entranceFee,
    interval,
    raffleState,
    players,
    latestTimestamp,
    recentWinner,
    latestRequestId,
    contractBalance,
    handleEnter,
    handlePerform,
    copyToClipboard,
    emergencyReset,
  } = useLottery();

  const address0 = "0x0000000000000000000000000000000000000000";

  if (!mounted) return <div className="shell">Loading wallet...</div>;

  return (
    <div className="shell">
      <div className="topbar">
        <div className="brandGroup">
          <div className="brand">链上抽奖</div>
          <div className="hint">Raffle · Chainlink VRF</div>
        </div>
        <ConnectButton />
      </div>

      <div className="main">
        <div className="hero">
          <h1>公平随机，按约执行</h1>
          <p>
            支付入场费参与奖池；间隔到期后由自动化节点触发 upkeep，经 VRF
            回调选出中奖地址并转账合约余额。
          </p>
        </div>

        <div className="board">
          <div className="boardHead">
            <div className="boardTitle">合约读数</div>
            {isConnected ? (
              <div className="boardNote" style={{ color: '#10b981', fontWeight: '600' }}>
                ● 已连接区块链
              </div>
            ) : (
              <div className="boardNote">未连接钱包，无法读取合约数据，请先连接钱包</div>
            )}
          </div>

          <div className="row">
            <div className="rowName">合约地址</div>
            <div className="rowVal">{isConnected ? contractAddress : "—"}</div>
          </div>
          <div className="row">
            <div className="rowName">入场费 (ETH)</div>
            <div className="rowVal">
              {isConnected && entranceFee
                ? `${formatEther(BigInt(entranceFee as string))} ETH`
                : "—"}
            </div>
          </div>
          <div className="row">
            <div className="rowName">抽奖间隔 (秒)</div>
            <div className="rowVal">
              {isConnected && interval ? interval.toString() : "—"}
            </div>
          </div>
          <div className="row">
            <div className="rowName">当前状态</div>
            <div className="rowVal">
              {isConnected
                ? (raffleState === 0 ? "OPEN" : "CALCULATING")
                : "—"}
            </div>
          </div>
          <div className="row">
            <div className="rowName">参与者人数</div>
            <div className="rowVal">
              {isConnected ? (Array.isArray(players) ? players.length : 0) : "—"}
            </div>
          </div>
          <div className="row">
            <div className="rowName">最近一次开奖时间</div>
            <div className="rowVal">
              {isConnected && latestTimestamp
                ? new Date(Number(latestTimestamp) * 1000).toLocaleString()
                : "—"}
            </div>
          </div>
          <div className="row">
            <div className="rowName">最近中奖者</div>
            <div className="rowVal">
              {isConnected && recentWinner && recentWinner !== address0
                ? recentWinner.toString()
                : "—"}
            </div>
          </div>
          <div className="row">
            <div className="rowName">最近 VRF 请求 ID</div>
            <div className="rowVal">
              {isConnected && latestRequestId ? latestRequestId.toString() : "—"}
            </div>
          </div>
        </div>

        <div className="actions">
          <div className="actionCard">
            <div className="actionTitle">参与抽奖</div>
            <div className="actionBody">调用 enterRaffle，附带不少于入场费的 value。</div>
            <button
              type="button"
              className={isConnected ? "btnPrimary" : "btnGhost"}
              disabled={!isConnected}
              onClick={handleEnter}
            >
              参与
            </button>
            <button onClick={() => copyToClipboard()}>获取获奖者地址</button>
            <button onClick={() => emergencyReset()}>管理员重置合约</button>
          </div>
          <div className="actionCard">
            <div className="actionTitle">触发开奖</div>
            <div className="actionBody">
              在间隔已过且满足 upkeep 条件时，调用 checkUpkeep / performUpkeep。
            </div>
            <button
              type="button"
              className={contractBalance?.formatted && Number(contractBalance.formatted) > 0 ? "btnPrimary" : "btnGhost"}
              disabled={!isConnected} onClick={handlePerform}>
              管理员/ 执行
            </button>
            <button disabled className="btnGhost">满足条件合约自动开奖</button>
          </div>
        </div>

        <div className="foot">
          <div className="footLine">本地或测试网部署后，将按钮与读数接到你的 hooks / viem 即可。</div>
        </div>
      </div>
    </div>
  );
}
