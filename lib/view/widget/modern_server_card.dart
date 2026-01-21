import 'package:flutter/material.dart';
import 'package:server_box/data/model/server/server.dart';
import 'package:server_box/view/widget/modern_design_system.dart';
import 'dart:ui';

/// 现代化服务器状态卡片
class ModernServerCard extends StatefulWidget {
  final Server server;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ModernServerCard({
    super.key,
    required this.server,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<ModernServerCard> createState() => _ModernServerCardState();
}

class _ModernServerCardState extends State<ModernServerCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _statusController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _statusAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: ModernDesignSystem.animationMedium,
      vsync: this,
    );
    _statusController = AnimationController(
      duration: ModernDesignSystem.animationSlow,
      vsync: this,
    );

    _hoverAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: ModernDesignSystem.animationCurve,
    ));

    _statusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statusController,
      curve: ModernDesignSystem.animationCurve,
    ));

    _statusController.forward();
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOnline = widget.server.conn == ServerConn.finished;

    return MouseRegion(
      onEnter: (_) {
        // 延迟执行setState避免mouse_tracker断言错误
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _isHovered = true);
            _hoverController.forward();
          }
        });
      },
      onExit: (_) {
        // 延迟执行setState避免mouse_tracker断言错误
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _isHovered = false);
            _hoverController.reverse();
          }
        });
      },
      child: AnimatedBuilder(
        animation: _hoverAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _hoverAnimation.value,
            child: AnimatedBuilder(
              animation: _statusAnimation,
              builder: (context, child) {
                return Container(
                  margin: const EdgeInsets.all(ModernDesignSystem.spacingS),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ModernDesignSystem.borderRadiusLarge),
                    boxShadow: _isHovered 
                      ? ModernDesignSystem.glowShadow
                      : ModernDesignSystem.modernShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(ModernDesignSystem.borderRadiusLarge),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: _getCardGradient(isDark, isOnline),
                          borderRadius: BorderRadius.circular(ModernDesignSystem.borderRadiusLarge),
                          border: Border.all(
                            color: _getBorderColor(isDark, isOnline),
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onTap,
                            onLongPress: widget.onLongPress,
                            borderRadius: BorderRadius.circular(ModernDesignSystem.borderRadiusLarge),
                            child: Padding(
                              padding: const EdgeInsets.all(ModernDesignSystem.spacingL),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeader(),
                                  const SizedBox(height: ModernDesignSystem.spacingL),
                                  if (isOnline) ...[
                                    _buildMetricsRow(),
                                    const SizedBox(height: ModernDesignSystem.spacingM),
                                    _buildDetailsRow(),
                                  ] else
                                    _buildOfflineState(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final isOnline = widget.server.conn == ServerConn.finished;
    final isConnecting = widget.server.conn == ServerConn.connecting ||
                        widget.server.conn == ServerConn.loading ||
                        widget.server.conn == ServerConn.connected;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.server.spi.name,
                style: ModernDesignSystem.headingSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: ModernDesignSystem.spacingXS),
              Text(
                '${widget.server.spi.ip}:${widget.server.spi.port}',
                style: ModernDesignSystem.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            if (isConnecting)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.8)),
                ),
              )
            else
              StatusIndicator(
                isOnline: isOnline,
                size: 16,
                showPulse: isOnline,
              ),
            const SizedBox(height: ModernDesignSystem.spacingXS),
            Text(
              _getStatusText(),
              style: ModernDesignSystem.caption.copyWith(
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsRow() {
    final server = widget.server;
    final status = server.status;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            label: 'CPU',
            value: '${status.cpu.usedPercent().toStringAsFixed(1)}%',
            progress: status.cpu.usedPercent() / 100,
            icon: Icons.memory,
            gradient: _getCpuGradient(status.cpu.usedPercent()),
          ),
        ),
        const SizedBox(width: ModernDesignSystem.spacingM),
        Expanded(
          child: _buildMetricCard(
            label: 'Memory',
            value: '${(status.mem.usedPercent * 100).toStringAsFixed(1)}%',
            progress: status.mem.usedPercent,
            icon: Icons.storage,
            gradient: _getMemoryGradient(status.mem.usedPercent),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsRow() {
    final server = widget.server;
    final status = server.status;

    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            icon: Icons.network_check,
            label: 'Network',
            value: _getNetworkInfo(status),
          ),
        ),
        const SizedBox(width: ModernDesignSystem.spacingM),
        Expanded(
          child: _buildDetailItem(
            icon: Icons.thermostat,
            label: 'Temp',
            value: _getTemperatureInfo(status),
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ModernDesignSystem.spacingL),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ModernDesignSystem.borderRadiusMedium),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off,
            color: Colors.white.withOpacity(0.6),
            size: 32,
          ),
          const SizedBox(height: ModernDesignSystem.spacingS),
          Text(
            _getOfflineMessage(),
            style: ModernDesignSystem.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required double progress,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(ModernDesignSystem.spacingM),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ModernDesignSystem.borderRadiusMedium),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: ModernDesignSystem.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: ModernDesignSystem.caption.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      value,
                      style: ModernDesignSystem.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ModernDesignSystem.spacingS),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(Colors.white),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(ModernDesignSystem.spacingM),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(ModernDesignSystem.borderRadiusMedium),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(width: ModernDesignSystem.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ModernDesignSystem.caption.copyWith(
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                Text(
                  value,
                  style: ModernDesignSystem.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Gradient _getCardGradient(bool isDark, bool isOnline) {
    if (!isOnline) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x40FF6B6B),
          Color(0x40FF8E53),
        ],
      );
    }

    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x40667EEA),
        Color(0x40764BA2),
      ],
    );
  }

  Color _getBorderColor(bool isDark, bool isOnline) {
    if (!isOnline) {
      return const Color(0x60FF6B6B);
    }
    return const Color(0x60667EEA);
  }

  Gradient _getCpuGradient(double usage) {
    if (usage < 50) {
      return ModernDesignSystem.successGradient;
    } else if (usage < 80) {
      return ModernDesignSystem.secondaryGradient;
    } else {
      return ModernDesignSystem.warningGradient;
    }
  }

  Gradient _getMemoryGradient(double usage) {
    if (usage < 0.6) {
      return ModernDesignSystem.successGradient;
    } else if (usage < 0.85) {
      return ModernDesignSystem.secondaryGradient;
    } else {
      return ModernDesignSystem.warningGradient;
    }
  }

  String _getStatusText() {
    switch (widget.server.conn) {
      case ServerConn.connecting:
        return 'Connecting';
      case ServerConn.connected:
        return 'Connected';
      case ServerConn.loading:
        return 'Loading';
      case ServerConn.finished:
        return 'Online';
      case ServerConn.failed:
        return 'Failed';
      case ServerConn.disconnected:
        return 'Offline';
    }
  }

  String _getOfflineMessage() {
    switch (widget.server.conn) {
      case ServerConn.failed:
        return 'Connection failed\nTap to retry';
      case ServerConn.disconnected:
        return 'Disconnected\nTap to connect';
      default:
        return 'Server unavailable';
    }
  }

  String _getNetworkInfo(ServerStatus status) {
    final upload = status.netSpeed.cachedVals.speedOut;
    final download = status.netSpeed.cachedVals.speedIn;
    return '$upload ↑\n$download ↓';
  }

  String _getTemperatureInfo(ServerStatus status) {
    final temp = status.temps.first;
    if (temp != null) {
      return '${temp.toStringAsFixed(1)}°C';
    }
    return 'N/A';
  }
}

