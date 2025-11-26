#!/usr/bin/env node

/**
 * MDX 到多平台格式转换脚本
 *
 * 功能：
 * - 将 Nextra MDX 文件转换为纯 Markdown（知乎/掘金）
 * - 将 Nextra MDX 文件转换为 HTML（微信公众号）
 *
 * 用法：
 *   node scripts/convert-mdx.js <input-file> [--output-dir <dir>]
 *   node scripts/convert-mdx.js pages/practical-skills/config/why-claude-md-matters.mdx
 *
 * 输出：
 *   dist/articles/
 *     ├── <filename>-wechat.html     # 微信公众号版本
 *     ├── <filename>-zhihu.md        # 知乎版本
 *     └── <filename>-juejin.md       # 掘金版本
 */

const fs = require('fs');
const path = require('path');

// ============================================
// 配置
// ============================================

const CONFIG = {
  // 网站基础 URL（用于图片绝对路径）
  baseUrl: 'https://claude-code-academy.com',

  // Callout 类型映射
  calloutEmoji: {
    info: '💡',
    warning: '⚠️',
    error: '🚫',
    danger: '🚫',
    success: '✅',
    default: '📌',
  },

  calloutTitle: {
    info: '提示',
    warning: '注意',
    error: '警告',
    danger: '警告',
    success: '成功',
    default: '备注',
  },
};

// ============================================
// MDX 解析和转换
// ============================================

class MdxConverter {
  constructor(content, filename) {
    this.original = content;
    this.filename = filename;
  }

  /**
   * 转换为纯 Markdown（知乎/掘金）
   */
  toMarkdown() {
    let content = this.original;

    // 1. 移除 frontmatter 并提取标题
    content = this.removeFrontmatter(content);

    // 2. 移除 import 语句
    content = this.removeImports(content);

    // 3. 移除 JSX 注释
    content = this.removeJsxComments(content);

    // 4. 转换 Callout 组件
    content = this.convertCallouts(content);

    // 5. 转换 Steps 组件
    content = this.convertSteps(content);

    // 6. 转换内联样式的 div（流程图、对比表等）
    content = this.convertStyledDivs(content);

    // 7. 转换图片路径为绝对路径
    content = this.convertImagePaths(content);

    // 8. 清理多余空行
    content = this.cleanupWhitespace(content);

    return content;
  }

  /**
   * 转换为微信公众号 HTML
   */
  toWechatHtml() {
    const markdown = this.toMarkdown();
    return this.markdownToWechatHtml(markdown);
  }

