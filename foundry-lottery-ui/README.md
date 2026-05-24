# foundry-lottery-ui

链上抽奖 DApp 前端，基于 **Next.js** + **Wagmi** + **RainbowKit**，与 `foundry-smart-contract-lottery` 部署的 `Raffle` 合约交互。

> 整体项目说明见上级目录 [`../README.md`](../README.md)。

---

## 功能概述

- 连接钱包（RainbowKit，支持 Sepolia 等网络）；
- 读取合约状态：入场费、间隔、状态、参与者、最近中奖者、VRF 请求 ID 等；
- **参与抽奖**：调用 `enterRaffle` 并附带 ETH；
- **触发开奖**：在满足 upkeep 且当前账户为 owner 时调用 `performUpkeep`；
- **紧急重置**：owner 可调用 `emergencyReset`（需合约有余额）。

---

## 目录结构

```text
foundry-lottery-ui/
├─ app/
│  ├─ page.tsx           # 主页面（读数 + 操作按钮）
│  ├─ layout.tsx         # 布局与 Provider
│  └─ globals.css        # 样式
├─ hooks/
│  └─ useLottery.js      # 合约读写与业务逻辑
├─ constants/
│  └─ index.js           # 合约地址与 ABI
├─ rainbowkit.js         # Wagmi / RainbowKit 配置
├─ .env.example
├─ package.json
└─ README.md
```

---

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Next.js 16、React 19 |
| 链交互 | Wagmi、Viem |
| 钱包 | RainbowKit |
| 样式 | Tailwind CSS 4 |

默认链：`sepolia`、`arbitrum`、`base`（见 `rainbowkit.js`）。

---

## 环境准备

### 依赖

- Node.js 18+
- npm / pnpm / yarn

### 环境变量

```bash
cp .env.example .env.local
```

| 变量 | 说明 |
|------|------|
| `NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID` | [WalletConnect Cloud](https://cloud.walletconnect.com/) 项目 ID |
| `NEXT_PUBLIC_RAFFLE_CONTRACT_ADDRESS` | 可选；当前默认在 `constants/index.js` 中配置 |

### 合约地址

部署 `Raffle` 后，修改 `constants/index.js`：

```javascript
export const contractAddress = "0x你的合约地址";
```

确保钱包连接的网络与合约部署网络一致。

---

## 安装与运行

```bash
npm install
npm run dev
```

浏览器访问：[http://localhost:3000](http://localhost:3000)

其他命令：

```bash
npm run build    # 生产构建
npm run start    # 启动生产服务
npm run lint     # ESLint
```

---

## 页面与交互说明

### 合约读数面板

连接钱包后展示：

- 合约地址、入场费、抽奖间隔；
- 状态 `OPEN` / `CALCULATING`；
- 参与者数量、最近开奖时间、最近中奖者、最近 VRF 请求 ID。

### 操作按钮

| 操作 | 合约方法 | 说明 |
|------|----------|------|
| 参与 | `enterRaffle` | 需附带不少于入场费的 ETH（当前 hook 默认 `0.01` ETH） |
| 管理员/执行 | `performUpkeep` | 仅 owner，且 `checkUpkeep` 为 true |
| 管理员重置合约 | `emergencyReset` | 仅 owner，且合约余额大于 0 |

未连接钱包时，读数为 `—`，按钮禁用。

---

## 核心文件

### `hooks/useLottery.js`

封装：

- `useReadContracts` 批量读取合约状态；
- `useWriteContract` 写入 `enterRaffle`、`performUpkeep`、`emergencyReset`；
- `useBalance` 查询钱包与合约余额。

### `rainbowkit.js`

配置 RainbowKit 与 Wagmi：`appName`、`projectId`（来自环境变量）、`chains`、`ssr`。

### `app/page.tsx`

UI 层：展示读数、连接钱包、绑定 `useLottery` 返回的方法。

---

## 与合约联调流程

1. 在 `foundry-smart-contract-lottery` 部署 `Raffle`（本地或 Sepolia）；
2. 将部署地址写入 `constants/index.js`；
3. 配置 `.env.local` 中的 WalletConnect Project ID；
4. 启动 `npm run dev`，连接与部署网络相同的钱包；
5. 支付入场费参与 → 等待间隔 → owner 执行开奖 → 等待 VRF 回调后查看中奖者。

---

## 安全说明

- `.env.local` 不要提交到 git（已由 `.gitignore` 忽略）；
- `NEXT_PUBLIC_*` 会暴露到浏览器，仅放可公开的配置；
- 不要在代码中硬编码私钥；所有链上写操作由用户钱包签名。
