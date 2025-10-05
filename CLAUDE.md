
# Claude Code Academy
Claude Code Academy 是一个开源协作的学习平台，致力于帮助中文开发者快速掌握 Claude Code 的核心功能，提升开发效率。

## 技术栈

1. 使用 Next.js (v14.2.0) 和 Nextra(v3.0.0) 构建静态文档站
2. Nextra 自带的 Component 有，除此之外没有其它的组件：
   - Callout. 使用方式 <Callout type="info">...</Callout>  type 可选 info | warning | danger | success
   - Cards. 使用方式 <Cards> <Cards.Card icon="🚀" title="快速上手" href="/getting-started/introduction" /> ... </Cards>
   - Tabs. 使用方式 <Tabs> <Tabs.Tab label="标签1">内容1</Tabs.Tab> ... </Tabs>
   - Image. 使用方式 <Image src="/path/to/image.jpg" alt="描述" />
   - Link. 使用方式 <Link href="/path/to/page">链接文本</Link>
   - Table. 使用方式 <Table> <thead>...</thead> <tbody>...</tbody> </Table>
   - Steps. 使用方式 <Steps> </Steps>
   使用这些组件时，需要从 'nextra/components' 导入。
3. 使用 `pnpm` 进行包管理和构建，不要使用 `npm` 或 `yarn`。