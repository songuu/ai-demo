# =============================================================================
# Agent Swarm 功能行为规范 (BDD/Gherkin)
# =============================================================================
# 项目: flutter_server_box
# 版本: 1.0.0
# 最后更新: 2026-03-29
#
# 目的: 为 Agent Swarm 多 agent 并行管理功能定义完整的行为场景
#       参考: Superset.sh (Electron+React) 的多 agent 管理模式
#
# 术语定义:
#   - Agent Swarm (蜂群): 一个管理会话，包含多个并行运行的 Agent 任务
#   - Agent Task (Agent 任务): 单个 agent 实例，在独立 git worktree 中运行
#   - Worktree (工作树): git worktree，为每个 agent 创建的独立工作目录
#   - Swarm Session (蜂群会话): 包含多个 agent 任务的完整管理工作区
#
# 标记说明:
#   @happy-path  : 核心功能的主成功路径
#   @edge-case   : 边界条件和特殊情况
#   @error-case  : 错误处理和异常场景
#   @critical    : 必须实现的核心功能
#
# =============================================================================

# =============================================================================
# A. Swarm Tab 基本功能
# =============================================================================

Feature: Swarm Tab 基本功能
  描述: 用户打开 Agent Swarm Tab 后，可以创建、管理和监控多个 agent 会话

  # ---------------------------------------------------------------------------
  # A-1: 创建新的 Agent Swarm 会话
  # ---------------------------------------------------------------------------
  @happy-path @critical
  Scenario: 用户创建新的 Agent Swarm 会话
    Given 用户已打开 Agent Swarm Tab
    And 当前没有任何活动的 Swarm 会话
    When 用户点击"新建 Swarm"按钮
    Then 系统显示新建 Swarm 会话对话框
    And 对话框包含以下输入项:
      | 字段名       | 类型     | 说明                         |
      | Swarm 名称   | 文本输入  | 会话标题                     |
      | 关联项目     | 下拉选择  | git 仓库列表                 |
      | 描述         | 文本输入  | 可选的会话描述               |
    When 用户填写 Swarm 名称为 "功能 X 开发"
    And 用户选择关联项目为 "flutter_server_box"
    And 用户点击"创建"按钮
    Then 系统在 Hive 中创建一个新的 SwarmSession 记录
    And 记录生成唯一 ID (时间戳格式)
    And 新会话自动出现在左侧会话列表顶部
    And 会话状态显示为"空闲"
    And 右侧面板切换为该会话的空白工作区

  @happy-path @critical
  Scenario: 用户创建 Swarm 时选择关联项目
    Given 用户已打开 Agent Swarm Tab
    When 用户点击"新建 Swarm"按钮
    Then 系统显示项目下拉列表，包含所有本地 git 仓库
    When 用户选择一个项目
    Then 系统显示该项目的详情信息:
      | 字段             | 值                                    |
      | 当前分支         | main                                  |
      | Worktree 数量    | 0 (仅显示主分支)                       |
      | 最后提交         | [提交哈希前7位] - [提交消息]             |
      | 未合并变更       | 无                                    |
    And 系统记录所选项目路径到新会话的 projectPath 字段

  # ---------------------------------------------------------------------------
  # A-2: 在 Swarm 中添加/移除 Agent 任务
  # ---------------------------------------------------------------------------
  @happy-path @critical
  Scenario: 用户向 Swarm 中添加一个新的 Agent 任务
    Given 用户已打开一个已存在的 Swarm 会话 "功能 X 开发"
    And 该会话当前包含 0 个 agent 任务
    When 用户点击工作区中的"+ 添加 Agent"按钮
    Then 系统显示 Agent 任务配置面板，包含:
      | 配置项           | 默认值 / 选项                           |
      | Agent 类型       | Claude Code / Codex / Gemini CLI / 自定义 |
      | 工作目录         | [自动填充为新 worktree 路径]              |
      | 启动命令         | [根据类型自动填充]                       |
      | 启动参数         | [空]                                    |
      | Task 描述        | [空]                                    |
    When 用户选择 Agent 类型为 "Claude Code"
    And 用户填写 Task 描述为 "实现用户认证模块"
    And 用户点击"添加并启动"按钮
    Then 系统自动为该任务创建一个 git worktree 分支
    And 分支命名格式为: `swarm/{swarm-id}/{agent-type}-{序号}`
    And 系统在该 worktree 中启动 agent 进程
    And 新任务卡片出现在工作区中，状态为"启动中"
    And 任务列表数量更新为 1

  @happy-path @critical
  Scenario: 用户从 Swarm 中移除一个 Agent 任务
    Given 用户已打开一个包含 2 个 agent 任务的 Swarm 会话
    And 其中一个任务状态为"已完成"
    When 用户点击该任务卡片的"..."菜单
    And 用户选择"移除此任务"
    Then 系统显示确认对话框:
      """
      确定要移除任务 "实现用户认证模块" 吗？
      提示: 关联的 worktree 将被 [保留 / 删除]（可切换）
      """
    And 默认勾选"同时删除关联的 worktree"复选框
    When 用户点击"确认移除"按钮
    Then 系统从会话任务列表中移除该任务
    And 如果用户勾选了删除 worktree，则执行 git worktree remove
    And 工作区中的任务卡片数量减少 1

  @edge-case
  Scenario: 用户尝试移除正在运行中的 Agent 任务
    Given 用户已打开一个包含 1 个"运行中"状态的 agent 任务的 Swarm
    When 用户点击该任务卡片的"..."菜单
    And 用户选择"移除此任务"
    Then 系统显示警告对话框:
      """
      警告: 该任务正在运行中！
      移除操作不会停止 agent 进程。
      请先停止任务或确认终止进程。
      """
    And 提供三个选项:
      | 选项               | 行为                                         |
      | 停止并移除         | 终止进程 → 删除 worktree → 从列表移除         |
      | 仅移除（保持运行） | 不停止进程 → 仅从列表移除 → worktree 保留     |
      | 取消               | 不执行任何操作                               |

  # ---------------------------------------------------------------------------
  # A-3: 查看所有运行中的 Agent 状态
  # ---------------------------------------------------------------------------
  @happy-path @critical
  Scenario: 用户在 Swarm 面板中查看所有 Agent 任务状态
    Given 用户已打开一个包含 3 个 agent 任务的 Swarm 会话
    And 各任务状态分别为: 运行中、已完成、失败
    When 用户查看 Swarm 工作区
    Then 系统以卡片网格或列表形式展示所有任务，每个卡片显示:
      | 信息项       | 显示内容示例                               |
      | 任务名称     | 实现用户认证模块                           |
      | Agent 类型   | Claude Code (橙色图标)                      |
      | 状态        | [运行中] [已完成] [失败] [已停止] [待启动]  |
      | 运行时间     | 01:23:45                                  |
      | 分支名      | swarm/s1/claude-1                         |
      | Worktree 路径 | .git/worktrees/swarm-s1-claude-1          |
      | 输出预览     | 最近 3 行终端输出文本                      |
    And 页面顶部显示汇总信息:
      """
      3 个任务 | 1 运行中 | 1 已完成 | 1 失败
      总运行时间: 02:45:30
      """

  @edge-case
  Scenario: 所有 Agent 任务都已完成时显示空状态
    Given 用户已打开一个包含 2 个"已完成"任务的 Swarm 会话
    When 所有任务状态都为已完成或失败
    Then 系统在工作区顶部显示汇总条:
      """
      2 个任务全部结束 | 1 成功 | 1 失败
      """
    And 显示"启动新 Agent"按钮，提示可继续添加任务
    And 不显示实时终端输出区域

  @edge-case
  Scenario: 快速过滤和搜索 Agent 任务
    Given 用户已打开一个包含 10 个 agent 任务的 Swarm 会话
    When 用户在任务列表上方的搜索框中输入 "认证"
    Then 系统实时过滤，只显示任务描述或分支名中包含"认证"的任务
    And 过滤条件包括: 任务名称、描述、Agent 类型、状态、分支名


