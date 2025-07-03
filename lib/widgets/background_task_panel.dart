import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/background_task_service.dart';

/// 后台任务面板
/// 显示当前正在进行的后台任务
class BackgroundTaskPanel extends StatelessWidget {
  const BackgroundTaskPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BackgroundTaskService>(
      builder: (context, taskService, child) {
        final activeTasks = taskService.activeTasks;

        if (activeTasks.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_sync,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '后台任务 (${activeTasks.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const Spacer(),
                    if (taskService.tasks.any((task) => task.isCompleted))
                      TextButton(
                        onPressed: () => taskService.clearCompletedTasks(),
                        child: const Text(
                          '清除已完成',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              // 任务列表
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeTasks.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final task = activeTasks[index];
                  return _buildTaskItem(context, task, taskService);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    BackgroundTask task,
    BackgroundTaskService taskService,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 任务图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: task.statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(task.icon, color: task.statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          // 任务信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 进度指示器
                if (task.isActive)
                  LinearProgressIndicator(
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(task.statusColor),
                  ),
              ],
            ),
          ),
          // 状态和操作
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 状态指示器
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: task.statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(task.status),
                  style: TextStyle(
                    fontSize: 10,
                    color: task.statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // 时间显示
              Text(
                _formatDuration(DateTime.now().difference(task.createdAt)),
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
              // 操作按钮
              if (task.isCompleted)
                IconButton(
                  onPressed: () => taskService.removeTask(task.id),
                  icon: const Icon(Icons.close, size: 16),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  padding: const EdgeInsets.all(4),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return '等待中';
      case TaskStatus.processing:
        return '处理中';
      case TaskStatus.completed:
        return '已完成';
      case TaskStatus.failed:
        return '失败';
      case TaskStatus.timeout:
        return '超时';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分${duration.inSeconds % 60}秒';
    } else {
      return '${duration.inSeconds}秒';
    }
  }
}
