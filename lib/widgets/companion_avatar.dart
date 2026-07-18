import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/companion_progress.dart';

class CompanionAvatar extends StatefulWidget {
  final double size;

  final CompanionStage stage;
  final CompanionMood mood;

  final VoidCallback? onTap;

  const CompanionAvatar({
    super.key,
    required this.stage,
    required this.mood,
    this.size = 120,
    this.onTap,
  });

  @override
  State<CompanionAvatar> createState() =>
      _CompanionAvatarState();
}

class _CompanionAvatarState
    extends State<CompanionAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _bounceController;

  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2200,
      ),
    )..repeat();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 420,
      ),
    );

    _bounceAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(
          tween: Tween(
            begin: 1,
            end: 1.08,
          ),
          weight: 35,
        ),
        TweenSequenceItem(
          tween: Tween(
            begin: 1.08,
            end: 0.97,
          ),
          weight: 30,
        ),
        TweenSequenceItem(
          tween: Tween(
            begin: 0.97,
            end: 1,
          ),
          weight: 35,
        ),
      ],
    ).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _idleController.dispose();
    _bounceController.dispose();

    super.dispose();
  }

  void _handleTap() {
    _bounceController.forward(
      from: 0,
    );

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _idleController,
        builder: (context, child) {
          final wave = math.sin(
            _idleController.value *
                math.pi *
                2,
          );

          final verticalMovement =
              wave * widget.size * 0.018;

          final idleScale =
              1 + (wave * 0.008);

          return Transform.translate(
            offset: Offset(
              0,
              verticalMovement,
            ),
            child: Transform.scale(
              scale: idleScale,
              child: ScaleTransition(
                scale: _bounceAnimation,
                child: child,
              ),
            ),
          );
        },
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _CompanionPainter(
              stage: widget.stage,
              mood: widget.mood,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanionPainter extends CustomPainter {
  final CompanionStage stage;
  final CompanionMood mood;

  const _CompanionPainter({
    required this.stage,
    required this.mood,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height * 0.56,
    );

    final bodyRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.72,
      height: size.height * 0.67,
    );

    _drawShadow(
      canvas,
      size,
    );

    _drawEars(
      canvas,
      size,
    );

    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.wineStrong,
          AppColors.wineDark,
        ],
      ).createShader(bodyRect);

    canvas.drawOval(
      bodyRect,
      bodyPaint,
    );

    final borderPaint = Paint()
      ..color = AppColors.wine
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.018;

    canvas.drawOval(
      bodyRect,
      borderPaint,
    );

    _drawFace(
      canvas,
      size,
    );

    _drawStageDetail(
      canvas,
      size,
    );
  }

  void _drawShadow(
    Canvas canvas,
    Size size,
  ) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(
        alpha: 0.25,
      )
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        8,
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          size.width / 2,
          size.height * 0.91,
        ),
        width: size.width * 0.58,
        height: size.height * 0.12,
      ),
      shadowPaint,
    );
  }

  void _drawEars(
    Canvas canvas,
    Size size,
  ) {
    final earPaint = Paint()
      ..color = AppColors.wineDark;

    final borderPaint = Paint()
      ..color = AppColors.wine
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.016;

    final leftEar = Rect.fromCenter(
      center: Offset(
        size.width * 0.31,
        size.height * 0.27,
      ),
      width: size.width * 0.25,
      height: size.height * 0.28,
    );

    final rightEar = Rect.fromCenter(
      center: Offset(
        size.width * 0.69,
        size.height * 0.27,
      ),
      width: size.width * 0.25,
      height: size.height * 0.28,
    );

    canvas.drawOval(
      leftEar,
      earPaint,
    );

    canvas.drawOval(
      rightEar,
      earPaint,
    );

    canvas.drawOval(
      leftEar,
      borderPaint,
    );

    canvas.drawOval(
      rightEar,
      borderPaint,
    );
  }

  void _drawFace(
    Canvas canvas,
    Size size,
  ) {
    final leftEye = Offset(
      size.width * 0.4,
      size.height * 0.53,
    );

    final rightEye = Offset(
      size.width * 0.6,
      size.height * 0.53,
    );

    final facePaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = size.width * 0.027
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (mood) {
      case CompanionMood.sleepy:
        canvas.drawLine(
          Offset(
            leftEye.dx - size.width * 0.035,
            leftEye.dy,
          ),
          Offset(
            leftEye.dx + size.width * 0.035,
            leftEye.dy,
          ),
          facePaint,
        );

        canvas.drawLine(
          Offset(
            rightEye.dx - size.width * 0.035,
            rightEye.dy,
          ),
          Offset(
            rightEye.dx + size.width * 0.035,
            rightEye.dy,
          ),
          facePaint,
        );

      case CompanionMood.happy:
      case CompanionMood.energized:
        canvas.drawArc(
          Rect.fromCenter(
            center: leftEye,
            width: size.width * 0.095,
            height: size.height * 0.075,
          ),
          math.pi,
          math.pi,
          false,
          facePaint,
        );

        canvas.drawArc(
          Rect.fromCenter(
            center: rightEye,
            width: size.width * 0.095,
            height: size.height * 0.075,
          ),
          math.pi,
          math.pi,
          false,
          facePaint,
        );

      case CompanionMood.curious:
      case CompanionMood.calm:
        final eyePaint = Paint()
          ..color = AppColors.textPrimary;

        canvas.drawCircle(
          leftEye,
          size.width * 0.026,
          eyePaint,
        );

        canvas.drawCircle(
          rightEye,
          size.width * 0.026,
          eyePaint,
        );
    }

    _drawMouth(
      canvas,
      size,
    );

    final blushPaint = Paint()
      ..color = AppColors.textPrimary.withValues(
        alpha: 0.12,
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          size.width * 0.32,
          size.height * 0.64,
        ),
        width: size.width * 0.11,
        height: size.height * 0.055,
      ),
      blushPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          size.width * 0.68,
          size.height * 0.64,
        ),
        width: size.width * 0.11,
        height: size.height * 0.055,
      ),
      blushPaint,
    );
  }

  void _drawMouth(
    Canvas canvas,
    Size size,
  ) {
    final mouthPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.025
      ..strokeCap = StrokeCap.round;

    final mouthCenter = Offset(
      size.width * 0.5,
      size.height * 0.65,
    );

    switch (mood) {
      case CompanionMood.curious:
        canvas.drawCircle(
          mouthCenter,
          size.width * 0.025,
          mouthPaint,
        );

      case CompanionMood.sleepy:
        canvas.drawLine(
          Offset(
            mouthCenter.dx - size.width * 0.035,
            mouthCenter.dy,
          ),
          Offset(
            mouthCenter.dx + size.width * 0.035,
            mouthCenter.dy,
          ),
          mouthPaint,
        );

      case CompanionMood.energized:
      case CompanionMood.happy:
      case CompanionMood.calm:
        canvas.drawArc(
          Rect.fromCenter(
            center: mouthCenter,
            width: size.width * 0.16,
            height: size.height * 0.11,
          ),
          0,
          math.pi,
          false,
          mouthPaint,
        );
    }
  }

  void _drawStageDetail(
    Canvas canvas,
    Size size,
  ) {
    switch (stage) {
      case CompanionStage.newcomer:
        _drawSprout(
          canvas,
          size,
        );

      case CompanionStage.companion:
        _drawCollar(
          canvas,
          size,
        );

      case CompanionStage.explorer:
        _drawStarBadge(
          canvas,
          size,
        );

      case CompanionStage.veteran:
        _drawCrown(
          canvas,
          size,
        );
    }
  }

  void _drawSprout(
    Canvas canvas,
    Size size,
  ) {
    final stemPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.018
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(
        size.width * 0.5,
        size.height * 0.22,
      ),
      Offset(
        size.width * 0.5,
        size.height * 0.1,
      ),
      stemPaint,
    );

    final leafPaint = Paint()
      ..color = AppColors.wineStrong;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          size.width * 0.44,
          size.height * 0.11,
        ),
        width: size.width * 0.13,
        height: size.height * 0.07,
      ),
      leafPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          size.width * 0.56,
          size.height * 0.09,
        ),
        width: size.width * 0.13,
        height: size.height * 0.07,
      ),
      leafPaint,
    );
  }

  void _drawCollar(
    Canvas canvas,
    Size size,
  ) {
    final collarPaint = Paint()
      ..color = AppColors.textPrimary
          .withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(
          size.width * 0.5,
          size.height * 0.67,
        ),
        width: size.width * 0.53,
        height: size.height * 0.35,
      ),
      0.2,
      math.pi - 0.4,
      false,
      collarPaint,
    );
  }

  void _drawStarBadge(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width * 0.68,
      size.height * 0.75,
    );

    final path = Path();

    for (var index = 0; index < 10; index++) {
      final radius = index.isEven
          ? size.width * 0.075
          : size.width * 0.035;

      final angle =
          (-math.pi / 2) +
          (index * math.pi / 5);

      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );

      if (index == 0) {
        path.moveTo(
          point.dx,
          point.dy,
        );
      } else {
        path.lineTo(
          point.dx,
          point.dy,
        );
      }
    }

    path.close();

    final starPaint = Paint()
      ..color = AppColors.textPrimary
          .withValues(alpha: 0.85);

    canvas.drawPath(
      path,
      starPaint,
    );
  }

  void _drawCrown(
    Canvas canvas,
    Size size,
  ) {
    final path = Path()
      ..moveTo(
        size.width * 0.37,
        size.height * 0.22,
      )
      ..lineTo(
        size.width * 0.41,
        size.height * 0.08,
      )
      ..lineTo(
        size.width * 0.5,
        size.height * 0.18,
      )
      ..lineTo(
        size.width * 0.59,
        size.height * 0.08,
      )
      ..lineTo(
        size.width * 0.63,
        size.height * 0.22,
      )
      ..close();

    final crownPaint = Paint()
      ..color = AppColors.textPrimary
          .withValues(alpha: 0.88);

    canvas.drawPath(
      path,
      crownPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _CompanionPainter oldDelegate,
  ) {
    return oldDelegate.stage != stage ||
        oldDelegate.mood != mood;
  }
}