/// 现代化服务器网格视图
class ModernServerGrid extends StatelessWidget {
  final List<Server> servers;
  final Function(Server) onServerTap;
  final Function(Server) onServerLongPress;

  const ModernServerGrid({
    super.key,
    required this.servers,
    required this.onServerTap,
    required this.onServerLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (servers.isEmpty) {
      return _buildEmptyState(context);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(ModernDesignSystem.spacingM),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        childAspectRatio: 1.4,
        crossAxisSpacing: ModernDesignSystem.spacingM,
        mainAxisSpacing: ModernDesignSystem.spacingM,
      ),
      itemCount: servers.length,
      itemBuilder: (context, index) {
        final server = servers[index];
        return ModernServerCard(
          server: server,
          onTap: () => onServerTap(server),
          onLongPress: () => onServerLongPress(server),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(ModernDesignSystem.spacingXL),
            decoration: BoxDecoration(
              gradient: ModernDesignSystem.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.dns_outlined,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: ModernDesignSystem.spacingL),
          Text(
            'No servers configured',
            style: ModernDesignSystem.headingMedium.copyWith(
              color: Theme.of(context).textTheme.headlineSmall?.color,
            ),
          ),
          const SizedBox(height: ModernDesignSystem.spacingS),
          Text(
            'Add your first server to get started',
            style: ModernDesignSystem.bodyMedium.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ModernDesignSystem.spacingXL),
          GradientButton(
            text: 'Add Server',
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              // TODO: Navigate to add server page
            },
          ),
        ],
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 3;
    if (width > 800) return 2;
    return 1;
  }
}