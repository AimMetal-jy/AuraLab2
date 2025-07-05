import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/huggingface_token_service.dart';
import '../services/bluelm_config_service.dart';

import '../widgets/custom_toast.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _appIdController = TextEditingController();
  final TextEditingController _appKeyController = TextEditingController();
  final GlobalKey<FormState> _huggingFaceFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _blueLMFormKey = GlobalKey<FormState>();

  // HuggingFace Token 相关
  bool _hasExistingToken = false;
  String? _existingTokenMasked;
  bool _obscureToken = true;

  // 蓝心大模型配置相关
  bool _hasExistingBlueLMConfig = false;
  String? _existingAppId;
  String? _existingAppKeyMasked;
  bool _obscureAppKey = true;

  // 显示模式相关
  

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingConfigs();
  }

  Future<void> _loadExistingConfigs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 加载HuggingFace Token
      final hasToken = await HuggingFaceTokenService.hasToken();
      if (hasToken) {
        final token = await HuggingFaceTokenService.getToken();
        if (token != null) {
          setState(() {
            _hasExistingToken = true;
            _existingTokenMasked = HuggingFaceTokenService.maskToken(token);
          });
        }
      }

      // 加载蓝心大模型配置
      final hasBlueLMConfig = await BlueLMConfigService.hasConfig();
      if (hasBlueLMConfig) {
        final config = await BlueLMConfigService.getConfig();
        if (config['app_id'] != null && config['app_key'] != null) {
          setState(() {
            _hasExistingBlueLMConfig = true;
            _existingAppId = config['app_id']!;
            _existingAppKeyMasked = BlueLMConfigService.maskAppKey(
              config['app_key']!,
            );
          });
        }
      }


    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '加载现有配置失败: $e',
          type: ToastType.error,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToken() async {
    if (!_huggingFaceFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await HuggingFaceTokenService.saveToken(
        _tokenController.text,
      );
      if (success) {
        // 刷新配置显示
        await _loadExistingConfigs();
        // 清空输入框，让已保存的配置在页面中隐式展示
        _tokenController.clear();
        if (mounted) {
          CustomToast.show(
            context,
            message: 'HuggingFace Token 保存成功！',
            type: ToastType.success,
          );
        }
      } else {
        if (mounted) {
          CustomToast.show(
            context,
            message: 'Token 保存失败，请重试',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: '保存失败: $e', type: ToastType.error);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeToken() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除已保存的 HuggingFace Token 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await HuggingFaceTokenService.removeToken();
        if (success) {
          setState(() {
            _hasExistingToken = false;
            _existingTokenMasked = null;
          });
          // 清空输入框
          _tokenController.clear();
          if (mounted) {
            CustomToast.show(
              context,
              message: 'HuggingFace Token 已删除',
              type: ToastType.warning,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          CustomToast.show(context, message: '删除失败: $e', type: ToastType.error);
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          CustomToast.show(context, message: '无法打开链接', type: ToastType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: '打开链接失败: $e', type: ToastType.error);
      }
    }
  }

  /// 保存蓝心大模型配置
  Future<void> _saveBlueLMConfig() async {
    if (!_blueLMFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await BlueLMConfigService.saveConfig(
        appId: _appIdController.text,
        appKey: _appKeyController.text,
      );
      if (success) {
        // 刷新配置显示
        await _loadExistingConfigs();
        // 清空输入框，让已保存的配置在页面中隐式展示
        _appIdController.clear();
        _appKeyController.clear();
        if (mounted) {
          CustomToast.show(
            context,
            message: '蓝心大模型配置保存成功！',
            type: ToastType.success,
          );
        }
      } else {
        if (mounted) {
          CustomToast.show(context, message: '保存失败，请重试', type: ToastType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: '保存失败: $e', type: ToastType.error);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 删除蓝心大模型配置
  Future<void> _removeBlueLMConfig() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除已保存的蓝心大模型配置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await BlueLMConfigService.removeConfig();
        if (success) {
          setState(() {
            _hasExistingBlueLMConfig = false;
            _existingAppId = null;
            _existingAppKeyMasked = null;
          });
          // 清空输入框
          _appIdController.clear();
          _appKeyController.clear();
          if (mounted) {
            CustomToast.show(
              context,
              message: '蓝心大模型配置已删除',
              type: ToastType.warning,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          CustomToast.show(context, message: '删除失败: $e', type: ToastType.error);
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 加载显示模式设置


  /// 构建链接卡片
  Widget _buildLinkCard({
    required String title,
    required String description,
    required String url,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.open_in_new),
        onTap: () => _launchUrl(url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('系统设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HuggingFace 配置区域
                  _buildHuggingFaceSection(),

                  const SizedBox(height: 40),

                  // 蓝心大模型配置区域
                  _buildBlueLMSection(),
                ],
              ),
            ),
    );
  }



  /// 构建HuggingFace配置区域
  Widget _buildHuggingFaceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和说明
        Row(
          children: [
            Icon(Icons.psychology, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              'HuggingFace 配置',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 说明信息
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      '说话人识别功能要求',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '如果您想使用 WhisperX 的说话人识别功能，需要：',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. 获取以下两个开源模型的使用许可：',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildLinkCard(
                  title: 'pyannote/segmentation-3.0',
                  description: '语音分割模型',
                  url: 'https://huggingface.co/pyannote/segmentation-3.0',
                  icon: Icons.graphic_eq,
                ),
                const SizedBox(height: 8),
                _buildLinkCard(
                  title: 'pyannote/speaker-diarization-3.1',
                  description: '说话人识别模型',
                  url:
                      'https://huggingface.co/pyannote/speaker-diarization-3.1',
                  icon: Icons.people,
                ),
                const SizedBox(height: 12),
                const Text(
                  '2. 生成 HuggingFace Token：',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildLinkCard(
                  title: '创建 Access Token',
                  description: '需要 Read 权限即可',
                  url: 'https://huggingface.co/settings/tokens',
                  icon: Icons.key,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 现有Token显示
        if (_hasExistingToken) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        '当前配置',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Token: '),
                      Expanded(
                        child: Text(
                          _existingTokenMasked ?? '',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _removeToken,
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('删除'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // HuggingFace Token 配置表单
        Form(
          key: _huggingFaceFormKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        _hasExistingToken ? '更新 Token' : '设置 Token',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tokenController,
                    obscureText: _obscureToken,
                    decoration: InputDecoration(
                      labelText: 'HuggingFace Access Token',
                      hintText: 'hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureToken
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureToken = !_obscureToken;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入 HuggingFace Token';
                      }
                      if (!HuggingFaceTokenService.isValidTokenFormat(value)) {
                        return 'Token 格式不正确';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Token 将被安全保存在本地\n'
                    '• 只需要 Read 权限\n'
                    '• 保存后将隐藏显示',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  // 保存HuggingFace Token按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveToken,
                      icon: const Icon(Icons.save),
                      label: Text(
                        _hasExistingToken
                            ? '更新 HuggingFace Token'
                            : '保存 HuggingFace Token',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建蓝心大模型配置区域
  Widget _buildBlueLMSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 蓝心大模型配置标题
        Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.orange),
            const SizedBox(width: 8),
            const Text(
              '蓝心大模型配置',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 现有蓝心大模型配置显示
        if (_hasExistingBlueLMConfig) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        '当前蓝心大模型配置',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('App ID: $_existingAppId'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('App Key: '),
                      Expanded(
                        child: Text(
                          _existingAppKeyMasked ?? '',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _removeBlueLMConfig,
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('删除'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 蓝心大模型配置表单
        Form(
          key: _blueLMFormKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        _hasExistingBlueLMConfig ? '更新蓝心大模型配置' : '设置蓝心大模型配置',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // App ID 输入
                  TextFormField(
                    controller: _appIdController,
                    decoration: const InputDecoration(
                      labelText: 'App ID',
                      hintText: '请输入蓝心大模型的 App ID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.fingerprint),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入 App ID';
                      }
                      if (!BlueLMConfigService.isValidAppIdFormat(value)) {
                        return 'App ID 不能为空';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // App Key 输入
                  TextFormField(
                    controller: _appKeyController,
                    obscureText: _obscureAppKey,
                    decoration: InputDecoration(
                      labelText: 'App Key',
                      hintText: '请输入蓝心大模型的 App Key',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureAppKey
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureAppKey = !_obscureAppKey;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入 App Key';
                      }
                      if (!BlueLMConfigService.isValidAppKeyFormat(value)) {
                        return 'App Key 不能为空';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• 配置将被安全保存在本地\n'
                    '• 用于蓝心大模型语音转录等服务\n'
                    '• 保存后 App Key 将隐藏显示',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  // 保存蓝心大模型配置按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveBlueLMConfig,
                      icon: const Icon(Icons.save),
                      label: Text(
                        _hasExistingBlueLMConfig ? '更新蓝心大模型配置' : '保存蓝心大模型配置',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _appIdController.dispose();
    _appKeyController.dispose();
    super.dispose();
  }
}
