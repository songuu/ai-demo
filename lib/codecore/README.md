# CodePal - CLI会话管理器

完整的CLI会话管理解决方案，支持 Claude Code、Codex、Gemini CLI 的历史导入、对话查看和续聊功能。


## 功能特性

### ✅ 已实现功能

#### 1. 历史会话导入
- **Claude Code 历史导入**
  - 支持全局历史文件：`~/.claude/history.jsonl`
  - 支持项目会话文件：`~/.claude/projects/<project>/*.jsonl`
  - 自动解析项目路径（Windows: `C--Users-Administrator` → `C:\Users\Administrator`）
  - 按 sessionId 分组消息
  - 智能提取会话标题（从第一条用户消息）
  - 过滤系统消息（file-history-snapshot、command、summary、meta消息等）

- **Codex 历史导入**
  - 扫描 `~/.codex/sessions` 和 `~/.codex/conversations`
  - 支持 JSONL 格式
  - 提取会话标题、工作目录、时间戳

- **Gemini CLI 历史导入**
  - 扫描 `~/.gemini/tmp` 和 `~/.gemini/sessions`
  - 支持目录格式和文件格式
  - 解析 metadata.json 和 conversation.jsonl

#### 2. 对话流查看
- **完整对话解析**
  - 解析 Claude Code JSONL 格式
  - 区分用户、助手、系统、工具消息
  - 提取工具调用信息（tool_use、tool_result）
  - 显示消息时间戳
  - 支持富文本内容（文本块、代码块）

- **对话统计**
  - 总消息数
  - 用户消息数
  - 助手消息数
  - 工具调用数
  - 总字符数

#### 3. Resume 功能
- **Claude Code Resume**
  - 命令：`claude --continue`
  - 在原工作目录中恢复最近会话
  - 支持 MCP 配置（`--mcp-strict`）

- **Codex Resume**
  - 命令：`codex resume <session_id>`
  - 或 `codex chat` 启动新会话

- **Gemini Resume**
  - 命令：`gemini resume <session_id>`
  - 或 `gemini chat` 启动新会话

#### 4. 终端集成
- **外部终端支持**
  - Windows: cmd, PowerShell, Windows Terminal
  - macOS: Terminal.app, iTerm2, Warp
  - Linux: gnome-terminal, xterm, konsole
  - 一键在终端中启动会话

- **内置终端**
  - 实时命令执行
  - 输出流式显示
  - 支持交互式输入
  - 命令历史
  - 工作目录切换

#### 5. UI 功能
- **三栏布局**（参考 CodePal 设计）
  - 左侧：项目导航 + 日历
  - 中间：时间线会话列表
  - 右侧：会话详情 + 对话/终端

- **会话管理**
  - 创建新会话
  - 导入历史会话
  - 查看会话详情
  - Resume 会话
  - 删除会话

- **搜索和过滤**
  - 按标题搜索
  - 按项目过滤
  - 按日期过滤
  - 多种排序方式（最近、时长、活跃度、A-Z、大小）

- **命令操作**
  - 复制 Resume 命令
  - 在终端中运行
  - 打开日志文件
  - 打开工作目录

## 文件结构

```
lib/codecore/
├── model/
│   ├── cod_session.dart          # 会话数据模型
│   └── cod_session.g.dart        # Hive 生成代码
├── service/
│   ├── cod_cli_runner.dart       # CLI 进程运行器
│   ├── cod_conversation_parser.dart  # 对话解析器
│   ├── cod_history_importer.dart # 历史导入器
│   └── cod_launcher.dart         # CLI 启动器
├── store/
│   ├── cod_session_store.dart    # 会话存储
│   └── cod_settings_store.dart   # 设置存储
├── widget/
│   └── cod_embedded_terminal.dart # 内置终端组件
└── README.md                     # 本文档
```

## 数据目录

