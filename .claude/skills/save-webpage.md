---
description: 抓取网页内容（文本和图片）并保存为 MDX 文件到项目中
triggers:
  - 保存网页
  - 抓取网页
  - 把网页保存到项目
  - 把这个页面保存下来
  - 下载网页内容
  - fetch webpage
  - save webpage
globs:
  - pages/**/*.mdx
  - public/images/**
---

# save-webpage

使用 Chrome DevTools MCP 抓取指定网页的内容，包括文本和图片，保存到本项目中。

## 可用脚本

本 skill 提供以下可复用的 JavaScript 脚本，位于 `.claude/skills/save-webpage/` 目录：

| 脚本 | 用途 | 适用场景 |
|------|------|---------|
| `detect-page-size.js` | 检测页面规模，返回建议策略 | 首先调用 |
| `extract-content-small.js` | 一次性提取全部内容 | 小页面 (<10000 字符) |
| `extract-content-full.js` | 返回 JSON，写入临时文件后分段读取 | 大页面 |
| `extract-content-chunk.js` | 按字符位置分段提取 | 大页面分段 |
| `extract-by-dom.js` | 按 DOM 元素分页提取 | 保留结构的分段 |
| `extract-by-scroll.js` | 滚动加载提取 | 懒加载/无限滚动页面 |
| `extract-images.js` | 提取图片列表 | 下载图片前 |
| `extract-structured.js` | 保留 HTML 层级结构 | 需要精确格式 |

**使用方式**：
1. 用 `Read` 读取脚本文件内容
2. 将脚本内容传入 `mcp__chrome-devtools__evaluate_script` 的 `function` 参数


## 工具说明

| 工具 | 返回内容 | 用途 |
|------|---------|------|
| `take_snapshot` | 基于 A11y 树的文本结构 + 元素 uid | 快速了解页面结构、定位元素 |
| `take_screenshot` | PNG/JPEG 图片 | 视觉截图 |
| `evaluate_script` | 自定义 JS 返回值 | 提取 DOM、执行操作、分段加载大页面 |

**关键特性**：`take_snapshot` 和 `take_screenshot` 都支持 `filePath` 参数，可将内容保存到临时文件，然后使用 `Read` 工具分段加载。


## 执行步骤

### 1. 导航到目标页面
```
mcp__chrome-devtools__navigate_page({ type: "url", url: "目标URL" })
```

### 2. 检测页面大小

使用 `detect-page-size.js` 脚本，根据返回的 `strategy` 字段判断：
- `strategy: 'direct'` → 小页面，直接提取
- `strategy: 'chunked'` → 大页面，分段提取或使用临时文件

### 3. 获取页面结构概览

#### 方式 A：直接获取（小页面）
```
mcp__chrome-devtools__take_snapshot()
```
注意：snapshot 有 ~25000 令牌限制，超大页面可能报错。

#### 方式 B：保存到临时文件后分段读取（大页面，推荐）
```
mcp__chrome-devtools__take_snapshot({ filePath: "/tmp/page-snapshot.txt" })
```
然后用 `Read` 工具的 `offset` 和 `limit` 参数分段读取。

### 4. 提取页面内容

根据 `strategy` 选择脚本：

| 策略 | 推荐脚本 | 说明 |
|------|---------|------|
| `direct` | `extract-content-small.js` | 一次性提取 |
| `chunked` | `extract-content-full.js` | 提取后写入临时文件，分段读取 |
| `chunked` | `extract-content-chunk.js` | 按字符位置分段，循环直到 `hasMore: false` |
| `chunked` | `extract-by-dom.js` | 按 DOM 元素分页，循环直到 `hasMore: false` |
| 懒加载页面 | `extract-by-scroll.js` | 滚动加载，循环直到 `hasMore: false` |

### 5. 提取所有图片链接

使用 `extract-images.js` 获取图片列表，返回包含 `src`、`alt`、`filename` 等字段。

### 6. 询问用户保存位置
- 根据项目目录结构判断保存位置
- 使用 AskUserQuestion 跟用户确认
- 建议格式：`pages/[类别]/[文件名].mdx`

### 7. 下载图片
```bash
mkdir -p public/images/[目录名]/[文章名]
curl -o public/images/[目录名]/[文章名]/[图片名] [图片URL]
```

### 8. 生成 MDX 文件
- 合并所有分段提取的内容
- 将提取的内容转换为 MDX 格式
- 图片路径替换为本地路径：`/images/[目录名]/[文章名]/[图片名]`
- 添加必要的 frontmatter（如 title）
- 使用 Nextra 的组件（如 Callout、Image 等）优化格式

### 9. 更新导航配置
如果需要，更新对应目录的 `_meta.js` 文件


## 示例用法

用户说：「帮我把 https://example.com/article 这个页面保存到项目里」

Claude 执行流程：
1. 导航到页面
2. 运行 `detect-page-size.js` 检测大小
3. 根据 `strategy` 选择提取脚本
4. 运行 `extract-images.js` 获取图片
5. 询问保存位置
6. 下载图片到 `public/images/`
7. 生成 MDX 文件
8. 更新 `_meta.js` 导航


## 注意事项

- 确保 Chrome 浏览器已启动并连接到 DevTools MCP
- 图片下载可能需要处理跨域问题
- 保持原文的结构和格式，文字和图片尽量原样保存
- 大页面分段提取时，循环直到 `hasMore: false`
- `take_snapshot` 有 ~25000 令牌限制，超大页面优先使用临时文件方式
