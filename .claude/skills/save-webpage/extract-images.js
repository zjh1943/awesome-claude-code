// 提取页面中所有图片信息

() => Array.from(document.querySelectorAll('img')).map((img, index) => ({
  index,
  src: img.src,
  alt: img.alt || '',
  width: img.naturalWidth,
  height: img.naturalHeight,
  // 从 URL 中提取文件名
  filename: img.src.split('/').pop().split('?')[0] || `image-${index}.jpg`
}))
