# CodePal 功能完整指南

## 📋 目录
1. [功能概述](#功能概述)
2. [快速开始](#快速开始)
3. [历史导入](#历史导入)
4. [会话管理](#会话管理)
5. [对话查看](#对话查看)
6. [Resume功能](#resume功能)
7. [终端集成](#终端集成)
8. [高级功能](#高级功能)
9. [故障排除](#故障排除)

---

## 功能概述

CodePal 是一个完整的 CLI 会话管理工具，完美集成了以下功能：

✅ **历史导入** - 从 Claude Code、Codex、Gemini CLI 导入历史会话  
✅ **对话查看** - 查看完整的对话流，包括工具调用  
✅ **Resume功能** - 一键恢复任何历史会话  
✅ **内置终端** - 直接在应用中运行命令  
✅ **外部终端** - 支持所有主流终端（Terminal、iTerm2、Warp、Windows Terminal等）  
✅ **命令复制** - 一键复制 resume 命令  
✅ **时间线视图** - 按日期分组显示会话  
✅ **智能搜索** - 按标题、项目、日期搜索  

---

## 快速开始

### 1. 首次使用

1. **打开 CodePal Tab**
   - 启动应用后，切换到 "CodePal" 标签页

2. **导入历史会话**
   - 点击顶部的 "历史" (History) 图标
   - 等待扫描完成
   - 查看导入结果

3. **选择会话**
   - 在中间列表中点击任意会话
   - 右侧面板会显示会话详情

### 2. 创建新会话

1. 点击 "创建会话" 按钮
2. 选择 AI 提供商（Claude、Codex、Gemini）
3. 输入标题和工作目录
4. 点击 "创建并运行"

---

## 历史导入

### 支持的CLI工具

#### Claude Code
- **Windows**: `C:\Users\<用户>\.claude\`
- **macOS/Linux**: `~/.claude/`
- **文件格式**:
  - 全局历史: `history.jsonl`
  - 项目会话: `projects/<project>/*.jsonl`

**示例**:
```
C:\Users\Administrator\.claude\
├── history.jsonl
└── projects\
    ├── C--Users-Administrator\
    │   ├── 3a04da49-6753-411b-91c7-46254e0dfa7e.jsonl
    │   └── agent-a258b1f.jsonl
    └── C--Users-Administrator--project\
        └── session.jsonl
```

#### Codex
- **Windows**: `C:\Users\<用户>\.codex\sessions\`
- **macOS/Linux**: `~/.codex/sessions/`
- **文件格式**: `*.jsonl`

#### Gemini CLI
- **Windows**: `C:\Users\<用户>\.gemini\tmp\`
- **macOS/Linux**: `~/.gemini/tmp/`
- **文件格式**: 目录或 `.jsonl` 文件

### 导入过程

1. **自动扫描**
   - 扫描所有支持的目录
   - 递归查找会话文件
   - 解析 JSONL 格式

2. **数据处理**
   - 按 sessionId 分组消息
   - 提取会话标题（从第一条用户消息）
   - 解析时间戳和工作目录
   - 过滤系统消息

3. **结果展示**
   - 显示导入数量
   - 显示扫描统计
   - 显示错误信息（如有）

### 导入统计示例

```
成功导入 42 个会话

详情:
• Scanned 3 project(s), 128 file(s), found 42 session(s)
• Scanned 15 Codex file(s)
• Scanned 8 Gemini session(s)
```

---

## 会话管理

### UI 布局

```
┌────────────┬──────────────────┬─────────────────────┐
│  Projects  │   Session List   │   Session Detail    │
│            │                  │                     │
│  • All     │  Today           │  ┌─ Title ────────┐ │
│  • Claude  │  ├─ 10:30 Chat   │  │ Resume  Terminal│ │
│  • Codex   │  └─ 09:15 Code   │  ├─────────────────┤ │
│  • Gemini  │                  │  │ Info Grid       │ │
│            │  Yesterday       │  ├─────────────────┤ │
│  Calendar  │  ├─ 16:45 Debug  │  │ Conversation    │ │
│  ┌────────┐│  └─ 14:20 Fix    │  │ • User: ...     │ │
│  │ Jan 26 ││                  │  │ • Assistant: ..│ │
│  └────────┘│                  │  └─────────────────┘ │
└────────────┴──────────────────┴─────────────────────┘
```

### 左侧面板 - 项目导航

**功能**:
- 按项目过滤会话
- 显示会话计数
- 日历视图（按创建日期或更新日期）

**操作**:
- 点击项目名称进行过滤
- 点击日历日期查看当天会话
- 有会话的日期会高亮显示

### 中间面板 - 会话列表

**功能**:
- 时间线布局（按日期分组）
- 会话卡片显示
- 快速操作按钮

**排序选项**:
- Recent: 最近更新
- Duration: 按时长
- Activity: 按活跃度
- A-Z: 按字母顺序
- Size: 按文件大小

**会话卡片信息**:
- 提供商图标（Claude/Codex/Gemini）
- 会话标题
- 时长
- 工作目录
- 状态指示器

**快速操作**:
- Resume: 恢复会话
- Terminal: 在终端中打开
- Copy Cmd: 复制命令

### 右侧面板 - 会话详情

**信息网格**:
- STARTED: 开始时间
- DURATION: 持续时间
- MODEL: 使用的模型
- CLI VERSION: CLI工具版本
- ORIGINATOR: 来源
- WORKING DIRECTORY: 工作目录
- FILE SIZE: 日志文件大小

**可折叠部分**:

1. **Environment Context**
   - Resume Command: 恢复命令
   - Full Command: 完整命令
   - Working Directory: 工作目录
   - Log Path: 日志路径
   - Status: 状态
   - 操作按钮: Copy Command、Open Folder

2. **Task Instructions**
   - 任务说明
   - 使用提示

**对话区域**:
- 消息列表（用户、助手、工具）
- 消息筛选
- 消息展开/折叠
- 刷新对话

**终端区域** (切换显示):
- 实时命令输出
- 交互式输入
- 进程控制

---

## 对话查看

### 消息类型

#### 1. 用户消息
```
┌─────────────────────────────┐
│ 👤 User           10:30:45  │
├─────────────────────────────┤
│ 帮我实现一个登录功能        │
└─────────────────────────────┘
```

#### 2. 助手消息
```
┌─────────────────────────────┐
│ 🤖 Assistant      10:30:52  │
├─────────────────────────────┤
│ 好的，我来帮你实现登录功能  │
│                             │
│ 首先需要以下几个步骤：      │
│ 1. 创建用户模型             │
│ 2. 实现认证逻辑             │
│ 3. 添加登录界面             │
└─────────────────────────────┘
```

#### 3. 工具调用
```
┌─────────────────────────────┐
│ 🔧 Tool           10:31:05  │
├─────────────────────────────┤
│ [Tool: edit_file]           │
│                             │
│ 正在编辑文件 auth.js...     │
└─────────────────────────────┘
```

### 消息操作

- **选择文本**: 所有消息内容可选择
- **复制消息**: 右键复制
- **查看时间**: 每条消息显示时间戳
- **消息编号**: 右上角显示消息序号

### 对话统计

显示在对话区域顶部：
- `42 messages, 15 user, 22 assistant, 5 tool calls`

---

## Resume功能

### Claude Code Resume

**命令格式**:
```bash
claude --continue
```

**特点**:
- ✅ 无需指定 session ID
- ✅ 在工作目录中恢复最近会话
- ✅ 支持 MCP 配置

**使用步骤**:

1. **从应用中 Resume**
   ```
   1. 选择会话
   2. 点击 "Resume" 按钮
   3. 应用会自动：
      - 切换到原工作目录
      - 执行 claude --continue
      - 显示输出
   ```

2. **在外部终端中 Resume**
   ```
   1. 选择会话
   2. 点击 "Terminal" 下拉菜单
   3. 选择终端（Windows Terminal/iTerm2/Warp）
   4. 终端会自动打开并执行命令
   ```

3. **复制命令手动执行**
   ```
   1. 选择会话
   2. 点击 "Copy Cmd"
   3. 在任意终端中粘贴执行
   ```

**示例**:
```bash
# Windows
cd C:\Users\Administrator\project
claude --continue

# macOS/Linux
cd /Users/john/project
claude --continue
```

### Codex Resume

**命令格式**:
```bash
codex resume <session_id>
```

**特点**:
- ✅ 使用 session ID 恢复
- ✅ 支持工作目录参数

**示例**:
```bash
codex resume abc123def456

# 或指定工作目录
codex chat --cwd /path/to/project
```

### Gemini Resume

**命令格式**:
```bash
gemini resume <session_id>
```

**特点**:
- ✅ 使用 session ID 恢复
- ✅ 支持 working-dir 参数

**示例**:
```bash
gemini resume xyz789abc123

# 或指定工作目录
gemini chat --working-dir /path/to/project
```

---

## 终端集成

### 内置终端

**功能**:
- ✅ 实时输出显示
- ✅ 交互式输入
- ✅ 进程控制（启动/停止）
- ✅ 命令历史
- ✅ 工作目录切换

**使用**:

1. **切换到终端视图**
   - 在会话详情中点击 "Terminal" 按钮

2. **运行命令**
   - 在输入框中输入命令
   - 按 Enter 或点击发送按钮

3. **内置命令**
   ```bash
   cd <directory>   # 切换目录
   pwd              # 显示当前目录
   clear / cls      # 清屏
   ```

4. **进程控制**
   - ▶️ Play: 启动/恢复进程
   - ⏹️ Stop: 停止进程
   - 📋 Copy: 复制输出
   - 📄 Copy Cmd: 复制命令

**终端窗口**:
```
┌─────────────────────────────────────┐
│ 🔴 🟡 🟢  Terminal         Running  │
├─────────────────────────────────────┤
│ $ cd /path/to/project               │
│ Changed directory to: /path/to/...  │
│ $ claude --continue                 │
│ Loading session...                  │
│ Session loaded. Type your message:  │
│                                     │
│ [更多输出...]                       │
├─────────────────────────────────────┤
│ $ ▊                           [📤]  │
└─────────────────────────────────────┘
```

### 外部终端

**Windows 支持**:
- ✅ cmd
- ✅ PowerShell
- ✅ Windows Terminal

**macOS 支持**:
- ✅ Terminal.app
- ✅ iTerm2
- ✅ Warp

**Linux 支持**:
- ✅ gnome-terminal
- ✅ xterm
- ✅ konsole

**使用**:

1. 选择会话
2. 点击 "Terminal" 下拉菜单
3. 选择终端应用
4. 终端自动打开并切换到工作目录
5. 命令自动执行

**优势**:
- 完整的终端功能
- 支持快捷键
- 持久化会话
- 更好的性能

---

## 高级功能

### 1. 搜索和过滤

**搜索栏**:
- 按标题搜索
- 按评论搜索
- 实时过滤结果

**项目过滤**:
- 按 AI 提供商过滤（All/Claude/Codex/Gemini）
- 显示匹配数量

**日期过滤**:
- 点击日历日期
- 按创建日期或更新日期
- 高亮有会话的日期

### 2. 会话统计

**总览统计**:
- 总会话数
- 总时长
- 总消息数

**单个会话**:
- 持续时间
- 消息数（用户/助手/工具）
- 文件大小
- 最后更新时间

### 3. 数据管理

**自动保存**:
- 所有会话自动保存到 Hive 数据库
- 支持离线访问
- 快速加载

**日志文件**:
- 每个会话有独立的日志文件
- 完整记录输入输出
- 可以在外部编辑器中查看

**导出功能** (计划中):
- 导出为 Markdown
- 导出对话历史
- 导出统计报告

### 4. 快捷操作

**一键操作**:
- Resume 会话
- 在终端中打开
- 复制命令
- 打开日志文件
- 打开工作目录

**批量操作** (计划中):
- 批量导入
- 批量删除
- 批量导出

---

## 故障排除

### 问题 1: 无法找到 CLI 工具

**症状**:
- CLI 不可用
- 版本显示 "N/A"

**解决方案**:

1. **确认已安装**
   ```bash
   # Windows
   where claude
   where codex
   where gemini
   
   # macOS/Linux
   which claude
   which codex
   which gemini
   ```

2. **检查 PATH**
   - Windows: `echo %PATH%`
   - macOS/Linux: `echo $PATH`

3. **手动配置路径** (在设置中)
   - 打开设置
   - 找到 CLI 配置
   - 输入完整路径

### 问题 2: 历史导入失败

**症状**:
- "No Claude session files found"
- 导入数量为 0

**解决方案**:

1. **检查目录**
   ```bash
   # Windows
   dir C:\Users\Administrator\.claude\projects
   
   # macOS/Linux
   ls -la ~/.claude/projects
   ```

2. **检查权限**
   - 确保有读取权限
   - Windows: 右键属性 → 安全
   - macOS/Linux: `chmod +r ~/.claude/projects/*`

3. **检查文件格式**
   - 确认是 `.jsonl` 文件
   - 使用文本编辑器打开验证

### 问题 3: Resume 失败

**症状**:
- "Process exited with code: 1"
- "Working directory not found"

**解决方案**:

1. **检查工作目录**
   ```bash
   # 确认目录存在
   cd <working-directory>
   ```

2. **检查 CLI 版本**
   ```bash
   claude --version
   ```

3. **手动测试**
   ```bash
   # 在正确的目录中手动运行
   cd <working-directory>
   claude --continue
   ```

### 问题 4: 内置终端无响应

**症状**:
- 输入后无输出
- 进程卡住

**解决方案**:

1. **停止进程**
   - 点击 Stop 按钮
   - 等待进程结束

2. **检查命令**
   - 确认命令正确
   - 检查参数

3. **使用外部终端**
   - 切换到外部终端
   - 更好的调试体验

### 问题 5: 对话显示为空

**症状**:
- 选择会话后对话区域为空
- "暂无对话记录"

**可能原因**:

1. **日志文件不存在**
   - 检查日志路径
   - 确认文件存在

2. **日志格式不正确**
   - 打开日志文件
   - 检查是否是 JSONL 格式

3. **所有消息被过滤**
   - 可能只包含系统消息
   - 检查原始文件内容

**解决方案**:
- 点击刷新按钮
- 重新选择会话
- 查看日志文件

---

## 常见问题 (FAQ)

### Q1: 支持哪些 CLI 工具？
A: 目前支持 Claude Code、Codex、Gemini CLI。

### Q2: 可以离线使用吗？
A: 可以！所有导入的会话都存储在本地，可以离线查看。Resume 功能需要对应的 CLI 工具可用。

### Q3: 会话数据存储在哪里？
A: 使用 Hive 数据库，存储在应用数据目录中。日志文件存储在 `~/.codecore/sessions/` 目录。

### Q4: 可以删除会话吗？
A: 是的，在会话详情中有删除选项（计划中）。

### Q5: 支持导出功能吗？
A: 目前可以复制对话内容。完整的导出功能正在开发中。

### Q6: 内置终端和外部终端有什么区别？
A: 
- 内置终端：集成在应用中，方便快速操作
- 外部终端：功能更强大，支持更多快捷键和配置

### Q7: 如何更新 CLI 工具？
A: 使用各工具的更新命令：
```bash
npm update -g @anthropic-ai/claude-cli
npm update -g codex-cli
npm update -g @google-ai/gemini-cli
```

### Q8: 支持团队协作吗？
A: 目前是单用户使用。团队功能计划在未来版本中添加。

---

## 性能优化建议

### 1. 导入大量会话

如果有数百个会话：
- 导入可能需要几分钟
- 建议定期清理旧会话
- 使用项目过滤减少显示数量

### 2. 大文件日志

如果日志文件很大（>10MB）：
- 加载可能较慢
- 考虑在外部编辑器中查看
- 使用搜索功能定位内容

### 3. 内置终端

对于长时间运行的会话：
- 建议使用外部终端
- 更好的性能和稳定性
- 支持后台运行

---

## 更新日志

### v1.0.0 (2026-01-14)
- ✅ 完整的历史导入功能
- ✅ Claude Code、Codex、Gemini CLI 支持
- ✅ 对话流查看
- ✅ Resume 功能
- ✅ 内置终端
- ✅ 外部终端集成
- ✅ 时间线布局
- ✅ 搜索和过滤
- ✅ 命令复制

---

## 反馈和支持

遇到问题或有建议？

1. 查看本指南的故障排除部分
2. 检查日志文件获取详细错误信息
3. 在项目中提交 Issue
4. 参与社区讨论

---

