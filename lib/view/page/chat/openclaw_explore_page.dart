import 'package:flutter/material.dart';

import 'package:server_box/chat/service/openclaw_service.dart';
import 'package:server_box/chat/store/openclaw_store.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

/// OpenClaw exploration page.
///
/// Provides a UI for connecting to the OpenClaw gateway, browsing the ClawHub
/// skill marketplace, and managing acpx sessions.
class OpenClawExplorePage extends StatefulWidget {
  const OpenClawExplorePage({super.key});

  @override
  State<OpenClawExplorePage> createState() => _OpenClawExplorePageState();
}

class _OpenClawExplorePageState extends State<OpenClawExplorePage> {
  final _searchController = TextEditingController();
  final _gatewayUrlController = TextEditingController();

  List<Map<String, dynamic>> _skills = [];
  bool _loadingSkills = false;
  String? _skillsError;

  /// Installed skills with their enabled state.
  final List<Map<String, dynamic>> _installedSkills = [];

  /// Active acpx sessions.
  final List<Map<String, dynamic>> _sessions = [];
  bool _loadingSessions = false;

  @override
  void initState() {
    super.initState();
    final config = OpenClawStore.getConfig();
    _gatewayUrlController.text = config?.gatewayUrl ?? 'ws://127.0.0.1:18789';
    _loadSkills();
    _loadSessions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gatewayUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSkills() async {
    setState(() {
      _loadingSkills = true;
      _skillsError = null;
    });

    try {
      final query = _searchController.text.trim();
      final skills = await OpenClawService.browseSkills(
        query: query.isNotEmpty ? query : null,
      );
      if (mounted) {
        setState(() {
          _skills = skills;
          _loadingSkills = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _skillsError = e.toString();
          _loadingSkills = false;
        });
      }
    }
  }

  Future<void> _loadSessions() async {
    if (OpenClawService.connectionStatus.value != OpenClawStatus.connected) {
      return;
    }

    setState(() => _loadingSessions = true);

    try {
      final status = await OpenClawService.getStatus();
      if (mounted) {
        final sessions = status['sessions'];
        setState(() {
          if (sessions is List) {
            _sessions
              ..clear()
              ..addAll(sessions.cast<Map<String, dynamic>>());
          }
          _loadingSessions = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSessions = false);
    }
  }

  Future<void> _toggleConnection() async {
    final status = OpenClawService.connectionStatus.value;
    if (status == OpenClawStatus.connected) {
      await OpenClawService.disconnect();
    } else {
      await OpenClawService.connect(url: _gatewayUrlController.text.trim());
    }
    // Reload sessions after connection state change.
    _loadSessions();
  }

  Future<void> _installSkill(String skillId) async {
    final success = await OpenClawService.installSkill(skillId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Skill installed successfully' : 'Failed to install skill',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(ModernDesignSystem.borderRadiusSmall),
        ),
      ),
    );

    if (success) _loadSkills();
  }

  void _toggleInstalledSkill(int index, bool enabled) {
    setState(() {
      _installedSkills[index]['enabled'] = enabled;
    });
  }

  void _showConfigureDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Configure Gateway'),
          content: TextField(
            controller: _gatewayUrlController,
            decoration: const InputDecoration(
              labelText: 'Gateway URL',
              hintText: 'ws://127.0.0.1:18789',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {}); // Refresh to show new URL.
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenClaw'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh skills',
            onPressed: _loadSkills,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSkills,
        child: ListView(
          padding: const EdgeInsets.all(ModernDesignSystem.spacingM),
          children: [
            _buildConnectionCard(),
            const SizedBox(height: ModernDesignSystem.spacingL),
            _buildSkillsSection(),
            const SizedBox(height: ModernDesignSystem.spacingL),
            _buildInstalledSkillsSection(),
            const SizedBox(height: ModernDesignSystem.spacingL),
            _buildSessionsSection(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Connection status card
  // ---------------------------------------------------------------------------

  Widget _buildConnectionCard() {
    return ValueListenableBuilder<OpenClawStatus>(
      valueListenable: OpenClawService.connectionStatus,
      builder: (context, status, _) {
        return GlassmorphismCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusIndicator(
                    isOnline: status == OpenClawStatus.connected,
                  ),
                  const SizedBox(width: ModernDesignSystem.spacingS),
                  Text(
                    'Gateway',
                    style: ModernDesignSystem.headingSmall.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: ModernDesignSystem.spacingM),
              Text(
                _gatewayUrlController.text,
                style: ModernDesignSystem.bodySmall.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.7),
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: ModernDesignSystem.spacingM),
              Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      text: status == OpenClawStatus.connected
                          ? 'Disconnect'
                          : status == OpenClawStatus.connecting
                              ? 'Connecting...'
                              : 'Connect',
                      gradient: status == OpenClawStatus.connected
                          ? ModernDesignSystem.warningGradient
                          : ModernDesignSystem.secondaryGradient,
                      onPressed: status == OpenClawStatus.connecting
                          ? null
                          : _toggleConnection,
                    ),
                  ),
                  const SizedBox(width: ModernDesignSystem.spacingS),
                  IconButton(
                    icon: const Icon(Icons.settings_rounded),
                    tooltip: 'Configure',
                    onPressed: _showConfigureDialog,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(OpenClawStatus status) {
    final (String label, Color color) = switch (status) {
      OpenClawStatus.connected => ('Connected', const Color(0xFF38ef7d)),
      OpenClawStatus.connecting => ('Connecting', const Color(0xFFFFE66D)),
      OpenClawStatus.error => ('Error', const Color(0xFFFF6B6B)),
      OpenClawStatus.disconnected => ('Disconnected', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ModernDesignSystem.spacingS,
        vertical: ModernDesignSystem.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius:
            BorderRadius.circular(ModernDesignSystem.borderRadiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: ModernDesignSystem.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Skills section
  // ---------------------------------------------------------------------------

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Skills',
              style: ModernDesignSystem.headingSmall.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const Spacer(),
            if (_loadingSkills)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: ModernDesignSystem.spacingS),

        // Search field
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search skills...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _loadSkills();
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ModernDesignSystem.spacingM,
              vertical: ModernDesignSystem.spacingS,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ModernDesignSystem.borderRadiusMedium,
              ),
            ),
          ),
          onSubmitted: (_) => _loadSkills(),
        ),
        const SizedBox(height: ModernDesignSystem.spacingM),

        // Skills grid / list
        if (_skillsError != null)
          _buildErrorCard(_skillsError!)
        else if (_skills.isEmpty && !_loadingSkills)
          _buildEmptySkillsCard()
        else
          ..._skills.map(_buildSkillCard),
      ],
    );
  }

  Widget _buildSkillCard(Map<String, dynamic> skill) {
    final name = skill['name'] as String? ?? 'Unnamed Skill';
    final description =
        skill['description'] as String? ?? 'No description available.';
    final author = skill['author'] as String? ?? 'Unknown';
    final skillId = skill['id']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: ModernDesignSystem.spacingS),
      child: GlassmorphismCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(ModernDesignSystem.spacingS),
                  decoration: BoxDecoration(
                    gradient: ModernDesignSystem.primaryGradient,
                    borderRadius: BorderRadius.circular(
                      ModernDesignSystem.borderRadiusSmall,
                    ),
                  ),
                  child: const Icon(
                    Icons.extension_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: ModernDesignSystem.spacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: ModernDesignSystem.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'by $author',
                        style: ModernDesignSystem.caption.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                GradientButton(
                  text: 'Install',
                  gradient: ModernDesignSystem.secondaryGradient,
                  height: 36,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ModernDesignSystem.spacingM,
                    vertical: ModernDesignSystem.spacingXS,
                  ),
                  textStyle: ModernDesignSystem.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  onPressed:
                      skillId.isNotEmpty ? () => _installSkill(skillId) : null,
                ),
              ],
            ),
            const SizedBox(height: ModernDesignSystem.spacingS),
            Text(
              description,
              style: ModernDesignSystem.bodySmall.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.8),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySkillsCard() {
    return GlassmorphismCard(
      child: Center(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: ModernDesignSystem.spacingXL),
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.4),
              ),
              const SizedBox(height: ModernDesignSystem.spacingS),
              Text(
                'No skills found',
                style: ModernDesignSystem.bodyMedium.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: ModernDesignSystem.spacingXS),
              Text(
                'Try a different search or refresh the list.',
                style: ModernDesignSystem.caption.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return GlassmorphismCard(
      gradient: const LinearGradient(
        colors: [Color(0x1AFF6B6B), Color(0x0DFF6B6B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFFF6B6B), size: 20),
          const SizedBox(width: ModernDesignSystem.spacingS),
          Expanded(
            child: Text(
              message,
              style: ModernDesignSystem.bodySmall.copyWith(
                color: const Color(0xFFFF6B6B),
              ),
            ),
          ),
          TextButton(
            onPressed: _loadSkills,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Installed skills section
  // ---------------------------------------------------------------------------

  Widget _buildInstalledSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Installed Skills',
          style: ModernDesignSystem.headingSmall.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: ModernDesignSystem.spacingS),
        if (_installedSkills.isEmpty)
          GlassmorphismCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: ModernDesignSystem.spacingL,
                ),
                child: Text(
                  'No installed skills yet.',
                  style: ModernDesignSystem.bodyMedium.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          )
        else
          ...List.generate(_installedSkills.length, (index) {
            final skill = _installedSkills[index];
            final name = skill['name'] as String? ?? 'Unnamed';
            final enabled = skill['enabled'] as bool? ?? false;

            return Padding(
              padding:
                  const EdgeInsets.only(bottom: ModernDesignSystem.spacingXS),
              child: GlassmorphismCard(
                child: Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.all(ModernDesignSystem.spacingXS),
                      decoration: BoxDecoration(
                        gradient: enabled
                            ? ModernDesignSystem.secondaryGradient
                            : ModernDesignSystem.darkGradient,
                        borderRadius: BorderRadius.circular(
                          ModernDesignSystem.borderRadiusSmall,
                        ),
                      ),
                      child: const Icon(
                        Icons.extension_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: ModernDesignSystem.spacingS),
                    Expanded(
                      child: Text(
                        name,
                        style: ModernDesignSystem.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.color,
                        ),
                      ),
                    ),
                    Switch(
                      value: enabled,
                      onChanged: (val) => _toggleInstalledSkill(index, val),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Sessions section
  // ---------------------------------------------------------------------------

  Widget _buildSessionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Sessions',
              style: ModernDesignSystem.headingSmall.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const Spacer(),
            if (_loadingSessions)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: ModernDesignSystem.spacingS),
        if (_sessions.isEmpty)
          GlassmorphismCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(ModernDesignSystem.spacingS),
                  decoration: BoxDecoration(
                    gradient: ModernDesignSystem.successGradient,
                    borderRadius: BorderRadius.circular(
                      ModernDesignSystem.borderRadiusSmall,
                    ),
                  ),
                  child: const Icon(
                    Icons.terminal_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: ModernDesignSystem.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'acpx CLI Sessions',
                        style: ModernDesignSystem.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: ModernDesignSystem.spacingXS),
                      Text(
                        'No active sessions. Start a gateway with '
                        '"acpx serve" and connect above to interact '
                        'with running agents.',
                        style: ModernDesignSystem.bodySmall.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ..._sessions.map(_buildSessionCard),
        const SizedBox(height: ModernDesignSystem.spacingS),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: 'New Session',
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            gradient: ModernDesignSystem.primaryGradient,
            onPressed: OpenClawService.connectionStatus.value ==
                    OpenClawStatus.connected
                ? () {
                    // Send a new-session request through the gateway.
                    OpenClawService.sendMessage(content: '/new-session');
                    _loadSessions();
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final sessionId = session['id']?.toString() ?? '';
    final name = session['name'] as String? ?? 'Session $sessionId';
    final status = session['status'] as String? ?? 'unknown';

    return Padding(
      padding: const EdgeInsets.only(bottom: ModernDesignSystem.spacingS),
      child: GlassmorphismCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(ModernDesignSystem.spacingS),
              decoration: BoxDecoration(
                gradient: status == 'active'
                    ? ModernDesignSystem.successGradient
                    : ModernDesignSystem.darkGradient,
                borderRadius: BorderRadius.circular(
                  ModernDesignSystem.borderRadiusSmall,
                ),
              ),
              child: const Icon(
                Icons.terminal_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: ModernDesignSystem.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: ModernDesignSystem.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    status,
                    style: ModernDesignSystem.caption.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusChip(
              status == 'active'
                  ? OpenClawStatus.connected
                  : OpenClawStatus.disconnected,
            ),
          ],
        ),
      ),
    );
  }
}
