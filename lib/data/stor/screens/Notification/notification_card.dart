import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:stors_admin_panel/data/stor/models/notification_model.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/helpers/helper_functions.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel data;
  final VoidCallback onTap;

  const NotificationCard({super.key, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    bool isOpened = data.isOpened;
    final isDark = THelperFunctions.isDarkMode(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // طابع زجاجي: خلفية فاتحة جداً مع شفافية
          color: isOpened
              ? (isDark ? TColors.darkContainer : Colors.white)
              : (TColors.primary.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOpened
                ? Colors.grey.withOpacity(0.1)
                : TColors.primary.withOpacity(0.2),
          ),
          boxShadow: [
            if (!isOpened)
              BoxShadow(
                color: TColors.primary.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // أيقونة الإشعار بتصميم دائري حديث
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isOpened
                        ? Colors.grey[200]
                        : TColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    data.type == 'REJECTION'
                        ? Iconsax.close_circle
                        : Iconsax.notification,
                    color: isOpened ? Colors.grey : TColors.primary,
                    size: 24,
                  ),
                ),
                if (!isOpened)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: TColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // محتوى الإشعار
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isOpened ? FontWeight.w500 : FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // وقت الإشعار بتنسيق "منذ متى" أو تاريخ مختصر
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data.createdAt != null
                            ? DateFormat(
                                'hh:mm a | yyyy-MM-dd',
                              ).format(data.createdAt!)
                            : "",
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                      if (!isOpened)
                        Text(
                          "جديد",
                          style: TextStyle(
                            color: TColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}




/*
class NotificationCard extends StatelessWidget {
  final Map data;
  final VoidCallback onTap;

  const NotificationCard({super.key, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    bool isOpened = data['isOpened'] ?? false;

    return Card(
      elevation: isOpened ? 1 : 4,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: isOpened
          ? Colors.white
          : Colors.teal.withAlpha((0.05 * 255).round()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isOpened ? Colors.grey[200] : Colors.teal,
          child: Icon(
            data['type'] == 'REJECTION'
                ? Icons.error_outline
                : Icons.notifications,
            color: isOpened ? Colors.grey : Colors.white,
          ),
        ),
        title: Text(
          data['title'] ?? "",
          style: TextStyle(
            fontWeight: isOpened ? FontWeight.normal : FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['body'] ?? "",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 5),
            Text(
              data['createdAt'] != null
                  ? DateFormat(
                      'hh:mm a | yyyy-MM-dd',
                    ).format(data['createdAt'].toDate())
                  : "",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        trailing: !isOpened
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }
}
*/