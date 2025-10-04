export default {
  logo: 
    <>
      <img src="/cc-club.svg" alt="Logo" style={{ height: '40px' }} />
      <span style={{ marginLeft: '0.5rem', fontWeight: 700 }}>Claude Code Academy</span>
    </>,
  project: {
    link: 'https://github.com/zjh1943/claude-code-academy'
  },
  docsRepositoryBase: 'https://github.com/zjh1943/claude-code-academy/tree/main',
  useNextSeoProps() {
    return {
      titleTemplate: '%s – Claude Code Academy'
    }
  },
  head: (
    <>
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <meta property="og:title" content="Claude Code Academy" />
      <meta property="og:description" content="为 Claude Code 开发者提供的中文学习资源库" />
    </>
  ),
  primaryHue: 220,
  primarySaturation: 90,
  banner: {
    key: 'beta-release',
    text: (
      <a href="https://github.com/zjh1943/claude-code-academy" target="_blank">
        🎉 欢迎来到 Claude Code Academy！这是一个开源协作项目，欢迎贡献 →
      </a>
    )
  },
  sidebar: {
    titleComponent({ title, type }) {
      if (type === 'separator') {
        return <span className="cursor-default">{title}</span>
      }
      return <>{title}</>
    },
    defaultMenuCollapseLevel: 1,
    toggleButton: true
  },
  footer: {
    text: (
      <>
        MIT {new Date().getFullYear()} © <a href="https://github.com/zjh1943/claude-code-academy" target="_blank">Claude Code Academy</a>
        {' · '}
        Built with ❤️ by the community
      </>
    )
  },
  editLink: {
    text: '在 GitHub 上编辑此页 →'
  },
  feedback: {
    content: '有问题？给我们反馈 →',
    labels: 'feedback'
  },
  toc: {
    title: '本页目录',
    backToTop: true
  },
  navigation: {
    prev: true,
    next: true
  },
  darkMode: true,
  search: {
    placeholder: '搜索文档...'
  },
  gitTimestamp: ({ timestamp }) => (
    <>最后更新于 {timestamp.toLocaleDateString('zh-CN')}</>
  )
}
