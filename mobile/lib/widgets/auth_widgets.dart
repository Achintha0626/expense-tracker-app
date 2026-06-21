import 'package:flutter/material.dart';

const Color kAuthCoral = Color(0xFFE97D7D);
const Color kAuthDarkText = Color(0xFF2F2F2F);
const Color kAuthMutedText = Color(0xFF6F6A6A);
const Color kAuthLightBackground = Color(0xFFFFFBFA);
const Color kAuthSoftCoral = Color(0xFFFFE8E6);

class AuthHeaderBackground extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AuthHeaderBackground({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.35,
      width: double.infinity,
      child: Stack(
        children: [
          const Positioned.fill(child: _AuthHeaderPainterWidget()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 72,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color.fromRGBO(255, 255, 255, 0.95),
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthHeaderPainterWidget extends StatelessWidget {
  const _AuthHeaderPainterWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AuthHeaderPainter(),
      child: Container(),
    );
  }
}

class _AuthHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE97D7D), Color(0xFFFFA08E)],
      ).createShader(rect);

    canvas.drawRect(rect, paint);

    final wavePaint = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;

    final circlePaint = Paint()..color = const Color.fromRGBO(255, 255, 255, 0.1);
    

    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.18), 58, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.26), 34, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.55), 18, circlePaint);

    final wavePath = Path()
      ..moveTo(0, size.height * 0.68)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.55,
        size.width * 0.34,
        size.height * 0.68,
      )
      ..quadraticBezierTo(
        size.width * 0.53,
        size.height * 0.84,
        size.width * 0.76,
        size.height * 0.66,
      )
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.55,
        size.width,
        size.height * 0.62,
      );

    canvas.drawPath(wavePath, wavePaint);

    final smallWave = Path()
      ..moveTo(size.width * 0.02, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.28,
        size.width * 0.42,
        size.height * 0.42,
      )
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.54,
        size.width * 0.86,
        size.height * 0.38,
      );

    canvas.drawPath(smallWave, wavePaint..strokeWidth = 10);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputAction textInputAction;
  final VoidCallback? onSuffixPressed;
  final String? hintText;
  final int maxLines;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.textInputAction = TextInputAction.next,
    this.onSuffixPressed,
    this.hintText,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: kAuthCoral),
        suffixIcon: suffixIcon == null
            ? null
            : IconButton(
                onPressed: onSuffixPressed,
                icon: suffixIcon!,
              ),
        filled: true,
        fillColor: Colors.white,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: kAuthCoral, width: 1.4),
        ),
      ),
    );
  }
}

class PrimaryAuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryAuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: kAuthCoral,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              )
            : Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
