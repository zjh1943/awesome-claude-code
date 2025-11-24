## 核心工作流程

**重要：每个任务必须遵循此流程**

### 1. 研究阶段（RESEARCH）
- 检查现有代码库中的类似实现
- 使用 Glob/Grep 搜索相关代码
- 理解项目架构和依赖关系
- **不确定时：联网搜索最新文档和最佳实践**

### 2. 计划阶段（PLAN）
- 列出要修改/创建的文件清单
- 说明实现方案和关键步骤
- 识别潜在风险和边缘情况
- **重要：获得用户确认后再开始编码**

### 3. 实现阶段（IMPLEMENT）
- 遵循项目现有代码风格
- 完整的错误处理（绝不跳过）
- 编写时同步添加测试
- 运行 linter/formatter/type-checker

**复杂架构问题：先深度思考再提出方案**

---

## 质量红线（绝不违反）

### 提交前强制检查
- **必须通过** Linter（零警告零错误）
- **必须通过** 所有测试
- **必须完成** 代码格式化
- **必须通过** 类型检查（TypeScript/静态类型语言）

### 绝对禁止的行为
- ❌ **绝不** 提交未通过测试的代码
- ❌ **绝不** 使用 TODO/占位符/Mock 作为最终代码
- ❌ **绝不** 使用 emoji（无论是 UI 图标还是文档标题）
- ❌ **绝不** 跳过错误处理
- ❌ **绝不** 硬编码密钥/凭证
- ❌ **绝不** 使用 `any` 类型（TypeScript 必须用 `unknown`）
- ❌ **绝不** 说"这是简化版"、"生产环境需要..."

---

## 通用编码标准

### Clean Code 原则（强制遵循）

**有意义的命名:**
- ✅ `getUserById(id)` ❌ `getData(x)`
- ✅ `MAX_RETRY_COUNT = 3` ❌ `num = 3`
- **函数名应该是动词**，变量名应该是名词

**单一职责原则（SRP）:**
- 一个函数只做一件事
- 一个类只有一个修改理由
- **重要：函数超过 30 行需要拆分**

**DRY 原则（Don't Repeat Yourself）:**
- **绝不** 复制粘贴代码
- 重复 3 次以上必须提取为函数
- 相似逻辑必须抽象为通用函数

### 错误处理（强制）

**TypeScript/JavaScript:**
```typescript
// 必须使用 unknown，不能用 any
try {
  await operation();
} catch (error: unknown) {
  if (error instanceof Error) {
    logger.error('操作失败', { message: error.message });
  }
  throw error; // 重新抛出，不要吞掉错误
}
```

**空值处理（重要）：**
```typescript
// ✅ 正确：使用可选链和空值合并
const userName = user?.profile?.name ?? 'Guest';

// ✅ 正确：函数参数验证
function processUser(user: User | null) {
  if (!user) {
    throw new Error('User is required');
  }
  // 继续处理
}

// ❌ 错误：未检查空值
const name = user.profile.name; // 可能导致运行时错误
```

**边界条件检查：**
```typescript
// 必须检查边界条件
function getItem(arr: any[], index: number) {
  if (index < 0 || index >= arr.length) {
    throw new Error('Index out of bounds');
  }
  return arr[index];
}
```

**Python:**
```python
# 必须使用具体异常类型
try:
    process_data()
except ValueError as e:
    logger.error(f"数据验证失败: {e}")
    raise
except Exception as e:
    logger.exception("未预期的错误")
    raise
```

### 命名规范

遵循项目现有风格，常见约定：
- 文件: `kebab-case.ts`, `PascalCase.tsx`（组件）
- 变量/函数: `camelCase`
- 类/组件: `PascalCase`
- 常量: `SCREAMING_SNAKE_CASE`
- 数据库表: `snake_case`

**重要：优先遵循项目现有命名风格**

### Emoji 使用规范（重要）

**禁止在任何地方使用 emoji：**
- ❌ UI 界面中（图标、按钮）
- ❌ 代码注释中
- ❌ 文档标题中（包括 README、CLAUDE.md）
- ❌ Git commit 消息中
- ❌ 日志输出中

**原因：**
- 跨平台显示不一致
- 可访问性差
- 不够专业
- 难以搜索和维护

**图标正确做法（按优先级）：**
1. UI 框架自带图标（Material-UI、Ant Design、Chakra UI）
2. 专业图标库（Lucide、React Icons、Heroicons）
3. 自定义 SVG