# =============================================================================
# B. Agent 生命周期
# =============================================================================

Feature: Agent 生命周期管理
  描述: 每个 Agent 任务从创建到结束的完整生命周期管理

  # ---------------------------------------------------------------------------
  # B-1: 启动新的 Agent 任务
  # ---------------------------------------------------------------------------
  @happy-path @critical
  Scenario: 用户启动一个新的 Agent 任务（完整流程）
    Given 用户已打开一个 Swarm 会话，关联项目 "flutter_server_box"
    And 该项目的 git 状态正常（无未提交的变更）
    When 用户点击"+ 添加 Agent"
    And 用户选择 Agent 类型为 "Claude Code"
    And 用户填写任务描述为 "重构数据库层"
    And 用户设置启动参数为 "--model opus-4"
    And 用户点击"添加并启动"
    Then 系统执行以下步骤:
      Step 1: 生成唯一的 worktree 分支名 `swarm/s1/claude-1`
      Step 2: 执行 `git worktree add .git/worktrees/swarm-s1-claude-1 swarm/s1/claude-1`
      Step 3: 在新 worktree 目录中创建会话记录文件
      Step 4: 启动 agent 进程: `cd .git/worktrees/swarm-s1-claude-1 && claude --model opus-4`
      Step 5: 将进程 stdout/stderr 通过管道实时推送到 UI 终端区域
      Step 6: 更新任务状态为"运行中"，记录启动时间
    And 任务卡片状态变为绿色脉冲指示器（运行中）
    And 终端区域显示 agent 的实时输出
    And 开始计时

  @edge-case
  Scenario: 用户自定义 Agent 启动命令
    Given 用户已打开 Agent 配置面板
    When 用户选择 Agent 类型为 "自定义"
    Then 系统显示更多配置字段:
      | 字段       | 说明                              |
      | 可执行文件  | 命令行工具路径（如 claude, codex）|
      | 启动参数   | 自定义 CLI 参数                   |
      | 工作目录   | 自定义 worktree 路径或现有目录    |
    When 用户填写可执行文件为 "D:/tools/claude.exe"
    And 用户填写启动参数为 "--no-mcp --full-auto"
    And 用户点击"添加并启动"
    Then 系统验证可执行文件存在
    And 使用用户指定的命令和参数启动 agent
    And 将命令记录到任务配置中供下次使用

  # ---------------------------------------------------------------------------
  # B-2: 自动创建 git worktree 分支
  # ---------------------------------------------------------------------------
  @happy-path @critical
  Scenario: 系统自动为每个 Agent 创建独立的 worktree 分支
    Given 用户已打开一个 Swarm 会话，关联项目位于 "E:/project/flutter_server_box"
    And 当前 main 分支没有同名 worktree
    When 用户添加第一个 Claude Code 任务
    Then 系统自动执行:
      """
      git worktree list  # 检查现有 worktree
      git branch swarm/s1/claude-1  # 在当前分支创建新分支
      git worktree add .git/worktrees/swarm-s1-claude-1 swarm/s1/claude-1
      """
    And 新 worktree 路径为: "E:/project/flutter_server_box/.git/worktrees/swarm-s1-claude-1"
    And 分支 `swarm/s1/claude-1` 已存在且包含 main 的最新提交
    And Worktree 记录写入 CodSession 的 worktreePath 字段

  @edge-case
  Scenario: worktree 分支命名冲突时自动重试
    Given 用户已添加一个 worktree 分支名为 `swarm/s1/claude-1`
    When 用户再次添加一个 Claude Code 任务
    Then 系统检测到分支名已存在
    And 自动将新分支名递增为 `swarm/s1/claude-2`
    And 再次尝试创建 worktree
    And 重复此过程直到找到可用名称
    And 如果 5 次尝试后仍失败，显示错误: "无法为任务分配唯一分支名，请检查 worktree 数量限制"

  @edge-case
  Scenario: 主分支有未提交变更时提示用户
    Given 用户已打开 Swarm 会话
    And 当前 git 分支有未提交的变更（`git status` 返回非空）
    When 用户尝试添加 Agent 任务
    Then 系统显示警告:
      """
      检测到未提交的变更: [变更文件列表]
      请先提交或暂存这些变更，否则 worktree 将基于脏状态创建。
      """
    And 提供选项: "提交变更" / "stash 暂存" / "强制继续（基于脏状态）" / "取消"

  # ---------------------------------------------------------------------------
  # B-3: 实时显示 Agent 输出
  # ---------------------------------------------------------------------------
  @happy-path @critical
  Scenario: 实时显示 Agent 终端输出
    Given 用户已启动一个 Agent 任务，终端区域已展开
    When Agent 进程产生新的 stdout/stderr 输出
    Then 系统通过进程管道实时接收输出
    And 在终端区域逐行追加显示（最多保留最近 5000 行）
    And 自动滚动到底部（用户可手动锁定）
    And 不同类型输出使用不同颜色区分:
      | 输出类型 | 颜色   | 示例                              |
      | stdout   | 白色   | Agent 的思考、回复文本            |
      | stderr   | 红色   | 错误信息、警告                    |
      | 系统     | 灰色   | [Tool: Read] [Tool: Bash] 等     |
      | 用户输入  | 绿色   | 用户注入的命令                    |
    And 终端区域支持: 复制全部、搜索、清屏、固定滚动

  @edge-case
  Scenario: Agent 输出过多时自动截断旧内容
    Given Agent 任务已运行超过 30 分钟
    And 终端输出行数已超过 5000 行
    When 新输出到达
    Then 系统自动删除最早的 1000 行
    And 在终端顶部显示标记: "[... 早期输出已截断 ...]"
    And 用户可以点击展开查看完整历史日志文件

  # ---------------------------------------------------------------------------
  # B-4: 向运行中的 Agent 注入命令
  # ---------------------------------------------------------------------------
  @happy-path @critical
  Scenario: 用户向运行中的 Agent 注入命令
    Given 一个 Agent 任务正在运行中
    And 终端区域处于展开状态
    When 用户在终端底部输入框中输入: "请查看 src/auth/login.dart"
    And 用户按下 Enter 键
    Then 系统执行以下操作:
      Step 1: 将命令写入终端区域（绿色显示，用户输入标记）
      Step 2: 将命令通过 stdin 管道发送给 Agent 进程
      Step 3: Agent 响应后，输出显示在终端中
      Step 4: 更新会话的最后交互时间

  @edge-case
  Scenario: 用户注入命令时 Agent 进程已终止
    Given 一个 Agent 任务状态为"已停止"或"已完成"
    When 用户在终端输入框中输入命令
    And 用户按下 Enter
    Then 系统显示提示: "Agent 已停止，无法接收命令"
    And 提供按钮: "重启 Agent" / "忽略"
    And 命令不会被发送

  @edge-case
  Scenario: 用户注入命令时 stdin 管道不可用
    Given 一个 Agent 任务正在运行中
    And Agent 进程不支持 stdin 交互（如 Claude Code 的某些模式）
    When 用户尝试注入命令
    Then 系统显示提示: "此 Agent 类型不支持命令注入"
    And 用户输入被禁用
    And 提供替代方案: "复制命令到剪贴板" / "在外部终端中手动执行"

  # ---------------------------------------------------------------------------
  # B-5: 停止/终止 Agent 任务
  # ---------------------------------------------------------------------------
  @happy-path @critical
  Scenario: 用户优雅停止 Agent 任务
    Given 一个 Agent 任务正在运行中
    When 用户点击任务卡片的"停止"按钮
    Then 系统显示停止确认:
      """
      停止 Agent 任务: "重构数据库层"
      进程将在收到 SIGTERM 后优雅退出。
      """
    When 用户点击"确认停止"
    Then 系统发送 SIGTERM 信号给 agent 进程
    And 等待最多 30 秒让进程自行退出
    And 如果进程在 30 秒内退出:
      Then 任务状态更新为"已停止"
      And 终端区域追加 "[已停止] 进程已优雅退出"
      And 停止时间被记录
    And 如果 30 秒后进程仍未退出:
      Then 显示二次确认: "进程未响应，是否强制终止？"
      And 提供"强制终止"（SIGKILL）和"继续等待"选项

  @happy-path @critical
  Scenario: 用户强制终止 Agent 任务
    Given 一个 Agent 任务正在运行中
    And 用户已点击停止但进程未响应
    When 用户点击"强制终止"按钮
    Then 系统发送 SIGKILL (kill -9) 信号
    And 进程立即被终止
    And 任务状态更新为"已终止"
    And 终端区域追加 "[已终止] 进程已被强制终止"
    And exitCode 记录为 -9 或 137

  # ---------------------------------------------------------------------------
  # B-6: Agent 任务完成后的状态变化
  # ---------------------------------------------------------------------------
  @happy-path @critical
  Scenario: Agent 任务正常完成后状态自动更新
    Given 一个 Agent 任务正在运行中
    When Agent 进程退出，exitCode = 0
    Then 系统执行以下更新:
      Step 1: 任务状态更新为"已完成"
      Step 2: 更新结束时间
      And 任务卡片状态指示器变为蓝色（完成）
      And 终端区域追加: "[已完成] Agent 任务正常退出 (exitCode: 0)"
      And 计算并显示总运行时间
      And 显示汇总信息: "完成 5 个文件修改，3 个文件创建"

  @error-case
  Scenario: Agent 任务异常退出（exitCode != 0）
    Given 一个 Agent 任务正在运行中
    When Agent 进程退出，exitCode = 1
    Then 任务状态更新为"失败"
    And 任务卡片状态指示器变为红色
    And 终端区域追加: "[失败] Agent 任务异常退出 (exitCode: 1)"
    And 显示诊断提示: "检查日志文件获取详细信息"

  @edge-case
  Scenario: Agent 进程崩溃（被操作系统终止）
    Given 一个 Agent 任务正在运行中
    When 操作系统发送 kill 信号终止进程
    Then 系统检测到进程已不存在
    And 任务状态更新为"已崩溃"
    And 记录崩溃原因（如果可获取）
    And 终端区域追加: "[崩溃] 进程被意外终止"
    And 显示错误详情和可能的解决方案


