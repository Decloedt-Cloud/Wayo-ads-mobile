import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Six single-digit fields with auto-advance (optional 3–3 separator).
class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.grouped = false,
    this.autoSubmit = true,
    this.enabled = true,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final bool grouped;
  final bool autoSubmit;
  final bool enabled;

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late final List<TextEditingController> _ctrls;
  late final List<FocusNode> _nodes;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _ctrls.map((c) => c.text).join();

  void _notifyChanged() {
    widget.onChanged?.call(_code);
    if (widget.autoSubmit &&
        _code.length == widget.length &&
        !_fired &&
        widget.enabled) {
      _fired = true;
      widget.onCompleted(_code);
      HapticFeedback.lightImpact();
    } else if (_code.length < widget.length) {
      _fired = false;
    }
  }

  void _onChanged(int i, String v) {
    if (v.length > 1) {
      final last = v.substring(v.length - 1);
      _ctrls[i].text = last;
      _ctrls[i].selection = TextSelection.collapsed(offset: 1);
    }
    if (v.isNotEmpty && i < widget.length - 1) {
      _nodes[i + 1].requestFocus();
    }
    if (v.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    }
    _notifyChanged();
  }

  Widget _box(int i, BuildContext context) {
    return SizedBox(
      width: 42,
      height: 52,
      child: TextField(
        controller: _ctrls[i],
        focusNode: _nodes[i],
        enabled: widget.enabled,
        maxLength: 1,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppTextStyles.headlineMedium(context).copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.surfaceElevatedOf(context),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.textMutedOf(context).withValues(alpha: 0.25),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.textMutedOf(context).withValues(alpha: 0.25),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        onChanged: (v) => _onChanged(i, v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.grouped || widget.length != 6) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(widget.length, (i) => _box(i, context)),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _box(i, context),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '–',
            style: AppTextStyles.headlineMedium(context).copyWith(
              fontSize: 18,
              color: AppColors.textMutedOf(context),
            ),
          ),
        ),
        for (var i = 3; i < 6; i++) ...[
          if (i > 3) const SizedBox(width: 8),
          _box(i, context),
        ],
      ],
    );
  }
}
