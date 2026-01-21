# CLI 配置管理指南

## 🎯 功能概述

CodePal 现在提供了强大的可视化 CLI 配置管理系统，让你能够轻松配置和管理 **Claude Code**、**Codex** 和 **Gemini** 等 CLI 工具。

### 核心功能

✅ **可视化配置界面** - 无需手动编辑配置文件  
✅ **API 密钥管理** - 安全存储和管理 API 密钥  
✅ **环境变量设置** - 自定义每个 CLI 的环境变量  
✅ **默认参数配置** - 预设常用参数  
✅ **自动历史导入** - 自动扫描并导入历史会话  
✅ **配置导入导出** - 轻松备份和共享配置  
✅ **CLI 可用性检测** - 自动检测 CLI 工具是否可用  

---

## 📖 使用指南

### 1. 打开配置管理器

**方式 1：通过设置按钮**
```
CodePal 主界面 → 右上角齿轮图标⚙️
```

**方式 2：首次使用**
- 首次安装时，系统会自动初始化默认配置
- Claude Code、Codex 和 Gemini 的默认配置会被创建

---

### 2. 配置界面布局

配置管理器采用**两栏布局**：

```
┌─────────────────────────────────────────────────┐
│ 🎨 CLI 配置管理                         ✕     │
├──────────────┬──────────────────────────────────┤
│              │                                  │
│ 📋 提供商列表  │  📝 详细配置                     │
│              │                                  │
│  • Claude    │  [配置字段]                      │
│  • Codex     │  - Command                      │
│  • Gemini    │  - API Key                      │
│              │  - History Path                 │
│              │  - ...                          │
│              │                                  │
│  [重置]       │  [测试配置]                      │
│  [导入]       │                                  │
│  [导出]       │                                  │
└──────────────┴──────────────────────────────────┘
```

---

### 3. 配置各个 CLI 工具

#### 3.1 Claude Code 配置

```yaml
显示名称: Claude Code
命令: claude
API 密钥: your-anthropic-api-key
历史路径: ${HOME}\.claude\projects
默认参数: []

环境变量:
  ANTHROPIC_API_KEY: [从 API Key 字段自动设置]

高级选项:
  ✓ 自动导入历史
  ✓ 在 Shell 中运行
  最大并发会话: 5
  超时时间: 3600秒
```

**配置步骤**：
1. 点击左侧 "Claude"
2. 点击右上角 "Edit" 按钮
3. 在 "API Key" 字段输入你的 Anthropic API 密钥
4. （可选）修改 "Command" 如果 claude 不在 PATH 中
5. 点击 "Save" 保存

#### 3.2 Codex CLI 配置

```yaml
显示名称: Codex CLI
命令: codex
API 密钥: your-openai-api-key
历史路径: ${HOME}\.codex\history.jsonl
默认参数: []

环境变量:
  OPENAI_API_KEY: [从 API Key 字段自动设置]

高级选项:
  ✓ 自动导入历史
  ✓ 在 Shell 中运行
  最大并发会话: 5
  超时时间: 3600秒
```

#### 3.3 Gemini CLI 配置

```yaml
显示名称: Gemini CLI
命令: gemini
API 密钥: your-google-api-key
历史路径: ${HOME}\.gemini\sessions
默认参数: []

环境变量:
  GOOGLE_API_KEY: [从 API Key 字段自动设置]

高级选项:
  ✓ 自动导入历史
  ✓ 在 Shell 中运行
  最大并发会话: 5
  超时时间: 3600秒
```

---

### 4. 配置字段详解

#### 基础配置

**Command（命令）**
- CLI 工具的命令名称或完整路径
- 示例：
  - `claude` （如果在 PATH 中）
  - `C:\App\nvm\v24.11.1\claude.exe` （完整路径）

**API Key（API 密钥）**
- 你的 CLI 工具的 API 密钥
- 密码输入框，安全存储
- 自动设置对应的环境变量：
  - Claude → `ANTHROPIC_API_KEY`
  - Codex → `OPENAI_API_KEY`
  - Gemini → `GOOGLE_API_KEY`

**History Path（历史路径模板）**
- 历史文件存储位置的路径模板
- 支持变量：
  - `${HOME}` - 用户主目录
  - `${USERPROFILE}` - Windows 用户配置目录
- 示例：
  - Windows: `C:\Users\Administrator\.claude\projects`
  - macOS/Linux: `~/.claude/projects`

**Working Directory（工作目录模板）**
- 默认工作目录（留空使用当前目录）

#### 高级选项

**Auto Import History（自动导入历史）**
- ✅ 启用：自动扫描并导入历史会话
- ❌ 禁用：不自动导入（手动触发）

