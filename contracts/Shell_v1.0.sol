// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ShellBox.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Shell is Initializable, ERC20Upgradeable, UUPSUpgradeable, OwnableUpgradeable{

    using SafeERC20 for IERC20;

    address public committee; // 委员会，也是国库地址，由委员会成员多签管理

    uint256 public lastIssueAmount; //上次发行量
    uint256 public decayCoefficient; // 衰减系数，18位小数

    mapping(address => uint256) public investors;
    address[] public investorsList;
    uint256 public investorsPoint;

    uint256 public distributionRatio1; //builder
    uint256 public distributionRatio2; //国库
    uint256 public distributionRatio3; //投资人

    address public shellBoxAddress; // 721合约地址

    IERC20 public usdcToken; // usdc

    event IssueShells(uint256 curIssueAmount);
    event SwapShells(address provider, address receiver, uint256 amount, uint256 usdcAmount);
    event AddInvestor(address investor, uint256 investmentAmount);
    event SetDistributionRatio(uint256 distributionRatio1, uint256 distributionRatio2, uint256 distributionRatio3);

    function initialize (
        string memory tokenName,
        string memory tokenSymbol,
        address _committee, 
        uint256 _lastIssueAmount, 
        address _shellBoxAddress, 
        address _usdcTokenAddress
    ) public initializer {
        __ERC20_init(tokenName, tokenSymbol);
        __Ownable_init();
        committee = _committee;
        lastIssueAmount = _lastIssueAmount; // 设置初始发行量
        decayCoefficient = 98;
        distributionRatio1 = 40;
        distributionRatio2 = 40;
        distributionRatio3 = 20;
        investorsPoint = 0;
        shellBoxAddress = _shellBoxAddress;
        usdcToken = IERC20(_usdcTokenAddress);
    }

    modifier onlyCommittee() {
        require(msg.sender == committee, "Only committee can call this function");
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyCommittee {

    }

    function addInvestor(address investor, uint256 investmentAmount) public onlyCommittee {
        investors[investor] += investmentAmount;
        investorsList.push(investor);
        emit AddInvestor(investor, investmentAmount);
    }

    function setDistributionRatio(uint256 _distributionRatio1, uint256 _distributionRatio2, uint256 _distributionRatio3) public onlyCommittee {
        require(_distributionRatio1 + _distributionRatio2 + _distributionRatio3 == 100, "Invaild distribution ratio.");
        distributionRatio1 = _distributionRatio1;
        distributionRatio2 = _distributionRatio2;
        distributionRatio3 = _distributionRatio3;
        emit SetDistributionRatio(distributionRatio1, distributionRatio2, distributionRatio3);
    }

    /*
        发行新的一批代币并分配代币，分配规则如下：
        按照distributionRatio，分配给builder,国库,投资人（暂时国库代领）
        builder的分配，根据addresses和ratios进行分配
     */
    function issueShells(address[] memory addresses, uint256[] memory ratios) public onlyCommittee {

        require(addresses.length == ratios.length, "Addresses and ratios length mismatch");
        
        // 计算当前发行量
        uint256 curIssueAmount = calIssueCount();

        // 遍历地址和比例数组，按比例分配代币
        _mint(committee, (curIssueAmount * distributionRatio2) / 100);
        _mint(committee, (curIssueAmount * distributionRatio3) / 100); //TODO：如果想直接发给每个investor，也可以提交一个工作量证明表

        // 以下是builder部分的分发
        uint256 issueForBuilders = (curIssueAmount * distributionRatio1) / 100;
        uint256 issueForBuilder;
        for (uint i = 0; i < addresses.length; i++) {
            issueForBuilder = (issueForBuilders * ratios[i]) / 100;
            mintWithShellBox(addresses[i], issueForBuilder);
        }

        lastIssueAmount = curIssueAmount;
        emit IssueShells(curIssueAmount);
    }

    /*
        由builder发起的兑换自己的token为USDC，provider是自己的NFT地址，receiver是自己接收USDC的地址（比如自己的钱包）。具体步骤如下：
        - 计算兑换金额：根据提供的price和amount计算出可以兑换多少USDC。
        - 转移Shell代币：将amount单位的Shell代币从提供者（provider）转移到当前investor地址。
        - 转移USDC代币：将对应的USDC数量从合约内转移到接收者（receiver）。
        - 更新investors映射：在investors映射中减去相应的资产值。
     */
    function swapShells(address provider, address receiver, uint256 price, uint256 amount) public {

        //TODO：价格可以从NFT的metadata里读出来，这里简单实现先直接传入（或者由前端读到直接当合约参数也可）
        uint256 usdcAmount = price * amount; //例如price=5表示：1 shell价格5USDC

        // 先看当前investor的余额够不够，不够的话顺序推到下一位
        
        uint256 curInvestorAmount = investors[investorsList[investorsPoint]];
        while (usdcAmount > curInvestorAmount) {
            uint256 curTokenAmount = curInvestorAmount / price;
            swapShellsWithInvestor(provider, receiver, investorsList[investorsPoint], curTokenAmount, curInvestorAmount);
            investorsPoint += 1;
            if (investorsPoint >= investorsList.length) {
                revert("Swap failed, out of asset.");
            }
            usdcAmount -= curInvestorAmount;
            amount -= curTokenAmount;
            curInvestorAmount = investors[investorsList[investorsPoint]];
        }
        swapShellsWithInvestor(provider, receiver, investorsList[investorsPoint], amount, usdcAmount);
        emit SwapShells(provider, receiver, amount, usdcAmount);
    }

    function calIssueCount() private view returns (uint256) {
        return lastIssueAmount * decayCoefficient / 100;
    }

    // 先mint一个shellBox，再把token转到shellBox，再把shellBox转给addr
    function mintWithShellBox(address addr, uint256 amount) private {
        address shellBoxAccount = ShellBox(shellBoxAddress).mintWithAccount(addr);//TODO:那些NFT里的信息咋搞
        _mint(shellBoxAccount, amount);
    }

    function swapShellsWithInvestor(address provider, address receiver, address investor, uint256 amount, uint256 usdcAmount) private {
        // 转移Shell代币
        this.transferFrom(provider, investor, amount);

        // 转移USDC代币
        usdcToken.safeTransfer(receiver, usdcAmount);

        // 更新投资者余额
        investors[investor] -= usdcAmount;
    }
}
