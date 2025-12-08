// 检测页面大小，决定提取策略
// 使用方式：mcp__chrome-devtools__evaluate_script({ function: `...此文件内容...` })

() => ({
  totalHeight: document.documentElement.scrollHeight,
  textLength: document.body.innerText.length,
  sectionsCount: document.querySelectorAll('section, article, .content, main').length,
  imagesCount: document.querySelectorAll('img').length,
  // 建议策略
  strategy: document.body.innerText.length < 10000 ? 'direct' : 'chunked'
})
