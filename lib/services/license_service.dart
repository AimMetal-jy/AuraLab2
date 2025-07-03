import 'package:flutter/foundation.dart';

/// 许可证管理服务
class LicenseService {
  /// 注册所有自定义许可证
  static void registerLicenses() {
    // 注册应用自身的许可证
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(
        ['AuraLab'],
        '''
MIT License

Copyright (c) 2025 AuraLab Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
''',
      );
    });

    // 注册第三方服务许可证（如果有特殊要求）
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(
        ['HuggingFace Models'],
        '''
Apache License 2.0

使用 HuggingFace 模型需要遵循相应的许可证条款。

特别说明：
- pyannote/segmentation-3.0：需要接受使用许可协议
- pyannote/speaker-diarization-3.1：需要接受使用许可协议

请访问相应的模型页面获取详细的许可证信息。
''',
      );
    });

    // 注册vivo AI服务声明
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(
        ['vivo AI 服务'],
        '''
vivo AI 服务使用声明

本应用集成了 vivo AI 开放平台提供的以下服务：
- 文字转语音 (TTS) 服务
- 语音转录服务
- 翻译服务

使用这些服务需要：
1. 遵守 vivo AI 开放平台的服务条款
2. 获取有效的 App ID 和 App Key
3. 遵循相应的使用限制和配额

详细信息请访问：https://aigc.vivo.com.cn/
''',
      );
    });

    // 注册音频资源许可证
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(
        ['音频资源'],
        '''
示例音频文件

本应用包含的示例音频文件 (English_Pod_30s.wav) 仅用于演示目的。

使用说明：
- 仅供学习和测试使用
- 不得用于商业用途
- 如需在生产环境中使用，请替换为您拥有合法使用权的音频文件

如对音频版权有疑问，请联系开发团队。
''',
      );
    });

    // 注册图标和UI资源
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(
        ['UI 资源'],
        '''
图标和界面资源

应用中使用的图标主要来自：
- Material Design Icons (Apache License 2.0)
- Flutter 默认图标集
- 自定义应用图标 (AuraLab_icon.png)

自定义图标和界面设计归 AuraLab 团队所有，遵循 MIT 许可证。
''',
      );
    });
  }

  /// 获取许可证数量统计
  static Future<int> getLicenseCount() async {
    int count = 0;
    await for (final _ in LicenseRegistry.licenses) {
      count++;
    }
    return count;
  }

  /// 检查是否有特定包的许可证
  static Future<bool> hasLicenseForPackage(String packageName) async {
    await for (final license in LicenseRegistry.licenses) {
      if (license.packages.contains(packageName)) {
        return true;
      }
    }
    return false;
  }
}
