// 按字符位置分段提取内容
// 参数：start (起始位置), length (提取长度)
// 使用方式：args: [{ value: 0 }, { value: 3000 }]

(start, length) => {
  const text = document.body.innerText;
  return {
    chunk: text.substring(start, start + length),
    hasMore: start + length < text.length,
    totalLength: text.length
  };
}
