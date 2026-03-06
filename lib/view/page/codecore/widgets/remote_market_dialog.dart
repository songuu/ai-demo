import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:server_box/codecore/model/claude_plugin_dev_item.dart';
import 'package:server_box/codecore/model/skillsmp_remote_skill.dart';
import 'package:server_box/codecore/service/claude_plugins_dev_service.dart';
import 'package:server_box/codecore/service/skillsmp_service.dart';
import 'package:server_box/codecore/store/cod_settings_store.dart';

/// Three-tab remote marketplace dialog.
/// Tab 0 – Skills      (SkillsMP, requires API key)
/// Tab 1 – Plugins     (claude-plugins.dev, free)
/// Tab 2 – Subagents   (claude-plugins.dev, category=agents, free)
class RemoteMarketDialog extends StatelessWidget {
  final Set<String> installedSkillNames;
  final Future<void> Function(String skillName) onSkillInstalled;

  const RemoteMarketDialog({
    super.key,
    required this.installedSkillNames,
    required this.onSkillInstalled,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
        child: SizedBox(
          width: 1020,
          height: 740,
          child: Column(
            children: [
              // ── header ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                decoration: const BoxDecoration(
                  color: Color(0xFF252525),
                  border: Border(bottom: BorderSide(color: Color(0xFF333333))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_sync_outlined, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '远端市场',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '搜索并一键同步到本地 ~/.claude/',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // ── tabs ────────────────────────────────────────────────────
              Container(
                color: const Color(0xFF252525),
                child: const TabBar(
                  indicatorColor: Colors.orange,
                  labelColor: Colors.orange,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.auto_awesome, size: 16),
                      text: 'Skills',
                    ),
                    Tab(
                      icon: Icon(Icons.extension_outlined, size: 16),
                      text: 'Plugins',
                    ),
                    Tab(
                      icon: Icon(Icons.smart_toy_outlined, size: 16),
                      text: 'Subagents',
                    ),
                  ],
                ),
              ),
              // ── tab bodies ───────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  children: [
                    _SkillsTab(
                      installedNames: installedSkillNames,
                      onInstalled: onSkillInstalled,
                    ),
                    const _PluginsTab(),
                    const _SubagentsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SkillsMP tab (existing logic, lifted into widget) ─────────────────────────

class _SkillsTab extends StatefulWidget {
  final Set<String> installedNames;
  final Future<void> Function(String skillName) onInstalled;

  const _SkillsTab({
    required this.installedNames,
    required this.onInstalled,
  });

  @override
  State<_SkillsTab> createState() => _SkillsTabState();
}

class _SkillsTabState extends State<_SkillsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _searchCtrl = TextEditingController();
  final _apiKeyCtrl =
      TextEditingController(text: CodSettingsStore.skillsMpApiKey);

  final _installedNames = <String>{};
  List<SkillsMpRemoteSkill> _results = [];
  bool _isSearching = false;
  bool _isSavingKey = false;
  String? _error;
  int _total = 0;
  String _sortBy = 'stars';

  @override
  void initState() {
    super.initState();
    _installedNames.addAll(widget.installedNames);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey({bool showMessage = true}) async {
    setState(() => _isSavingKey = true);
    try {
      await CodSettingsStore.setSkillsMpApiKey(_apiKeyCtrl.text.trim());
      if (!mounted || !showMessage) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SkillsMP API Key 已保存')),
      );
    } finally {
      if (mounted) setState(() => _isSavingKey = false);
    }
  }

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      setState(() => _error = '请输入搜索关键词');
      return;
    }
    if (_apiKeyCtrl.text.trim().isEmpty) {
      setState(() => _error = '请先配置 SkillsMP API Key');
      return;
    }
    if (_apiKeyCtrl.text.trim() != CodSettingsStore.skillsMpApiKey.trim()) {
      await _saveApiKey(showMessage: false);
    }
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final result =
          await SkillsMpService.searchSkills(query: query, sortBy: _sortBy);
      if (!mounted) return;
      setState(() {
        _results = result.skills;
        _total = result.total;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _total = 0;
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _install(SkillsMpRemoteSkill skill) async {
    setState(() => _error = null);
    try {
      await SkillsMpService.installToClaudeCode(skill);
      _installedNames.add(skill.name);
      await widget.onInstalled(skill.name);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已同步到本地: /${skill.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // API key row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _apiKeyCtrl,
                      label: 'SkillsMP API Key',
                      hint: 'sk_live_xxx（skillsmp.com 登录后生成）',
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildActionBtn(
                    label: '保存 Key',
                    icon: Icons.key,
                    busy: _isSavingKey,
                    onPressed: _saveApiKey,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Search row
              _buildSearchRow(
                ctrl: _searchCtrl,
                hint: '搜索 SkillsMP，例如: react, docker, git',
                sortBy: _sortBy,
                onSortChanged: (v) => setState(() => _sortBy = v),
                isBusy: _isSearching,
                onSearch: _search,
              ),
              _buildMeta(
                hint: '搜索接口需 API Key，每日 500 次配额。',
                total: _total,
              ),
            ],
          ),
        ),
        if (_error != null) _buildError(_error!),
        Expanded(
          child: _isSearching && _results.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange))
              : _results.isEmpty
                  ? _buildEmpty('输入关键词后开始搜索 Skills')
                  : _buildSkillList(),
        ),
      ],
    );
  }

