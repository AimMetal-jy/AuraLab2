# AuraLab - 多功能AI音频处理应用

![AuraLab Logo](assets/images/AuraLab_icon.png)

AuraLab是一款基于Flutter开发的多功能AI音频处理应用，集成了语音转录、文字转语音、音频播放、多语言翻译、笔记管理等功能。

## 🌟 主要功能

### 🎵 音频处理
- **语音转录 (ASR)**: 支持多种音频格式的语音识别转文字
- **文字转语音 (TTS)**: 高质量的文本朗读功能
- **音频播放器**: 支持多种音频格式播放，带歌词同步显示
- **音频库管理**: 本地音频文件管理和播放列表

### 📝 笔记管理
- **智能笔记**: 支持富文本编辑和标签分类
- **自动保存**: 实时保存编辑内容，防止数据丢失
- **搜索筛选**: 支持按标题、内容、标签搜索笔记
- **排序功能**: 按创建时间、修改时间、标题排序

### 🌍 多语言支持
- **实时翻译**: 支持多种语言间的文本翻译
- **单词本管理**: 收藏和管理学习词汇
- **语言学习**: 结合TTS功能进行语音学习

### 🔧 系统功能
- **高刷新率支持**: 优化120Hz显示体验
- **后台任务**: 支持后台音频处理
- **性能优化**: 针对移动设备优化的流畅体验

## 🛠️ 技术栈

### 前端框架
- **Flutter**: 3.8.1+
- **Dart**: 最新稳定版

### 核心依赖
- **状态管理**: Provider
- **路由管理**: go_router
- **数据库**: sqflite (本地SQLite)
- **网络请求**: dio, http
- **音频播放**: audioplayers
- **文件处理**: file_picker
- **图像处理**: image_picker
- **本地存储**: shared_preferences
- **Markdown支持**: flutter_markdown
- **文档处理**: docx_template, xml

### UI组件
- **Material Design**: 遵循Material 3设计规范
- **自适应布局**: 支持多种屏幕尺寸
- **流畅动画**: 针对高刷新率优化的动画效果

## 📱 系统要求

### Android
- Android 6.0 (API level 23) 或更高版本
- 至少2GB RAM
- 500MB可用存储空间

### iOS
- iOS 12.0 或更高版本
- iPhone 6s 或更新机型
- 500MB可用存储空间

## 🚀 快速开始

### 环境准备

1. **安装Flutter SDK**
   ```bash
   # 下载Flutter SDK
   git clone https://github.com/flutter/flutter.git -b stable
   
   # 添加到环境变量
   export PATH="$PATH:`pwd`/flutter/bin"
   ```

2. **验证环境**
   ```bash
   flutter doctor
   ```

### 项目安装

1. **克隆项目**
   ```bash
   git clone <https://github.com/AimMetal-jy/AuraLab2.git>
   cd auralab_0701
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **生成应用图标**
   ```bash
   flutter pub run flutter_launcher_icons:main
   ```

### 运行应用

1. **连接设备或启动模拟器**
   ```bash
   flutter devices
   ```

2. **运行应用**
   ```bash
   # 调试模式
   flutter run
   
   # 发布模式
   flutter run --release
   ```

### 构建发布版本

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 📁 项目结构

```
lib/
├── config/              # 配置文件
│   └── performance_config.dart
├── routes/              # 路由配置
│   └── app_routes.dart
├── screens/             # 页面组件
│   ├── tabs.dart        # 主标签页
│   ├── note_list_page.dart    # 笔记列表
│   ├── note_edit_page.dart    # 笔记编辑
│   ├── asr_page.dart          # 语音转录
│   ├── tts_processing.dart    # 文字转语音
│   ├── vocabulary_book_page.dart  # 单词本
│   └── settings_page.dart     # 设置页面
├── services/            # 业务服务
│   ├── audio_player_service.dart
│   ├── audio_library_service.dart
│   ├── background_task_service.dart
│   ├── transcription_service.dart
│   ├── tts_service.dart
│   ├── database_helper.dart
│   ├── license_service.dart
│   └── display_mode_service.dart
├── widgets/             # 通用组件
│   ├── drawer.dart      # 侧边栏
│   └── music_player/    # 音乐播放器组件
└── main.dart           # 应用入口
```

## 🔧 配置说明

### 后端服务配置

应用需要连接后端服务以使用AI功能，请确保后端服务正常运行：

- **BlueLM服务**: 提供TTS、翻译、OCR等AI功能
- **WhisperX服务**: 提供高精度语音转录功能

### 权限配置

#### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
```

#### iOS (ios/Runner/Info.plist)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>需要麦克风权限进行语音录制</string>
<key>NSCameraUsageDescription</key>
<string>需要相机权限进行拍照识别</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要相册权限选择图片</string>
```

## 🎯 使用指南

### 语音转录
1. 进入ASR页面
2. 点击录音按钮开始录制
3. 录制完成后自动上传并转录
4. 查看转录结果和时间戳

### 文字转语音
1. 在TTS页面输入文本
2. 选择语音参数（语速、音调等）
3. 点击播放按钮生成语音
4. 支持保存音频文件

### 笔记管理
1. 在笔记页面创建新笔记
2. 支持富文本编辑和标签分类
3. 自动保存功能防止数据丢失
4. 使用搜索功能快速查找笔记

### 音频播放
1. 导入音频文件到音频库
2. 支持播放列表管理
3. 歌词同步显示（如有）
4. 后台播放支持

## 🐛 故障排除

### 常见问题

1. **构建失败**
   ```bash
   flutter clean
   flutter pub get
   flutter build
   ```

2. **权限问题**
   - 检查AndroidManifest.xml和Info.plist权限配置
   - 确保在设备上手动授予必要权限

3. **网络连接问题**
   - 检查后端服务是否正常运行
   - 确认网络连接和防火墙设置

4. **音频播放问题**
   - 检查音频文件格式是否支持
   - 确认设备音频输出正常

### 性能优化

- 启用高刷新率显示
- 使用Release模式构建
- 优化图片和音频资源大小
- 合理使用缓存机制

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🤝 贡献

欢迎提交Issue和Pull Request来改进项目！

### 开发指南
1. Fork项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建Pull Request

## 🙏 致谢

特别感谢以下开源项目和服务：

- [Flutter](https://flutter.dev/) - 跨平台UI框架
- [WhisperX](https://github.com/m-bain/whisperX) - 高精度语音识别
- [vivo AI平台](https://ai.vivo.com/) - AI服务支持
- [HuggingFace](https://huggingface.co/) - AI模型和工具
- 所有开源社区贡献者

---

**AuraLab Team** © 2025
