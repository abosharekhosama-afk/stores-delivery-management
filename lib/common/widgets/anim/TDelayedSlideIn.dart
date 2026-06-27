import 'package:flutter/material.dart';

// تعريف الاتجاهات المتاحة للأنيميشن

// تعريف الاتجاهات المتاحة للأنيميشن
enum SlideDirection { leftToRight, rightToLeft, topToBottom, bottomToTop }

class TDelayedSlideIn extends StatefulWidget {
  final Widget child;
  final int delayInMilliseconds;
  final SlideDirection direction;
  final bool isScrollingDown; // إضافة هذا المتغير لمعرفة اتجاه التمرير الحالي

  const TDelayedSlideIn({
    super.key,
    required this.child,
    this.delayInMilliseconds = 0,
    this.direction = SlideDirection.bottomToTop,
    this.isScrollingDown = true, // افتراضياً نعم
  });

  @override
  State<TDelayedSlideIn> createState() => _TDelayedSlideInState();
}

class _TDelayedSlideInState extends State<TDelayedSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slide = Tween<Offset>(
      begin: _getBeginOffset(),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));

    // التحقق: إذا كان المستخدم يصعد للأعلى، لا ننتظر ولا نحرك، نعرض الكارت فوراً
    if (!widget.isScrollingDown) {
      _controller.value = 1.0; // يضع الأنميشن في نهايته فوراً (مكتمل ومكتوم)
    } else {
      if (widget.delayInMilliseconds > 0) {
        Future.delayed(Duration(milliseconds: widget.delayInMilliseconds), () {
          if (mounted) _controller.forward();
        });
      } else {
        _controller.forward();
      }
    }
  }

  Offset _getBeginOffset() {
    // إذا لم يكن يمرر لأسفل، نجعل الـ Offset صفراً حتى لا يقفز الكارت أثناء الصعود
    if (!widget.isScrollingDown) return Offset.zero;

    switch (widget.direction) {
      case SlideDirection.leftToRight:
        return const Offset(-0.15, 0);
      case SlideDirection.rightToLeft:
        return const Offset(0.15, 0);
      case SlideDirection.topToBottom:
        return const Offset(0, -0.15);
      case SlideDirection.bottomToTop:
        return const Offset(0, 0.15);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}


/*
class TDelayedSlideIn extends StatefulWidget {
  final Widget child;
  final int delayInMilliseconds;
  final SlideDirection direction;

  const TDelayedSlideIn({
    super.key,
    required this.child,
    this.delayInMilliseconds = 0, // قيمة افتراضية 0 لعدم التأخير إلا عند الطلب
    this.direction =
        SlideDirection.bottomToTop, // الاتجاه الافتراضي المريح للقوائم
  });

  @override
  State<TDelayedSlideIn> createState() => _TDelayedSlideInState();
}

class _TDelayedSlideInState extends State<TDelayedSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    // تقليل المدة ليكون الانيميشن أسرع (400ms بدلاً من 500ms)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slide = Tween<Offset>(
      begin: _getBeginOffset(), // جلب نقطة البداية بناءً على الاتجاه
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));

    // بدء الأنيميشن بعد التأخير المحدد
    if (widget.delayInMilliseconds > 0) {
      Future.delayed(Duration(milliseconds: widget.delayInMilliseconds), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  // دالة لتحديد من أين يبدأ العنصر حركته (المسافة بسيطة 0.15 لسرعة الإيحاء)
  Offset _getBeginOffset() {
    switch (widget.direction) {
      case SlideDirection.leftToRight:
        return const Offset(-0.15, 0);
      case SlideDirection.rightToLeft:
        return const Offset(0.15, 0);
      case SlideDirection.topToBottom:
        return const Offset(0, -0.15);
      case SlideDirection.bottomToTop:
        return const Offset(0, 0.15);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

*/

//////////



/*
class TDelayedSlideIn extends StatelessWidget {
  final Widget child;
  final int delayInMilliseconds;
  final SlideDirection direction; // الخاصية الجديدة

  const TDelayedSlideIn({
    super.key,
    required this.child,
    this.delayInMilliseconds = 0,
    this.direction = SlideDirection.rightToLeft, // القيمة الافتراضية اختيارية
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
      // إضافة التأخير الزمني
      builder: (context, value, child) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: value,
          child: Transform.translate(offset: _getOffset(value), child: child),
        );
      },
      // استخدام Future.delayed للتحكم في وقت البدء بناءً على delayInMilliseconds
      child: child,
    );
  }

  // دالة لحساب المسافة بناءً على الاتجاه المختار
  Offset _getOffset(double value) {
    double distance = 50 * (1 - value);
    switch (direction) {
      case SlideDirection.leftToRight:
        return Offset(-distance, 0);
      case SlideDirection.rightToLeft:
        return Offset(distance, 0);
      case SlideDirection.topToBottom:
        return Offset(0, -distance);
      case SlideDirection.bottomToTop:
        return Offset(0, distance);
    }
  }
}
*/

/*
class TDelayedSlideIn extends StatefulWidget {
  final Widget child;
  final int delayInMilliseconds;

  const TDelayedSlideIn({
    super.key,
    required this.child,
    required this.delayInMilliseconds,
  });

  @override
  State<TDelayedSlideIn> createState() => _TDelayedSlideInState();
}

class _TDelayedSlideInState extends State<TDelayedSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 600,
      ), // زدنا المدة قليلاً ليكون التأثير أنعم
    );

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // التعديل هنا:
    // Offset(0.3, 0) تعني سيبدأ من اليمين بمقدار 30% من عرض الشاشة
    // وينتهي عند Offset.zero أي مكانه الطبيعي
    _slide = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    Future.delayed(Duration(milliseconds: widget.delayInMilliseconds), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
*/