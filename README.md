# WeDo Contract

这是一个基于 Hardhat 的智能合约项目，实现了 Shell Box 相关的智能合约功能。该项目包含了多个智能合约，包括 Shell Box 核心合约、账户合约以及 ERC6551 注册表合约。

## 项目结构

```
├── contracts/              # 智能合约目录
│   ├── Shell_v1.0.sol     # Shell 主合约
│   ├── ShellBox.sol       # Shell Box 合约
│   ├── ShellBoxAccount.sol # Shell Box 账户合约
│   ├── ERC6551Registry.sol # ERC6551 注册表合约
│   └── interface/         # 接口定义目录
├── scripts/               # 部署脚本目录
├── test/                 # 测试文件目录
└── hardhat.config.ts     # Hardhat 配置文件
```

## 技术栈

- Solidity
- Hardhat
- TypeScript
- OpenZeppelin Contracts
- Etherscan

## 安装

1. 克隆项目
```bash
git clone [项目地址]
cd WeDo_Contract
```

2. 安装依赖
```bash
npm install
```

3. 配置环境变量
创建 `.env` 文件并配置以下环境变量：
```
PRIVATE_KEY=你的私钥
ETHERSCAN_API_KEY=你的 Etherscan API 密钥
```

## 使用方法

### 编译合约
```bash
npx hardhat compile
```

### 运行测试
```bash
npx hardhat test
```

### 部署合约
```bash
npx hardhat run scripts/deploy.ts --network [网络名称]
```

### 验证合约
```bash
npx hardhat verify --network [网络名称] [合约地址] [构造函数参数]
```

## 合约说明

### Shell_v1.0.sol
Shell 主合约，实现了核心业务逻辑。

### ShellBox.sol
Shell Box 合约，用于管理 Shell Box 相关的功能。

### ShellBoxAccount.sol
Shell Box 账户合约，实现了账户相关的功能。

### ERC6551Registry.sol
ERC6551 注册表合约，用于管理 ERC6551 标准的注册。

## 开发

1. 创建新的分支
```bash
git checkout -b feature/your-feature-name
```

2. 提交更改
```bash
git add .
git commit -m "描述你的更改"
```

3. 推送到远程仓库
```bash
git push origin feature/your-feature-name
```

## 许可证

ISC License
