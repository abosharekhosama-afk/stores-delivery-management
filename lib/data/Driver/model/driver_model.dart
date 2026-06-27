import 'package:cloud_firestore/cloud_firestore.dart';

class DriverModel {
  // --- ثوابت أسماء الحقول (Field Constants) ---
  // تمكنك من استدعاء DriverModel.fldName بدلاً من كتابة "name" يدوياً
  static const String driverCollectionName = 'DeliveryDrivers';
  static const String fldId = 'id';
  static const String fldName = 'name';
  static const String fldEmail = 'email';
  static const String fldPhone = 'phoneNumber';
  static const String fldImage = 'profilePicture';
  static const String fldIsActive = 'isActive';
  static const String fldRole = 'role';
  static const String fldLastTokenUpdate = 'lastTokenUpdate';
  static const String fldCreatedAt = 'createdAt';
  static const String fldToken = 'fcmToken';

  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String profilePicture;
  final bool isActive;
  final String role;
  final String? fcmToken;
  final DateTime? lastTokenUpdate;
  final DateTime? createdAt;

  DriverModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber = '',
    this.profilePicture = '',
    this.isActive = true,
    this.role = 'driver',
    this.fcmToken = '',
    this.lastTokenUpdate,
    this.createdAt,
  });

  // --- تحويل الكائن إلى JSON لحفظه في Firestore ---
  Map<String, dynamic> toJson() => {
    fldId: id,
    fldName: name,
    fldEmail: email,
    fldPhone: phoneNumber,
    fldImage: profilePicture,
    fldIsActive: isActive,
    fldRole: role,
    fldToken: fcmToken,
    fldLastTokenUpdate: lastTokenUpdate,
    fldCreatedAt: createdAt,
  };

  // --- تحويل Map (JSON) إلى كائن Model ---
  factory DriverModel.fromJson(Map<String, dynamic> json) => DriverModel(
    id: json[fldId] ?? '',
    name: json[fldName] ?? '',
    email: json[fldEmail] ?? '',
    phoneNumber: json[fldPhone] ?? '',
    profilePicture: json[fldImage] ?? '',
    isActive: json[fldIsActive] ?? true,
    role: json[fldRole] ?? 'driver',
    fcmToken: json[fldToken] ?? '',
    lastTokenUpdate: json[fldLastTokenUpdate] != null
        ? (json[fldLastTokenUpdate] as Timestamp).toDate()
        : null,
  );

  // --- الدالة المطلوبة: تحويل DocumentSnapshot مباشرة إلى Model ---
  // تسهل عليك التعامل مع البيانات القادمة من Firestore مباشرة
  factory DriverModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (snapshot.data() != null) {
      final data = snapshot.data()!;
      return DriverModel(
        id:
            data[fldId] ??
            snapshot.id, // نأخذ الـ ID من المستند نفسه لضمان الدقة
        name: data[fldName] ?? '',
        email: data[fldEmail] ?? '',
        phoneNumber: data[fldPhone] ?? '',
        profilePicture: data[fldImage] ?? '',
        isActive: data[fldIsActive] ?? true,
        role: data[fldRole] ?? 'driver',
        fcmToken: data[fldToken] ?? '',
        lastTokenUpdate: data[fldLastTokenUpdate] != null
            ? (data[fldLastTokenUpdate] as Timestamp).toDate()
            : null,
        createdAt: data[fldCreatedAt] != null
            ? (data[fldCreatedAt] as Timestamp).toDate()
            : DateTime.now(),
      );
    } else {
      // إرجاع كائن فارغ أو افتراضي في حال كان المستند خالي
      return DriverModel.empty();
    }
  }

  // ميثود إضافية لإنشاء كائن فارغ (تفيد في التهيئة الابتدائية)
  static DriverModel empty() => DriverModel(id: '', name: '', email: '');
}
