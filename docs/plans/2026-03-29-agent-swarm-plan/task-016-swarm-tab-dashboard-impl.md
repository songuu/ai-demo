# Task 016: SwarmTab Entry and SwarmDashboard Layout

**depends-on**: task-015

## Description

实现 Swarm Tab 入口页面和 SwarmDashboard 三栏布局主视图。

## Execution Context

**Task Number**: 16 of 25
**Phase**: Phase 3 — Swarm Orchestration
**Prerequisites**: Task 015 SwarmSessionStore 已完成

## BDD Scenario

```gherkin
Scenario: 用户创建新的 Agent Swarm 会话
  Given 用户已打开 Agent Swarm Tab
  And 当前没有任何活动的 Swarm 会话
  When 用户点击"新建 Swarm"按钮
  Then 系统显示新建 Swarm 会话对话框
  And 新会话自动出现在左侧会话列表顶部
  And 会话状态显示为"空闲"
```

**Spec Source**: `test/agent_swarm.feature` (A-1, A-2, A-3)

## Files to Modify/Create

- Create: `lib/view/page/swarm/swarm_tab.dart` — Tab 入口
- Create: `lib/swarm/view/swarm_dashboard.dart` — 三栏主布局
- Modify: `lib/main.dart` 或路由配置 — 注册 /swarm 路由

## Steps

### Step 1: Create SwarmTab
创建 `lib/view/page/swarm/swarm_tab.dart`：

```dart
class SwarmTab extends StatefulWidget {
  const SwarmTab({super.key});

  @override
  State<SwarmTab> createState() => _SwarmTabState();
}

class _SwarmTabState extends State<SwarmTab> {
  final _currentSessionId = ValueNotifier<String?>(null);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        if (isWide) {
          return Row(
            children: [
              SizedBox(width: 280, child: _SessionSidebar(...)),
              VerticalDivider(...),
              Expanded(child: SwarmDashboard(...)),
            ],
          );
        } else {
          return Scaffold(
            drawer: Drawer(child: _SessionSidebar(...)),
            body: SwarmDashboard(...),
          );
        }
      },
    );
  }
}
```

### Step 2: Create _SessionSidebar
- 显示会话列表（使用 `SwarmSessionStore.listenable()`）
- 每个 item 显示：会话名称、项目名、状态、最后更新时间
- 底部：「新建 Swarm」按钮
- 支持点击切换当前会话

### Step 3: Create SwarmDashboard
创建 `lib/swarm/view/swarm_dashboard.dart`：

三栏布局（参考 `lib/view/page/chat/chat_tab.dart` 的模式）：
- **左栏**（280px）：会话列表（窄屏时 drawer）
- **中栏**：Agent 任务卡片列表（`ListView.builder` + `AgentStatusCard`）
- **右栏**：多终端面板（`SwarmMultiTerminal`）或空状态

### Step 4: Register Route
- 在 `lib/route.dart` 或 `main.dart` 中注册 `/swarm` 路由指向 `SwarmTab`

### Step 5: Update AppTab
- 确保 `AppTab.swarm` 在 Tab 导航中可用

### Step 6: Verify
- 运行 `flutter analyze lib/view/page/swarm/ lib/swarm/view/swarm_dashboard.dart`

## Verification Commands

```bash
flutter analyze lib/view/page/swarm/ lib/swarm/view/swarm_dashboard.dart
```

## Success Criteria

- SwarmTab 作为独立页面可访问
- 三栏布局正确渲染
- 会话列表可点击切换
- 新建 Swarm 按钮触发对话框