**代码示例：**
```typescript
// ❌ 错误：UI 中使用 emoji
<button>💾 保存</button>

// ❌ 错误：注释中使用 emoji
// 🔥 重要：这个函数很关键

// ❌ 错误：日志中使用 emoji
logger.info('✅ 用户登录成功');

// ✅ 正确：使用图标库
import { Save } from 'lucide-react';
<button><Save size={20} />保存</button>

// ✅ 正确：纯文本注释
// 重要：这个函数很关键

// ✅ 正确：纯文本日志
logger.info('用户登录成功');
```

---

## 安全标准（强制）

### 输入验证
- **必须** 验证所有用户输入
- **必须** 使用验证库（Zod、Joi、Pydantic）
- **绝不** 信任客户端数据

### 数据库安全
- **必须** 使用参数化查询
- **必须** 防止 SQL 注入
- **推荐** 使用 ORM/查询构建器

### 认证授权
- 短期访问令牌（15分钟）+ 长期刷新令牌（7天）
- **绝不** 在代码中硬编码密钥
- **必须** 使用环境变量存储敏感信息

---

## 前端开发规范

### 组件设计原则
- **组件拆分粒度**：单个组件代码不超过 200 行
- **组件命名**：`PascalCase`，见名知意（如 `UserProfileCard`）
- **Props 设计**：必须定义类型（TypeScript/PropTypes）
- **状态管理**：遵循项目选择的方案，保持一致性

### React Hooks 规范（如使用 React）

**useState 规范：**
```typescript
// ✅ 正确：相关状态合并
const [user, setUser] = useState({ firstName: '', lastName: '' });

// ❌ 错误：分散的相关状态
const [firstName, setFirstName] = useState('');
const [lastName, setLastName] = useState('');
```

**useEffect 规范（重要）：**
```typescript
// ✅ 正确：总是声明依赖数组
useEffect(() => {
  fetchData(id);
}, [id]);

// ❌ 错误：缺少依赖会导致 bug
useEffect(() => {
  fetchData(id); // id 未声明在依赖中
}, []);
```

**性能优化：**
```typescript
// ✅ 使用 key 优化列表渲染
{items.map(item => <Item key={item.id} data={item} />)}

// ❌ 错误：使用索引作为 key
{items.map((item, index) => <Item key={index} />)}
```

### UI 组件库使用原则
- **遵循项目选择**：使用项目已选择的 UI 库
- **按需引入**：避免全量引入增大打包体积
- **保持一致性**：禁止在同一项目混用多个 UI 库
- **查阅文档**：不确定时联网搜索该 UI 库的最佳实践

### 样式规范
- **遵循项目规范**：使用项目已选择的样式方案
- **避免行内样式**：除非需要动态计算
- **避免全局样式污染**：使用模块化样式方案
- **保持一致性**：整个项目使用统一的样式方案

### 构建优化原则
- 启用代码分割和懒加载
- 启用压缩和 Tree Shaking
- 优化图片资源（压缩、懒加载、现代格式）
- **具体工具选择**：遵循项目配置

---

## 后端开发规范

### API 设计原则（重要）

**路由命名：**
- **必须使用名词**，不用动词：`/api/users` ✅ `/api/getUsers` ❌
- **复数形式**：`/users` 而不是 `/user`
- **RESTful 标准**：
  ```
  GET    /api/users          # 列表
  GET    /api/users/:id      # 详情
  POST   /api/users          # 创建
  PUT    /api/users/:id      # 完整更新
  PATCH  /api/users/:id      # 部分更新
  DELETE /api/users/:id      # 删除
  ```

**版本控制：**
- URL 版本：`/api/v1/users`（推荐）
- Header 版本：`Accept: application/vnd.api+json; version=1`

### OpenAPI 规范（强制）

**每个后端项目必须：**
1. **先设计 OpenAPI 规范**（openapi.yaml），后写代码
2. **生成类型定义**（TypeScript/Python）确保类型安全
3. **运行时验证**：请求/响应自动校验
4. **生成文档**：Swagger UI 或 ReDoc

**不确定 OpenAPI 实现细节时：联网搜索项目技术栈的最新文档**

### 响应格式标准
```json
// 成功
{"data": {...}, "meta": {"timestamp": "2025-11-20T10:00:00Z"}}

// 错误（必须包含 code 和 message）
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "验证失败",
    "details": [{"field": "email", "message": "邮箱格式错误"}]
  }
}
```

### HTTP 状态码（严格遵循）
- 200: 成功 | 201: 创建成功 | 204: 删除成功（无返回）
- 400: 请求错误 | 401: 未认证 | 403: 无权限 | 404: 不存在
- 422: 验证失败 | 429: 请求过多 | 500: 服务器错误

