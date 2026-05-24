# foundry-smart-contract-lottery

基于 Foundry 的链上抽奖智能合约工程，核心合约为 `Raffle`，使用 **Chainlink VRF v2.5** 生成可验证随机数，并通过 **Chainlink Automation（Upkeep）** 在满足条件时触发开奖。

> 整体项目说明见上级目录 [`../README.md`](../README.md)。

---

## 功能概述

1. 用户支付入场费调用 `enterRaffle` 参与当前轮次；
2. 间隔时间到期且满足 upkeep 条件时，触发 `performUpkeep` 向 VRF 请求随机数；
3. VRF 回调 `fulfillRandomWords` 选出中奖者，将合约余额转给赢家；
4. 重置玩家列表与时间戳，进入下一轮（状态回到 `OPEN`）。

---

## 目录结构

```text
foundry-smart-contract-lottery/
├─ src/
│  └─ Raffle.sol              # 主业务合约
├─ script/
│  ├─ HelperConfig.s.sol      # 按链 ID 返回网络参数
│  ├─ DeployRaffle.s.sol      # 部署 + VRF 订阅编排
│  └─ Interactions.s.sol      # 创建/充值订阅、添加 consumer
├─ test/
│  └─ RaffleTest.t.sol        # 单元测试
├─ lib/                       # Foundry 依赖（forge-std、Chainlink 等）
├─ foundry.toml
├─ .env.example
└─ README.md
```

---

## 技术栈

| 类别 | 技术 |
|------|------|
| 语言 | Solidity ^0.8.19 |
| 工具链 | Foundry（Forge / Cast / Anvil） |
| 随机数 | Chainlink VRF v2.5 |
| 自动化 | Chainlink Automation（`checkUpkeep` / `performUpkeep`） |
| 网络 | 本地 Anvil（31337）、Sepolia（11155111） |

---

## 合约状态机

| 状态 | 含义 |
|------|------|
| `OPEN` | 可入场，等待开奖条件 |
| `CALCULATING` | 已请求 VRF，等待回调，禁止入场 |

`checkUpkeep` 需同时满足：有玩家、间隔已过、状态为 `OPEN`、合约有余额。

---

## 环境准备

### 依赖

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Sepolia 测试网 ETH（部署到测试网时）
- Chainlink VRF 订阅（部署脚本可在 `_subscriptionId == 0` 时自动创建）

### 环境变量

```bash
cp .env.example .env
```

| 变量 | 说明 |
|------|------|
| `SEPOLIA_RPC_URL` | Sepolia RPC 地址 |
| `PRIVATE_KEY` | 部署账户私钥（不含 `0x` 前缀） |
| `ETHERSCAN_API_KEY` | 可选，用于合约验证 |

> `.env` 已被 git 忽略，切勿提交真实私钥。

---

## 常用命令

```bash
# 编译
forge build

# 测试（详细日志）
forge test -vv

# 格式化
forge fmt

# 本地节点
anvil
```

### 部署到 Sepolia

```bash
source .env   # Windows 可用 $env:SEPOLIA_RPC_URL 等方式加载

forge script script/DeployRaffle.s.sol:DeployRaffle \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY \
  -vvvv
```

部署脚本会自动完成：

1. 读取 `HelperConfig` 网络配置；
2. 若 `subscriptionId == 0`，创建并充值 VRF 订阅；
3. 部署 `Raffle` 合约；
4. 将合约加入 VRF consumer 白名单。

### 部署到本地 Anvil

```bash
# 终端 1
anvil

# 终端 2
forge script script/DeployRaffle.s.sol:DeployRaffle \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast \
  --private-key <anvil 默认账户私钥>
```

本地链会自动部署 `VRFCoordinatorV2_5Mock` 与 `LinkToken` mock。

---

## 核心脚本说明

### `HelperConfig.s.sol`

按链 ID 返回 `NetworkConfig`（入场费、间隔、VRF 协调器、gasLane、订阅 ID、LINK 地址等）。

- Sepolia：使用官方 Chainlink 合约地址，`_subscriptionId = 0` 时由部署脚本自动创建订阅；
- Anvil：自动部署 mock 合约并写入本地配置。

### `DeployRaffle.s.sol`

部署入口，串联配置读取、订阅管理、合约部署与 consumer 注册。

### `Interactions.s.sol`

- `CreateSubscription`：创建 VRF 订阅；
- `FundSubscription`：为订阅充值 LINK；
- `AddConsumner`：将 `Raffle` 加入订阅 consumer 列表。

---

## 主要合约接口

| 函数 | 说明 |
|------|------|
| `enterRaffle()` | 支付入场费参与（需 `msg.value >= i_entranceFee`） |
| `checkUpkeep(bytes)` | 检查是否满足开奖条件 |
| `performUpkeep(bytes)` | 触发 VRF 随机数请求 |
| `fulfillRandomWords(...)` | VRF 回调，选出赢家并转账 |
| `getPlayers()` / `getRaffleState()` 等 | 读接口，供前端与测试使用 |

---

## 与前端联调

部署完成后，将合约地址写入前端 `foundry-lottery-ui/constants/index.js` 中的 `contractAddress`，并确保钱包网络与部署网络一致（如 Sepolia）。

---

## 安全说明

- 私钥、RPC、Etherscan Key 仅保存在本地 `.env`；
- `broadcast/` 部署记录已加入 `.gitignore`；
- 若私钥曾泄露，请立即更换钱包并轮换 API Key。