  Widget _buildSkillList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final item = _results[i];
        final installed = _installedNames.contains(item.name);
        return _RemoteCard(
          name: '/${item.name}',
          description: item.description,
          stars: item.stars,
          author: item.author,
          source: item.githubSource,
          badge: null,
          installed: installed,
          skillUrl: item.skillUrl,
          githubUrl: item.githubUrl,
          onInstall: installed ? null : () => _install(item),
          installLabel: '同步到 skills',
        );
      },
    );
  }
}

// ─── Plugins tab ──────────────────────────────────────────────────────────────

class _PluginsTab extends StatefulWidget {
  const _PluginsTab();

  @override
  State<_PluginsTab> createState() => _PluginsTabState();
}

class _PluginsTabState extends State<_PluginsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _searchCtrl = TextEditingController();
  final _installed = <String>{};
  List<ClaudePluginsDevItem> _results = [];
  bool _isSearching = false;
  String? _error;
  int _total = 0;
  String _sortBy = 'downloads';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final result = await ClaudePluginsDevService.searchPlugins(
        query: query,
        sortBy: _sortBy,
      );
      if (!mounted) return;
      setState(() {
        _results = result.items;
        _total = result.total;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _total = 0;
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _install(ClaudePluginsDevItem item) async {
    setState(() => _error = null);
    try {
      await ClaudePluginsDevService.install(item);
      _installed.add(item.fullId);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已安装插件: ${item.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _buildSearchRow(
                ctrl: _searchCtrl,
                hint: '搜索 claude-plugins.dev，例如: react, testing, devops',
                sortBy: _sortBy,
                onSortChanged: (v) => setState(() => _sortBy = v),
                isBusy: _isSearching,
                onSearch: _search,
              ),
              _buildMeta(
                hint: '数据来自 claude-plugins.dev，无需 API Key。',
                total: _total,
              ),
            ],
          ),
        ),
        if (_error != null) _buildError(_error!),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_isSearching && _results.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.orange));
    }
    if (_results.isEmpty) {
      return _buildEmpty('输入关键词后搜索 Plugins（留空搜索全部热门）');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final item = _results[i];
        final installed = _installed.contains(item.fullId);
        return _RemoteCard(
          name: item.name,
          description: item.description,
          stars: item.stars,
          downloads: item.downloads,
          author: item.author,
          source: item.namespace,
          badge: item.verified ? '官方认证' : item.category,
          installed: installed,
          githubUrl: item.gitUrl,
          onInstall: installed ? null : () => _install(item),
          installLabel: '安装 Plugin',
          installCmd: item.installCommand,
        );
      },
    );
  }
}

// ─── Subagents tab ────────────────────────────────────────────────────────────

class _SubagentsTab extends StatefulWidget {
  const _SubagentsTab();

  @override
  State<_SubagentsTab> createState() => _SubagentsTabState();
}

class _SubagentsTabState extends State<_SubagentsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _searchCtrl = TextEditingController();
  final _installed = <String>{};
  List<ClaudePluginsDevItem> _results = [];
  bool _isSearching = false;
  String? _error;
  int _total = 0;
  String _sortBy = 'downloads';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final result = await ClaudePluginsDevService.searchSubagents(
        query: query,
        sortBy: _sortBy,
      );
      if (!mounted) return;
      setState(() {
        _results = result.items;
        _total = result.total;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _total = 0;
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _install(ClaudePluginsDevItem item) async {
    setState(() => _error = null);
    try {
      await ClaudePluginsDevService.install(item);
      _installed.add(item.fullId);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已安装子代理: ${item.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _buildSearchRow(
                ctrl: _searchCtrl,
                hint: '搜索 Subagents，例如: frontend, backend, testing',
                sortBy: _sortBy,
                onSortChanged: (v) => setState(() => _sortBy = v),
                isBusy: _isSearching,
                onSearch: _search,
              ),
              _buildMeta(
                hint: '子代理安装到 ~/.claude/agents/，无需 API Key。',
                total: _total,
              ),
            ],
          ),
        ),
        if (_error != null) _buildError(_error!),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_isSearching && _results.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.orange));
    }
    if (_results.isEmpty) {
      return _buildEmpty('输入关键词后搜索 Subagents（留空搜索全部热门）');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final item = _results[i];
        final installed = _installed.contains(item.fullId);
        return _RemoteCard(
          name: item.name,
          description: item.description,
          stars: item.stars,
          downloads: item.downloads,
          author: item.author,
          source: item.namespace,
          badge: item.verified ? '官方认证' : 'agent',
          installed: installed,
          githubUrl: item.gitUrl,
          onInstall: installed ? null : () => _install(item),
          installLabel: '安装 Subagent',
          installCmd: item.installCommand,
        );
      },
    );
  }
}

