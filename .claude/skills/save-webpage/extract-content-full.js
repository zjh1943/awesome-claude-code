// 提取完整内容（用于保存到临时文件）
// 返回 JSON 字符串，可写入 /tmp/page-content.json 后分段读取

() => {
  const content = {
    title: document.title,
    url: window.location.href,
    content: document.body.innerText,
    html: document.body.innerHTML
  };
  return JSON.stringify(content, null, 2);
}
