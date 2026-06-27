import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class NotificationTypeHelper {
  /// دالة ترجع الاسم العربي، اللون، والأيقونة بناءً على نوع الإشعار القادم من الفايربيز
  static Map<String, dynamic> getTypeDetails(String type) {
    switch (type) {
      case 'NEW_ORDER':
        return {
          'title': 'طلب جديد 📦',
          'color': Colors.green,
          'icon': Iconsax.box,
          'description': 'تم استلام طلب جديد في المتجر',
        };
      case 'withdrawal':
        return {
          'title': 'عملية سحب 💰',
          'color': Colors.amber.shade700,
          'icon': Iconsax.money_send,
          'description': 'تمت عملية سحب مالي من الحساب',
        };
      default:
        return {
          'title': 'تنبيه عام 🔔',
          'color': Colors.blue,
          'icon': Iconsax.notification,
          'description': 'إشعار جديد من النظام',
        };
    }
  }
}
