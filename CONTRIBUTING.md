# 贡献指南

感谢你对 Claude Code Academy 的关注！我们欢迎所有形式的贡献。

## 🎯 贡献方式

### 📝 文档贡献

适合所有人，不需要编程经验：

- 编写教程和指南
- 改进现有文档
- 修正错别字和表述
- 翻译英文资料
- 添加示例说明

### 💡 案例贡献

分享你的实战经验：

- 提交项目案例
- 分享使用技巧
- 记录踩坑经验
- 展示创意用法

### 🔧 工具推荐

帮助社区发现好工具：

- 推荐优质 MCP Server
- 分享有用的插件
- 介绍开发工具
- 编写工具使用指南

### 🐛 问题反馈

帮助我们改进：

- 报告文档错误
- 提出改进建议
- 反馈使用体验
- 讨论最佳实践

## 🚀 快速开始

### 1. 准备环境

```bash
# Fork 并克隆仓库
git clone https://github.com/YOUR_USERNAME/claude-code-academy.git
cd claude-code-academy

# 安装依赖
npm install

# 启动开发服务器
npm run dev
```

访问 `http://localhost:3000` 预览网站。

### 2. 创建分支

```bash
git checkout -b feature/your-feature-name
```

分支命名规范：
- `feature/xxx` - 新功能或新内容
- `fix/xxx` - 修复错误
- `docs/xxx` - 文档改进
- `style/xxx` - 格式调整

### 3. 编辑内容

所有文档位于 `pages/` 目录：

```
pages/
├── getting-started/     # 入门指南
├── tutorials/           # 教程
├── examples/            # 实战案例
├── resources/           # 资源
├── best-practices/      # 最佳实践
└── community/           # 社区
```

### 4. 文档格式规范

#### Frontmatter

每个 MDX 文件应包含 frontmatter：

```markdown
---
title: 文档标题
description: 简短描述（用于 SEO）
---
```

#### 文档结构

```markdown
---
title: 标题
description: 描述
---

# 主标题

简短介绍，说明本文内容。

## 适用场景

描述什么时候使用这个功能/工具。

## 前置条件

- 需要的知识
- 需要的工具
- 环境要求

## 详细步骤

### 步骤 1

说明...

```bash
# 代码示例
```

### 步骤 2

说明...

## 完整示例

提供完整的、可运行的代码示例。

## 常见问题

### 问题 1

解答...

## 相关资源

- [相关文档](链接)
- [参考资料](链接)
```

#### 代码示例

使用语法高亮：

````markdown
```javascript
// JavaScript 代码
function example() {
  console.log('Hello')
}
```

```bash
# Bash 命令
npm install
```

```typescript
// TypeScript 代码
interface User {
  name: string
}
```
````

#### 提示框

使用 Nextra 的 Callout 组件：

```markdown
import { Callout } from 'nextra/components'

<Callout type="info">
  提示信息
</Callout>

<Callout type="warning">
  警告信息
</Callout>

<Callout type="error">
  错误信息
</Callout>
```

### 5. 提交更改

#### 提交信息规范

使用清晰的提交信息：

```bash
# 好的示例
git commit -m "Add: MCP Server 开发教程"
git commit -m "Fix: 修正安装步骤中的错误"
git commit -m "Update: 改进工作流优化文档"

# 不好的示例
git commit -m "update"
git commit -m "fix bug"
git commit -m "修改"
```

提交信息格式：

- `Add:` 添加新内容
- `Update:` 更新现有内容
- `Fix:` 修复错误
- `Remove:` 删除内容
- `Refactor:` 重构内容
- `Style:` 格式调整

### 6. 推送并创建 PR

```bash
# 推送到你的 fork
git push origin feature/your-feature-name
```

然后在 GitHub 上创建 Pull Request。

## 📋 PR 检查清单

提交 PR 前，请确认：

- [ ] 内容准确无误
- [ ] 代码示例已测试
- [ ] 遵循文档格式规范
- [ ] 提交信息清晰明确
- [ ] 本地预览效果正常
- [ ] 没有拼写错误
- [ ] 添加了必要的截图/示例

## 📚 内容质量标准

### 教程类

- ✅ 目标明确，适用场景清晰
- ✅ 步骤完整，易于跟随
- ✅ 代码可运行，已经测试
- ✅ 包含常见问题解答
- ✅ 提供完整示例

### 案例类

- ✅ 真实项目经验
- ✅ 解决实际问题
- ✅ 包含完整代码
- ✅ 说明效果和收益
- ✅ 提供 GitHub 链接（可选）

### 工具推荐

- ✅ 工具仍在维护
- ✅ 亲自使用过
- ✅ 说明使用场景
- ✅ 提供安装和使用说明
- ✅ 注明优缺点

## 🎨 文档风格指南

### 语言风格

- 使用简洁明了的中文
- 避免过于口语化
- 技术术语保持一致
- 适当使用英文原词

### 格式规范

- 使用 Markdown 标准语法
- 代码块指定语言
- 合理使用标题层级
- 适当使用列表和表格

### 示例代码

- 保持代码简洁
- 添加必要注释
- 遵循最佳实践
- 确保可以运行

## 🤝 行为准则

### 我们的承诺

- 尊重所有贡献者
- 欢迎建设性反馈
- 保持友好和专业
- 关注内容质量

### 不被接受的行为

- 人身攻击或侮辱
- 骚扰或歧视
- 发布不当内容
- 故意破坏

## 💬 获得帮助

遇到问题？

- 💬 [GitHub Discussions](https://github.com/zjh1943/awesome-claude-code/discussions) - 提问讨论
- 🐛 [Issues](https://github.com/zjh1943/awesome-claude-code/issues) - 报告问题
- 📧 Email: your-email@example.com

## 📊 贡献者认可

我们重视每一个贡献：

- 贡献者会在 README 中展示
- 优质贡献会在社区展示页面推荐
- 活跃贡献者可以成为核心维护者

## 🙏 感谢

感谢你为 Claude Code Academy 做出贡献！

你的努力将帮助更多开发者学习和使用 Claude Code。

---

有任何疑问？欢迎随时在 [Discussions](https://github.com/zjh1943/awesome-claude-code/discussions) 中提问！
