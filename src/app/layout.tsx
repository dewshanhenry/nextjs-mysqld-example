import { Inter } from "next/font/google";
import "./globals.css";
import { RootLayoutProps } from "@/Type/RootLayoutProps";

const inter = Inter({ subsets: ["latin"] });

export const metadata = {
  title: "Next.js MySQL CRUD",
  description: "Production-ready Next.js and MySQL CRUD application."
};

export default function RootLayout({ children }: RootLayoutProps) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  );
}
