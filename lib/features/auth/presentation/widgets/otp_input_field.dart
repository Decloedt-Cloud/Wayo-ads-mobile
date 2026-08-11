import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Six digit OTP boxes with paste / SMS autofill support (optional 3–3 group).
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
  bool _updating = false;

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

  void _setDigit(int index, String digit) {
    final next = TextEditingValue(
      text: digit,
      selection: TextSelection.collapsed(offset: digit.length),
    );
    if (_ctrls[index].value != next) {
      _ctrls[index].value = next;
    }
  }

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

  void _applyDigits(int startIndex, String raw) {
    if (_updating) return;
    _updating = true;
    try {
      final digits = raw.replaceAll(RegExp(r'\D'), '');

      if (digits.isEmpty) {
        _setDigit(startIndex, '');
        if (startIndex > 0) {
          _nodes[startIndex - 1].requestFocus();
        }
        return;
      }

      // Full OTP paste / SMS autofill → fill from the first box.
      final fillFrom = digits.length >= widget.length ? 0 : startIndex;
      final toApply = digits.length >= widget.length
          ? digits.substring(0, widget.length)
          : digits;

      if (toApply.length == 1) {
        _setDigit(startIndex, toApply);
        if (startIndex < widget.length - 1) {
          _nodes[startIndex + 1].requestFocus();
        } else {
          _nodes[startIndex].unfocus();
        }
        return;
      }

      var idx = fillFrom;
      for (var j = 0; j < toApply.length && idx < widget.length; j++, idx++) {
        _setDigit(idx, toApply[j]);
      }
      // If a full code was pasted into a middle box, clear leftover multi-char.
      if (_ctrls[startIndex].text.length > 1) {
        _setDigit(
          startIndex,
          startIndex < fillFrom + toApply.length
              ? toApply[startIndex - fillFrom]
              : '',
        );
      }

      final focusIdx = idx < widget.length ? idx : widget.length - 1;
      _nodes[focusIdx].requestFocus();
    } finally {
      _updating = false;
      _notifyChanged();
    }
  }

  Widget _box(int i, BuildContext context, double width) {
    return SizedBox(
      width: width,
      height: 52,
      child: TextField(
        controller: _ctrls[i],
        focusNode: _nodes[i],
        enabled: widget.enabled,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        textInputAction: TextInputAction.next,
        autofillHints: i == 0 ? const [AutofillHints.oneTimeCode] : null,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(widget.length),
        ],
        style: AppTextStyles.headlineMedium(context).copyWith(
          fontSize: width < 36 ? 16 : 20,
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
        onChanged: (v) => _applyDigits(i, v),
        onTap: () {
          _ctrls[i].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _ctrls[i].text.length,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final grouped = widget.grouped && widget.length == 6;
          const gap = 6.0;
          final sepW = grouped ? 16.0 : 0.0;
          final gapsTotal = grouped
              ? (4 * gap) + sepW
              : (widget.length - 1) * gap;
          final maxW = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width - 48;
          final boxW =
              ((maxW - gapsTotal) / widget.length).clamp(28.0, 44.0);

          if (!grouped) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  _box(i, context, boxW),
                ],
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                _box(i, context, boxW),
              ],
              SizedBox(
                width: sepW,
                child: Text(
                  '–',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineMedium(context).copyWith(
                    fontSize: 16,
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ),
              for (var i = 3; i < 6; i++) ...[
                if (i > 3) const SizedBox(width: gap),
                _box(i, context, boxW),
              ],
            ],
          );
        },
      ),
    );
  }
}
