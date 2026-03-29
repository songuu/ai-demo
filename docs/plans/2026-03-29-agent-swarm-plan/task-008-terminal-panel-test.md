# Task 008: SwarmTerminalPanel Widget Tests

**depends-on**: task-007

## Description

为 SwarmTerminalPanel widget 编写 widget 测试。

## Execution Context

**Task Number**: 8 of 25
**Phase**: Phase 2 — Enhanced Terminal
**Prerequisites**: Task 007 CodCliRunner.injectCommand 已添加

## BDD Scenario

```gherkin
Scenario: 实时显示 Agent 终端输出
  Given 用户已启动一个 Agent 任务，终端区域已展开
  When Agent 进程产生新的 stdout/stderr 输出
  Then 系统通过进程管道实时接收输出
  And 在终端区域逐行追加显示
  And 不同类型输出使用不同颜色区分
```

```gherkin
Scenario: 用户向运行中的 Agent 注入命令
  Given 一个 Agent 任务正在运行中
  And 终端区域处于展开状态
  When 用户在终端底部输入框中输入命令
  And 用户按下 Enter 键
  Then 系统将命令通过 stdin 管道发送给 Agent 进程
```

```gherkin
Scenario: Agent 输出过多时自动截断旧内容
  Given Agent 任务已运行超过 30 分钟
  And 终端输出行数已超过 5000 行
  When 新输出到达
  Then 系统自动删除最早的 1000 行
```

**Spec Source**: `test/agent_swarm.feature` (B-3, B-4, B-3 edge-case)

## Files to Modify/Create

- Create: `test/swarm/swarm_terminal_panel_test.dart`

## Steps

### Step 1: Create Widget Test File
- 创建 `test/swarm/swarm_terminal_panel_test.dart`
- 使用 `flutter_test` 和 `flutter_test_widget_tester`
- 由于 xterm.dart Terminal widget 需要 native 渲染，使用 golden test 或 mock Terminal

### Step 2: Write Test Cases (Red - Must Fail)
1. **`terminal_renders_withAgent_attachesOutput`**: 给定 AgentInstance，终端 widget 应渲染并开始监听输出
2. **`injectCommand_sendsToStdin`**: 调用 `injectCommand()` 方法后，stdin 被写入正确内容
3. **`output_overflow_truncatesOldLines`**: 输出超过 5000 行时，最早的 1000 行被截断
4. **`terminatedAgent_showsCannotInjectMessage`**: Agent 已终止时，终端输入框显示「无法注入命令」提示
5. **`stderr_showsInRedColor`**: stderr 输出以红色显示

### Step 3: Verify Tests Fail
- 运行 `flutter test test/swarm/swarm_terminal_panel_test.dart`
- 确认测试因实现缺失而失败（RED 状态）

## Verification Commands

```bash
# Run widget tests (should fail - RED state)
flutter test test/swarm/swarm_terminal_panel_test.dart
```

## Success Criteria

- 所有 5 个 widget 测试已编写
- 测试因 `SwarmTerminalPanel` 不存在而失败
- Mock 正确隔离了 Terminal native 渲染
