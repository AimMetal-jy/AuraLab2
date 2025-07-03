import 'package:flutter/material.dart';

/// 可点击和拖拽的进度条组件
class ClickableProgressBar extends StatefulWidget {
  final double progress;
  final ValueChanged<double>? onSeek;
  final Color? backgroundColor;
  final Color? valueColor;
  final double height;

  const ClickableProgressBar({
    super.key,
    required this.progress,
    this.onSeek,
    this.backgroundColor,
    this.valueColor,
    this.height = 4.0,
  });

  @override
  State<ClickableProgressBar> createState() => _ClickableProgressBarState();
}

class _ClickableProgressBarState extends State<ClickableProgressBar> {
  bool _isDragging = false;
  double? _dragProgress;

  void _handleSeek(Offset localPosition, double width) {
    if (widget.onSeek != null) {
      final double seekPosition = (localPosition.dx / width).clamp(0.0, 1.0);
      widget.onSeek!(seekPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayProgress = _isDragging
        ? (_dragProgress ?? widget.progress)
        : widget.progress;

    return GestureDetector(
      onTapDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        _handleSeek(details.localPosition, box.size.width);
      },
      onPanStart: (details) {
        setState(() {
          _isDragging = true;
        });
      },
      onPanUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final double seekPosition = (details.localPosition.dx / box.size.width)
            .clamp(0.0, 1.0);
        setState(() {
          _dragProgress = seekPosition;
        });
      },
      onPanEnd: (details) {
        if (_dragProgress != null && widget.onSeek != null) {
          widget.onSeek!(_dragProgress!);
        }
        setState(() {
          _isDragging = false;
          _dragProgress = null;
        });
      },
      child: Container(
        height: widget.height + 16, // 增加触摸区域
        alignment: Alignment.topCenter, // 顶部对齐
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? Colors.grey[300],
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
              child: Stack(
                children: [
                  // 进度条背景
                  Container(
                    width: double.infinity,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: widget.backgroundColor ?? Colors.grey[300],
                      borderRadius: BorderRadius.circular(widget.height / 2),
                    ),
                  ),
                  // 进度条前景
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: displayProgress.clamp(0.0, 1.0),
                    child: Container(
                      height: widget.height,
                      decoration: BoxDecoration(
                        color:
                            widget.valueColor ?? Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(widget.height / 2),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
