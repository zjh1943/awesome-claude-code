export default {
  logo:
    <div style={{ display: 'flex', flexDirection: 'row', alignItems: 'center', height: '100%' }}>
      <img src="/cc-club.svg" alt="Logo" style={{ width: '40px', height: '40px', backgroundColor: '#030219', borderRadius: '4px' }} />
      <span style={{ marginLeft: 8, fontWeight: 'bold', fontSize: '24px' }}>CC Academy</span>
      {/* <a href="https://claude-code.club" target="_blank" rel="noopener noreferrer" style={{ marginLeft: 8, fontSize: '14px', color: '#888' }}>by CC Club</a> */}
    </div>,
  // logoLink: '/',
  project: {
    link: 'https://github.com/zjh1943/claude-code-academy'
  },
  docsRepositoryBase: 'https://github.com/zjh1943/claude-code-academy/tree/main',
  useNextSeoProps() {
    return {
      titleTemplate: '%s – Claude Code Academy - by CC Club'
    }
  },
  head: (
    <>
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <meta property="og:title" content="Claude Code Academy - by CC Club" />
      <meta property="og:description" content="为 Claude Code 开发者提供的中文学习资源库" />
      <link rel="icon" type="image/svg+xml" href="/cc-club.svg" />
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
