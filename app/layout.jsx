import { Layout, Footer, Navbar } from 'nextra-theme-docs'
import { Banner, Head } from 'nextra/components'
import { Analytics } from '@vercel/analytics/react'
import 'nextra-theme-docs/style.css'
import '../styles/global.css'

export const metadata = {
  title: {
    template: '%s – Claude Code Academy - by CC Club',
    default: 'Claude Code Academy - by CC Club'
  },
  description: '为 Claude Code 开发者提供的中文学习资源库',
  openGraph: {
    title: 'Claude Code Academy - by CC Club',
    description: '为 Claude Code 开发者提供的中文学习资源库',
  },
  icons: {
    icon: '/cc-club.svg'
  }
}

export const viewport = {
  width: 'device-width',
  initialScale: 1
}

const banner = (
  <a href="https://github.com/zjh1943/awesome-claude-code" target="_blank">
    🎉 欢迎来到 Claude Code Academy！这是一个开源协作项目，欢迎贡献 →
  </a>
)

const footer = (
  <Footer>
    MIT {new Date().getFullYear()} © <a href="https://github.com/zjh1943/awesome-claude-code" target="_blank">Claude Code Academy</a>
    {' · '}
    Built with ❤️ by the community
  </Footer>
)

export default async function RootLayout({ children }) {
  const { getPageMap } = await import('nextra/page-map')

  return (
    <html lang="zh-CN" suppressHydrationWarning>
      <Head />
      <body>
        <Layout
          banner={<Banner>{banner}</Banner>}
          navbar={
            <Navbar
              logo={
                <div style={{ display: 'flex', flexDirection: 'row', alignItems: 'center', height: '100%' }}>
                  <img src="/cc-club.svg" alt="Logo" style={{ width: '40px', height: '40px', backgroundColor: '#030219', borderRadius: '4px' }} />
                  <span style={{ marginLeft: 8, fontWeight: 'bold', fontSize: '24px' }}>CC Academy</span>
                </div>
              }
              project={{ link: 'https://github.com/zjh1943/awesome-claude-code' }}
            />
          }
          sidebar={{ defaultOpen: true, defaultMenuCollapseLevel: 1, toggleButton: true }}
          footer={footer}
          pageMap={await getPageMap()}
          docsRepositoryBase="https://github.com/zjh1943/awesome-claude-code/tree/main"
          feedback={{
            content: '有问题？给我们反馈 →'
          }}
          toc={{
            title: '本页目录'
          }}
        >
          {children}
        </Layout>
        <Analytics />
      </body>
    </html>
  )
}