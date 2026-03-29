# Task 011: SwarmMultiTerminal Layout Widget

**depends-on**: task-010

## Description

实现 SwarmMultiTerminal widget——支持 split-h、split-v、grid、tabs 四种布局方式的多终端面板。

## Execution Context

**Task Number**: 11 of 25
**Phase**: Phase 2 — Enhanced Terminal
**Prerequisites**: Task 010 AgentStatusCard 已完成

## Files to Modify/Create

- Create: `lib/swarm/widget/swarm_multi_terminal.dart`

## Steps

### Step 1: Create SwarmMultiTerminal
创建 `lib/swarm/widget/swarm_multi_terminal.dart`：

```dart
enum TerminalLayoutMode { splitH, splitV, grid, tabs }

class SwarmMultiTerminal extends StatefulWidget {
  final List<AgentInstance> agents;
  final TerminalLayoutMode initialMode;

  const SwarmMultiTerminal({
    super.key,
    required this.agents,
    this.initialMode = TerminalLayoutMode.grid,
  });
}
```

### Step 2: Implement Layout Switcher
- 顶部工具栏显示布局切换按钮（图标 + tooltip）：
  - split-h: 水平并排
  - split-v: 垂直堆叠
  - grid: 网格布局（2x2, 3x2 等自适应）
  - tabs: Tab 切换
- 当前选中的布局高亮显示

### Step 3: Implement Each Layout
1. **split-h**: `Row` + `Expanded`（每个 agent 一个 panel）
2. **split-v**: `Column` + `Expanded`（每个 agent 一个 panel）
3. **grid**: `LayoutBuilder` 根据 agent 数量计算行列数，使用 `GridView`
4. **tabs**: `TabBar` + `TabBarView`

### Step 4: Integrate AgentStatusCard
- 在每个面板顶部显示对应的 `AgentStatusCard`
- 点击卡片切换焦点到对应终端

### Step 5: Verify
- 运行 `flutter analyze lib/swarm/widget/swarm_multi_terminal.dart`

## Verification Commands

```bash
flutter analyze lib/swarm/widget/swarm_multi_terminal.dart
```

## Success Criteria

- 四种布局模式均可切换
- 布局切换时保留终端内容
- agent 数量变化时自动调整布局
- 响应式支持（agent 数量多时自动缩小面板尺寸）
