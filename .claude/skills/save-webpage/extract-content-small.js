// 小页面直接提取全部内容
// 适用于 textLength < 10000 的页面

() => ({
  title: document.title,
  url: window.location.href,
  content: document.body.innerText,
  images: Array.from(document.querySelectorAll('img')).map(img => ({
    src: img.src,
    alt: img.alt || ''
  }))
})
