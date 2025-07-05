# AuraLab - 多功能AI音频处理应用

![AuraLab Logo](assets/images/AuraLab_icon.png)

AuraLab是一款基于Flutter开发的多功能AI音频处理应用，集成了语音转录、文字转语音、音频播放、多语言翻译、笔记管理等功能。

## 🚀 快速开始

### 环境准备

1. **安装Flutter SDK（flutter_3.32.5）**
   
   ```bash
   # 下载Flutter SDK (flutter_3.32.5)
   # 添加到环境变量
   # 将flutter SDK的bin文件夹添加到环境变量
   ```
   
2. **验证环境**
   ```bash
   flutter doctor
   ```

### 项目安装


1. **安装依赖**
   ```bash
   flutter pub get
   ```

2. **生成应用图标**
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

## 🐛 故障排除

### 常见问题

1. **构建失败**
   ```bash
   flutter clean
   flutter pub get
   flutter build
   ```

2. **网络连接问题**
   
   - 检查后端服务是否正常运行
   - 确认网络连接和防火墙设置
   
4. **音频播放问题**
   - 检查音频文件格式是否支持
   - 确认设备音频输出正常