# =============================================================================
# C. Worktree 隔离
# =============================================================================

Feature: Worktree 隔离管理
  描述: 每个 Agent 在独立的 git worktree 中运行，确保工作空间完全隔离

  # ---------------------------------------------------------------------------
  # C-1: 自动为每个 Agent 创建独立的 worktree
  # ---------------------------------------------------------------------------
  @happy-path @critical
  Scenario: 系统为每个 Agent 任务自动创建独立的 worktree
    Given 用户已打开一个 Swarm 会话
    And 关联项目的主分支为 main
    When 用户添加 3 个不同类型的 Agent 任务
    Then 系统自动创建 3 个 worktree:
      | 序号 | Agent 类型    | 分支名                   | Worktree 路径                            |
      | 1    | Claude Code   | swarm/s1/claude-1        | .git/worktrees/swarm-s1-claude-1         |
      | 2    | Codex         | swarm/s1/codex-2         | .git/worktrees/swarm-s1-codex-2           |
      | 3    | Gemini CLI    | swarm/s1/gemini-3        | .git/worktrees/swarm-s1-gemini-3          |
    And 每个 worktree 的 `.git` 文件指向主仓库
    And 每个 worktree 可独立执行 git 操作（commit、branch、diff 等）
    And 各 worktree 之间的文件修改完全隔离

  @edge-case
  Scenario: 项目不存在 .git/worktrees 目录时自动创建
    Given 关联项目存在
    And 但 .git/worktrees 目录不存在
    When 系统尝试创建第一个 worktree
    Then 系统自动创建目录: `{project}/.git/worktrees/`
    And 然后执行 git worktree add 命令
    And 不需要用户手动干预

  # ---------------------------------------------------------------------------
  # C-2: Worktree 分支命名规范
  # ---------------------------------------------------------------------------
  @happy-path
  Scenario: Worktree 分支命名遵循规范
    Given Swarm 会话 ID 为 "s1"
    When 用户添加不同类型的 Agent 任务
    Then 系统使用以下分支命名规范:
      | Agent 类型      | 命名模式                    | 示例                       |
      | Claude Code     | swarm/{swarm-id}/claude-{n} | swarm/s1/claude-1          |
      | Codex           | swarm/{swarm-id}/codex-{n}  | swarm/s1/codex-1           |
      | Gemini CLI      | swarm/{swarm-id}/gemini-{n} | swarm/s1/gemini-1          |
      | 自定义          | swarm/{swarm-id}/task-{n}   | swarm/s1/task-1            |
    And 序号 {n} 在该 Swarm 会话内按类型递增
    And 分支名称中的特殊字符被替换为连字符

  @edge-case
  Scenario: 用户自定义分支名
    Given 用户已打开 Agent 任务配置面板
    When 用户勾选"自定义分支名"选项
    Then 系统显示分支名输入框，预填默认名称
    When 用户修改分支名为 "feature/auth-refactor"
    Then 系统验证分支名格式是否合法（无空格、无非法字符）
    And 如果格式非法，显示错误: "分支名包含非法字符"
    And 如果分支名已存在，显示错误: "分支名已存在，请选择其他名称"

  # ---------------------------------------------------------------------------
  # C-3: Agent 完成后 worktree 的处理选项
  # ---------------------------------------------------------------------------
  @happy-path @critical
  Scenario: Agent 完成后用户选择保留 worktree
    Given 一个 Agent 任务已完成，关联 worktree 包含变更
    When 用户点击任务卡片的"完成"菜单
    And 用户选择"保留 worktree"
    Then 系统执行以下操作:
      Step 1: 在 worktree 中执行 `git status` 获取变更摘要
      Step 2: 提示用户: "worktree 将保留，包含 N 个文件变更"
      Step 3: 询问用户是否立即合并到主分支或稍后处理
      Step 4: worktree 目录保持不变
      And worktree 路径被记录到会话历史中
      And 用户可以在其他工具（如 VS Code）中继续使用

  @happy-path @critical
  Scenario: Agent 完成后用户选择删除 worktree
    Given 一个 Agent 任务已完成
    When 用户点击任务卡片的"完成"菜单
    And 用户选择"删除 worktree"
    Then 系统显示确认:
      """
      确定要删除 worktree 及其所有变更吗？
      路径: E:/project/.git/worktrees/swarm-s1-claude-1
      注意: 此操作不可撤销！
      """
    When 用户点击"确认删除"
    Then 系统执行 `git worktree remove --force {worktree-path}`
    And 删除 worktree 目录
    And 任务状态保持为"已完成"，worktreePath 字段清空
    And 显示提示: "worktree 已删除。如果需要保留变更，请先手动备份。"

  @edge-case
  Scenario: 删除包含未提交变更的 worktree 时警告
    Given 一个已完成任务的 worktree 包含未提交的变更
    When 用户尝试删除该 worktree
    Then 系统显示警告:
      """
      worktree 包含未提交的变更！
      删除将丢失以下文件变更:
      - src/auth/login.dart (已修改)
      - src/auth/register.dart (新文件)
      """
    And 提供选项:
      | 选项               | 行为                                         |
      | 先提交变更再删除   | 自动创建提交 → 删除 worktree                 |
      | stash 暂存再删除   | stash push → 删除 worktree（可在主分支恢复）  |
      | 强制删除（丢失变更）| 直接删除 worktree（不保留变更）              |
      | 取消               | 不执行任何操作                               |

  # ---------------------------------------------------------------------------
  # C-4: Worktree 列表管理
  # ---------------------------------------------------------------------------
  @happy-path @critical
  Scenario: 用户在 Swarm 面板中查看所有 worktree 列表
    Given 用户已打开一个包含 3 个任务的 Swarm 会话
    When 用户点击侧边栏中的"Worktrees"标签
    Then 系统显示 worktree 管理面板，列出所有 worktree:
      | 分支名                  | 路径                            | 状态      | 任务数 |
      | swarm/s1/claude-1       | .git/worktrees/swarm-s1-claude-1 | 活跃      | 1      |
      | swarm/s1/codex-2         | .git/worktrees/swarm-s1-codex-2  | 活跃      | 1      |
      | swarm/s1/gemini-3        | .git/worktrees/swarm-s1-gemini-3  | 空闲      | 1      |
    And 每个 worktree 卡片提供操作按钮:
      | 按钮         | 功能                                 |
      | 打开目录     | 在文件管理器中打开该 worktree        |
      | 查看状态     | 显示 `git status` 和变更统计         |
      | 合并         | 打开合并操作面板                     |
      | 删除         | 删除该 worktree                      |

  @edge-case
  Scenario: 显示已失效的 worktree 记录
    Given 一个 worktree 目录已被手动删除
    But 数据库中仍保留该 worktree 的记录
    When 用户打开 Swarm 会话
    Then 系统检测到 worktree 目录不存在
    And 在 worktree 列表中显示为 "失效" 状态（红色标记）
    And 提供"清理记录"按钮以同步状态
    And 提示: "检测到 1 个失效的 worktree 记录，是否清理？"


