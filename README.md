# 彩票项目（前端 + 智能合约）完整说明

这是一个链上抽奖项目，包含两个子工程：

- `foundry-smart-contract-lottery`：Foundry 智能合约工程（Raffle + Chainlink VRF + Automation）
- `foundry-lottery-ui`：Next.js 前端工程（Wagmi + RainbowKit）

---

## 1. 项目目录结构

```text
彩票项目/
├─ foundry-smart-contract-lottery/   # 智能合约工程
├─ foundry-lottery-ui/               # 前端工程
├─ .gitignore                        # 根级统一忽略规则
└─ README.md                         # 当前文档
```

---

## 2. 技术栈

- 合约端：Solidity、Foundry、Chainlink VRF v2.5、Chainlink Automation
- 前端：Next.js、React、Wagmi、RainbowKit、Viem
- 网络：本地 Anvil / Sepolia（可按需扩展）

---

## 3. 运行前准备

### 3.1 合约端环境变量

在 `foundry-smart-contract-lottery` 下复制模板并填写：

```bash
cp .env.example .env
```

需要配置：

- `SEPOLIA_RPC_URL`
- `PRIVATE_KEY`
- `ETHERSCAN_API_KEY`（可选）

### 3.2 前端环境变量

在 `foundry-lottery-ui` 下复制模板并填写：

```bash
cp .env.example .env.local
```

需要配置：

- `NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID`
- `NEXT_PUBLIC_RAFFLE_CONTRACT_ADDRESS`（可选，当前代码默认从 `constants/index.js` 读取）

---

## 4. 合约端使用说明（Foundry）

进入目录：

```bash
cd foundry-smart-contract-lottery
```

常用命令：

```bash
forge build
forge test -vv
forge fmt
```

部署示例（Sepolia）：

```bash
forge script script/DeployRaffle.s.sol:DeployRaffle \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY
```

说明：

- `HelperConfig.s.sol` 中 Sepolia 的 `_subscriptionId` 已设置为 `0`，部署脚本会自动创建并充值 VRF 订阅。
- 真实私钥和 RPC 仅放在 `.env`，不会提交到 git。

---

## 5. 前端使用说明（Next.js）

进入目录：

```bash
cd foundry-lottery-ui
```

安装与启动：

```bash
npm install
npm run dev
```

访问：

- 默认地址：`http://localhost:3000`

前端主要逻辑：

- 页面：`app/page.tsx`
- 交互 Hook：`hooks/useLottery.js`
- 合约配置：`constants/index.js`

---


## 6. 安全提醒

- 你当前本地 `.env` 里存在真实私钥与 API Key，虽然已被忽略，但**建议立即轮换**（尤其是私钥）。
- 提交前建议执行：

```bash
git status
git check-ignore -v foundry-smart-contract-lottery/.env
```

确认敏感文件未被纳入提交范围后再 push。
