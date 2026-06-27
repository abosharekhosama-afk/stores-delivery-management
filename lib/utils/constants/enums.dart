import 'package:hive/hive.dart'; // 1. هذا السطر ناقص عندكpart 'enums.g.dart'; // 2. وهذا السطر ضروري جداً لتوليد الـ Adapter
part 'enums.g.dart'; // 2. وهذا السطر ضروري جداً لتوليد الـ Adapter

/* --
      LIST OF Enums
      They cannot be created inside a class.
-- */

/// Switch of Custom Brand-Text-Size Widget
enum AppRole { admin, driver }

enum StoreStatus { active, suspended, pending }

enum Daye { pm, am }

enum TransactionType { buy, sell }

enum ProductType { single, variable }

@HiveType(typeId: 4) // رقم ID جديد لم يُستخدم
enum ProductVisibility {
  @HiveField(0)
  published,

  @HiveField(1)
  hidden,
}

enum TextSizes { small, medium, large }

enum ImageType { asset, network, memory, file }

enum MediaCategory { folders, banners, brands, categories, products, users }

enum PaymentMethods {
  paypal,
  googlePay,
  applePay,
  visa,
  masterCard,
  creditCard,
  paystack,
  razorPay,
  paytm,
}

enum OrderStatus {
  pending, // الطلب بانتظار المراجعة أو الدفع
  processing, // الطلب قيد التجهيز (تم قبول بعض أو كل العناصر)
  accepted,
  shipped, // الطلب بالكامل مع المندوب وفي الطريق للعميل
  delivered, // تم التسليم بنجاح
  cancelled, // تم إلغاء الطلب بالكامل
  refunded, // تم استرداد مبالغ العناصر المرفوضة للعميل
  readyForPickup,
  rejected,
}

/// 2. حالة كل عنصر داخل الطلب (خاص بالتعامل بين المتجر والمندوب)
enum ItemStatus {
  pending, // العنصر جديد وبانتظار موافقة صاحب المتجر
  accepted, // تم قبول العنصر من قبل المتجر
  rejected, // تم رفض العنصر (غير متوفر مثلاً) - سيتم تفعيل استرداد المبلغ هنا
  readyForPickup, // المتجر قام بتغليف العنصر وهو جاهز الآن ليستلمه المندوب
  shipped, // العنصر تم استلامه من قبل المندوب وهو في الطريق
  delivered, // تم تسليم هذا العنصر تحديداً للعميل
  cancelled, // تم إلغاء هذا العنصر من قبل العميل قبل البدء بتجهيزه
  pickupFailed_Confirmed, // تم تأكيد فشل استلام العنصر من قبل المندوب (مثلاً بسبب مشكلة في العنوان أو عدم وجود العميل)
  pickupFailed_WaitingAction, // تم الإبلاغ عن فشل استلام العنصر من قبل المندوب، ونحن الآن في انتظار رد المتجر (هل يريد إعادة جدولة الاستلام أو إلغاء العنصر)
}

enum DeliveryStatus { pickedUp, onTheWay, delivered }
