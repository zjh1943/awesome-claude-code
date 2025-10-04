# 🎓 Claude Code Academy

<p align="center">
  <strong>为 Claude Code 开发者提供的中文学习资源库</strong>
  <br />
  <a href="https://zjh1943.github.io/claude-code-academy">📚 在线文档</a> ·
  <a href="#快速开始">快速开始</a> ·
  <a href="#贡献指南">参与贡献</a>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/zjh1943/claude-code-academy?style=social" />
  <img src="https://img.shields.io/github/forks/zjh1943/claude-code-academy?style=social" />
  <img src="https://img.shields.io/github/contributors/zjh1943/claude-code-academy" />
  <img src="https://img.shields.io/github/license/zjh1943/claude-code-academy" />
</p>

---

## 📖 关于本项目

Claude Code Academy 是一个**开源协作**的学习资源库，旨在帮助中文开发者：

- 🚀 快速掌握 Claude Code 核心功能
- 💡 学习最佳实践和开发技巧
- 🛠️ 发现优质 MCP Servers 和工具
- 🤝 分享实战经验和案例

### ✨ 核心特色

- ✅ **中文友好** - 专为中文开发者打造
- ✅ **实战导向** - 所有案例可直接运行
- ✅ **持续更新** - 跟进 Claude Code 最新版本
- ✅ **社区共建** - 欢迎每个人贡献内容
- ✅ **精美文档站** - 基于 Next.js + Nextra 构建

---

## 🌐 双重访问方式