**Run in Shell（在 Shell 中运行）**
- ✅ 启用：通过 cmd/bash 运行（推荐）
- ❌ 禁用：直接运行可执行文件

**Max Concurrent Sessions（最大并发会话数）**
- 同时运行的最大会话数
- 默认：5

**Timeout（超时时间）**
- 会话超时时间（秒）
- 默认：3600（1小时）

#### 默认参数

为 CLI 工具设置默认参数，每次启动时自动添加。

**示例**：
```
• --full-auto
• --model gpt-4
• --verbose
```

**添加方式**：
1. 进入编辑模式
2. 点击 "Add Argument"
3. 输入参数

#### 环境变量

设置自定义环境变量，仅对该 CLI 工具生效。

**示例**：
```
DEBUG = 1
VERBOSE = true
MAX_TOKENS = 4096
```

**添加方式**：
1. 进入编辑模式
2. 点击 "Add Variable"
3. 输入变量名和值

---

### 5. 启用/禁用 CLI 工具

每个 CLI 工具都有一个启用/禁用开关。

**禁用 CLI 工具时**：
- ❌ 不会显示在新建会话列表中
- ❌ 不会自动导入历史
- ✅ 已有会话仍可查看和管理
- ✅ 配置保留，可随时重新启用

**操作**：
```
选择提供商 → 右上角开关按钮 → Toggle
```

---

### 6. 测试配置

配置完成后，可以测试 CLI 是否正常工作。

**测试步骤**：
1. 选择要测试的提供商
2. 滚动到底部
3. 点击 "Test Configuration" 按钮
4. 查看测试结果

**测试内容**：
- ✅ CLI 命令是否可执行
- ✅ API 密钥是否有效
- ✅ 环境变量是否正确
- ✅ 历史路径是否存在

---

### 7. 导入导出配置

#### 导出配置

**用途**：
- 备份当前配置
- 分享给团队成员
- 迁移到其他机器

**操作**：
```
配置管理器 → 底部 "Export" 按钮 → 配置复制到剪贴板
```

**导出格式**（JSON）：
```json
{
  "version": "1.0",
  "exportedAt": "2026-01-15T12:00:00Z",
  "configs": {
    "claude": { ... },
    "codex": { ... },
    "gemini": { ... }
  }
}
```

#### 导入配置

**操作**：
```
配置管理器 → 底部 "Import" 按钮 → 粘贴 JSON
```

**注意事项**：
- ⚠️ 导入会覆盖现有配置
- ✅ 建议先导出备份
- ✅ 导入后自动验证格式

---

### 8. 重置为默认配置

如果配置出现问题，可以重置为默认值。

**操作**：
```
配置管理器 → 底部 "Reset" 按钮 → 确认
```

**重置后**：
- 所有配置恢复为默认值
- API 密钥会被清空
- 自定义环境变量和参数会被删除

**默认配置**：
- Claude Code: 命令 `claude`, 历史路径 `${HOME}\.claude\projects`
- Codex CLI: 命令 `codex`, 历史路径 `${HOME}\.codex\history.jsonl`
- Gemini CLI: 命令 `gemini`, 历史路径 `${HOME}\.gemini\sessions`

---

## 🔧 高级用法

### 自定义 CLI 工具（未来功能）

目前支持三个内置提供商，未来将支持：
- 添加自定义 CLI 工具
- 自定义命令格式
- 自定义历史解析规则

### 配置文件位置

配置存储在 Hive 数据库中：
```
Windows: C:\Users\<User>\AppData\Roaming\<App>\cod_provider_configs.hive
macOS: ~/Library/Application Support/<App>/cod_provider_configs.hive
Linux: ~/.local/share/<App>/cod_provider_configs.hive
```

### 手动编辑配置（不推荐）

虽然配置存储在二进制格式中，但你可以：
1. 导出配置为 JSON
2. 编辑 JSON
3. 重新导入

---

## 💡 最佳实践

### 1. API 密钥安全

✅ **推荐**：
- 使用专用的 API 密钥
- 定期轮换密钥
- 不要分享包含密钥的导出文件

❌ **不推荐**：
- 在环境变量中硬编码密钥
- 将密钥存储在版本控制中

### 2. 历史路径设置

✅ **推荐**：
- 使用 `${HOME}` 变量以支持多用户
- 确保路径存在且有读写权限
- 对于 Claude Code，使用 `projects` 子目录

❌ **不推荐**：
- 使用绝对路径（如 `C:\Users\John\...`）
- 指向不存在的目录

### 3. 环境变量

✅ **推荐**：
- 只设置必要的环境变量
- 使用 API Key 字段而不是手动设置 `*_API_KEY`
- 变量名使用大写

❌ **不推荐**：
- 覆盖系统关键变量（如 `PATH`, `HOME`）
- 设置冲突的变量

