// 提取结构化内容（保留 HTML 标签层级）
// 适合需要保留格式的场景

() => {
  const extractNode = (node, depth = 0) => {
    if (node.nodeType === Node.TEXT_NODE) {
      const text = node.textContent.trim();
      return text ? { type: 'text', content: text } : null;
    }

    if (node.nodeType !== Node.ELEMENT_NODE) return null;

    const tag = node.tagName.toLowerCase();
    const skipTags = ['script', 'style', 'noscript', 'svg', 'path'];
    if (skipTags.includes(tag)) return null;

    const children = Array.from(node.childNodes)
      .map(child => extractNode(child, depth + 1))
      .filter(Boolean);

    if (children.length === 0 && !node.textContent.trim()) return null;

    return {
      type: 'element',
      tag,
      children: children.length === 1 && children[0].type === 'text'
        ? children[0].content
        : children
    };
  };

  const main = document.querySelector('main, article, .content, #content, .post') || document.body;

  return {
    title: document.title,
    url: window.location.href,
    structure: extractNode(main)
  };
}
