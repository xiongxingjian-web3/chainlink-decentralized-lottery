"use client";
import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { sepolia, arbitrum, base } from "wagmi/chains";
const config = getDefaultConfig({
  appName: "Foundry Lottery UI",
  projectId:
    process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID ?? "YOUR_WALLETCONNECT_PROJECT_ID",
  chains: [sepolia, arbitrum, base],
  ssr: true, // If your dApp uses server side rendering (SSR)
  autoConnect: true,
});
export default config;
