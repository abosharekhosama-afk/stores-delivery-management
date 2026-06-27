import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:stors_admin_panel/data/Driver/Notification/service/driver_notification_controller.dart'; // لتنسيق الوقت

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DriverNotificationController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "الإشعارات",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data();
              bool isOpened = data['isOpened'] ?? false;

              return _buildNotificationCard(doc.id, data, isOpened, controller);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    String docId,
    Map<String, dynamic> data,
    bool isOpened,
    DriverNotificationController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isOpened ? Colors.white : Colors.blue.withAlpha((0.05 * 255).round()),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isOpened ? Colors.transparent : Colors.blue.withAlpha((0.1 * 255).round()),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () => controller.markAsOpened(docId),
        leading: _buildLeadingIcon(data['type']),
        title: Text(
          data['title'] ?? 'إشعار جديد',
          style: TextStyle(
            fontWeight: isOpened ? FontWeight.normal : FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              data['body'] ?? '',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(data['createdAt']),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: isOpened ? Colors.redAccent : Colors.grey[300],
          ),
          onPressed: () => controller.deleteNotification(docId, isOpened),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(String? type) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'NEW_ORDER_AVAILABLE':
        iconData = Icons.local_shipping;
        color = Colors.green;
        break;
      case 'SYSTEM_ALERT':
        iconData = Icons.warning_amber_rounded;
        color = Colors.amber;
        break;
      default:
        iconData = Icons.notifications_none_rounded;
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            "لا توجد إشعارات حالياً",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "";
    DateTime date = (timestamp as Timestamp).toDate();
    return DateFormat('hh:mm a').format(date);
  }
}