### Windows
- Claude Code: `C:\Users\<user>\.claude\`
  - 全局历史: `history.jsonl`
  - 项目会话: `projects\<project>\*.jsonl`
- Codex: `C:\Users\<user>\.codex\sessions\`
- Gemini: `C:\Users\<user>\.gemini\tmp\`

### macOS/Linux
- Claude Code: `~/.claude/`
  - 全局历史: `history.jsonl`
  - 项目会话: `projects/<project>/*.jsonl`
- Codex: `~/.codex/sessions/`
- Gemini: `~/.gemini/tmp/`

## Claude Code 历史文件格式

### 全局历史 (history.jsonl)
```json
{
  "display": "/plugins",
  "pastedContents": {},
  "timestamp": 1766996247095,
  "project": "E:\\project\\工程化\\bff",
  "sessionId": "6ae7d27f-a78b-40bc-a48d-6c5c447dca2f"
}
```

### 会话文件 (projects/<project>/<sessionId>.jsonl)
```json
{
  "type": "user",
  "sessionId": "3a04da49-6753-411b-91c7-46254e0dfa7e",
  "cwd": "C:\\Users\\Administrator",
  "version": "2.0.76",
  "message": {
    "role": "user",
    "content": "帮我实现一个功能"
  },
  "timestamp": "2026-01-05T03:40:37.490Z",
  "uuid": "a4ca8030-97d9-4cd8-993c-29c27d13e77b"
}
```

### 助手消息
```json
{
  "type": "assistant",
  "sessionId": "...",
  "message": {
    "role": "assistant",
    "content": [
      {
        "type": "text",
        "text": "好的，我来帮你实现"
      },
      {
        "type": "tool_use",
        "name": "edit_file",
        "input": {...}
      }
    ]
  },
  "timestamp": "..."
}
```

### 工具结果
```json
{
  "type": "tool_result",
  "message": {
    "role": "user",
    "content": [
      {
        "type": "tool_result",
        "tool_use_id": "...",
        "content": "文件已更新"
      }
    ]
  }
}
```

## Resume 命令格式

### Claude Code
```bash
# 在工作目录中恢复最近会话
cd /path/to/project
claude --continue

# 带选项
claude --continue --model claude-3-5-sonnet-20241022 --mcp-strict
```

### Codex
```bash
# 恢复指定会话
codex resume <session_id>

# 新会话
codex chat --cwd /path/to/project
```

### Gemini
```bash
# 恢复指定会话
gemini resume <session_id>

# 新会话
gemini chat --working-dir /path/to/project
```

## 环境变量

代码会自动补全 PATH 环境变量以找到 CLI 工具：

### Windows
- `%USERPROFILE%\AppData\Roaming\npm`
- `%USERPROFILE%\AppData\Local\Programs\Microsoft VS Code\bin`
- `%USERPROFILE%\.local\bin`
- `C:\Program Files\nodejs`
- `C:\Windows\System32`

### macOS/Linux
- `/opt/homebrew/bin`
- `/usr/local/bin`
- `/usr/bin`
- `/bin`
- `~/.local/bin`
- `~/.nvm/versions/node/v20/bin`

## 使用示例

### 1. 导入历史会话
```dart
final result = await CodHistoryImporter.importAllSessions();
print(result.summary); // "成功导入 15 个会话"
```

### 2. 查看对话
```dart
final conversation = await CodConversationParser.loadConversation(session);
for (final msg in conversation) {
  print('${msg.displayRole}: ${msg.content}');
}
```

### 3. Resume 会话
```dart
final result = await CodLauncher.resumeSession(session);
if (result.success) {
  print('会话已恢复');
}
```

### 4. 在终端中运行
```dart
// 在 Windows Terminal 中运行
await CodCliRunner.runInTerminal(session, terminalApp: 'Windows Terminal');

// 在 iTerm2 中运行（macOS）
await CodCliRunner.runInTerminal(session, terminalApp: 'iTerm2');
```

### 5. 获取 Resume 命令
```dart
final cmd = CodCliRunner.buildResumeCommand(session);
Clipboard.setData(ClipboardData(text: cmd));
```

## CLI 可用性检查

```dart
// 检查单个CLI
final check = await CodLauncher.checkCliAvailability('claude');
if (check.available) {
  print('Claude Code 版本: ${check.version}');
}

// 检查所有CLI
final checks = await CodLauncher.checkAllCliAvailability();
for (final entry in checks.entries) {
  print('${entry.key}: ${entry.value.status}');
}
```

## 注意事项

1. **Claude Code 特殊性**
   - Resume 使用 `--continue` 而不是 `resume <id>`
   - 必须在原工作目录中执行
   - 会恢复最近的会话，而不是指定ID的会话

2. **路径格式**
   - Windows: 反斜杠 `\`
   - Unix: 正斜杠 `/`
   - Claude 项目名使用 `--` 分隔路径组件

3. **消息过滤**
   - 自动跳过 `file-history-snapshot`
   - 自动跳过 `command` 类型
   - 自动跳过 `summary` 类型
   - 自动跳过 `isMeta: true` 消息
   - 自动跳过命令输出消息

4. **终端兼容性**
   - Windows Terminal 需要安装
   - iTerm2/Warp 仅 macOS 可用
   - 确保 CLI 工具在 PATH 中

## 故障排除

### 无法找到 CLI 工具
1. 确认已安装对应的 CLI
2. 检查是否在 PATH 中
3. 在设置中配置自定义路径

### 历史导入失败
1. 检查历史目录是否存在
2. 确认有读取权限
3. 查看导入结果的错误信息

### Resume 失败
1. 确认工作目录存在
2. 检查 CLI 版本兼容性
3. 查看日志文件错误信息

### 内置终端无响应
1. 检查进程是否已启动
2. 确认工作目录存在
3. 查看错误输出

## 开发计划

### 未来功能
- [ ] 会话分组管理
- [ ] 自定义标签
- [ ] 导出会话为 Markdown
- [ ] 会话搜索增强（全文搜索）
- [ ] 会话统计分析
- [ ] 多语言对话界面
- [ ] 快捷键支持
- [ ] 会话模板

## 贡献

欢迎贡献代码和反馈问题！

## 许可

本项目遵循与主项目相同的许可协议。
