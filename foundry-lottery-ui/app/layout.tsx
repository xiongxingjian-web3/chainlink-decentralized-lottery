import type { Metadata } from "next";
import "./globals.css";
import Web3Provider from './components/Web3Provider';
export const metadata: Metadata = {
  title: "链上抽奖",
  description: "Foundry Raffle 前端占位页",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>
        <Web3Provider>
          {children}
        </Web3Provider>
      </body>
    </html>
  );
}
