import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Six single-digit fields with auto-advance and [onCompleted] when full.
class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
    this.length = 6,
    required this.onCompleted,
  });

  final int length;
  final ValueChanged<String> onCompleted;

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
    final code = _ctrls.map((c) => c.text).join();
    if (code.length == widget.length && !_fired) {
      _fired = true;
      widget.onCompleted(code);
      HapticFeedback.lightImpact();
    } else if (code.length < widget.length) {
      _fired = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (i) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextField(
            controller: _ctrls[i],
            focusNode: _nodes[i],
            maxLength: 1,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.headlineMedium(context).copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.surfaceElevatedOf(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            onChanged: (v) => _onChanged(i, v),
          ),
        );
      }),
    );
  }
}
