import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Next.js AWS Starter",
  description: "Production-ready Next.js on AWS ECS Fargate",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}