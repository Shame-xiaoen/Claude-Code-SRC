# Claude Code SRC

  ## 🏗 架构摘要

  ### 1. 工具系统

  > **路径说明**：工具接口与注册表在 `src/`，工具实现在 `packages/builtin-tools/`。

  | 文件/目录 | 作用 |
  |----------|------|
  | `src/Tool.ts` | `Tool` 接口定义 + `findToolByName` / `toolMatchesName` 辅助函数 |
  | `src/tools.ts` | 工具注册表，从 `@claude-code-best/builtin-tools` 拼装最终 tool list，按 feature flag / `USER_TYPE`
  条件加载 |
  | `src/constants/tools.ts` | `CORE_TOOLS` 白名单常量（38 个核心工具名），用于 `isDeferredTool` 白名单判定 |
  | `packages/builtin-tools/src/tools/` | **63 个工具实现目录**，导出 `@claude-code-best/builtin-tools` 包 |
  | `src/services/searchExtraTools/` | TF-IDF 工具索引（`toolIndex.ts`），延迟工具按需加载与语义搜索 |

  **主要工具分类**：

  - **文件操作**：`FileEditTool`、`FileReadTool`、`FileWriteTool`、`GlobTool`、`GrepTool`、`NotebookEditTool`
  - **Shell / 执行**：`BashTool`、`PowerShellTool`、`ExecuteTool`、`REPLTool`
  - **Agent 系统**：`AgentTool`、`TaskCreateTool`、`TaskUpdateTool`、`TaskListTool`、`TaskGetTool`
  - **规划**：`EnterPlanModeTool`、`ExitPlanModeTool`、`VerifyPlanExecutionTool`
  - **Web /
  MCP**：`WebFetchTool`、`WebSearchTool`、`MCPTool`、`McpAuthTool`、`ListMcpResourcesTool`、`ReadMcpResourceTool`
  - **调度**：`CronCreateTool`、`CronDeleteTool`、`CronListTool`、`MonitorTool`
  - **工具发现**：`SearchExtraToolsTool`、`ExecuteExtraTool`、`DiscoverSkillsTool`、`SyntheticOutput`
  - **其他**：`LSPTool`、`ConfigTool`、`SkillTool`、`EnterWorktreeTool`、`ExitWorktreeTool`、`AskUserQuestionTool`、`Pus
  hNotificationTool`

  ---

  ### 2. 指挥系统 (`src/commands/`)

  用户在 REPL 中用 `/` 前缀调用的 slash command（例如 `/login`、`/poor`、`/teach-me`）。

  - **120+ 个子目录**：每个 slash command 一个目录，目录内含命令实现（`.ts`/`.tsx`）。
  - **顶层 `.ts`/`.tsx`**：跨命令复用的实现，如 `commit.ts`、`commit-push-pr.ts`、`review.ts`、`security-review.ts`、`in
  it.ts`、`monitor.ts`、`statusline.tsx`、`ultraplan.tsx`、`autonomy.ts`。
  - **`_shared/`**：命令间共享工具函数。
  - **`createMovedToPluginCommand.ts`**：将旧命令重定向到插件实现的兼容层。

  **常用命令**：`/login`、`/logout`、`/help`、`/clear`、`/config`、`/model`、`/poor`、`/fast`、`/cost`、`/compact`、`/hi
  story`、`/resume`、`/teach-me`、`/agents`、`/mcp`、`/plugin`、`/skill-search`、`/skill-store`、`/permissions`、`/hooks
  `、`/output-style`、`/theme`、`/keybindings`、`/doctor`、`/upgrade`、`/feedback`、`/review`、`/security-review`、`/sha
  re`、`/recap`、`/stats`、`/vim`、`/voice`、`/ide`、`/chrome` 等。

  > 命令通过 `src/main.tsx` 注册到 Commander.js，REPL 中由输入解析器拦截 `/` 前缀分发到对应处理器。

  ---

  ### 3. 服务层 (`src/services/`)

  跨模块复用的后台服务，**不直接暴露给用户**，由 REPL、tools、commands 调用。

  | 子目录 | 作用 |
  |--------|------|
  | `api/` | 核心 API 客户端 + **7 个 provider 兼容层**（详见下表） |
  | `acp/` | ACP (Agent Client Protocol) agent 实现：`agent.ts`、`bridge.ts`、`permissions.ts`、`entry.ts` |
  | `acp/` | ACP (Agent Client Protocol) agent 实现：`agent.ts`、`bridge.ts`、`permissions.ts`、`entry.ts` |
  | `auth/` | Anthropic OAuth 登录、API key 管理 |
  | `oauth/` | 通用 OAuth flow（用于 MCP server、外部集成） |
  | `mcp/` | MCP server 客户端连接、资源/工具发现 |
  | `plugins/` | 插件加载与生命周期管理 |
  | `lsp/` | LSP 服务器管理（Language Server Protocol） |
  | `searchExtraTools/` | TF-IDF 工具索引，支持延迟工具语义搜索 |
  | `skillSearch/` | Skill 语义搜索与预取 |
  | `skillLearning/` | 学习记录持久化 |
  | `compact/` / `contextCollapse/` | 对话压缩 |
  | `extractMemories/` | 自动抽取并存储用户记忆 |
  | `SessionMemory/` | 会话级记忆 |
  | `MagicDocs/` | 自动更新 CLAUDE.md / 项目文档 |
  | `sessionTranscript/` | 会话转录持久化 |
  | `analytics/` | 统计上报（已 stub） |
  | `langfuse/` | Langfuse 集成 |
  | `policyLimits/` / `providerRegistry/` / `providerUsage/` | 配额、限流、provider 选路 |
  | `AgentSummary/` / `PromptSuggestion/` / `toolUseSummary/` | LLM 辅助子任务（依赖 API） |
  | `autoDream/` / `awaySummary.ts` | 会话间总结 / 自动构思 |
  | `localVault/` | 本地凭据保险箱 |
  | `remoteManagedSettings/` / `settingsSync/` / `teamMemorySync/` | 设置/记忆远程同步 |
  | `tools/` | 服务层调用工具的辅助层 |
  | `voice.ts` / `voiceStreamSTT.ts` / `doubaoSTT.ts` | 语音输入实现 |

  #### `api/` 下的 Provider 兼容层

  **设计模式**：流适配器（Stream Adapter）——把不同厂商协议的请求/响应转成 Anthropic Messages 内部格式，下游 `query.ts`
  与工具系统完全无感知。

  **选路逻辑**（`src/utils/model/providers.ts`）：`modelType` 参数 → 环境变量 → 默认 `firstParty`

  | Provider | 启用方式 | 实现位置 | 作用 |
  | --- | --- | --- | --- |
  | `firstParty` | 默认 | `claude.ts` / `client.ts` | Anthropic 官方直连，原生 Messages 协议，无需转换 |
  | `bedrock` | `CLAUDE_CODE_USE_BEDROCK=1` | `bedrockClient.ts` | AWS Bedrock Runtime，适配 IAM 签名、region、ARN model id |
  | `vertex` | `CLAUDE_CODE_USE_VERTEX=1` | `client.ts`（vertex 分支） | Google Vertex AI，适配 GCP 认证（service account / ADC）、project id、location |
  | `foundry` | `CLAUDE_CODE_USE_FOUNDRY=1` | `client.ts`（foundry 分支） | Azure AI Foundry，适配 Azure 认证与 endpoint URL |
  | `openai` | `CLAUDE_CODE_USE_OPENAI=1` | `openai/` | Anthropic Messages ↔ OpenAI Chat Completions 协议双向转换；支持
  | `openai` | `CLAUDE_CODE_USE_OPENAI=1` | `openai/` | Anthropic Messages ↔ OpenAI Chat Completions 协议双向转换。支持Ollama、DeepSeek、vLLM 等任意 OpenAI 兼容端点（含 DeepSeek thinking mode） |
  | `gemini` | `CLAUDE_CODE_USE_GEMINI=1` | `gemini/` | Anthropic Messages ↔ Google `generateContent` 流式 API 双向转换；适配 tools/system/role 命名差异 |
  | `grok` | `CLAUDE_CODE_USE_GROK=1` | `grok/` | xAI Grok API 适配，自定义模型映射 |

  **关键环境变量**：

  - **OpenAI**：`OPENAI_API_KEY` / `OPENAI_BASE_URL` / `OPENAI_MODEL`
  - **Gemini**：`GEMINI_API_KEY`（必填）/ `GEMINI_MODEL` / `GEMINI_DEFAULT_SONNET_MODEL` / `GEMINI_DEFAULT_OPUS_MODEL`

  > 在 REPL 中输入 `/login` 可图形化配置，无需手动设置环境变量
  ---

  ### 4. 桥接系统 (`src/bridge/`)

  Remote Control / Bridge 模式实现（feature-gated by `BRIDGE_MODE`），让 Claude Code 能被远程客户端（Web UI / 手机 App /
   acp-link 等）控制。

  | 文件 | 作用 |
  |------|------|
  | `bridgeMain.ts` | Bridge 模式入口（CLI 子命令 `remote-control` / `rc` / `bridge` 触发） |
  | `bridgeApi.ts` | Bridge 与 Remote Control Server 之间的 REST/WS API |
  | `bridgeMessaging.ts` | 消息传输层（双向 streaming） |
  | `bridgePermissionCallbacks.ts` | 远程权限回调（远端审批本地工具调用） |
  | `bridgeConfig.ts` / `envLessBridgeConfig.ts` / `pollConfig.ts` | Bridge 配置与轮询 |
  | `bridgeEnabled.ts` | Feature flag 检查 |
  | `bridgeStatusUtil.ts` / `bridgeUI.ts` / `bridgeDebug.ts` | 状态/UI/调试辅助 |
  | `createSession.ts` / `sessionRunner.ts` / `sessionIdCompat.ts` | 远程会话管理 |
  | `replBridge.ts` / `replBridgeHandle.ts` / `replBridgeTransport.ts` / `initReplBridge.ts` | REPL 与 Bridge 的胶水层 |
  | `jwtUtils.ts` / `trustedDevice.ts` / `workSecret.ts` / `webhookSanitizer.ts` | JWT 认证 / 设备信任 / 工作密钥 / Webhook 清洗 |
  | `peerSessions.ts` | 多设备会话同步 |
  | `inboundMessages.ts` / `inboundAttachments.ts` | 入站消息与附件处理 |
  | `remoteBridgeCore.ts` / `remoteInterruptHandling.ts` | 远程核心调度 / 中断处理 |
  | `codeSessionApi.ts` | 代码会话 REST 接口 |
  | `capacityWake.ts` / `flushGate.ts` / `bridgeResultScheduling.ts` | 唤醒 / 输出冲刷 / 结果调度 |
  | `rcDebugLog.ts` | Remote control 调试日志 |
  | `types.ts` | Bridge 类型定义 |

  **配套基础设施**：`packages/remote-control-server/`（自托管 RCS + Web UI）、`packages/acp-link/`（ACP 代理）。详见
  `docs/features/remote-control-self-hosting.md`。

  ---

  ### 5. 权限系统 (`src/hooks/toolPermission/`)

  工具执行前的权限审批中枢，连接 REPL UI / Bridge 远程审批 / 协调器多 worker 三种场景。

  | 文件/目录 | 作用 |
  |----------|------|
  | `PermissionContext.ts` | 权限上下文定义（`permissionMode`、当前会话信任级别、bypass 状态等） |
  | `permissionLogging.ts` | 权限决策日志（审计用） |
  | `handlers/coordinatorHandler.ts` | **协调器模式**（feature `COORDINATOR_MODE`）下转发权限请求给主控 worker |
  | `handlers/interactiveHandler.ts` | **交互模式**下弹出 Ink UI 对话框由用户审批 |
  | `handlers/swarmWorkerHandler.ts` | **Swarm 多 worker** 模式下子 worker 把权限请求转发给主 worker |

  **调用链**（顶层入口在 `src/hooks/useCanUseTool.tsx`）：

  ```
  Tool 调用 → useCanUseTool → toolPermission/handlers/* → 用户审批/Bridge远端审批/Coordinator转发
                                                         └→ permissionLogging
  ```

  **权限模式**（`src/types/permissions.ts`）：`default` / `acceptEdits` / `bypassPermissions` / `plan` / `auto` /
  `dontAsk`。

  **相关组件**：`src/components/permissions/` 提供 UI 对话框；`src/services/acp/permissions.ts` 处理 ACP
  协议下的权限传递；`bridgePermissionCallbacks.ts` 把权限请求路由到远端客户端。

  ---

  ### 6. 功能标记

  > 详见 `CLAUDE.md` 的 "Feature Flag System" 段。

  **使用方式**：

  ```ts
  import { feature } from 'bun:bundle';

  if (feature('BUDDY')) {
    // ...
  }
  ```

  > ⚠️ **Bun 编译器限制**：`feature()` 只能直接出现在 `if`
  条件或三元表达式位置，不能赋值给变量、不能放在箭头函数体里、不能作为 `&&` 链的一部分。

  **启用方式**：环境变量 `FEATURE_<FLAG_NAME>=1`。

  ```bash
  FEATURE_BUDDY=1 FEATURE_FORK_SUBAGENT=1 bun run dev
  ```

  **默认行为**：
  - **Dev mode**（`scripts/dev.ts`）：全部 flag 启用。
  - **Build mode**（`build.ts`）：65+ 个 flag 默认启用，列表见 `DEFAULT_BUILD_FEATURES`。
  - **不传环境变量时**：`feature()` 返回 `false`。

  **常见 Feature Flag 分类**：

  | 类别 | Flag |
  |------|------|
  | 基础 | `BUDDY`、`TRANSCRIPT_CLASSIFIER`、`BRIDGE_MODE`、`AGENT_TRIGGERS_REMOTE`、`CHICAGO_MCP`、`VOICE_MODE` |
  | 统计/缓存 | `SHOT_STATS`、`PROMPT_CACHE_BREAK_DETECTION`、`TOKEN_BUDGET` |
  | P0 本地 | `AGENT_TRIGGERS`、`ULTRATHINK`、`BUILTIN_EXPLORE_PLAN_AGENTS`、`LODESTONE` |
  | P1 API 依赖 | `EXTRACT_MEMORIES`、`VERIFICATION_AGENT`、`KAIROS_BRIEF`、`AWAY_SUMMARY`、`ULTRAPLAN` |
  | P2 | `DAEMON`、`ACP` |
  | 工作流 | `WORKFLOW_SCRIPTS`、`HISTORY_SNIP`、`MONITOR_TOOL`、`KAIROS` |
  | 多 worker | `COORDINATOR_MODE`、`BG_SESSIONS`、`TEMPLATES` |
  | 连接器 | `CONNECTOR_TEXT`、`COMMIT_ATTRIBUTION`、`DIRECT_CONNECT` |
  | 实验性 | `EXPERIMENTAL_SKILL_SEARCH`、`EXPERIMENTAL_SEARCH_EXTRA_TOOLS` |
  | 模式 | `POOR`、`SSH_REMOTE` |
  | 已禁用 | `CONTEXT_COLLAPSE`、`FORK_SUBAGENT`、`UDS_INBOX`、`LAN_PIPES`、`REVIEW_ARTIFACT`、`TEAMMEM`、`SKILL_LEARNING` |

  **类型声明**：`src/types/internal-modules.d.ts` 中声明 `bun:bundle` 模块的 `feature` 函数签名。

  **实现位置**：
  - 注入：`scripts/defines.ts`（dev 模式 `-d` flag）+ `build.ts`（`Bun.build({ define })`）
  - 解析：Bun 内置 `bun:bundle` 模块在编译时静态替换为常量

