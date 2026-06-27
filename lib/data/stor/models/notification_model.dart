import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // مثل: 'NEW_ORDER', 'withdrawal', 'REJECTION'
  final DateTime? createdAt;
  bool isOpened;
  bool isRead;

  NotificationModel({
    required this.id,
    this.title = "",
    this.body = "",
    this.type = "",
    this.createdAt,
    this.isOpened = false,
    this.isRead = false,
  });

  // --- اسم الكولكشن الثابت في الفايربيس ---
  static String get getCollectionName => "Notifications";

  // --- أسماء الحقول الثابتة في الفايربيس منعا للأخطاء الإملائية ---
  static String get getFieldTitle => "title";
  static String get getFieldBody => "body";
  static String get getFieldType => "type";
  static String get getFieldCreatedAt => "createdAt";
  static String get getFieldIsOpened => "isOpened";
  static String get getFieldIsRead => "isRead";

  // --- نموذج فارغ للاستخدام الافتراضي عند الحاجة ---
  static NotificationModel empty() =>
      NotificationModel(id: "", createdAt: DateTime.now());

  // --- تحويل الموديل إلى Map لحفظه في الفايربيس ---
  Map<String, dynamic> toJson() {
    return {
      getFieldTitle: title,
      getFieldBody: body,
      getFieldType: type,
      getFieldCreatedAt: createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      getFieldIsOpened: isOpened,
      getFieldIsRead: isRead,
    };
  }

  // --- تحويل الـ DocumentSnapshot القادم من الفايربيس إلى الموديل بذكاء وأمان ---
  factory NotificationModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!snapshot.exists || snapshot.data() == null) {
      return NotificationModel.empty();
    }

    final data = snapshot.data()!;

    return NotificationModel(
      id: snapshot.id,
      title: data[getFieldTitle] ?? "",
      body: data[getFieldBody] ?? "",
      type: data[getFieldType] ?? "الكل",
      // معالجة الـ Timestamp بأمان لضمان عدم حدوث انهيار إذا كان الوقت فارغاً في السيرفر مؤقتاً
      createdAt: data[getFieldCreatedAt] != null
          ? (data[getFieldCreatedAt] as Timestamp).toDate()
          : null,
      isOpened: data[getFieldIsOpened] ?? false,
      isRead: data[getFieldIsRead] ?? false,
    );
  }

  // --- دالة النسخ والتعديل السحرية (copyWith) لتحديث البيانات محلياً فوراً ---
  NotificationModel copyWith({
    String? title,
    String? body,
    String? type,
    DateTime? createdAt,
    bool? isOpened,
    bool? isRead,
  }) {
    return NotificationModel(
      id: this.id, // المعرف يبقى ثابتاً دائماً
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isOpened: isOpened ?? this.isOpened,
      isRead: isRead ?? this.isRead,
    );
  }
}
