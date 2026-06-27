import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class Tableheader extends StatelessWidget {
  const Tableheader({
    super.key,
    this.onPressed,
    required this.buttonText,
    required this.searchController,
    required this.focusNode,
    required this.showClear,
    this.onSearchSubmit,
    this.onClearPressed,
    this.searchOnChanged,
  });

  final void Function()? onPressed;
  final String buttonText;
  final TextEditingController searchController;
  final FocusNode focusNode;
  final bool showClear;
  final void Function()? onSearchSubmit;
  final void Function()? onClearPressed;
  final void Function(String)? searchOnChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🌟 السطر الأول: العنوان وزر الإضافة الأنيق
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "إدارة المنتجات",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            // زر الإضافة بشكل محترف ومدمج بأيقونة
            TextButton.icon(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                backgroundColor: TColors.primary.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(
                  horizontal: TSizes.md,
                  vertical: TSizes.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
                ),
              ),
              icon: const Icon(
                Iconsax.add_circle,
                size: 20,
                color: TColors.primary,
              ),
              label: Text(
                buttonText,
                style: const TextStyle(
                  color: TColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: TSizes.spaceBtwItems),

        // 🌟 السطر الثاني: حقل البحث المستقل بكامل عرض الشاشة
        TextFormField(
          controller: searchController,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          onFieldSubmitted: (_) => onSearchSubmit?.call(),
          onChanged: searchOnChanged, // فلترة فورية أثناء الكتابة إن رغبت
          decoration: InputDecoration(
            hintText: "ابحث باسم المنتج، الباركود أو التصنيف...",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(
              Iconsax.search_normal,
              color: Colors.grey.shade500,
              size: 20,
            ),
            fillColor: Colors.grey.shade50,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(vertical: TSizes.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            suffixIcon: showClear
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                    onPressed: onClearPressed,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}





/*
class Tableheader extends StatelessWidget {
  const Tableheader({
    super.key,
    this.onPressed,
    required this.buttonText,
    required this.searchController,
    required this.focusNode,
    required this.isExpanded,
    required this.showClear,
    this.onSearchSubmit,
    this.onClearPressed,
  });

  final void Function()? onPressed;
  final String buttonText;
  final TextEditingController searchController;
  final FocusNode focusNode;
  final bool isExpanded; // تأتي من الـ controller عبر الـ Obx
  final bool showClear; // تأتي من الـ controller عبر الـ Obx
  final void Function()? onSearchSubmit;
  final void Function()? onClearPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // زر إضافة منتج يتقلص أو يختفي بنعومة عند تمدد البحث
        AnimatedExpanded(
          flex: isExpanded ? 1 : 3,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isExpanded && !TDeviceUtils.isDesktopScreen(context)
                ? 0.0
                : 1.0,
            child: isExpanded && !TDeviceUtils.isDesktopScreen(context)
                ? const SizedBox.shrink()
                : ElevatedButton(
                    onPressed: onPressed,
                    child: Text(
                      buttonText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
        ),

        const SizedBox(width: 16), // مسافة ثابتة أو TSizes.spaceBtwInputFields
        // حقل البحث الذي يتمدد ديناميكياً
        AnimatedExpanded(
          flex: isExpanded ? 5 : 2,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: TextFormField(
            controller: searchController,
            focusNode: focusNode,
            textInputAction:
                TextInputAction.search, // تغيير زر الكيبورد إلى "بحث" أو "تم"
            onFieldSubmitted: (_) =>
                onSearchSubmit?.call(), // البحث عند الضغط على "تم"
            decoration: InputDecoration(
              hintText: "البحث عن منتج...",
              // أيقونة البحث كزر تفاعلي في البداية
              prefixIcon: IconButton(
                icon: const Icon(Iconsax.search_normal),
                onPressed: onSearchSubmit,
              ),
              // أيقونة الإزالة (X) تظهر فقط عند وجود نص داخل الحقل
              suffixIcon: showClear
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: onClearPressed,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ودجت مخصصة لتسهيل الـ Animation للـ Expanded
class AnimatedExpanded extends StatelessWidget {
  final int flex;
  final Duration duration;
  final Curve curve;
  final Widget child;

  const AnimatedExpanded({
    super.key,
    required this.flex,
    required this.duration,
    required this.curve,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: AnimatedContainer(duration: duration, curve: curve, child: child),
    );
  }
}

*/









/*
class Tableheader extends StatelessWidget {
  const Tableheader({
    super.key,
    this.onPressed,
    required this.buttonText,
    this.searchController,
    this.searchOnChanged,
  });

  final void Function()? onPressed;
  final String buttonText;
  final TextEditingController? searchController;
  final void Function(String)? searchOnChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: TDeviceUtils.isDesktopScreen(context) ? 3 : 1,
          child: ElevatedButton(onPressed: onPressed, child: Text(buttonText)),
        ),
        const SizedBox(width: TSizes.spaceBtwInputFields),
        Expanded(
          flex: TDeviceUtils.isDesktopScreen(context) ? 2 : 1,
          child: TextFormField(
            controller: searchController,
            onChanged: searchOnChanged,
            decoration: const InputDecoration(
              hintText: "البحث عن منتج...",
              prefixIcon: Icon(Iconsax.search_normal),
            ),
          ),
        ),
      ],
    );
  }
}
*/