### 📚 在线文档站（推荐）
访问 **[https://zjh1943.github.io/claude-code-academy](https://zjh1943.github.io/claude-code-academy)** 获得最佳阅读体验：
- 🔍 全文搜索
- 📱 响应式设计
- 🌙 深色模式
- 📖 目录导航

### 💻 GitHub 仓库
在本仓库浏览所有文档源文件（Markdown 格式），适合：
- 📝 贡献内容
- 🔧 本地开发
- 📥 离线阅读

---

## 🚀 快速开始

### 对于学习者

直接访问 **[在线文档站](https://zjh1943.github.io/claude-code-academy)** 开始学习！

推荐路径：
1. [什么是 Claude Code？](https://zjh1943.github.io/claude-code-academy/getting-started/introduction)
2. [安装和配置](https://zjh1943.github.io/claude-code-academy/getting-started/installation)
3. [第一个项目](https://zjh1943.github.io/claude-code-academy/getting-started/first-project)

### 对于贡献者

#### 1. Fork 并克隆仓库

```bash
git clone https://github.com/zjh1943/claude-code-academy.git
cd claude-code-academy
```

#### 2. 安装依赖

```bash
npm install
# 或
pnpm install
# 或
yarn install
```

#### 3. 本地预览

```bash
npm run dev
```

访问 `http://localhost:3000` 查看效果。

#### 4. 编辑文档

所有文档位于 `pages/` 目录，使用 Markdown/MDX 格式编写：

```
pages/
├── getting-started/     # 入门指南
├── tutorials/           # 教程
├── examples/            # 示例
├── resources/           # 资源
├── best-practices/      # 最佳实践
└── community/           # 社区
```

---

## 📚 内容概览

<table>
<tr>
<td width="50%">

### 📘 基础教程
- [Claude Code 介绍](pages/getting-started/introduction.mdx)
- [MCP Server 开发](pages/tutorials/mcp-servers/index.mdx)
- [Sub-Agent 开发](pages/tutorials/sub-agents/index.mdx)
- [Slash Command 开发](pages/tutorials/slash-commands/index.mdx)

</td>
<td width="50%">

### 💼 实战案例
- [天气查询 MCP](pages/examples/mcp-examples/weather.mdx)
- [代码审查 Agent](pages/examples/agent-examples/code-review.mdx)
- [数据库助手](pages/examples/mcp-examples/database.mdx)

</td>
</tr>
<tr>
<td>

### 🛠️ 工具资源
- [精选 MCP Servers](pages/resources/tools/mcp-servers.mdx)
- [Claude Code 插件](pages/resources/tools/extensions.mdx)
- [开发辅助工具](pages/resources/tools/dev-tools.mdx)

</td>
<td>

### 💎 最佳实践
- [开发工作流优化](pages/best-practices/workflow.mdx)
- [性能优化技巧](pages/best-practices/performance.mdx)
- [团队协作指南](pages/best-practices/collaboration.mdx)

</td>
</tr>
</table>

---

## 🤝 贡献指南

我们欢迎所有形式的贡献！🎉

### 贡献方式

| 类型 | 说明 | 示例 |
|------|------|------|
| 📝 文档 | 添加/改进教程文档 | 编写新教程、修正错误 |
| 💡 案例 | 提交实战案例 | 分享你的项目经验 |
| 🔧 工具 | 推荐优质工具 | 推荐 MCP Server |
| 🐛 修复 | 修复错误和问题 | 修正文档错误 |
| 🌐 翻译 | 翻译英文资料 | 翻译官方文档 |

### 快速贡献流程

1. **Fork** 本仓库
2. **创建分支**：`git checkout -b feature/awesome-tutorial`
3. **编辑内容**：在 `pages/` 目录下编辑或新建文件
4. **本地预览**：运行 `npm run dev` 确保效果正确
5. **提交更改**：`git commit -m 'Add: awesome tutorial'`
6. **推送分支**：`git push origin feature/awesome-tutorial`
7. **提交 PR**：在 GitHub 上创建 Pull Request

### 内容规范

#### 文档格式
```markdown
---
title: 文档标题
description: 简短描述
---

# 文档标题

## 适用场景
描述什么时候使用

## 前置条件
- 需要的知识/工具

## 详细步骤
具体内容...

## 完整示例
可运行的代码...
```

#### 提交信息规范
- `Add:` 添加新内容
- `Update:` 更新现有内容
- `Fix:` 修复错误
- `Docs:` 文档相关
- `Style:` 格式调整

**详细规范请参考：** [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 🌟 社区展示

展示优秀的社区贡献和项目案例：

- **[@contributor1]** - [项目名称](链接) - 用 Claude Code 实现了自动化测试工具
- **[@contributor2]** - [项目名称](链接) - 开发效率提升 5 倍的实战经验

> 想展示你的项目？[提交你的案例](content/community/showcase.mdx)

---

## 📊 项目统计

- 📚 教程文档：**持续增长中**
- 💼 实战案例：**持续增长中**
- 🛠️ 收录工具：**持续增长中**
- 👥 贡献者：**欢迎你加入**

---

## 🛠️ 技术栈

本项目使用以下技术构建：

- **[Next.js](https://nextjs.org/)** - React 框架
- **[Nextra](https://nextra.site/)** - 文档站点生成器
- **[MDX](https://mdxjs.com/)** - Markdown + React 组件
- **[Tailwind CSS](https://tailwindcss.com/)** - 样式框架

---

## 🔗 相关资源

- [Claude Code 官方文档](https://docs.claude.com/claude-code)
- [Claude Code GitHub](https://github.com/anthropics/claude-code)
- [MCP 协议文档](https://modelcontextprotocol.io/)
- [Anthropic 官网](https://www.anthropic.com)

---

## 📅 更新日志

查看 [CHANGELOG.md](CHANGELOG.md) 了解项目更新历史。

---

## 📜 开源协议

本项目采用 [MIT License](LICENSE) 开源协议。

---

## 💬 联系我们

- 💬 [GitHub Discussions](https://github.com/zjh1943/claude-code-academy/discussions) - 提问和讨论
- 🐛 [Issues](https://github.com/zjh1943/claude-code-academy/issues) - 报告问题
- 📧 Email: [z@claude-code.club](mailto:z@claude-code.club)

---

## 🙏 致谢

感谢所有为本项目做出贡献的开发者！

<a href="https://github.com/zjh1943/claude-code-academy/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=zjh1943/claude-code-academy" />
</a>

---

## ⭐ Star History

如果这个项目对你有帮助，请给我们一个 ⭐️

[![Star History Chart](https://api.star-history.com/svg?repos=zjh1943/claude-code-academy&type=Date)](https://star-history.com/#zjh1943/claude-code-academy&Date)

---

<p align="center">
  <sub>Built with ❤️ by the community</sub>
  <br />
  <sub>让 Claude Code 开发更简单、更高效</sub>
</p>