### 中间件规范
- **必须顺序**：日志 → CORS → 认证 → 权限 → 业务逻辑
- 错误处理中间件放最后
- 每个中间件单一职责

---

## 测试规范

### 测试覆盖率要求
- 业务逻辑: **80% 以上**
- 关键路径: **100%**
- API 端点: **必须有集成测试**
- **重要：所有测试必须通过才能提交代码**

### 测试文件管理（重要）

**测试文件位置：**
- 单元测试：与源文件同目录（`user.service.ts` → `user.service.test.ts`）
- 集成测试：`tests/integration/` 目录
- E2E 测试：`tests/e2e/` 目录

**测试文件命名：**
- `*.test.ts` 或 `*.spec.ts`（保持项目一致）
- 描述性命名：`user-authentication.test.ts`

**测试数据管理：**
- **测试完成后必须清理**：删除测试数据、关闭连接、清理临时文件
- 使用 `beforeEach/afterEach` 钩子自动清理
- **绝不** 在测试中修改生产数据
- 使用独立的测试数据库

**测试隔离原则：**
```typescript
describe('UserService', () => {
  let testUser;

  beforeEach(async () => {
    // 每个测试前创建干净的测试数据
    testUser = await createTestUser();
  });

  afterEach(async () => {
    // 每个测试后必须清理
    await deleteTestUser(testUser.id);
  });

  it('should update user profile', async () => {
    // 测试逻辑
  });
});
```

### 测试运行策略
- 开发时：运行单个测试（性能优先）
- 提交前：运行完整测试套件
- CI/CD：自动运行所有测试
- **重要：失败的测试必须立即修复**

---

## Git 规范

### 分支命名
- `feature/功能描述`
- `bugfix/问题描述`
- `hotfix/紧急修复`

### Commit 消息（Conventional Commits）
```
类型(范围): 简短描述

[可选的详细说明]
```

**类型:** feat, fix, docs, style, refactor, perf, test, chore

**示例:**
```
feat(认证): 添加 OAuth2 登录

实现 Google 和 GitHub OAuth2 登录流程

Closes #123
```

---

## 性能优化原则

### 数据库
- 避免 N+1 查询（使用 eager loading）
- 合理使用索引
- 适当缓存查询结果

### 前端
- 代码分割和懒加载
- 图片优化（WebP、压缩、CDN）
- 避免不必要的重渲染

### 后端
- 异步处理耗时操作
- 使用连接池
- Redis 缓存热点数据

**不确定优化方案时：联网搜索该技术栈的性能最佳实践**

---

## 文档标准

### 代码注释
```typescript
/**
 * 处理订单支付
 *
 * @param orderId - 订单 ID
 * @param method - 支付方式
 * @returns 支付确认信息
 * @throws {PaymentError} 支付失败时抛出
 */
```

### README 必须包含
- 项目简介
- 环境要求（Node.js 版本、Python 版本等）
- 安装步骤
- 开发/测试/构建命令
- 部署说明

---

## 项目适配

### 识别技术栈
每个新项目：
1. 检查 `package.json` / `requirements.txt` / `go.mod`
2. 理解使用的框架和工具
3. **遵循项目现有代码风格**（这点最重要）
4. 不确定时联网搜索该技术栈最佳实践

### 技术栈适配原则
**重要：不要假设技术栈，遵循项目实际使用的技术**

遇到任何技术时，联网查找最新文档和最佳实践：
- 前端框架（React、Vue、Angular、Svelte 等）
- 后端框架（Express、FastAPI、Django、Spring Boot 等）
- 数据库（PostgreSQL、MySQL、MongoDB、Redis 等）
- 移动端（React Native、Flutter、Kotlin、Swift 等）
- UI 库（根据项目选择）
- 状态管理（根据项目选择）
- 样式方案（根据项目选择）

---

## 部署检查清单

**部署前必须完成：**
- [ ] 所有测试通过
- [ ] Linter 零警告
- [ ] 类型检查通过
- [ ] 环境变量已配置
- [ ] 数据库迁移就绪
- [ ] 安全扫描通过

**环境变量管理：**
```bash
# .env.example（提交到 Git）
DATABASE_URL=postgresql://user:pass@host/db
JWT_SECRET=your-secret-here

# .env（添加到 .gitignore，绝不提交）
```

---

## 问题解决流程

### 遇到不确定的情况

**重要：按此顺序执行**

