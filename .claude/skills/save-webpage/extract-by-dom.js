// 按 DOM 元素分页提取
// 参数：pageIdx (页码，从0开始), pageSize (每页元素数)
// 使用方式：args: [{ value: 0 }, { value: 30 }]

(pageIdx, pageSize) => {
  const elements = Array.from(document.querySelectorAll('p, h1, h2, h3, h4, h5, h6, li, blockquote, pre, code'));
  const start = pageIdx * pageSize;
  const slice = elements.slice(start, start + pageSize);

  return {
    elements: slice.map(el => ({
      tag: el.tagName.toLowerCase(),
      text: el.innerText
    })),
    hasMore: start + pageSize < elements.length,
    totalElements: elements.length,
    currentPage: pageIdx
  };
}
