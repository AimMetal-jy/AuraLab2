# AuraLab - 多功能AI音频处理应用

![AuraLab Logo](assets/images/AuraLab_icon.png)

AuraLab是一款基于Flutter开发的多功能AI音频处理应用，集成了语音转录、文字转语音、音频播放、多语言翻译、笔记管理等功能。

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
```
### 🔧 配置说明

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

**AuraLab Team** © 2025
