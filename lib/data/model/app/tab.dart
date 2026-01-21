/*
 * @Author: songyu
 * @Date: 2025-02-13 20:32:32
 * @LastEditTime: 2026-01-21 12:00:00
 * @LastEditor: songyu
 */
// ignore_for_file: unused_import
import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/material.dart';
import 'package:server_box/core/extension/context/locale.dart';
import 'package:server_box/view/page/server/tab.dart';
import 'package:server_box/view/page/server/modern_server_tab.dart';
import 'package:server_box/data/res/store.dart';
// import 'package:server_box/view/page/setting/entry.dart';
import 'package:server_box/view/page/snippet/list.dart';
import 'package:server_box/view/page/ssh/tab.dart';
import 'package:server_box/view/page/codecore/codecore_tab.dart';
import 'package:server_box/view/page/codecore/widgets/claude_skill_page.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:server_box/view/page/storage/local.dart';

enum AppTab {
  codecore,
  skills,
  // server,
  // ssh,
  // file,
  // snippet,
  //settings,
  ;

  Widget get page {
    return switch (this) {
      codecore => const CodePalTabPage(),
      skills => const ClaudeSkillPage(),
      // server => _getServerPage(),
      // //settings => const SettingsPage(),
      // ssh => const SSHTabPage(),
      // file => const LocalFilePage(),
      // snippet => const SnippetListPage(),
    };
  }

  // ignore: unused_element
  Widget _getServerPage() {
    // Check if user prefers modern UI (using our modern theme color)
    final useModernUI = Stores.setting.colorSeed.fetch() == 0x667EEA ||
        !Stores.setting.useSystemPrimaryColor.fetch();

    return useModernUI ? const ModernServerPage() : const ServerPage();
  }

  NavigationDestination get navDestination {
    return switch (this) {
      codecore => const NavigationDestination(
          icon: Icon(Icons.smart_toy_outlined),
          label: 'CodePal',
          selectedIcon: Icon(Icons.smart_toy),
        ),
      skills => const NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          label: 'Skills',
          selectedIcon: Icon(Icons.auto_awesome),
        ),
      // server => NavigationDestination(
      //     icon: const Icon(BoxIcons.bx_server),
      //     label: l10n.server,
      //     selectedIcon: const Icon(BoxIcons.bxs_server),
      //   ),
      // // settings => NavigationDestination(
      // //     icon: const Icon(Icons.settings),
      // //     label: libL10n.setting,
      // //     selectedIcon: const Icon(Icons.settings),
      // //   ),
      // ssh => const NavigationDestination(
      //     icon: Icon(Icons.terminal_outlined),
      //     label: 'SSH',
      //     selectedIcon: Icon(Icons.terminal),
      //   ),
      // snippet => NavigationDestination(
      //     icon: const Icon(Icons.code),
      //     label: l10n.snippet,
      //     selectedIcon: const Icon(Icons.code),
      //   ),
      // file => NavigationDestination(
      //     icon: const Icon(Icons.folder_open),
      //     label: libL10n.file,
      //     selectedIcon: const Icon(Icons.folder),
      //   ),
    };
  }

  static List<NavigationDestination> get navDestinations {
    return AppTab.values.map((e) => e.navDestination).toList();
  }
}