## 📂 目录结构

  ```text
  claude-code/
  ├── src/                              # 主源码目录
  │   ├── entrypoints/                 # CLI 入口（cli.tsx 真入口、init、mcp）
  │   ├── main.tsx                     # Commander.js CLI 主定义（~5674 行）
  │   ├── query.ts / QueryEngine.ts    # 核心 API 查询与对话编排
  │   ├── Tool.ts / tools.ts           # Tool 接口定义与注册表
  │   ├── context.ts                   # 系统/用户上下文构建
  │   ├── bootstrap/                   # 启动初始化（session、CWD、project root 单例）
  │   ├── state/                       # 全局状态（AppState、Zustand store、selectors）
  │   ├── screens/                     # 顶层屏幕（REPL.tsx 主交互界面）
  │   ├── components/                  # Ink UI 组件（149+ 个，消息渲染、权限对话、design-system）
  │   ├── services/                    # 服务层（API 客户端、ACP、工具/技能搜索）
  │   ├── commands/                    # CLI 子命令实现（mcp、auth、plugin、agents、poor 等）
  │   ├── tools/                       # 工具系统辅助函数
  │   ├── tasks/ / Task.ts             # 任务/计划系统
  │   ├── skills/                      # 内置 skill
  │   ├── bridge/                      # Remote Control / Bridge 模式
  │   ├── daemon/                      # 长驻 daemon supervisor
  │   ├── server/                      # 内置 HTTP 服务
  │   ├── ssh/                         # SSH 远程模式
  │   ├── plugins/                     # 插件系统
  │   ├── voice/                       # 语音输入（Push-to-Talk）
  │   ├── vim/                         # Vim 模式
  │   ├── hooks/                       # 用户 hook 系统
  │   ├── jobs/                        # 后台任务/模板 job
  │   ├── coordinator/                 # 多 worker 协调器
  │   ├── self-hosted-runner/          # 自托管运行器
  │   ├── environment-runner/          # BYOC 环境运行器
  │   ├── cli/                         # CLI 工具函数（bg、print、exit 等）
  │   ├── outputStyles/                # 输出样式
  │   ├── proactive/                   # 主动建议系统
  │   ├── memdir/ / migrations/        # 持久化记忆 / 配置迁移
  │   ├── schemas/ / constants/        # JSON Schema / 常量（CORE_TOOLS 等）
  │   ├── utils/                       # 通用工具函数
  │   ├── types/                       # TypeScript 类型声明
  │   └── __tests__/                   # 单元测试（就近放置）
  │
  ├── packages/                         # Bun workspace 包
  │   ├── @ant/                        # Anthropic 内部 fork 集合
  │   │   ├── ink/                     # Forked Ink 框架（components/hooks/theme）
  │   │   ├── computer-use-mcp/        # Computer Use MCP server
  │   │   ├── computer-use-input/      # 键鼠模拟（darwin/win32/linux）
  │   │   ├── computer-use-swift/      # 截图 + 应用管理
  │   │   ├── claude-for-chrome-mcp/   # Chrome 浏览器控制
  │   │   └── model-provider/          # Model provider 抽象层
  │   ├── builtin-tools/               # 60+ 内置工具实现
  │   ├── agent-tools/                 # Agent 工具集
  │   ├── mcp-client/                  # MCP 客户端库
  │   ├── acp-link/                    # ACP 代理服务器（WS → ACP agent 桥接）
  │   ├── remote-control-server/       # 自托管 RCS + Web UI（React 19 + Vite）
  │   ├── audio-capture-napi/          # 原生音频捕获
  │   ├── image-processor-napi/        # 图像处理
  │   ├── color-diff-napi/             # 颜色差异计算
  │   ├── modifiers-napi/              # 键盘修饰键检测（macOS FFI）
  │   ├── url-handler-napi/            # URL scheme 处理
  │   └── weixin/                      # 微信集成
  │
  ├── tests/                            # 测试根目录
  │   ├── integration/                 # 集成测试（CLI、context、pipeline、tool-chain 等）
  │   └── mocks/                       # 共享 mock 与 fixture
  │
  ├── scripts/                          # 构建脚本（dev.ts、defines.ts、post-build.ts、gen-icon.ts）
  ├── docs/                             # 文档（features/internals/diagrams/test-plans 等 16 个子目录）
  ├── spec/                             # 功能设计规范（feature_<日期>_<编号>_<名称>）
  ├── vendor/                           # 第三方二进制资源（audio-capture 等）
  ├── teach-me/                         # /teach-me skill 学习记录
  │
  ├── .github/                          # GitHub Actions 工作流（ci、release-rcs、update-contributors）
  ├── .husky/                           # Pre-commit hook
  ├── .vscode/                          # VS Code 配置（含 attach 调试）
  ├── .claude/                          # 项目级 Claude Code 工作区
  │
  ├── build.ts                          # Bun 构建脚本（splitting + post-process）
  ├── vite.config.ts                    # Vite 备选构建管线
  ├── biome.json                        # Biome lint/format 配置
  ├── tsconfig.json / tsconfig.base.json # TypeScript 配置
  ├── package.json / bun.lock           # 项目依赖与锁文件
  ├── CLAUDE.md                         # 项目级 AI agent 指令
  ├── AGENTS.md                         # Agent 配置说明
  ├── DEV-LOG.md                        # 开发日志
  └── README.md                         # 本文件
  ```

  > 顶层关键文件含义见 [`CLAUDE.md`](CLAUDE.md)，里面对 entrypoint、Tool 系统、Feature Flag、Multi-API 兼容层、Stubbed
  模块等都有更详细的说明。