### 4. 默认参数

✅ **推荐**：
- 设置常用的参数节省时间
- 使用长选项名（如 `--full-auto` 而不是 `-f`）
- 分条列出，每行一个

❌ **不推荐**：
- 设置互相冲突的参数
- 设置会改变 CLI 行为的危险参数

---

## 🆘 常见问题

### Q1: 配置保存后不生效？

**A**: 确保：
1. ✅ 点击了 "Save" 按钮
2. ✅ CLI 工具是启用状态（开关打开）
3. ✅ 重启了应用（某些情况下需要）

### Q2: API 密钥无效？

**A**: 检查：
1. ✅ 密钥格式正确（无多余空格）
2. ✅ 密钥有效且未过期
3. ✅ 密钥权限足够
4. ✅ 使用 "Test Configuration" 验证

### Q3: 历史导入失败？

**A**: 检查：
1. ✅ 历史路径模板正确
2. ✅ 路径存在且可访问
3. ✅ 历史文件格式正确（JSONL）
4. ✅ "Auto Import History" 已启用

### Q4: 命令找不到？

**A**: 解决方案：
1. ✅ 使用完整路径（如 `C:\App\nvm\v24.11.1\claude.exe`）
2. ✅ 确保 CLI 在系统 PATH 中
3. ✅ 使用 "Test Configuration" 检测
4. ✅ 检查 "Run in Shell" 是否启用

### Q5: 配置丢失了？

**A**: 恢复方案：
1. ✅ 检查是否有导出备份
2. ✅ 使用 "Reset" 恢复默认配置
3. ✅ 检查 Hive 数据库文件是否存在

### Q6: 如何迁移配置到新电脑？

**A**: 步骤：
1. 旧电脑：导出配置 → 复制 JSON
2. 新电脑：安装 CodePal → 导入配置
3. 更新路径（如果需要）
4. 测试配置

---

## 📊 配置示例

### 示例 1：基本 Claude Code 配置

```yaml
Provider: claude
Display Name: Claude Code
Enabled: ✓
Command: claude
API Key: sk-ant-api03-... [安全存储]
History Path: C:\Users\Administrator\.claude\projects

Advanced:
  Auto Import History: ✓
  Run in Shell: ✓
  Max Concurrent Sessions: 5
  Timeout: 3600

Environment Variables:
  ANTHROPIC_API_KEY: [自动设置]

Default Args:
  [无]
```

### 示例 2：高级 Codex 配置

```yaml
Provider: codex
Display Name: Codex CLI
Enabled: ✓
Command: C:\Tools\codex\codex.exe
API Key: sk-... [安全存储]
History Path: D:\Projects\.codex\history.jsonl
Working Directory: D:\Projects

Advanced:
  Auto Import History: ✓
  Run in Shell: ✓
  Max Concurrent Sessions: 3
  Timeout: 7200

Environment Variables:
  OPENAI_API_KEY: [自动设置]
  DEBUG: 1
  MODEL: gpt-4-turbo

Default Args:
  • --full-auto
  • --verbose
  • --model gpt-4-turbo
```

### 示例 3：团队共享配置（无密钥）

```json
{
  "version": "1.0",
  "configs": {
    "claude": {
      "provider": "claude",
      "displayName": "Claude Code",
      "enabled": true,
      "command": "claude",
      "historyPathTemplate": "${HOME}\\.claude\\projects",
      "autoImportHistory": true,
      "runInShell": true,
      "defaultArgs": [],
      "environmentVariables": {
        "VERBOSE": "true"
      }
    }
  }
}
```
（注意：团队共享时不包含 `apiKey` 字段）

---

## 🚀 快速开始

### 5 分钟配置指南

**步骤 1**: 打开配置管理器
```
主界面 → 齿轮图标⚙️
```

**步骤 2**: 配置 Claude Code
```
1. 点击 "Claude"
2. 点击 "Edit"
3. 输入 API Key: sk-ant-api03-...
4. 点击 "Save"
```

**步骤 3**: 测试配置
```
滚动到底部 → "Test Configuration"
```

**步骤 4**: 导入历史
```
返回主界面 → 点击历史图标 → 自动导入
```

**步骤 5**: 开始使用
```
选择会话 → Resume → 开始对话！
```

---

## ✅ 完成！

你现在已经掌握了 CLI 配置管理的所有功能！

**下一步**：
- 📖 阅读 [快速开始指南](./QUICK_START.md)
- 🔧 查看 [内置终端指南](./EMBEDDED_TERMINAL_GUIDE.md)
- 🆘 遇到问题？查看 [故障排除](./QUICK_FIX_GUIDE.md)

**需要帮助？**
- 检查配置是否正确
- 使用测试功能验证
- 查看日志输出

祝使用愉快！🎉