  /**
   * 获取文章标题
   */
  getTitle() {
    // 从 frontmatter 中提取标题
    const titleMatch = this.original.match(/^---\n[\s\S]*?title:\s*(.+)\n[\s\S]*?---/);
    if (titleMatch) {
      return titleMatch[1].trim();
    }
    // 或者从第一个 # 标题提取
    const h1Match = this.original.match(/^#\s+(.+)$/m);
    return h1Match ? h1Match[1].trim() : this.filename;
  }

  /**
   * 获取文章描述
   */
  getDescription() {
    // 从 frontmatter 中提取描述
    const descMatch = this.original.match(/^---\n[\s\S]*?description:\s*(.+)\n[\s\S]*?---/);
    return descMatch ? descMatch[1].trim() : '';
  }

  /**
   * 生成微信文章简介（120字以内，有吸引力）
   */
  generateSummary() {
    const title = this.getTitle();

    // 根据文章标题生成有吸引力的简介
    const summaryTemplates = {
      '为什么': '同样的需求，为什么别人一次搞定，你却要改5遍？90%的人不知道，一个配置文件就能让Claude Code的输出质量提升10倍。',
      '工作流': '还在让AI上来就写代码？难怪总是返工！掌握这套「研究→计划→实现」三阶段工作流，让Claude Code像资深工程师一样思考。',
      '质量': '代码写完一堆bug？类型全是any？这份质量红线清单，帮你堵住Claude Code偷懒的每一个漏洞。',
      '编码': '函数超过100行、命名乱七八糟、错误处理全靠猜...这些坏习惯，一份编码规范就能根治。',
      '安全': 'SQL注入、硬编码密钥、不验证输入...这些安全漏洞你的AI助手可能正在写。这份安全清单必须收藏。'
    };

    // 匹配标题关键词
    for (const [keyword, summary] of Object.entries(summaryTemplates)) {
      if (title.includes(keyword)) {
        return summary;
      }
    }

    // 默认模板
    return '用好Claude Code的秘诀，不是提示词写得多花哨，而是这个99%的人都忽略的配置文件。5分钟配置，效率提升10倍。';
  }

  /**
   * 生成封面图 HTML（2.35:1 比例）
   */
  generateCoverHtml() {
    const title = this.getTitle();
    const subtitle = this.getDescription() || 'Claude Code 配置指南';
    const theme = this.getCoverTheme(title);

    return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>封面图 - ${title}</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      background: #111;
      font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", "Microsoft YaHei", sans-serif;
    }
    .cover {
      width: 900px;
      height: 383px;
      background: ${theme.gradient};
      position: relative;
      overflow: hidden;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      text-align: center;
    }
    /* 背景光晕 */
    .cover::before {
      content: '';
      position: absolute;
      top: -50%;
      left: -50%;
      width: 200%;
      height: 200%;
      background:
        radial-gradient(circle at 20% 30%, rgba(255,255,255,0.18) 0%, transparent 35%),
        radial-gradient(circle at 85% 60%, rgba(255,255,255,0.12) 0%, transparent 30%),
        radial-gradient(circle at 70% 20%, rgba(0,0,0,0.1) 0%, transparent 25%);
    }
    /* 浮动圆形 */
    .circle {
      position: absolute;
      border-radius: 50%;
      background: rgba(255,255,255,0.08);
    }
    .circle-1 { width: 300px; height: 300px; top: -100px; right: -80px; }
    .circle-2 { width: 200px; height: 200px; bottom: -60px; left: -60px; }
    .circle-3 { width: 120px; height: 120px; top: 60px; left: 80px; background: rgba(255,255,255,0.05); }
    .circle-4 { width: 80px; height: 80px; bottom: 40px; right: 120px; background: rgba(255,255,255,0.06); }
    /* 小光点 */
    .dot {
      position: absolute;
      width: 6px;
      height: 6px;
      background: rgba(255,255,255,0.4);
      border-radius: 50%;
    }
    .dot-1 { top: 40px; left: 150px; }
    .dot-2 { top: 80px; right: 200px; }
    .dot-3 { bottom: 100px; left: 250px; }
    .dot-4 { bottom: 60px; right: 300px; }
    .dot-5 { top: 150px; left: 50px; width: 4px; height: 4px; }
    .dot-6 { top: 200px; right: 80px; width: 4px; height: 4px; }
    .dot-7 { bottom: 150px; right: 180px; width: 5px; height: 5px; }
    /* 装饰线条 */
    .line {
      position: absolute;
      background: rgba(255,255,255,0.1);
    }
    .line-1 { width: 100px; height: 2px; top: 60px; right: 60px; transform: rotate(-20deg); }
    .line-2 { width: 60px; height: 2px; bottom: 80px; left: 40px; transform: rotate(15deg); }
    .line-3 { width: 80px; height: 2px; top: 120px; left: 120px; transform: rotate(-10deg); background: rgba(255,255,255,0.06); }
    /* 方块装饰 */
    .square {
      position: absolute;
      border: 2px solid rgba(255,255,255,0.1);
      transform: rotate(45deg);
    }
    .square-1 { width: 40px; height: 40px; top: 30px; left: 300px; }
    .square-2 { width: 25px; height: 25px; bottom: 50px; right: 220px; }
    .square-3 { width: 60px; height: 60px; bottom: 120px; left: 60px; border-color: rgba(255,255,255,0.06); }
    /* 代码装饰 */
    .code-decoration {
      position: absolute;
      font-family: 'SF Mono', 'Consolas', monospace;
      font-size: 11px;
      color: rgba(255,255,255,0.12);
      white-space: nowrap;
    }
    .code-1 { top: 25px; left: 30px; }
    .code-2 { bottom: 25px; left: 30px; }
    .code-3 { top: 30px; right: 30px; text-align: right; }
    /* 图标 */
    .icon {
      font-size: 72px;
      margin-bottom: 20px;
      position: relative;
      z-index: 2;
      filter: drop-shadow(0 8px 24px rgba(0,0,0,0.3));
    }
    /* 标题 */
    .title {
      font-size: 42px;
      font-weight: 700;
      color: #fff;
      position: relative;
      z-index: 2;
      text-shadow: 0 4px 20px rgba(0,0,0,0.3);
      line-height: 1.2;
      max-width: 750px;
      padding: 0 40px;
    }
    /* 副标题 */
    .subtitle {
      font-size: 17px;
      color: rgba(255,255,255,0.8);
      margin-top: 14px;
      position: relative;
      z-index: 2;
      font-weight: 400;
    }
    /* 品牌 */
    .brand {
      position: absolute;
      bottom: 20px;
      right: 28px;
      color: rgba(255,255,255,0.5);
      font-size: 13px;
      font-weight: 500;
      z-index: 2;
    }
    .tip {
      position: fixed;
      bottom: 20px;
      left: 50%;
      transform: translateX(-50%);
      background: #333;
      color: #fff;
      padding: 12px 24px;
      border-radius: 8px;
      font-size: 14px;
    }
  </style>
</head>
<body>
  <div class="cover">
    <!-- 圆形装饰 -->
    <div class="circle circle-1"></div>
    <div class="circle circle-2"></div>
    <div class="circle circle-3"></div>
    <div class="circle circle-4"></div>
    <!-- 光点 -->
    <div class="dot dot-1"></div>
    <div class="dot dot-2"></div>
    <div class="dot dot-3"></div>
    <div class="dot dot-4"></div>
    <div class="dot dot-5"></div>
    <div class="dot dot-6"></div>
    <div class="dot dot-7"></div>
    <!-- 线条 -->
    <div class="line line-1"></div>
    <div class="line line-2"></div>
    <div class="line line-3"></div>
    <!-- 方块 -->
    <div class="square square-1"></div>
    <div class="square square-2"></div>
    <div class="square square-3"></div>
    <!-- 代码装饰 -->
    <div class="code-decoration code-1"># CLAUDE.md</div>
    <div class="code-decoration code-2">workflow: research → plan → implement</div>
    <div class="code-decoration code-3">quality_gates: enabled</div>
    <!-- 主内容 -->
    <div class="icon">${theme.icon}</div>
    <h1 class="title">${title}</h1>
    <p class="subtitle">${subtitle}</p>
    <div class="brand">⚡ Claude Code Academy</div>
  </div>
  <div class="tip">💡 右键 → 检查 → 右键 .cover → Capture node screenshot</div>
</body>
</html>`;
  }

  /**
   * 根据文章标题获取封面主题
   */
  getCoverTheme(title) {
    const themes = {
      '为什么': {
        gradient: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        icon: '📋',
        badge: 'Claude Code 配置指南',
        badgeBg: 'rgba(102, 126, 234, 0.2)',
        badgeColor: '#a5b4fc'
      },
      '工作流': {
        gradient: 'linear-gradient(135deg, #059669 0%, #34d399 100%)',
        icon: '🔄',
        badge: '效率提升',
        badgeBg: 'rgba(52, 211, 153, 0.2)',
        badgeColor: '#6ee7b7'
      },
      '质量': {
        gradient: 'linear-gradient(135deg, #dc2626 0%, #f97316 100%)',
        icon: '🛡️',
        badge: '代码质量',
        badgeBg: 'rgba(239, 68, 68, 0.2)',
        badgeColor: '#fca5a5'
      },
      '编码': {
        gradient: 'linear-gradient(135deg, #0ea5e9 0%, #22d3ee 100%)',
        icon: '💻',
        badge: '编码规范',
        badgeBg: 'rgba(14, 165, 233, 0.2)',
        badgeColor: '#7dd3fc'
      },
      '安全': {
        gradient: 'linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%)',
        icon: '🔒',
        badge: '安全最佳实践',
        badgeBg: 'rgba(245, 158, 11, 0.2)',
        badgeColor: '#fcd34d'
      },
      'default': {
        gradient: 'linear-gradient(135deg, #8b5cf6 0%, #d946ef 100%)',
        icon: '⚡',
        badge: 'Claude Code',
        badgeBg: 'rgba(139, 92, 246, 0.2)',
        badgeColor: '#c4b5fd'
      }
    };

    for (const [keyword, theme] of Object.entries(themes)) {
      if (keyword !== 'default' && title.includes(keyword)) {
        return theme;
      }
    }
    return themes.default;
  }

  /**
   * 移除 frontmatter
   */
  removeFrontmatter(content) {
    const frontmatterRegex = /^---\n[\s\S]*?\n---\n/;
    return content.replace(frontmatterRegex, '');
  }

  /**
   * 移除 import 语句
   */
  removeImports(content) {
    return content.replace(/^import\s+.*$/gm, '');
  }

  /**
   * 移除 JSX 注释
   */
  removeJsxComments(content) {
    return content.replace(/\{\/\*[\s\S]*?\*\/\}/g, '');
  }

  /**
   * 转换 Callout 组件为 Markdown 引用块
   */
  convertCallouts(content) {
    // 匹配 <Callout type="xxx">...</Callout>
    const calloutRegex = /<Callout\s+type=["'](\w+)["']>\s*([\s\S]*?)\s*<\/Callout>/g;

    return content.replace(calloutRegex, (match, type, innerContent) => {
      const emoji = CONFIG.calloutEmoji[type] || CONFIG.calloutEmoji.default;
      const title = CONFIG.calloutTitle[type] || CONFIG.calloutTitle.default;

      // 处理内部内容的换行
      const lines = innerContent.trim().split('\n');
      const quotedContent = lines.map(line => `> ${line}`).join('\n');

      return `> ${emoji} **${title}**\n>\n${quotedContent}`;
    });
  }

  /**
   * 转换 Steps 组件为有序列表
   */
  convertSteps(content) {
    // 移除 <Steps> 和 </Steps> 标签
    content = content.replace(/<Steps>\s*/g, '');
    content = content.replace(/\s*<\/Steps>/g, '');

    // 将 ### 步骤标题转换为有序列表格式
    // 但保持原有的 ### 格式，因为 Steps 内部通常已经是 ### 标题

    return content;
  }

  /**
   * 转换内联样式的 div 为纯文本/表格
   */
  convertStyledDivs(content) {
    // 处理对比图（有无 CLAUDE.md 的差异）
    content = this.convertComparisonDiv(content);

    // 处理流程图（三阶段工作流）
    content = this.convertWorkflowDiv(content);

    // 处理模块架构图
    content = this.convertArchitectureDiv(content);

    // 处理配置文件层次图
    content = this.convertConfigHierarchyDiv(content);

    // 移除剩余的简单 div 包装
    content = this.removeSimpleDivWrappers(content);

    return content;
  }

  /**
   * 转换对比图 div
   */
  convertComparisonDiv(content) {
    // 匹配整个对比图的 div 结构（包含 grid 布局的整个块）
    // 从 display: 'grid' 开始匹配到包含"一次到位"的最后一个 </div>
    const comparisonRegex = /<div style=\{\{\s*display:\s*['"]grid['"],\s*gridTemplateColumns[\s\S]*?一次到位[\s\S]*?<\/p>\s*<\/div>\s*<\/div>\s*<\/div>/g;

    return content.replace(comparisonRegex, () => {
      return `
| 没有 CLAUDE.md | 有 CLAUDE.md |
|:--------------|:-------------|
| 用户: "写一个登录函数" | 用户: "写一个登录函数" |
| ↓ Claude: 直接开始写代码 | ↓ Claude: 先研究现有代码 |
| ↓ 输出: camelCase 命名、无错误处理 | ↓ Claude: 制定实现计划 |
| ↓ 用户: "改成 snake_case" | ↓ Claude: 获得确认后编码 |
| ↓ 用户: "加上错误处理" | ↓ 输出: 符合规范、完整错误处理 |
| ↓ 用户: "不要用 any" | |
| **反复修改 3-5 次** | **一次到位** |
`;
    });
  }

  /**
   * 转换工作流 div
   */
  convertWorkflowDiv(content) {
    // 匹配整个三阶段工作流（从外层 margin div 到包含"等待用户确认再编码"的 div）
    const workflowRegex = /<div style=\{\{[^}]*margin:\s*['"]24px 0['"][^}]*padding[\s\S]*?1\.\s*研究阶段[\s\S]*?等待用户确认再编码[\s\S]*?<\/div>\s*<\/div>/g;

    return content.replace(workflowRegex, () => {
      return `
**三阶段工作流程**

\`\`\`
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  1. 研究阶段    │ →  │  2. 计划阶段    │ →  │  3. 实现阶段    │
│  (RESEARCH)     │    │  (PLAN)         │    │  (IMPLEMENT)    │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • 检查现有代码  │    │ • 列出文件清单  │    │ • 遵循代码风格  │
│ • Glob/Grep搜索 │    │ • 说明方案      │    │ • 完整错误处理  │
│ • 理解架构      │    │ • 识别风险      │    │ • 同步写测试    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              ↓
                    ⚠️ 等待用户确认再编码
\`\`\`
`;
    });
  }

  /**
   * 转换架构图 div
   */
  convertArchitectureDiv(content) {
    // 匹配整个模块架构图（从外层 margin div 到包含"沟通风格"的最后一个 div）
    const archRegex = /<div style=\{\{[^}]*margin:\s*['"]24px 0['"][^}]*\}\}>\s*<div style=\{\{[^}]*marginBottom[\s\S]*?沟通风格[\s\S]*?<\/div>\s*<\/div>\s*<\/div>\s*<\/div>\s*<\/div>/g;

    return content.replace(archRegex, () => {
      return `
**CLAUDE.md 模块架构（按重要性排序）**

| 优先级 | 模块 | 说明 |
|:------|:-----|:-----|
| 🔴 高 | 核心工作流程 | 研究→计划→实现 |
| 🔴 高 | 质量红线 | 禁止清单+检查清单 |
| 🔴 高 | 编码标准 | 命名+函数规范 |
| 🔴 高 | 安全标准 | 输入验证+数据安全 |
| 🟡 中 | 技术栈适配 | 框架+依赖管理 |
| 🟡 中 | 测试规范 | 覆盖率+文件组织 |
| 🟡 中 | Git 规范 | 分支+提交格式 |
| 🔵 低 | 沟通风格 | 语言偏好+交互方式 |
`;
    });
  }

  /**
   * 转换配置层次图 div
   */
  convertConfigHierarchyDiv(content) {
    // 匹配配置文件层次结构图
    const hierarchyRegex = /<div style=\{\{[^}]*margin:[^}]*\}\}>\s*<div style=\{\{[^}]*display:\s*['"]flex['"][^}]*flexDirection:\s*['"]column['"][\s\S]*?项目级配置[\s\S]*?全局配置[\s\S]*?<\/div>\s*<\/div>/g;

    return content.replace(hierarchyRegex, () => {
      return `
**配置文件优先级**

\`\`\`
┌────────────────────────────────────────────┐
│  项目级配置（优先级最高）                  │
│  位置：项目根目录/CLAUDE.md                │
│  作用：当前项目特定规范                    │
└────────────────────────────────────────────┘
                     ↓ 覆盖
┌────────────────────────────────────────────┐
│  全局配置（优先级较低）                    │
│  位置：~/.claude/CLAUDE.md                 │
│  作用：所有项目通用偏好                    │
└────────────────────────────────────────────┘
\`\`\`
`;
    });
  }

  /**
   * 移除简单的 div 包装和残留 JSX
   */
  removeSimpleDivWrappers(content) {
    // 移除图片 div 包装，保留图片
    content = content.replace(/<div[^>]*>\s*(<img[^>]*>)\s*<p[^>]*>([^<]*)<\/p>\s*<\/div>/g, (match, img, caption) => {
      const srcMatch = img.match(/src=["']([^"']+)["']/);
      const altMatch = img.match(/alt=["']([^"']+)["']/);
      const src = srcMatch ? srcMatch[1] : '';
      const alt = altMatch ? altMatch[1] : caption;
      return `![${alt}](${CONFIG.baseUrl}${src})\n\n*${caption}*`;
    });

    // 移除所有带 style 属性的 div 开始标签
    content = content.replace(/<div\s+style=\{\{[^}]*\}\}>\s*/g, '');

    // 移除所有 </div> 闭合标签
    content = content.replace(/<\/div>/g, '');

    // 移除带样式的 h4 标签，保留内容
    content = content.replace(/<h4\s+style=\{\{[^}]*\}\}>([^<]*)<\/h4>/g, '**$1**\n');

    // 移除带样式的 p 标签，保留内容
    content = content.replace(/<p\s+style=\{\{[^}]*\}\}>([^<]*)<\/p>/g, '$1');
    content = content.replace(/<p>([^<]*)<\/p>/g, '$1');

    // 移除 <br/> 和 <br>
    content = content.replace(/<br\s*\/?>/g, '\n');

    return content;
  }

  /**
   * 转换图片路径为绝对路径
   */
  convertImagePaths(content) {
    // 转换 Markdown 图片语法
    content = content.replace(/!\[([^\]]*)\]\(\/([^)]+)\)/g, `![$1](${CONFIG.baseUrl}/$2)`);

    // 转换 img 标签
    content = content.replace(/<img\s+src=["']\/([^"']+)["']/g, `<img src="${CONFIG.baseUrl}/$1"`);

    return content;
  }

  /**
   * 清理多余空行和残留内容
   */
  cleanupWhitespace(content) {
    // 移除只包含空白字符的行（缩进的空行）
    content = content.replace(/^[ \t]+$/gm, '');

    // 移除连续的多个空行，保留最多两个
    content = content.replace(/\n{3,}/g, '\n\n');

    // 移除开头的空行
    content = content.replace(/^\n+/, '');

    // 确保文件以单个换行结尾
    content = content.replace(/\n*$/, '\n');

    return content;
  }

  /**
   * 将 Markdown 转换为微信公众号友好的 HTML
   */
  markdownToWechatHtml(markdown) {
    let html = markdown;

    // 1. 先用占位符保护代码块，避免被其他转换影响
    const codeBlocks = [];
    html = html.replace(/```(\w*)\n([\s\S]*?)```/g, (match, lang, code) => {
      const placeholder = `___CODE_BLOCK_${codeBlocks.length}___`;
      codeBlocks.push(`<pre style="background: #f8f8f8; padding: 15px; border-radius: 5px; overflow-x: auto; font-size: 13px; line-height: 1.5; white-space: pre; font-family: 'Courier New', Consolas, monospace;"><code>${this.escapeHtml(code.trim())}</code></pre>`);
      return placeholder;
    });

    // 2. 转换标题
    html = html.replace(/^### (.*$)/gm, '<h3 style="font-size: 18px; font-weight: bold; color: #3f3f3f; margin: 20px 0 10px;">$1</h3>');
    html = html.replace(/^## (.*$)/gm, '<h2 style="font-size: 20px; font-weight: bold; color: #2f2f2f; margin: 25px 0 15px; border-bottom: 1px solid #eee; padding-bottom: 8px;">$1</h2>');
    html = html.replace(/^# (.*$)/gm, '<h1 style="font-size: 24px; font-weight: bold; color: #1f1f1f; margin: 30px 0 20px; text-align: center;">$1</h1>');

    // 3. 转换粗体和斜体
    html = html.replace(/\*\*([^*]+)\*\*/g, '<strong style="color: #333;">$1</strong>');
    html = html.replace(/\*([^*]+)\*/g, '<em>$1</em>');

    // 4. 转换行内代码
    html = html.replace(/`([^`]+)`/g, '<code style="background: #f5f5f5; padding: 2px 6px; border-radius: 3px; font-family: Consolas, monospace; font-size: 14px; color: #e83e8c;">$1</code>');

    // 5. 转换引用块
    html = html.replace(/^>\s*(.*)$/gm, '<blockquote style="border-left: 4px solid #4caf50; padding: 10px 15px; margin: 15px 0; background: #f9f9f9; color: #666;">$1</blockquote>');
    html = html.replace(/<\/blockquote>\s*<blockquote[^>]*>/g, '<br>');

    // 6. 转换无序列表
    html = html.replace(/^- (.*)$/gm, '<li style="margin: 5px 0;">$1</li>');
    html = html.replace(/(<li[^>]*>.*<\/li>\n?)+/g, '<ul style="padding-left: 20px; margin: 10px 0;">$&</ul>');

    // 7. 转换表格
    html = this.convertMarkdownTable(html);

    // 8. 转换段落（排除已转换的标签和占位符）
    html = html.replace(/^(?!<[hupblo]|<\/|___CODE_BLOCK|$)(.+)$/gm, '<p style="margin: 10px 0; line-height: 1.8; color: #333;">$1</p>');

    // 9. 转换图片
    html = html.replace(/!\[([^\]]*)\]\(([^)]+)\)/g, '<img src="$2" alt="$1" style="max-width: 100%; display: block; margin: 15px auto;">');

    // 10. 转换链接
    html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" style="color: #576b95; text-decoration: none;">$1</a>');

    // 11. 转换分隔线
    html = html.replace(/^---$/gm, '<hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">');

    // 12. 最后把代码块占位符换回来
    codeBlocks.forEach((block, index) => {
      html = html.replace(`___CODE_BLOCK_${index}___`, block);
    });

    // 包装为完整 HTML
    return this.wrapWechatHtml(html);
  }

  /**
   * 转换 Markdown 表格为 HTML
   */
  convertMarkdownTable(html) {
    const tableRegex = /\|(.+)\|\n\|[-:\s|]+\|\n((?:\|.+\|\n?)+)/g;

    return html.replace(tableRegex, (match, headerRow, bodyRows) => {
      const headers = headerRow.split('|').filter(h => h.trim());
      const rows = bodyRows.trim().split('\n').map(row =>
        row.split('|').filter(c => c.trim())
      );

      let table = '<table style="width: 100%; border-collapse: collapse; margin: 15px 0; font-size: 14px;">';

      // Header
      table += '<thead><tr>';
      headers.forEach(h => {
        table += `<th style="background: #f5f5f5; padding: 10px; border: 1px solid #ddd; text-align: left; font-weight: bold;">${h.trim()}</th>`;
      });
      table += '</tr></thead>';

      // Body
      table += '<tbody>';
      rows.forEach(row => {
        table += '<tr>';
        row.forEach(cell => {
          table += `<td style="padding: 10px; border: 1px solid #ddd;">${cell.trim()}</td>`;
        });
        table += '</tr>';
      });
      table += '</tbody></table>';

      return table;
    });
  }

  /**
   * HTML 转义
   */
  escapeHtml(text) {
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  /**
   * 包装为完整的微信公众号 HTML
   */
  wrapWechatHtml(content) {
    return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>微信公众号文章</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      line-height: 1.8;
      color: #333;
      max-width: 677px;
      margin: 0 auto;
      padding: 20px;
    }
  </style>
</head>
<body>
  <section style="max-width: 677px; margin: 0 auto;">
    ${content}
  </section>
</body>
</html>`;
  }
}

// ============================================
// CLI 入口
// ============================================

function main() {
  const args = process.argv.slice(2);

  if (args.length === 0 || args.includes('--help') || args.includes('-h')) {
    console.log(`
MDX 多平台转换脚本

用法:
  node scripts/convert-mdx.js <input-file> [options]

选项:
  --output-dir <dir>   输出目录（默认: dist/articles）
  --format <format>    输出格式: all, markdown, wechat（默认: all）
  --help, -h           显示帮助信息

示例:
  node scripts/convert-mdx.js pages/practical-skills/config/why-claude-md-matters.mdx
  node scripts/convert-mdx.js pages/**/*.mdx --format markdown
`);
    process.exit(0);
  }

  const inputFile = args[0];
  const outputDirIndex = args.indexOf('--output-dir');
  const formatIndex = args.indexOf('--format');

  const outputDir = outputDirIndex !== -1 ? args[outputDirIndex + 1] : 'dist/articles';
  const format = formatIndex !== -1 ? args[formatIndex + 1] : 'all';

  // 检查输入文件是否存在
  if (!fs.existsSync(inputFile)) {
    console.error(`错误: 文件不存在 - ${inputFile}`);
    process.exit(1);
  }

  // 读取文件
  const content = fs.readFileSync(inputFile, 'utf-8');
  const filename = path.basename(inputFile, '.mdx');

  // 每篇文章创建独立文件夹
  const articleDir = path.join(outputDir, filename);
  if (!fs.existsSync(articleDir)) {
    fs.mkdirSync(articleDir, { recursive: true });
  }

  // 转换
  const converter = new MdxConverter(content, filename);

  console.log(`\n📄 正在转换: ${inputFile}\n`);
  console.log(`📁 输出目录: ${articleDir}/\n`);

  if (format === 'all' || format === 'markdown') {
    const markdown = converter.toMarkdown();

    // 知乎版本
    const zhihuPath = path.join(articleDir, 'zhihu.md');
    fs.writeFileSync(zhihuPath, markdown);
    console.log(`✅ 知乎版本: ${zhihuPath}`);

    // 掘金版本（同 Markdown）
    const juejinPath = path.join(articleDir, 'juejin.md');
    fs.writeFileSync(juejinPath, markdown);
    console.log(`✅ 掘金版本: ${juejinPath}`);
  }

  if (format === 'all' || format === 'wechat') {
    const wechatHtml = converter.toWechatHtml();
    const wechatPath = path.join(articleDir, 'wechat.html');
    fs.writeFileSync(wechatPath, wechatHtml);
    console.log(`✅ 微信公众号版本: ${wechatPath}`);

    // 生成文章简介
    const summary = converter.generateSummary();
    const summaryPath = path.join(articleDir, 'summary.txt');
    fs.writeFileSync(summaryPath, summary);
    console.log(`✅ 文章简介 (${summary.length}字): ${summaryPath}`);

    // 生成封面图 HTML
    const coverHtml = converter.generateCoverHtml();
    const coverPath = path.join(articleDir, 'cover.html');
    fs.writeFileSync(coverPath, coverHtml);
    console.log(`✅ 封面图模板: ${coverPath}`);
  }

  console.log(`\n🎉 转换完成！\n`);
  console.log(`📝 简介内容:\n${converter.generateSummary()}\n`);
}

main();
