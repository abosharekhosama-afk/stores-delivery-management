import 'package:flutter/material.dart';

class TDialogs {
  static defaultDialog({
    required BuildContext context,
    String title = 'تاكيد الحذف',
    String content =
        'ازالة هذه البيانات سوف حذف جميع البيانات بشكل نهائي. هل انت متاكد',
    String cancelText = 'الغاء',
    String confirmText = 'حذف',
    Function()? onCancel,
    Function()? onConfirm,
  }) {
    // Show a confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: onCancel ?? () => Navigator.of(context).pop(),
              child: Text(cancelText),
            ),
            TextButton(onPressed: onConfirm, child: Text(confirmText)),
          ],
        );
      },
    );
  }
}