// ─── Shared card widget ───────────────────────────────────────────────────────

class _RemoteCard extends StatelessWidget {
  final String name;
  final String description;
  final int stars;
  final int? downloads;
  final String author;
  final String source;
  final String? badge;
  final bool installed;
  final String? skillUrl;
  final String? githubUrl;
  final VoidCallback? onInstall;
  final String installLabel;
  final String? installCmd;

  const _RemoteCard({
    required this.name,
    required this.description,
    required this.stars,
    this.downloads,
    required this.author,
    required this.source,
    required this.badge,
    required this.installed,
    this.skillUrl,
    this.githubUrl,
    required this.onInstall,
    required this.installLabel,
    this.installCmd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: installed
              ? Colors.green.withValues(alpha: 0.5)
              : const Color(0xFF333333),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── first row: name + badges + install button ──────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null && badge!.isNotEmpty) ...[
                const SizedBox(width: 6),
                _chip(badge!, Colors.blue),
              ],
              const SizedBox(width: 6),
              _chip('⭐ $stars', Colors.orange),
              if (downloads != null) ...[
                const SizedBox(width: 6),
                _chip('↓ $downloads', Colors.grey),
              ],
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: onInstall,
                icon: Icon(
                  installed
                      ? Icons.check_circle_outline
                      : Icons.download_outlined,
                  size: 15,
                ),
                label: Text(installed ? '已安装' : installLabel,
                    style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: installed ? Colors.green : Colors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── description ───────────────────────────────────────────
          Text(
            description.isEmpty ? '暂无描述' : description,
            style: TextStyle(
                color: Colors.grey.shade300, fontSize: 12, height: 1.45),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          // ── meta row ──────────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _metaChip('作者', author.isEmpty ? 'unknown' : author),
              _metaChip(
                  '来源', source.length > 50 ? source.substring(0, 50) : source),
            ],
          ),
          // ── link / copy buttons ───────────────────────────────────
          if (installCmd != null || skillUrl != null || githubUrl != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 0,
              children: [
                if (installCmd != null)
                  _linkBtn(
                    context,
                    Icons.terminal_outlined,
                    '复制安装命令',
                    () {
                      Clipboard.setData(ClipboardData(text: installCmd!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制安装命令')),
                      );
                    },
                  ),
                if (skillUrl != null && skillUrl!.isNotEmpty)
                  _linkBtn(
                    context,
                    Icons.link,
                    '复制详情链接',
                    () {
                      Clipboard.setData(ClipboardData(text: skillUrl!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制链接')),
                      );
                    },
                  ),
                if (githubUrl != null && githubUrl!.isNotEmpty)
                  _linkBtn(
                    context,
                    Icons.code,
                    '复制 GitHub',
                    () {
                      Clipboard.setData(ClipboardData(text: githubUrl!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制 GitHub 链接')),
                      );
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 11)),
      );

  Widget _metaChip(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Text(
          '$label: $value',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
        ),
      );

  Widget _linkBtn(BuildContext context, IconData icon, String label,
          VoidCallback onTap) =>
      TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 13),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
        ),
      );
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
}) =>
    TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
        hintStyle: const TextStyle(color: Color(0xFF616161)),
        filled: true,
        fillColor: const Color(0xFF252525),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.orange),
        ),
      ),
    );

Widget _buildActionBtn({
  required String label,
  required IconData icon,
  required bool busy,
  required VoidCallback onPressed,
}) =>
    ElevatedButton.icon(
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
    );

Widget _buildSearchRow({
  required TextEditingController ctrl,
  required String hint,
  required String sortBy,
  required ValueChanged<String> onSortChanged,
  required bool isBusy,
  required VoidCallback onSearch,
}) =>
    Row(
      children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF616161)),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF252525),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF333333)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF333333)),
              ),
            ),
            onSubmitted: (_) => onSearch(),
          ),
        ),
        const SizedBox(width: 10),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: sortBy,
            dropdownColor: const Color(0xFF252525),
            borderRadius: BorderRadius.circular(8),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            items: const [
              DropdownMenuItem(value: 'downloads', child: Text('按下载')),
              DropdownMenuItem(value: 'stars', child: Text('按 Star')),
            ],
            onChanged: (v) {
              if (v != null) onSortChanged(v);
            },
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: isBusy ? null : onSearch,
          icon: isBusy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.travel_explore, size: 16),
          label: const Text('搜索'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        ),
      ],
    );

Widget _buildMeta({required String hint, required int total}) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Text(
            hint,
            style: const TextStyle(color: Color(0xFF757575), fontSize: 11),
          ),
          const Spacer(),
          Text(
            total > 0 ? '共 $total 条结果' : '尚未搜索',
            style: const TextStyle(color: Color(0xFF757575), fontSize: 11),
          ),
        ],
      ),
    );

Widget _buildError(String msg) => Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Text(
        msg,
        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
      ),
    );

Widget _buildEmpty(String text) => Center(
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF757575)),
      ),
    );
