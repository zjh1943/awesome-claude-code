# 抓取网页内容并保存到项目

使用 Chrome DevTools MCP 抓取指定网页的内容，包括文本和图片，保存到本项目中。

## 参数

- **URL**: $ARGUMENTS (必填，要抓取的网页地址)
- **保存目录**: 请在执行时询问用户


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
使用 `evaluate_script` 检测页面规模，决定是否需要分段提取：

```javascript
mcp__chrome-devtools__evaluate_script({
  function: `() => ({
    totalHeight: document.documentElement.scrollHeight,
    textLength: document.body.innerText.length,
    sectionsCount: document.querySelectorAll('section, article, .content, main').length,
    imagesCount: document.querySelectorAll('img').length
  })`
})
```

**判断标准：**
- 文本长度 < 10000 字符 → 小页面，直接提取
- 文本长度 >= 10000 字符 → 大页面，分段提取或使用临时文件

### 3. 获取页面结构概览

#### 方式 A：直接获取（小页面）
```
mcp__chrome-devtools__take_snapshot()
```
用于快速了解页面结构，但注意 **snapshot 有 ~25000 令牌限制**，超大页面可能报错。

#### 方式 B：保存到临时文件后分段读取（大页面，推荐）
```
# 步骤 1：保存 snapshot 到临时文件
mcp__chrome-devtools__take_snapshot({ filePath: "/tmp/page-snapshot.txt" })

# 步骤 2：分段读取文件内容
Read(file_path: "/tmp/page-snapshot.txt", limit: 500)           # 前 500 行
Read(file_path: "/tmp/page-snapshot.txt", offset: 500, limit: 500)   # 500-1000 行
Read(file_path: "/tmp/page-snapshot.txt", offset: 1000, limit: 500)  # 1000-1500 行
# 继续按需读取...
```

**临时文件方式的优势**：
- 避免单次返回内容过大导致超时或截断
- 可以按需读取特定部分，节省 token
- 文件可复用，多次查阅无需重新抓取

### 4. 提取页面内容

#### 小页面（< 10000 字符）：直接提取
```javascript
mcp__chrome-devtools__evaluate_script({
  function: `() => ({
    title: document.title,
    content: document.body.innerText,
    images: Array.from(document.querySelectorAll('img')).map(img => ({
      src: img.src,
      alt: img.alt
    }))
  })`
})
```

#### 大页面（>= 10000 字符）：多种分段策略

**方案 A：保存到临时文件后分段读取（推荐）**
```javascript
// 步骤 1：将完整内容保存到临时文件
mcp__chrome-devtools__evaluate_script({
  function: `() => {
    const content = {
      title: document.title,
      url: window.location.href,
      content: document.body.innerText,
      html: document.body.innerHTML
    };
    return JSON.stringify(content, null, 2);
  }`
})
// 将返回的 JSON 内容写入临时文件
Write(file_path: "/tmp/page-content.json", content: "上面返回的内容")

// 步骤 2：分段读取
Read(file_path: "/tmp/page-content.json", limit: 300)
Read(file_path: "/tmp/page-content.json", offset: 300, limit: 300)
// 继续按需读取...
```

**方案 B：按字符位置分段**
```javascript
// 第 1 段（0-3000 字符）
mcp__chrome-devtools__evaluate_script({
  function: `(start, length) => document.body.innerText.substring(start, start + length)`,
  args: [{ value: 0 }, { value: 3000 }]
})

// 第 2 段（3000-6000 字符）
mcp__chrome-devtools__evaluate_script({
  function: `(start, length) => document.body.innerText.substring(start, start + length)`,
  args: [{ value: 3000 }, { value: 3000 }]
})

// 继续循环直到提取完所有内容...
```

**方案 C：按 DOM 元素分段**
```javascript
// 提取第 0 页（前 30 个段落/标题）
mcp__chrome-devtools__evaluate_script({
  function: `(pageIdx, pageSize) => {
    const elements = Array.from(document.querySelectorAll('p, h1, h2, h3, h4, li, blockquote'));
    const start = pageIdx * pageSize;
    return elements.slice(start, start + pageSize).map(el => ({
      tag: el.tagName,
      text: el.innerText
    }));
  }`,
  args: [{ value: 0 }, { value: 30 }]
})

// 提取第 1 页
// args: [{ value: 1 }, { value: 30 }]

// 继续循环直到返回空数组...
```

**方案 D：按滚动位置分段（适合懒加载页面）**
```javascript
// 滚动到指定位置并提取可见内容
mcp__chrome-devtools__evaluate_script({
  function: `(scrollY) => {
    window.scrollTo(0, scrollY);
    return {
      scrollPosition: window.scrollY,
      viewportContent: document.body.innerText.substring(0, 3000)
    };
  }`,
  args: [{ value: 0 }]
})
// 下一次 args: [{ value: 1000 }]
```

### 5. 提取所有图片链接
```javascript
mcp__chrome-devtools__evaluate_script({
  function: `() => Array.from(document.querySelectorAll('img')).map(img => ({
    src: img.src,
    alt: img.alt || '',
    width: img.naturalWidth,
    height: img.naturalHeight
  }))`
})
```

### 6. 询问用户保存位置
- 请你根据本项目的目录结构自己决定本文件该保存到哪里
- 使用 AskUserQuestion 跟用户确认你的判断
- 建议默认目录格式：`pages/[类别]/[文件名].mdx`

### 7. 下载图片
将页面中的图片下载到 `public/images/[目录名]/[文章名]/` 下：
```bash
mkdir -p public/images/[目录名]/[文章名]
curl -o public/images/[目录名]/[文章名]/[图片名] [图片URL]
```
- 保持原图片文件名，如有冲突则添加序号

### 8. 生成 MDX 文件
- 合并所有分段提取的内容
- 将提取的内容转换为 MDX 格式
- 图片路径替换为本地路径：`/images/[目录名]/[文章名]/[图片名]`
- 添加必要的 frontmatter（如 title）
- 使用 Nextra 的组件（如 Callout、Image 等）优化格式

### 9. 更新导航配置
如果需要，更新对应目录的 `_meta.js` 文件


## 示例用法

```
/fetch-webpage https://example.com/article
```

然后 Claude 会询问保存位置，例如：`pages/practical-skills/claude-skills/article-name.mdx`


## 注意事项

- 确保 Chrome 浏览器已启动并连接到 DevTools MCP
- 图片下载可能需要处理跨域问题
- 保持原文的结构和格式，文字和图片尽量原样保存，不要做任何修改
- 大页面分段提取时，确保不丢失任何信息，循环直到提取完所有内容
- `take_snapshot` 有 ~25000 令牌限制，超大页面优先使用 `evaluate_script`