## ⚡ 快速开始

### ⚙️ 环境要求

一定要最新版本的 bun 啊, 不然一堆奇奇怪怪的 BUG!!! bun upgrade!!!

- 📦 [Bun](https://bun.sh/) >= 1.3.11

**安装 Bun：**

```bash
# Linux 和 macOS
curl -fsSL https://bun.sh/install | bash

# Windows (PowerShell)
powershell -c "irm bun.sh/install.ps1 | iex"
```

**安装后的操作：**

1. **让当前终端识别 `bun` 命令**

   安装脚本会把 `~/.bun/bin` 写入对应的 shell 配置文件。macOS 默认 zsh 环境通常会看到：

   ```text
   Added "~/.bun/bin" to $PATH in "~/.zshrc"
   ```

   可以按安装脚本提示重启当前 shell：

   ```bash
   exec /bin/zsh
   ```

   如果你使用 bash，重新加载 bash 配置：

   ```bash
   source ~/.bashrc
   ```

   Windows PowerShell 用户关闭并重新打开 PowerShell 即可。

2. **验证 Bun 是否可用**

   ```bash
   bun --help
   bun --version
   ```

3. **如果已经安装过 Bun，更新到最新版本**

   ```bash
   bun upgrade
   ```

- ⚙️ 常规的配置 CC 的方式, 各大提供商都有自己的配置方式

### 📍 命令执行位置

- 安装或检查 Bun 的命令可以在任意目录执行：
  `curl -fsSL https://bun.sh/install | bash`、`bun --help`、`bun --version`、`bun upgrade`
- 安装本项目依赖、启动开发模式、构建项目时，必须先进入本仓库根目录，也就是包含 `package.json` 的目录。

### 📥 安装

```bash
cd /path/to/claude-code
bun install
```

### ▶️ 运行

```bash
# 开发模式, 看到版本号 888 说明就是对了
bun run dev

# 构建 (code splitting 多文件打包)
bun run build
```

构建产物输出到 `dist/` 目录：

| 产物 | 说明 |
|------|------|
| `dist/cli-bun.js` | 入口文件，Bun 运行时 |
| `dist/cli-node.js` | 入口文件，Node.js 运行时 |
| `dist/chunks/` | Code split chunk 文件 |

```bash
# 直接运行
bun run dist/cli-bun.js

# 或用 Node.js
node dist/cli-node.js
```

#### 编译独立 exe（Windows）

```bash
# 1. 构建 JS bundle
bun run build

# 2. 编译为独立 exe（自带 Bun 运行时，无需安装环境）
bun build --compile .\dist\cli-bun.js --outfile "Claude Code.exe"

# 3. 生成图标（使用 @lobehub/icons 的 Claude Code 官方 SVG）
bun run scripts/gen-icon.ts

# 4. 嵌入图标（需先安装 rcedit）
bun add rcedit
npx rcedit "Claude Code.exe" --set-icon claude-code.ico
```

生成的 `Claude Code.exe` 约 123 MB，可独立运行于任意 Windows 机器。

> 图标通过 `scripts/gen-icon.ts` 生成，SVG 来源 `@lobehub/icons`，深色 R 角背景 + Claude 官方橙色 Logo (`#D97757`)。产物 `claude-code.ico` 包含 16~256px 六个尺寸。

如果遇到 bug 请直接提一个 issues

### 👤 新人配置 /login

首次运行后，在 REPL 中输入 `/login` 命令进入登录配置界面，选择 **Anthropic Compatible** 即可对接第三方 API 兼容服务（无需 Anthropic 官方账号）。
选择 OpenAI 和 Gemini 对应的栏目都是支持相应协议的

需要填写的字段：


| 📌 字段      | 📝 说明       | 💡 示例                      |
| ------------ | ------------- | ---------------------------- |
| Base URL     | API 服务地址  | `https://api.example.com/v1` |
| API Key      | 认证密钥      | `sk-xxx`                     |
| Haiku Model  | 快速模型 ID   | `claude-haiku-4-5-20251001`  |
| Sonnet Model | 均衡模型 ID   | `claude-sonnet-4-6`          |
| Opus Model   | 高性能模型 ID | `claude-opus-4-6`            |

- ⌨️ **Tab / Shift+Tab** 切换字段，**Enter** 确认并跳到下一个，最后一个字段按 Enter 保存

> ℹ️ 支持所有 Anthropic API 兼容服务（如 OpenRouter、AWS Bedrock 代理等），只要接口兼容 Messages API 即可。

## Feature Flags

所有功能开关通过 `FEATURE_<FLAG_NAME>=1` 环境变量启用，例如：

```bash
FEATURE_BUDDY=1 FEATURE_FORK_SUBAGENT=1 bun run dev
```

各 Feature 的详细说明见 [`docs/features/`](docs/features/) 目录，欢迎投稿补充。

## VS Code 调试

TUI (REPL) 模式需要真实终端，无法直接通过 VS Code launch 启动调试。使用 **attach 模式**：

### 步骤

1. **终端启动 inspect 服务**：

   ```bash
   bun run dev:inspect
   ```

   会输出类似 `ws://localhost:8888/xxxxxxxx` 的地址。
2. **VS Code 附着调试器**：

   - 在 `src/` 文件中打断点
   - F5 → 选择 **"Attach to Bun (TUI debug)"**

## Teach Me 学习项目

项目中添加了一个 teach-me skills, 通过问答式引导帮你理解这个项目的任何模块。(调整 [sigma skill 而来](https://github.com/sanyuan0704/sanyuan-skills))

```bash
# 在 REPL 中直接输入
/teach-me Claude Code 架构
/teach-me React Ink 终端渲染 --level beginner
/teach-me Tool 系统 --resume
```

### 它能做什么

- **诊断水平** — 自动评估你对相关概念的掌握程度，跳过已知的、聚焦薄弱的
- **构建学习路径** — 将主题拆解为 5-15 个原子概念，按依赖排序逐步推进
- **苏格拉底式提问** — 用选项引导思考，而非直接给答案
- **错误概念追踪** — 发现并纠正深层误解
- **断点续学** — `--resume` 从上次进度继续

### 学习记录

学习进度保存在 `.claude/skills/teach-me/` 目录下，支持跨主题学习者档案。

本项目仅供学习研究用途。Claude Code 的所有权利归 [Anthropic](https://www.anthropic.com/) 所有。
