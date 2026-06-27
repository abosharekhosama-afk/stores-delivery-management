import 'package:flutter/material.dart';
import 'package:stors_admin_panel/common/widgets/shimmers/TransactionShimmer.dart';

class TransactionListShimmer extends StatelessWidget {
  final int itemCount;
  const TransactionListShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    // نستخدم الـ SliverList إذا كنت تستخدمها مباشرة داخل الـ CustomScrollView الاقتصادية المحدثة
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => const TransactionShimmer(),
        childCount: itemCount,
      ),
    );
  }
}
