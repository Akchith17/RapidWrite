import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'canvas_background_painter.dart';

/// Floating or embedded toolbar providing quick stylus controls:
/// nib thickness, ink swatches, eraser, paper style, palm rejection toggle, and undo/redo.
class CanvasToolbar extends StatelessWidget {
  final Color selectedColor;
  final double selectedWidth;
  final bool isEraser;
  final bool strictStylusMode;
  final PaperStyle paperStyle;
  final bool canUndo;
  final bool canRedo;

  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<bool> onEraserToggled;
  final ValueChanged<bool> onPalmRejectionToggled;
  final ValueChanged<PaperStyle> onPaperStyleChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  const CanvasToolbar({
    super.key,
    required this.selectedColor,
    required this.selectedWidth,
    required this.isEraser,
    required this.strictStylusMode,
    required this.paperStyle,
    required this.canUndo,
    required this.canRedo,
    required this.onColorChanged,
    required this.onWidthChanged,
    required this.onEraserToggled,
    required this.onPalmRejectionToggled,
    required this.onPaperStyleChanged,
    required this.onUndo,
    required this.onRedo,
  });

  static const List<Color> _availableColors = [
    AppTheme.inkMidnight,
    AppTheme.inkRoyalBlue,
    AppTheme.inkEmerald,
    AppTheme.inkCrimson,
  ];

  static const List<double> _availableWidths = [1.8, 3.2, 5.5];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF12182B).withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryLight.withOpacity(0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Pen vs Eraser Segment
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.bgDark.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToolButton(
                  icon: Icons.edit,
                  label: 'Pen',
                  isSelected: !isEraser,
                  onTap: () => onEraserToggled(false),
                ),
                const SizedBox(width: 4),
                _ToolButton(
                  icon: Icons.auto_fix_high,
                  label: 'Eraser',
                  isSelected: isEraser,
                  onTap: () => onEraserToggled(true),
                ),
              ],
            ),
          ),

          // Nib Sizes
          if (!isEraser)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: _availableWidths.map((w) {
                final isSelected = selectedWidth == w;
                return GestureDetector(
                  onTap: () => onWidthChanged(w),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withOpacity(0.25)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: AppTheme.primaryLight, width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Container(
                        width: w * 2.8,
                        height: w * 2.8,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white60,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

          // Ink Color Swatches
          if (!isEraser)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: _availableColors.map((c) {
                final isSelected = selectedColor == c;
                return GestureDetector(
                  onTap: () => onColorChanged(c),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white24,
                        width: isSelected ? 2.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: c.withOpacity(0.6),
                                blurRadius: 8,
                              )
                            ]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),

          // Paper Guidelines Selector
          PopupMenuButton<PaperStyle>(
            initialValue: paperStyle,
            tooltip: 'Change Paper Format',
            onSelected: onPaperStyleChanged,
            color: AppTheme.surfaceDark,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: PaperStyle.ruled,
                child: Row(
                  children: [
                    Icon(Icons.format_line_spacing, size: 18, color: Colors.white70),
                    SizedBox(width: 10),
                    Text('Ruled Notebook Lines', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: PaperStyle.dottedGrid,
                child: Row(
                  children: [
                    Icon(Icons.grid_3x3, size: 18, color: Colors.white70),
                    SizedBox(width: 10),
                    Text('Dotted Drafting Grid', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: PaperStyle.blank,
                child: Row(
                  children: [
                    Icon(Icons.crop_portrait, size: 18, color: Colors.white70),
                    SizedBox(width: 10),
                    Text('Blank Digital Linen', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.bgDark.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.layers, size: 16, color: Colors.white70),
                  SizedBox(width: 6),
                  Text('Paper', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Icon(Icons.arrow_drop_down, size: 16, color: Colors.white54),
                ],
              ),
            ),
          ),

          // Strict Palm Rejection Switch
          Tooltip(
            message: strictStylusMode
                ? 'Palm Rejection Active: Only Stylus Registered (Palm Ignored)'
                : 'Touch Mode: Touch & Stylus Allowed',
            child: InkWell(
              onTap: () => onPalmRejectionToggled(!strictStylusMode),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: strictStylusMode
                      ? AppTheme.primary.withOpacity(0.3)
                      : AppTheme.bgDark.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: strictStylusMode
                        ? AppTheme.primaryLight
                        : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      strictStylusMode ? Icons.shield : Icons.shield_outlined,
                      size: 16,
                      color: strictStylusMode ? AppTheme.primaryLight : Colors.white54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      strictStylusMode ? 'Palm Guard ON' : 'Palm Guard OFF',
                      style: TextStyle(
                        color: strictStylusMode ? Colors.white : Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Undo / Redo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.undo, size: 20),
                tooltip: 'Undo Stroke',
                onPressed: canUndo ? onUndo : null,
                color: Colors.white,
                disabledColor: Colors.white24,
              ),
              IconButton(
                icon: const Icon(Icons.redo, size: 20),
                tooltip: 'Redo Stroke',
                onPressed: canRedo ? onRedo : null,
                color: Colors.white,
                disabledColor: Colors.white24,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