# =============================================================================
# D. Diff 和合并
# =============================================================================

Feature: Diff 查看和 Git 合并操作
  描述: 用户可以查看 agent 产生的变更并进行合并操作

  # ---------------------------------------------------------------------------
  # D-1: 查看 Agent 变更的 Diff
  # ---------------------------------------------------------------------------
  @happy-path @critical
  Scenario: 用户查看单个 Agent 任务的变更 Diff
    Given 一个 Agent 任务已完成，worktree 包含变更
    When 用户点击该任务卡片的"查看 Diff"按钮
    Then 系统打开内置 Diff Viewer，显示:
      | 信息项       | 内容示例                                      |
      | 任务         | 重构数据库层                                   |
      | 变更统计     | 5 个文件修改, 3 个文件创建, 2 个文件删除      |
      | Base commit  | abc1234 (main 最新提交)                       |
    And Diff 区域以 unified diff 格式显示:
      | 区域         | 样式                                          |
      | 文件头       | 蓝色背景，文件路径                             |
      | 增加行       | 绿色背景，以 + 开头                           |
      | 删除行       | 红色背景，以 - 开头                           |
      | 上下文行     | 默认背景色                                    |
    And 支持展开/折叠文件
    And 支持跳转到上一个/下一个变更

  @happy-path @critical
  Scenario: 用户跨多个 Agent 任务查看汇总 Diff
    Given 一个 Swarm 会话包含 3 个已完成任务的 Agent
    When 用户点击"汇总 Diff"标签
    Then 系统显示所有 agent 变更的合并视图:
      Step 1: 获取每个 worktree 的 `git diff main`
      Step 2: 按文件聚合变更，按 agent 任务分组显示
      Step 3: 检测文件冲突（同一文件被多个 agent 修改）
    And 汇总视图显示:
      | 分组维度   | 显示效果                                             |
      | 按文件     | 同一文件的所有变更集中显示                           |
      | 按 agent   | 不同 agent 修改的文件用不同颜色边框区分               |
      | 冲突文件   | 红色边框高亮，显示冲突标记                           |

  @edge-case
  Scenario: Diff 区域显示二进制文件变更
    Given Agent 任务产生了一个二进制文件（如图片、压缩包）的变更
    When 用户查看 Diff
    Then 系统检测到文件为二进制
    And 不显示具体的 diff 内容
    And 显示: "[二进制文件] src/assets/logo.png | 变更大小: +24KB"
    And 提供"查看文件信息"和"还原此文件"按钮

  # ---------------------------------------------------------------------------
  # D-2: 执行 Git Merge 到主分支
  # ---------------------------------------------------------------------------
  @happy-path @critical
  Scenario: 用户将单个 Agent 的变更合并到主分支
    Given 一个 Agent 任务已完成，worktree 分支为 `swarm/s1/claude-1`
    And worktree 中包含干净的变更（无冲突）
    When 用户点击任务卡片的"合并到主分支"按钮
    Then 系统显示合并预览:
      """
      合并操作预览:
      FROM: swarm/s1/claude-1
      TO:   main
      变更文件: 5 个
      """
    When 用户点击"确认合并"
    Then 系统切换到主分支，执行以下命令:
      """
      git checkout main
      git merge swarm/s1/claude-1 --no-ff -m "Merge swarm/s1: 重构数据库层"
      """
    And 合并成功后:
      Step 1: 主分支更新到最新提交
      Step 2: 任务状态更新为"已合并"
      Step 3: worktree 保持不变（默认保留）
      Step 4: 显示成功通知: "成功合并到 main！"

  @happy-path @critical
  Scenario: 用户批量合并多个 Agent 的变更
    Given 一个 Swarm 会话包含 3 个已完成任务的 Agent
    And 所有变更都无冲突
    When 用户在汇总 Diff 面板中选择多个 agent 变更
    And 用户点击"批量合并选中项"
    Then 系统按顺序逐个合并:
      Step 1: 合并 swarm/s1/claude-1 → main
      Step 2: 合并 swarm/s1/codex-2 → main (基于最新 main)
      Step 3: 合并 swarm/s1/gemini-3 → main (基于最新 main)
    And 每个合并操作独立执行和记录
    And 完成后显示合并报告:
      """
      批量合并完成:
      ✓ swarm/s1/claude-1 → main (无冲突)
      ✓ swarm/s1/codex-2 → main (无冲突)
      ✓ swarm/s1/gemini-3 → main (无冲突)
      """

  # ---------------------------------------------------------------------------
  # D-3: 执行 Git Rebase
  # ---------------------------------------------------------------------------
  @happy-path
  Scenario: 用户将 Agent 分支 Rebase 到主分支最新提交
    Given 一个 Agent 任务已完成，worktree 分支为 `swarm/s1/claude-1`
    And 主分支在 agent 工作期间有新提交
    When 用户点击"Rebase 到 main"按钮
    Then 系统显示 rebase 预览:
      """
      Rebase 操作预览:
      FROM: swarm/s1/claude-1 (基于 abc1234)
      ONTO: main (基于 def5678) [新增 3 个提交]
      """
    When 用户点击"确认 Rebase"
    Then 系统在 worktree 中执行:
      """
      git checkout swarm/s1/claude-1
      git rebase main
      """
    And Rebase 成功后:
      And 任务分支的提交历史更新，base 变为最新 main
      And 终端区域追加 rebase 结果
      And 显示成功通知

  # ---------------------------------------------------------------------------
  # D-4: 冲突检测和处理
  # ---------------------------------------------------------------------------
  @error-case @critical
  Scenario: 合并时检测到文件冲突
    Given Agent A 修改了文件 "src/auth/login.dart" 的第 10-20 行
    And Agent B 也修改了同一个文件的第 15-25 行
    And 用户尝试将 Agent B 的变更合并到 main
    When 用户点击"合并到主分支"
    Then 系统检测到冲突:
      """
      冲突检测结果:
      冲突文件: src/auth/login.dart
      Agent B 的变更: swarm/s1/claude-1
      主分支的变更: main (提交: abc1234)
      """
    And Diff Viewer 显示冲突区域:
      | 标记          | 内容                                          |
      | <<<<<<< HEAD  | main 分支的变更内容（蓝色）                    |
      | =======       | 分隔符                                        |
      | >>>>>>>       | agent 分支的变更内容（橙色）                   |
    And 提供冲突解决选项:
      | 选项               | 行为                                       |
      | 保留主分支版本      | 删除 agent 的变更，采用 main 版本           |
      | 保留 agent 版本     | 删除 main 的变更，采用 agent 版本           |
      | 手动解决            | 打开编辑器让用户手动合并                    |
      | 取消合并            | 终止合并操作，状态回滚                      |
    When 用户选择"手动解决"
    Then 系统打开内置合并编辑器
    And 用户编辑完成后点击"标记为已解决"
    Then 系统执行 `git add src/auth/login.dart`
    And 继续合并流程

  @error-case
  Scenario: 多个 Agent 之间存在文件冲突（汇总 Diff 视图）
    Given Agent A 和 Agent B 都修改了 "src/config/settings.dart"
    When 用户打开汇总 Diff 视图
    Then 系统检测并高亮冲突:
      Step 1: 文件卡片显示红色边框（冲突警告）
      Step 2: 在文件下方显示冲突摘要:
        """
        ⚠ 文件冲突: src/config/settings.dart
        Agent A (swarm/s1/claude-1): 修改了第 5-10 行
        Agent B (swarm/s1/codex-2):   修改了第 8-15 行
        """
    And 提供"检查冲突"按钮，点击后显示详细的冲突视图
    And 用户需要选择合并策略或手动解决才能进行批量合并

  @edge-case
  Scenario: Rebase 过程中发生冲突
    Given 用户对 Agent 分支执行 rebase 操作
    And rebase 过程中在某个提交处发生冲突
    Then 系统暂停 rebase，终端显示冲突信息
    And 任务卡片状态更新为"Rebase 暂停（冲突）"
    And 提供选项:
      | 选项               | 行为                                         |
      | 解决冲突后继续      | 用户解决冲突 → git rebase --continue         |
      | 跳过此提交         | git rebase --skip                            |
      | 终止 Rebase        | git rebase --abort，恢复到 rebase 前状态     |


