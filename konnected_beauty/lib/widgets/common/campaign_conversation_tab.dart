import 'package:flutter/material.dart';
import 'package:konnected_beauty/core/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Conversation tab with a gentle pulse when not selected so users notice chat exists.
class CampaignConversationTabLabel extends StatefulWidget {
  final bool selected;
  final VoidCallback onTap;
  final String label;
  final Color selectedColor;
  final Color unselectedColor;
  final Color pulseColor;

  const CampaignConversationTabLabel({
    super.key,
    required this.selected,
    required this.onTap,
    required this.label,
    required this.selectedColor,
    required this.unselectedColor,
    this.pulseColor = AppTheme.greenPrimary,
  });

  @override
  State<CampaignConversationTabLabel> createState() =>
      _CampaignConversationTabLabelState();
}

class _CampaignConversationTabLabelState extends State<CampaignConversationTabLabel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pulse = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(CampaignConversationTabLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    if (!widget.selected) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final textColor = widget.selected
                  ? widget.selectedColor
                  : Color.lerp(
                      widget.unselectedColor,
                      widget.pulseColor,
                      _pulse.value * 0.7,
                    )!;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        LucideIcons.messageCircle,
                        size: 18,
                        color: textColor,
                      ),
                      if (!widget.selected)
                        Positioned(
                          top: -3,
                          right: -5,
                          child: Opacity(
                            opacity: _pulse.value,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: widget.pulseColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.pulseColor
                                        .withOpacity(0.55 * _pulse.value),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: widget.selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final underlineColor = widget.selected
                  ? widget.selectedColor
                  : widget.pulseColor.withOpacity(0.2 + 0.8 * _pulse.value);

              return Container(
                height: 3,
                decoration: BoxDecoration(
                  color: underlineColor,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: widget.selected || _pulse.value < 0.45
                      ? null
                      : [
                          BoxShadow(
                            color: widget.pulseColor.withOpacity(0.35),
                            blurRadius: 6,
                          ),
                        ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