1. **停止** - 不要猜测或假设
2. **研究** - 检查现有代码库类似实现
3. **搜索** - 联网查找官方文档和最佳实践
4. **提问** - 向用户确认需求和方案
5. **计划** - 制定详细实施方案
6. **实现** - 执行并验证

### 应该联网搜索的场景
- 新技术/框架的最佳实践
- 特定库的最新 API 文档
- 错误消息的解决方案
- 性能优化技巧
- 安全漏洞修复方法
- 行业标准和规范

**示例：** "如何在 Next.js 15 中实现 Server Actions 的错误处理"

---

## 沟通规范

### 与用户沟通
- 使用清晰、专业的语言
- 避免过度解释和废话
- **提供代码示例优于理论描述**
- 需求不明确时主动提问
- **避免社交短语**（"您说得对"、"好问题"、"我觉得可能"）

### 进度汇报
- 简明说明当前步骤
- 遇到问题立即告知
- 提供预期完成时间（如适用）

---

## 禁止模式

### 禁止的表述
- "这是简化版..."
- "生产环境需要..."
- "TODO: 稍后实现"
- "我觉得可能..."
- "您说得对"

### 禁止的代码
- 超过 50 行的函数
- 嵌套超过 3 层的条件
- 魔法数字（必须使用常量）
- 注释掉的代码
- 重复代码（DRY 原则）

---

## 完成标准

**代码达到生产就绪：**
- ✅ Linter 零警告
- ✅ 所有测试通过
- ✅ 格式化完成
- ✅ 类型检查通过
- ✅ 功能端到端验证
- ✅ 文档已更新
- ✅ 无 TODO 注释
- ✅ Code Review 通过

---

## 快速参考

### 常用命令
```bash
# 开发
npm run dev / pnpm dev / yarn dev
python manage.py runserver / uvicorn main:app --reload

# 测试
npm test / pytest / go test
npm run test:watch

# 构建
npm run build / pnpm build
python -m build / go build

# 质量检查
npm run lint / black . / gofmt -w .
npm run format / prettier --write .
npm run type-check / mypy .

# Git
git status
git add .
git commit -m "feat: 功能描述"
git push -u origin branch-name
```

### 关键原则
1. **先研究、后计划、再实现**
2. **不确定时联网搜索**
3. **严格遵循项目现有风格**
4. **测试必须100%通过**
5. **绝不提交失败的代码**

---

## 持续改进

### 项目开始时
- 阅读项目 README 和现有文档
- 了解技术栈和工具链
- 理解现有代码结构和风格
- 搜索该技术栈的最佳实践

### 项目进行中
- 保持代码风格一致性
- 及时更新文档
- 重构混乱代码
- 添加必要的测试

### 项目交付前
- 完整的用户文档
- 清理无用代码和注释
- 确保所有测试通过
- 准备部署和维护文档

---

## 特别提醒

### 中国开发者注意事项
1. **国内网络环境**：提供国内镜像源配置
   ```bash
   # npm 使用淘宝镜像
   npm config set registry https://registry.npmmirror.com

   # pip 使用清华镜像
   pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
   ```

2. **时区处理**：明确时区为 Asia/Shanghai（UTC+8）
3. **语言支持**：确保正确处理中文字符（UTF-8 编码）
4. **合规要求**：遵守《数据安全法》和《个人信息保护法》
5. **支付集成**：优先支持微信支付、支付宝

### TypeScript 严格模式（强制）

**tsconfig.json 必须启用：**
```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true
  }
}
```

### 无障碍性（A11y）标准

**必须遵循：**
- 所有图片必须有 `alt` 属性
- 交互元素必须可键盘访问
- 使用语义化 HTML 标签
- 表单必须有 label 关联
- 颜色对比度符合 WCAG 2.1 AA 标准

```typescript
// ✅ 正确
<button onClick={handleClick} aria-label="关闭对话框">
  <CloseIcon aria-hidden="true" />
</button>

// ❌ 错误：缺少无障碍标签
<div onClick={handleClick}><CloseIcon /></div>
```

### 日志记录规范

**日志级别：**
- **ERROR**: 错误，需要立即处理
- **WARN**: 警告，可能导致问题
- **INFO**: 重要业务流程
- **DEBUG**: 调试信息（生产环境禁用）

```typescript
// ✅ 正确：包含上下文信息
logger.error('支付失败', {
  orderId: order.id,
  userId: user.id,
  error: error.message
});

// ❌ 错误：缺少上下文
logger.error('支付失败');
```
