import type { Metadata } from "next";
import type { ReactNode } from "react";
import "./globals.css";

export const metadata: Metadata = {
  title: "Milka VN — tasty milk adventure 🥛",
  description: "A milky visual novel with Milka-chan. Name input & rhythm minigame.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body className="bg-[#fdf6ec] text-[#3a2a1f] antialiased">{children}</body>
    </html>
  );
}
