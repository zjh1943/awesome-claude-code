# 开发指南

本文档面向 Claude Code Academy 项目的开发者和维护者。

## 🏗️ 项目架构

### 技术栈

- **Next.js 14** - React 框架
- **Nextra 3** - 文档站点生成器
- **TypeScript** - 类型安全
- **Tailwind CSS** - 样式（Nextra 内置）

### 目录结构

```
claude-code-academy/
├── pages/                # 文档内容（MDX）+ Next.js Pages
│   ├── _meta.js          # 导航配置
│   ├── _app.jsx          # App 组件
│   ├── _document.jsx     # Document 组件
│   ├── index.mdx         # 首页
│   ├── getting-started/  # 入门指南
│   ├── tutorials/        # 教程
│   ├── examples/         # 案例
│   ├── resources/        # 资源
│   ├── best-practices/   # 最佳实践
│   └── community/        # 社区
├── public/               # 静态资源
│   ├── images/           # 图片
│   └── assets/           # 其他资源
├── components/           # React 组件
├── .github/              # GitHub Actions
│   └── workflows/
│       └── deploy.yml    # 部署工作流
├── next.config.mjs       # Next.js 配置
├── theme.config.jsx      # Nextra 主题配置
├── package.json          # 依赖
├── tsconfig.json         # TypeScript 配置
└── README.md             # 项目说明
```

## 🚀 本地开发

### 环境要求

- Node.js 18+
- npm/pnpm/yarn

### 安装依赖

```bash
npm install
```

### 启动开发服务器

```bash
npm run dev
```

访问 `http://localhost:3000`

### 构建生产版本

```bash
npm run build
```

### 预览生产构建

```bash
npm run build
npm run start
```

## 📝 添加新内容

### 1. 创建新页面

在 `pages/` 目录下创建 `.mdx` 文件：

```bash
# 例如：添加新教程
touch pages/tutorials/new-tutorial.mdx
```

### 2. 配置导航

在对应目录的 `_meta.js` 中添加配置：

```javascript
// pages/tutorials/_meta.js
export default {
  'mcp-servers': 'MCP Server 开发',
  'new-tutorial': '新教程标题',  // 添加这行
  // ...
}
```

### 3. 编写内容

```markdown
---
title: 新教程标题
description: 简短描述
---

# 新教程标题

内容...
```

### 4. 添加子目录

```bash
mkdir pages/tutorials/new-section
touch pages/tutorials/new-section/_meta.js
touch pages/tutorials/new-section/index.mdx
```

## 🎨 自定义主题

编辑 `theme.config.jsx`：

```javascript
export default {
  logo: <span>🎓 Claude Code Academy</span>,
  project: {
    link: 'https://github.com/zjh1943/awesome-claude-code'
  },
  // 更多配置...
}
```

## 🚢 部署

### GitHub Pages（自动）

1. 推送到 `main` 分支
2. GitHub Actions 自动构建和部署
3. 访问 `https://zjh1943.github.io/claude-code-academy`

### 手动部署到其他平台

#### Vercel

```bash
npm install -g vercel
vercel
```

#### Netlify

```bash
npm run build
# 上传 out/ 目录
```

#### 自托管

```bash
npm run build
# 部署 out/ 目录到 Web 服务器
```

## 🔧 配置说明

### Next.js 配置

`next.config.mjs`：

```javascript
export default withNextra({
  output: 'export',  // 静态导出
  basePath: process.env.BASE_PATH || '',  // GitHub Pages 路径
  // ...
})
```

### Nextra 配置

`theme.config.jsx`：

```javascript
export default {
  primaryHue: 220,        // 主题色调
  primarySaturation: 90,  // 饱和度
  darkMode: true,         // 支持深色模式
  // ...
}
```

## 📦 依赖管理

### 主要依赖

- `next` - Next.js 框架
- `react` & `react-dom` - React
- `nextra` - 文档生成器
- `nextra-theme-docs` - 文档主题

### 更新依赖

```bash
# 检查过时的包
npm outdated

# 更新所有依赖
npm update

# 更新主要版本
npm install next@latest react@latest react-dom@latest
```

## 🐛 调试

### 查看构建日志

```bash
npm run build -- --debug
```

### 清除缓存

```bash
rm -rf .next
npm run dev
```

## 📊 性能优化

### 图片优化

使用 Next.js Image 组件：

```jsx
import Image from 'next/image'

<Image src="/images/example.png" alt="Example" width={800} height={600} />
```

### 代码分割

Nextra 自动处理代码分割，无需额外配置。

## 🧪 测试

### 链接检查

```bash
# 安装 broken-link-checker
npm install -g broken-link-checker

# 检查链接
npm run build
npx http-server out
blc http://localhost:8080 -ro
```

## 📚 相关资源

- [Next.js 文档](https://nextjs.org/docs)
- [Nextra 文档](https://nextra.site)
- [MDX 文档](https://mdxjs.com)

## 🤝 维护指南

### 定期任务

- [ ] 每月更新依赖
- [ ] 每季度检查过时链接
- [ ] 每季度更新内容
- [ ] 响应 Issues 和 PR

### 发布流程

1. 更新版本号（如果需要）
2. 更新 CHANGELOG.md
3. 创建 Git tag
4. 推送到 main 分支
5. GitHub Actions 自动部署

## 💬 获得帮助

- [GitHub Issues](https://github.com/zjh1943/awesome-claude-code/issues)
- [Discussions](https://github.com/zjh1943/awesome-claude-code/discussions)
