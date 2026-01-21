import 'dart:async';

import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/material.dart';
import 'package:server_box/core/extension/context/locale.dart';
import 'package:server_box/core/extension/ssh_client.dart';
import 'package:server_box/data/model/app/shell_func.dart';
import 'package:server_box/view/page/server/edit.dart';
import 'package:server_box/view/page/setting/entry.dart';
import 'package:server_box/view/widget/modern_design_system.dart';
import 'package:server_box/view/widget/modern_theme.dart';
import 'package:server_box/view/widget/modern_server_card.dart';

import 'package:server_box/core/route.dart';
import 'package:server_box/data/model/server/server.dart';
import 'package:server_box/data/provider/server.dart';

part 'modern_top_bar.dart';

/// 现代化服务器页面
class ModernServerPage extends StatefulWidget {
  const ModernServerPage({super.key});

  @override
  State<ModernServerPage> createState() => _ModernServerPageState();
}

class _ModernServerPageState extends State<ModernServerPage>
    with AutomaticKeepAliveClientMixin, AfterLayoutMixin, TickerProviderStateMixin {
  late MediaQueryData _media;
  late AnimationController _refreshController;
  late AnimationController _fabController;
  
  final _scrollController = ScrollController();
  final _tag = ''.vn;
  
  bool _showFab = true;
  Timer? _timer;

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    _scrollController.dispose();
    _refreshController.dispose();
    _fabController.dispose();
    _tag.dispose();
  }

  @override
  void initState() {
    super.initState();
    
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fabController = AnimationController(
      duration: ModernDesignSystem.animationMedium,
      vsync: this,
    );

    _scrollController.addListener(_onScroll);
    _fabController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _media = MediaQuery.of(context);
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && _showFab) {
      setState(() => _showFab = false);
      _fabController.reverse();
    } else if (_scrollController.offset <= 100 && !_showFab) {
      setState(() => _showFab = true);
      _fabController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _ModernTopBar(
        tags: ServerProvider.tags,
        onTagChanged: (tag) => _tag.value = tag,
        initTag: _tag.value,
        onRefresh: _handleRefresh,
      ),
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: _buildBody(),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabController,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabController.value,
            child: ModernFloatingActionButton(
              onPressed: () => ServerEditPage.route.go(context),
              icon: const Icon(Icons.add, color: Colors.white, size: 24),
              tooltip: libL10n.add,
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isDark) {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F0F23),
            Color(0xFF16213E),
            Color(0xFF0F0F23),
          ],
          stops: [0.0, 0.3, 1.0],
        ),
      );
    } else {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFE2E8F0),
            Color(0xFFF1F5F9),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      );
    }
  }

  Widget _buildBody() {
    return ServerProvider.serverOrder.listenVal((order) {
      return _tag.listenVal((tagValue) {
        final filtered = _filterServers(order, tagValue);
        
        if (filtered.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Spacing for app bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
              
              // Server stats header
              SliverToBoxAdapter(
                child: _buildStatsHeader(filtered),
              ),
              
              // Server grid - 防溢出优化
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.02.clamp(8.0, 16.0),
                  vertical: 8.0,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: _getMaxCrossAxisExtent(),
                    childAspectRatio: _getChildAspectRatio(),
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final serverId = filtered[index];
                      final serverNode = ServerProvider.pick(id: serverId);
                      if (serverNode == null) return const SizedBox.shrink();
                      
                      return serverNode.listenVal((server) {
                        if (server == null) return const SizedBox.shrink();
                        
                        return ModernServerCard(
                          server: server,
                          onTap: () => _handleServerTap(server),
                          onLongPress: () => _handleServerLongPress(server),
                        );
                      });
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
              
              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        );
      });
    });
  }

  Widget _buildStatsHeader(List<String> serverIds) {
    final stats = _calculateServerStats(serverIds);
    
    return Container(
      margin: const EdgeInsets.all(ModernDesignSystem.spacingM),
      child: GlassmorphismCard(
        borderRadius: ModernDesignSystem.borderRadiusLarge,
        child: Column(
          children: [
            Text(
              'Server Overview',
              style: ModernDesignSystem.headingMedium.copyWith(
                color: Theme.of(context).textTheme.headlineSmall?.color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: ModernDesignSystem.spacingL),
            Row(
              children: [
                Expanded(child: _buildStatItem('Total', '${stats.total}', Icons.dns)),
                Expanded(child: _buildStatItem('Online', '${stats.online}', Icons.check_circle)),
                Expanded(child: _buildStatItem('Offline', '${stats.offline}', Icons.error_outline)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(ModernDesignSystem.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ModernDesignSystem.borderRadiusMedium),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: ModernDesignSystem.spacingS),
          Text(
            value,
            style: ModernDesignSystem.headingSmall.copyWith(
              color: Theme.of(context).textTheme.headlineSmall?.color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: ModernDesignSystem.bodySmall.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ModernDesignSystem.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: ModernDesignSystem.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: ModernDesignSystem.modernShadow,
              ),
              child: const Icon(
                Icons.dns_outlined,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: ModernDesignSystem.spacingXL),
            Text(
              'No servers found',
              style: ModernDesignSystem.headingMedium.copyWith(
                color: Theme.of(context).textTheme.headlineSmall?.color,
              ),
            ),
            const SizedBox(height: ModernDesignSystem.spacingM),
            Text(
              'Add your first server to monitor its status',
              style: ModernDesignSystem.bodyMedium.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ModernDesignSystem.spacingXL),
            GradientButton(
              text: 'Add Server',
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => ServerEditPage.route.go(context),
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    _refreshController.forward();
    await ServerProvider.refresh();
    if (mounted) {
      _refreshController.reverse();
    }
  }

  void _handleServerTap(Server server) {
    if (server.canViewDetails) {
      AppRoutes.serverDetail(spi: server.spi).go(context);
    } else {
      ServerEditPage.route.go(context, args: server.spi);
    }
  }

  void _handleServerLongPress(Server server) {
    _showServerActions(server);
  }

  void _showServerActions(Server server) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassmorphismCard(
        margin: const EdgeInsets.all(ModernDesignSystem.spacingM),
        borderRadius: ModernDesignSystem.borderRadiusLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: ModernDesignSystem.spacingL),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              server.spi.name,
              style: ModernDesignSystem.headingSmall.copyWith(
                color: Theme.of(context).textTheme.headlineSmall?.color,
              ),
            ),
            const SizedBox(height: ModernDesignSystem.spacingL),
            if (server.conn == ServerConn.finished) ...[
              _buildActionButton('Suspend', Icons.stop, () => _executeServerAction(server, ShellFunc.suspend)),
              _buildActionButton('Shutdown', Icons.power_off, () => _executeServerAction(server, ShellFunc.shutdown)),
              _buildActionButton('Reboot', Icons.restart_alt, () => _executeServerAction(server, ShellFunc.reboot)),
            ],
            _buildActionButton('Edit', Icons.edit, () {
              Navigator.pop(context);
              ServerEditPage.route.go(context, args: server.spi);
            }),
            const SizedBox(height: ModernDesignSystem.spacingL),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: ModernDesignSystem.spacingS),
      child: GradientButton(
        text: label,
        icon: Icon(icon, color: Colors.white),
        onPressed: () {
          Navigator.pop(context);
          onPressed();
        },
      ),
    );
  }

  void _executeServerAction(Server server, ShellFunc func) {
    context.showRoundDialog(
      title: libL10n.attention,
      child: Text(libL10n.askContinue('${func.name} ${l10n.server}(${server.spi.name})')),
      actions: Btn.ok(
        onTap: () {
          context.pop();
          server.client?.execWithPwd(
            func.exec(server.spi.id),
            context: context,
            id: server.id,
          );
        },
      ).toList,
    );
  }

  List<String> _filterServers(List<String> order, String tag) {
    if (tag.isEmpty || tag == TagSwitcher.kDefaultTag) return order;
    return order.where((serverId) {
      final server = ServerProvider.pick(id: serverId)?.value;
      return server?.spi.tags?.contains(tag) ?? false;
    }).toList();
  }

  _ServerStats _calculateServerStats(List<String> serverIds) {
    int online = 0;
    int offline = 0;
    
    for (final serverId in serverIds) {
      final server = ServerProvider.pick(id: serverId)?.value;
      if (server?.conn == ServerConn.finished) {
        online++;
      } else {
        offline++;
      }
    }
    
    return _ServerStats(
      total: serverIds.length,
      online: online,
      offline: offline,
    );
  }

  int _getCrossAxisCount() {
    final width = _media.size.width;
    if (width > 1200) return 3;
    if (width > 800) return 2;
    return 1;
  }

  double _getMaxCrossAxisExtent() {
    final width = _media.size.width;
    final padding = width * 0.04.clamp(16.0, 32.0);
    final availableWidth = width - padding;
    
    if (width > 1200) {
      return (availableWidth / 3).clamp(280.0, 400.0);
    } else if (width > 800) {
      return (availableWidth / 2).clamp(320.0, 450.0);
    } else {
      return availableWidth.clamp(280.0, double.infinity);
    }
  }

  double _getChildAspectRatio() {
    final width = _media.size.width;
    if (width < 600) {
      return 1.4; // 窄屏幕使用更高的比例
    } else if (width < 1200) {
      return 1.25;
    } else {
      return 1.15; // 宽屏幕使用稍低的比例
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Future<void> afterFirstLayout(BuildContext context) async {
    ServerProvider.refresh();
    ServerProvider.startAutoRefresh();
  }
}

class _ServerStats {
  final int total;
  final int online;
  final int offline;

  _ServerStats({
    required this.total,
    required this.online,
    required this.offline,
  });
}