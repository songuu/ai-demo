import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../codecore/model/cod_provider_config.dart';
import '../../../../codecore/store/cod_config_store.dart';

/// CLI 配置管理面板
class CodConfigPanel extends StatefulWidget {
  const CodConfigPanel({super.key});

  @override
  State<CodConfigPanel> createState() => _CodConfigPanelState();
}

class _CodConfigPanelState extends State<CodConfigPanel> {
  final _configStore = CodConfigStore();
  List<CodProviderConfig> _configs = [];
  CodProviderConfig? _selectedConfig;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  void _loadConfigs() {
    setState(() {
      _configs = _configStore.getAll();
      if (_configs.isNotEmpty && _selectedConfig == null) {
        _selectedConfig = _configs.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        children: [
          // 左侧：提供商列表
          _buildProviderList(),
          
          // 右侧：配置详情
          Expanded(child: _buildConfigDetails()),
        ],
      ),
    );
  }

  Widget _buildProviderList() {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: Color(0xFF252525),
        border: Border(right: BorderSide(color: Color(0xFF333333))),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF333333))),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'CLI Providers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  color: Colors.green,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  onPressed: _addNewProvider,
                  tooltip: 'Add provider',
                ),
              ],
            ),
          ),
          
          // 提供商列表
          Expanded(
            child: ListView.builder(
              itemCount: _configs.length,
              itemBuilder: (context, index) {
                final config = _configs[index];
                final isSelected = _selectedConfig?.provider == config.provider;
                
                return InkWell(
                  onTap: () => setState(() => _selectedConfig = config),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF3A3A3A) : null,
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFF2A2A2A)),
                      ),
                    ),
                    child: Row(
                      children: [
                        // 图标
                        Icon(
                          _getProviderIcon(config.provider),
                          size: 16,
                          color: config.enabled ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        
                        // 名称
                        Expanded(
                          child: Text(
                            config.displayName,
                            style: TextStyle(
                              color: config.enabled ? Colors.white : Colors.grey,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // 状态指示
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: config.enabled ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 底部操作
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF333333))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomButton(
                  Icons.refresh,
                  'Reset',
                  _resetToDefaults,
                ),
                _buildBottomButton(
                  Icons.download,
                  'Import',
                  _importConfigs,
                ),
                _buildBottomButton(
                  Icons.upload,
                  'Export',
                  _exportConfigs,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildConfigDetails() {
    if (_selectedConfig == null) {
      return const Center(
        child: Text(
          'Select a provider to configure',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和操作
          Row(
            children: [
              Icon(
                _getProviderIcon(_selectedConfig!.provider),
                size: 24,
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedConfig!.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _selectedConfig!.provider.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 启用/禁用开关
              Switch(
                value: _selectedConfig!.enabled,
                onChanged: (value) => _toggleEnabled(),
                activeColor: Colors.green,
              ),
              const SizedBox(width: 8),
              
              // 编辑/保存按钮
              if (_isEditing)
                ElevatedButton.icon(
                  onPressed: _saveConfig,
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Divider(color: Color(0xFF333333)),
          const SizedBox(height: 16),
          
          // 配置字段
          _buildConfigField(
            'Command',
            _selectedConfig!.command,
            'CLI command name or full path',
            (value) => _selectedConfig = _selectedConfig!.copyWith(command: value),
          ),
          
          _buildConfigField(
            'API Key',
            _selectedConfig!.apiKey ?? '',
            'Your API key (will be stored securely)',
            (value) => _selectedConfig = _selectedConfig!.copyWith(apiKey: value),
            obscureText: true,
          ),
          
          _buildConfigField(
            'History Path',
            _selectedConfig!.historyPathTemplate ?? '',
            'Path template for history files (use \${HOME} for home directory)',
            (value) => _selectedConfig = _selectedConfig!.copyWith(historyPathTemplate: value),
          ),
          
          _buildConfigField(
            'Working Directory',
            _selectedConfig!.workingDirectoryTemplate ?? '',
            'Default working directory (leave empty for current)',
            (value) => _selectedConfig = _selectedConfig!.copyWith(workingDirectoryTemplate: value),
          ),
          
          const SizedBox(height: 16),
          
          // 高级选项
          _buildSectionHeader('Advanced Options'),
          const SizedBox(height: 12),
          
          _buildCheckboxField(
            'Auto Import History',
            _selectedConfig!.autoImportHistory,
            (value) => _selectedConfig = _selectedConfig!.copyWith(autoImportHistory: value),
          ),
          
          _buildCheckboxField(
            'Run in Shell',
            _selectedConfig!.runInShell,
            (value) => _selectedConfig = _selectedConfig!.copyWith(runInShell: value),
          ),
          
          _buildNumberField(
            'Max Concurrent Sessions',
            _selectedConfig!.maxConcurrentSessions,
            (value) => _selectedConfig = _selectedConfig!.copyWith(maxConcurrentSessions: value),
          ),
          
          _buildNumberField(
            'Timeout (seconds)',
            _selectedConfig!.timeoutSeconds,
            (value) => _selectedConfig = _selectedConfig!.copyWith(timeoutSeconds: value),
          ),
          
          const SizedBox(height: 16),
          
          // 默认参数
          _buildSectionHeader('Default Arguments'),
          const SizedBox(height: 12),
          _buildArgumentsList(),
          
          const SizedBox(height: 16),
          
          // 环境变量
          _buildSectionHeader('Environment Variables'),
          const SizedBox(height: 12),
          _buildEnvironmentVariables(),
          
          const SizedBox(height: 24),
          
          // 测试按钮
          Center(
            child: ElevatedButton.icon(
              onPressed: _testConfiguration,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Test Configuration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildConfigField(
    String label,
    String value,
    String hint,
    ValueChanged<String> onChanged, {
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: TextEditingController(text: value),
            enabled: _isEditing,
            obscureText: obscureText,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              filled: true,
              fillColor: _isEditing ? const Color(0xFF2A2A2A) : const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF333333)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF333333)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxField(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: _isEditing ? (v) => setState(() => onChanged(v ?? false)) : null,
            activeColor: Colors.blue,
          ),
          Text(
            label,
            style: TextStyle(
              color: _isEditing ? Colors.white : Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: TextEditingController(text: value.toString()),
              enabled: _isEditing,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => onChanged(int.tryParse(v) ?? value),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: _isEditing ? const Color(0xFF2A2A2A) : const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFF333333)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArgumentsList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedConfig!.defaultArgs.isEmpty)
            const Text(
              'No default arguments',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            )
          else
            ...(_selectedConfig!.defaultArgs.map((arg) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $arg',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ))),
          if (_isEditing) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _addArgument,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add Argument'),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnvironmentVariables() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedConfig!.environmentVariables.isEmpty)
            const Text(
              'No environment variables',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            )
          else
            ...(_selectedConfig!.environmentVariables.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${entry.key} = ${entry.value}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ))),
          if (_isEditing) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _addEnvironmentVariable,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add Variable'),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'claude':
        return Icons.psychology;
      case 'codex':
        return Icons.code;
      case 'gemini':
        return Icons.auto_awesome;
      default:
        return Icons.terminal;
    }
  }

  void _toggleEnabled() async {
    await _configStore.toggleEnabled(_selectedConfig!.provider);
    _loadConfigs();
  }

  void _saveConfig() async {
    if (_selectedConfig != null) {
      await _configStore.save(_selectedConfig!);
      setState(() => _isEditing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration saved successfully')),
        );
      }
    }
  }

  void _addNewProvider() {
    // TODO: Show dialog to add custom provider
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Custom providers coming soon!')),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'This will reset all configurations to default values. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _configStore.resetToDefaults();
              _loadConfigs();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _importConfigs() {
    // TODO: Implement import from JSON file
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import feature coming soon!')),
    );
  }

  void _exportConfigs() async {
    final data = _configStore.exportConfigs();
    final json = data.toString();
    
    await Clipboard.setData(ClipboardData(text: json));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurations copied to clipboard')),
      );
    }
  }

  void _addArgument() {
    // TODO: Show dialog to add argument
  }

  void _addEnvironmentVariable() {
    // TODO: Show dialog to add environment variable
  }

  void _testConfiguration() {
    // TODO: Test the CLI configuration
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Testing ${_selectedConfig!.displayName} configuration...'),
      ),
    );
  }
}