# =============================================================================
# E. 项目管理
# =============================================================================

Feature: 跨项目管理和会话持久化
  描述: 用户可以管理多个 git 项目的 Swarm 会话，并保存/恢复会话历史

  # ---------------------------------------------------------------------------
  # E-1: 切换管理不同 git 项目
  # ---------------------------------------------------------------------------
  @happy-path @critical
  Scenario: 用户切换到不同的 git 项目
    Given 用户当前管理的是项目 "flutter_server_box"
    And 用户系统中还有其他 git 项目 "my_frontend_app" 和 "backend_api"
    When 用户点击项目选择器
    Then 系统显示项目列表:
      """
      当前项目: flutter_server_box [✓]
      其他项目:
      - my_frontend_app
      - backend_api
      - [添加新项目...]
      """
    When 用户选择 "backend_api"
    Then 系统切换到该项目:
      Step 1: 加载该项目下的所有 Swarm 会话历史
      Step 2: 更新项目选择器显示当前项目
      Step 3: 工作区显示该项目最新的 Swarm 会话或空状态
      Step 4: worktree 目录指向新项目的 .git/worktrees/

  @edge-case
  Scenario: 切换项目时存在运行中的任务
    Given 用户当前项目的 Swarm 会话中有运行中的 Agent 任务
    When 用户尝试切换到其他项目
    Then 系统显示警告:
      """
      当前有 2 个 Agent 任务正在运行中。
      切换项目将隐藏这些任务，但不会停止它们。
      """
    And 提供选项: "切换（后台继续运行）" / "全部停止后切换" / "取消"

  @edge-case
  Scenario: 添加新的 git 项目到 Swarm
    Given 用户点击项目选择器中的"添加新项目..."
    When 用户输入项目路径 "E:/project/new_project"
    Or 用户通过目录选择器选择路径
    Then 系统验证:
      Step 1: 路径是否存在
      Step 2: 是否为有效的 git 仓库（存在 .git 目录）
    And 如果验证通过:
      Then 系统将项目添加到项目列表
      And 执行 `git status` 获取项目当前状态
      And 切换到新项目
    And 如果路径无效，显示错误: "路径不存在或不是有效的 git 仓库"

  # ---------------------------------------------------------------------------
  # E-2: 同一项目内的多 Agent 协作
  # ---------------------------------------------------------------------------
  @happy-path @critical
  Scenario: 同一项目内多个 Agent 分工协作
    Given 用户已打开项目 "flutter_server_box" 的一个 Swarm 会话
    When 用户添加 3 个 Agent 任务，分别分配不同职责:
      | Agent        | 任务描述                       | 关注目录              |
      | Claude Code  | 实现用户认证模块               | src/auth/            |
      | Codex        | 重构数据库访问层               | lib/data/            |
      | Gemini CLI   | 编写单元测试                   | test/                |
    Then 每个 Agent 在独立的 worktree 中运行
    And 各 Agent 并行执行，互不干扰
    And 用户可以在汇总 Diff 中查看所有变更
    And 用户可以选择性地合并各 Agent 的变更
    And 最终所有变更汇聚到 main 分支

  @edge-case
  Scenario: 多个 Agent 修改了同一文件（自动检测）
    Given 2 个 Agent 任务正在并行运行
    And 系统实时监控各 worktree 的 git status
    When Agent A 修改了 "src/utils/helper.dart"
    And Agent B 也修改了 "src/utils/helper.dart"
    Then 系统检测到潜在冲突
    And 显示警告通知:
      """
      ⚠ 冲突预警: src/utils/helper.dart
      由 Agent "Agent B" (worktree: swarm/s1/codex-2) 修改
      该文件也可能被 Agent "Agent A" 修改中
      """
    And 用户可以选择:
      | 选项                 | 行为                                               |
      | 通知 Agent B         | 向 Agent B 注入提示：文件被其他 Agent 修改          |
      | 暂停 Agent B         | 暂停 Agent B 直到冲突解决                          |
      | 忽略                 | 继续运行，稍后处理冲突                              |

  # ---------------------------------------------------------------------------
  # E-3: 会话历史保存和恢复
  # ---------------------------------------------------------------------------
  @happy-path @critical
  Scenario: 系统自动保存 Swarm 会话状态
    Given 用户正在操作一个 Swarm 会话
    When 以下事件发生时:
      | 触发时机                 | 保存内容                                     |
      | 添加/移除 Agent 任务      | 任务列表及其配置                              |
      | Agent 任务状态变化        | 状态、时间戳、exitCode                        |
      | 用户在终端注入命令        | 命令历史（最近 100 条）                       |
      | 启动定时保存（每 30 秒）  | 完整会话状态（所有上述内容）                   |
    Then 系统将状态保存到 Hive 数据库的对应 SwarmSession 记录
    And 保存操作在后台异步执行，不阻塞 UI

  @happy-path @critical
  Scenario: 用户恢复之前的 Swarm 会话
    Given 用户关闭了应用程序
    And 之前有一个 Swarm 会话，状态为"已完成"
    When 用户重新打开应用
    And 用户打开 Agent Swarm Tab
    Then 系统从 Hive 加载所有历史会话
    And 在会话列表中显示:
      | 字段       | 值                                          |
      | 会话名称   | 功能 X 开发                                  |
      | 项目       | flutter_server_box                           |
      | 任务数     | 3 个任务（2 成功, 1 失败）                   |
      | 最后活动   | 2026-03-29 14:30                            |
      | 状态       | 已结束                                       |
    When 用户点击该会话
    Then 系统恢复会话详情:
      Step 1: 加载所有任务记录
      Step 2: 重建 worktree 路径信息
      Step 3: 显示各任务的最终状态和变更摘要
      And 提供操作: "查看 Diff" / "合并变更" / "继续任务" / "删除会话"

  @edge-case
  Scenario: 恢复会话时 worktree 已不存在
    Given 一个历史会话记录中的 worktree 路径为 "E:/project/.git/worktrees/swarm-s1-claude-1"
    And 该目录已被手动删除
    When 用户尝试恢复该会话
    Then 系统检测到 worktree 失效
    And 显示警告: "部分 worktree 目录不存在"
    And 对失效的 worktree:
      And 任务状态显示为"工作区丢失"
      And 提供"重新创建 worktree"按钮
      Or 提供"清理记录"按钮
    And 有效的 worktree 仍可正常操作

  @edge-case
  Scenario: 用户导出 Swarm 会话报告
    Given 用户已打开一个已完成的 Swarm 会话
    When 用户点击会话菜单中的"导出报告"
    Then 系统生成 Markdown 格式的报告，包含:
      | 章节               | 内容                                               |
      | 会话概览           | 会话名称、项目、创建时间、总运行时长               |
      | 任务列表           | 每个任务的状态、类型、分支名、运行时间、变更统计    |
      | 变更汇总           | 所有 worktree 的变更文件列表                       |
      | 合并状态           | 各分支是否已合并到 main                            |
      | 终端日志摘要       | 关键事件的时间线（启动、完成、错误等）              |
    And 文件保存到用户指定的位置
    And 显示成功通知: "报告已导出到: E:/Downloads/swarm-report-xxx.md"


