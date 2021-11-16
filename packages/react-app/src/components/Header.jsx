import { PageHeader } from "antd";
import React from "react";

// displays a page header

export default function Header() {
  return (
    <a href="/">
      <PageHeader
        title="🐍 Snakes On A Chain 🐍"
        subTitle="Snakes on a chain is a NFT project with little snakey frens living completly on the chain. Each snake is randomly generated and follows its own path (in life)."
        style={{ cursor: "pointer" }}
      />
    </a>
  );
}
