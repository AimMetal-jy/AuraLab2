# 统一播放器系统

## 概述

统一播放器系统将原来的两个独立播放器（`music_player_page.dart` 和 `audio_lyrics_player_page.dart`）合并为一个功能强大的统一系统。

## 架构设计

### 组件结构
```
widgets/music_player/
├── music_player.dart          # 统一导出文件
├── unified_player_page.dart   # 主播放器页面
├── player_controls.dart       # 播放控制组件
├── progress_bar.dart          # 进度条组件
├── lyrics_display.dart        # 歌词显示组件
├── player_settings.dart       # 设置对话框组件
├── mini_player.dart           # 迷你播放器（原MusicBar）
├── playlist_dialog.dart       # 播放列表对话框
├── clickable_progress_bar.dart # 可点击进度条组件
└── README.md                  # 本文档
```

### 主要特性

#### 🎵 普通音频播放
- **专辑封面显示**：经典的音乐播放器界面
- **基础控制**：播放/暂停、上一首/下一首、随机播放、循环播放
- **音量控制**：滑块调节音量
- **进度控制**：拖拽跳转到任意位置

#### 🎙️ 转录音频播放（WhisperX/ASR）
- **歌词同步**：实时跟随播放进度
- **单词高亮**：精确到单词级别的高亮显示
- **说话人识别**：不同说话人的颜色标签
- **智能交互**：
  - 点击歌词行跳转到对应时间点
  - 歌词自动滚动到屏幕中央
  - 用户手动滚动后自动恢复
- **高级控制**：
  - 播放速度调节 (0.5x - 2.0x)
  - 精确的时间戳显示
  - 句子级别的前进/后退

#### ⚙️ 智能设置
- **转录音频专用**：
  - 单词高亮开关
  - 说话人标签开关
  - 歌词自动滚动开关
  - 详细的播放速度控制
- **普通音频专用**：
  - 随机播放开关
  - 音量控制滑块
- **通用设置**：
  - 循环播放开关

#### 🎚️ 迷你播放器（原MusicBar）
- **底部播放栏**：显示在底部导航栏上方的迷你播放器
- **快速控制**：播放/暂停、播放列表按钮
- **智能展示**：根据音频类型显示不同图标
- **一键跳转**：点击可直接跳转到全屏播放器
- **实时进度**：可点击的进度条显示播放进度
- **播放列表**：快速访问音频库中的所有文件

## 使用方法

### 1. 转录音频播放

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => UnifiedPlayerPage(
      audioData: audioPlayData, // AudioPlayData类型
      isTranscriptionAudio: true,
    ),
  ),
);
```

### 2. 普通音频播放

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => UnifiedPlayerPage(
      audioData: 'path/to/audio/file.mp3', // 文件路径字符串
      isTranscriptionAudio: false,
    ),
  ),
);
```

### 3. 使用包装器（向后兼容）

```dart
// 旧的MusicPlayerPage现在内部使用UnifiedPlayerPage
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => MusicPlayerPage(
      audioData: audioPath,
    ),
  ),
);
```

### 4. 迷你播放器（全局使用）

```dart
// 在底部导航栏中使用
Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    MiniPlayer(
      onTap: () {
        // 自定义点击行为（可选）
        Navigator.push(context, /* 跳转到播放器 */);
      },
    ),
    BottomNavigationBar(...),
  ],
)

// 向后兼容别名
MusicBar(onTap: () => {}); // 等同于 MiniPlayer(onTap: () => {})
```

## API 参考

### UnifiedPlayerPage

| 参数 | 类型 | 说明 |
|------|------|------|
| `audioData` | `dynamic` | 音频数据，可以是AudioPlayData、文件路径字符串或Map |
| `isTranscriptionAudio` | `bool` | 是否为转录音频，决定显示哪些功能 |

### 支持的音频数据格式

#### 转录音频 (AudioPlayData)
```dart
AudioPlayData(
  taskId: 'task_123',
  filename: '英语播客.wav',
  audioFilePath: '/path/to/audio.wav',
  language: 'en',
  lyrics: [...], // 歌词行列表
  speakers: [...], // 说话人列表
  duration: 180.5,
)
```

#### 普通音频 (字符串)
```dart
String audioPath = '/path/to/music.mp3';
```

#### 普通音频 (Map)
```dart
Map<String, dynamic> audioData = {
  'filePath': '/path/to/music.mp3',
  'title': '歌曲名称',
  'artist': '艺术家',
};
```

## 向后兼容性

✅ **完全兼容**：现有的代码无需修改即可工作
- `MusicPlayerPage` 现在是 `UnifiedPlayerPage` 的包装器
- `MusicBar` 现在是 `MiniPlayer` 的别名
- ASR页面已自动更新使用新的播放器
- 所有原有的功能都得到保留和增强

### 组件迁移映射
| 原组件 | 新组件 | 状态 |
|--------|--------|------|
| `music_player_page.dart` | `UnifiedPlayerPage` | ✅ 包装器形式保留 |
| `audio_lyrics_player_page.dart` | `UnifiedPlayerPage` | ✅ 直接替换 |
| `MusicBar` | `MiniPlayer` | ✅ 别名形式保留 |
| `PlaylistDialog` | `PlaylistDialog` | ✅ 移动到music_player中 |
| `ClickableProgressBar` | `ClickableProgressBar` | ✅ 移动到music_player中 |

## 优势总结

### 🚀 性能提升
- **代码复用**：消除了重复代码，减少应用大小
- **统一管理**：所有播放相关组件都在music_player中统一维护
- **模块化架构**：完整的播放器生态系统，从迷你播放器到全屏播放器

### 🎨 用户体验
- **一致的界面**：无论什么类型的音频都有相同的操作体验
- **智能适配**：根据音频类型自动启用相应功能
- **流畅动画**：统一的动画效果和交互反馈

### 🔧 开发友好
- **模块化设计**：各组件独立，易于测试和维护
- **类型安全**：完整的类型检查和错误处理
- **扩展性强**：新功能可以轻松添加到统一系统中

### 📱 功能完整
- **功能覆盖**：包含了原有两个播放器的所有功能
- **增强体验**：添加了新的交互方式和设置选项
- **无缝切换**：支持在播放器视图和歌词视图间切换（转录音频）

## 技术实现

- **状态管理**：使用Provider模式管理播放状态
- **组件通信**：通过回调函数实现组件间通信  
- **异步处理**：完善的异步操作和错误处理
- **内存管理**：正确的资源清理和生命周期管理 