# Windows 构建错误修复：atlstr.h / atls.lib 找不到

## 错误信息

```
error C1083: 无法打开包括文件: "atlstr.h": No such file or directory
LINK : fatal error LNK1104: 无法打开文件"atls.lib"
```

## 原因

`flutter_secure_storage_windows` 插件使用 ATL（Active Template Library）的 `atlstr.h` 和 `CA2W`/`CW2A` 等宏进行字符串转换。ATL 是 Visual Studio 的可选组件，默认安装时不会包含。即使已安装，CMake 构建有时也无法自动找到其 include 和 lib 路径。

## 解决方案

### 项目已内置修复

本项目已在 `windows/CMakeLists.txt` 中添加 ATL 的 include 和 lib 路径。若你已安装 ATL 组件，构建应能正常通过。

### 方法一：安装 C++ ATL 组件（若未安装）

1. 打开 **Visual Studio Installer**
2. 找到已安装的 **Visual Studio 2022** 或 **Build Tools 2022**，点击 **修改**
3. 切换到 **“单个组件”** 标签页
4. 在搜索框中输入 `ATL`
5. 勾选 **“C++ ATL for latest v143 build tools (x86 & x64)”** 或类似名称的 ATL 组件
6. 点击 **修改** 完成安装

### 方法二：清理并重新构建

```powershell
flutter clean
flutter pub get
flutter build windows
# 或
flutter run -d windows
```

## 验证安装

运行项目自带的检查脚本：

```powershell
.\check_windows_setup.ps1
```

若看到 `✅ Found ATL headers at: ...` 表示 ATL 已正确安装。

## 参考

- [flutter_secure_storage #379](https://github.com/juliansteenbakker/flutter_secure_storage/issues/379)
- [Flutter Windows 开发环境要求](https://docs.flutter.dev/get-started/install/windows#additional-windows-requirements)