# =============================================================================
# F. 错误和边界情况
# =============================================================================

Feature: 错误处理和边界情况
  描述: 系统对各种异常情况的健壮处理

  # ---------------------------------------------------------------------------
  # F-1: Git Worktree 冲突处理
  # ---------------------------------------------------------------------------
  @error-case @critical
  Scenario: Git worktree 创建失败 - 分支已存在
    Given 用户尝试添加一个新的 Agent 任务
    And 系统尝试创建分支 `swarm/s1/claude-1`
    But 该分支在远程仓库已存在（且不在本地）
    When 系统执行 `git branch swarm/s1/claude-1`
    Then 系统尝试从远程追踪该分支
    And 自动重命名本地分支为 `swarm/s1/claude-1-local`
    And 创建 worktree 使用新分支名
    And 显示通知: "分支名冲突，已创建分支 swarm/s1/claude-1-local"

  @error-case
  Scenario: Git worktree 创建失败 - 目录已存在
    Given 系统尝试创建 worktree，路径为 `.git/worktrees/swarm-s1-claude-1`
    But 该目录已存在（可能是之前遗留的）
    When 系统执行 `git worktree add`
    Then Git 返回错误: "fatal: 'swarm-s1-claude-1' already exists"
    And 系统尝试清理:
      Step 1: 检查目录是否为空
      Step 2: 如果为空，直接使用该目录
      Step 3: 如果非空，询问用户是否覆盖或选择其他路径
    And 如果无法解决，显示完整错误信息

  @error-case
  Scenario: Worktree 数量达到 Git 上限
    Given 用户添加了多个 Agent 任务
    And Git 配置了 worktree 数量限制（如 `core.worktreeSearchPath`）
    When 系统尝试创建新的 worktree
    And 达到数量上限
    Then 系统显示错误:
      """
      无法创建新的 worktree: 已达到 Git worktree 数量上限。
      当前限制: N 个
      当前使用: N 个
      提示: 请删除不再需要的 worktree 或联系仓库管理员调整限制。
      """
    And 提供"查看现有 worktree"和"删除 least recent"选项

  # ---------------------------------------------------------------------------
  # F-2: Agent 进程崩溃恢复
  # ---------------------------------------------------------------------------
  @error-case @critical
  Scenario: Agent 进程异常退出后自动检测
    Given 一个 Agent 任务状态为"运行中"
    And 进程意外崩溃或被终止
    When 系统检测到进程不再存活（通过进程监控）
    Then 系统执行恢复流程:
      Step 1: 更新任务状态为"已崩溃"
      Step 2: 记录崩溃时间和可能的退出码
      Step 3: 终端区域追加崩溃通知
      Step 4: 显示恢复选项:
        """
        Agent 进程已意外终止。
        是否要重启此任务？
        [重新启动] [保持崩溃状态] [删除任务]
        """
    And 用户可以选择是否重启

  @edge-case
  Scenario: Agent 进程僵死（无响应但进程存活）
    Given 一个 Agent 任务状态为"运行中"
    And 进程在 5 分钟内没有产生任何输出
    When 系统检测到输出停滞
    Then 终端区域显示警告: "[注意] Agent 输出已停滞 5 分钟"
    And 任务卡片显示黄色警告标记
    And 提供"发送 ping" / "终止并重启" / "忽略" 选项
    And 如果用户选择"发送 ping":
      Then 系统向进程发送空行（如果支持 stdin）
      And 等待响应
      And 如果进程在 1 分钟内无响应，更新状态为"疑似僵死"

  # ---------------------------------------------------------------------------
  # F-3: 网络和资源限制
  # ---------------------------------------------------------------------------
  @error-case
  Scenario: Agent 进程启动时命令不存在
    Given 用户配置了 Agent 类型为 "Claude Code"
    And 系统尝试执行命令 `claude`
    But `claude` 命令不在系统 PATH 中
    When 系统尝试启动 agent 进程
    Then 系统检测到命令不可用
    And 显示错误:
      """
      无法启动 Claude Code: 命令 'claude' 未找到。
      请确认 Claude Code CLI 已安装并添加到系统 PATH。
      """
    And 提供以下选项:
      | 选项                 | 行为                                           |
      | 检查安装路径         | 让用户指定 claude 可执行文件的完整路径         |
      | 查看安装指南         | 打开 Claude Code 安装文档链接                  |
      | 取消                 | 不启动该任务                                   |

  @edge-case
  Scenario: Agent 进程启动时工作目录不存在
    Given 用户配置了 Agent 任务
    And 指定的工作目录路径不存在
    When 系统尝试启动 agent 进程
    Then 系统检测到目录不存在
    And 显示错误: "工作目录不存在: E:/project/xxx"
    And 提供选项:
      | 选项                 | 行为                                           |
      | 自动创建目录         | 系统创建该目录                                 |
      | 选择其他目录         | 打开目录选择器                                 |
      | 取消                 | 不启动该任务                                   |

  @error-case
  Scenario: 磁盘空间不足
    Given 用户启动 Agent 任务
    And 系统检测到磁盘空间低于阈值（如 1GB）
    When 系统尝试创建 worktree 或写入日志文件
    Then 系统显示警告:
      """
      警告: 磁盘空间不足！
      可用空间: XXX MB
      请释放磁盘空间后再继续操作。
      """
    And 阻止创建新的 worktree
    And 仍允许查看和操作现有任务

  @edge-case
  Scenario: 系统内存不足导致 Agent 运行缓慢
    Given 多个 Agent 任务正在同时运行
    And 系统内存使用率超过 90%
    When 系统检测到内存压力
    Then 在终端区域显示性能警告:
      """
      系统内存使用率较高 (90%)。
      Agent 响应可能变慢。
      """
    And 提供建议: "考虑停止部分 Agent 任务以释放内存"
    And 不自动终止任何任务

  # ---------------------------------------------------------------------------
  # F-4: 工作目录不存在
  # ---------------------------------------------------------------------------
  @error-case
  Scenario: 打开会话时关联项目目录不存在
    Given 用户保存了一个 Swarm 会话，关联项目路径为 "E:/project/my_project"
    When 用户重新打开应用并尝试恢复该会话
    Then 系统检测到项目目录不存在
    And 显示错误:
      """
      无法找到关联项目: E:/project/my_project
      项目目录可能被移动或删除。
      """
    And 提供选项:
      | 选项                 | 行为                                           |
      | 重新定位项目         | 让用户重新选择项目目录                         |
      | 移除会话             | 删除该会话的所有记录                           |
      | 保持离线状态         | 保留会话但标记为"项目丢失"                     |

  @error-case
  Scenario: Git 仓库损坏或 .git 目录不存在
    Given 用户尝试将一个目录添加为 Swarm 项目
    But 该目录的 .git 目录损坏或不存在
    When 系统验证项目
    Then 系统显示错误: "目录不是有效的 git 仓库"
    And 阻止将其添加为 Swarm 项目
    And 提供建议: "请确保目录包含完整的 .git 目录"

  @edge-case
  Scenario: Worktree 目录被外部工具移动或删除
    Given 一个 worktree 目录存在于 `.git/worktrees/swarm-s1-claude-1`
    And 该目录被用户通过文件管理器手动删除
    When 系统通过 git worktree list 检测到
    Then git 会报告 worktree 失效
    And 系统在下次打开会话时检测并标记为"失效"
    And 提供清理选项: `git worktree prune`
