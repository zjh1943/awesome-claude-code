// 按滚动位置提取（适合懒加载页面）
// 参数：scrollY (滚动位置)
// 使用方式：args: [{ value: 0 }], 然后 [{ value: 1000 }], ...

(scrollY) => {
  window.scrollTo(0, scrollY);

  // 等待懒加载内容
  return new Promise(resolve => {
    setTimeout(() => {
      resolve({
        scrollPosition: window.scrollY,
        maxScroll: document.documentElement.scrollHeight - window.innerHeight,
        viewportContent: document.body.innerText.substring(0, 5000),
        hasMore: window.scrollY < document.documentElement.scrollHeight - window.innerHeight
      });
    }, 500);
  });
}
