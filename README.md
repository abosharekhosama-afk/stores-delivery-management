# 🏪 متجر غزة الإلكتروني - تطبيق المتاجر والمناديب | Gaza E-Commerce - Vendor & Courier App

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![GetX](https://img.shields.io/badge/State_Management-GetX-purple?style=for-the-badge)](https://pub.dev/packages/get)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
> [!IMPORTANT]
> **⚠️ المشروع قيد التطوير النشط | Project Under Active Development**
> 
> **بالعربية:** يرجى العلم أن هذه المنظومة والمستودعات البرمجية المرتبطة بها لا تزال في مرحلة التطوير والاختبار النشط، ويتم تحديث الميزات ورفع الواجهات بشكل مستمر لتجهيزها للإطلاق الكامل.
> 
> **In English:** Please note that this ecosystem and its related repositories are currently under active development and testing. Features, fixes, and UI screens are continuously being updated as we push toward the stable production release.


تطبيق الهاتف المحمول المخصص **للمتاجر والمناديب**، ويمثل الشق الإداري واللوجستي لمنظومة متجر غزة الإلكتروني. يتيح لأصحاب المتاجر إدارة منتجاتهم ومبيعاتهم وتتبع إحصائياتهم، كما يُمكّن مناديب التوصيل من استلام الشحنات وتوصيلها بناءً على توجيه ذكي مجمع حسب المناطق الجغرافية بقطاع غزة.

The administrative and logistical mobile application for the Gaza E-Commerce ecosystem, built for **Vendors and Couriers**. It empowers store owners to manage products, sales, and analytics, while enabling delivery couriers to collect and deliver orders efficiently through a smart, region-based clustering system.

---

## 🌍 رؤية الشق الإداري | Administrative Vision

يهدف هذا التطبيق إلى أتمتة العمليات التجارية بالكامل داخل قطاع غزة، بدءاً من لحظة استقبال المتجر للطلب وتجهيزه، مروراً بتجميعه لوجستياً بناءً على المنطقة الجغرافية، وحتى وصوله الآمن إلى يد الزبون عبر واجهة مندوب مخصصة تدعم حل المشكلات الميدانية فورياً.

This application aims to fully automate commercial operations in the Gaza Strip. It covers everything from order reception and preparation by the vendor, through regional logistical clustering, to final delivery via a dedicated courier interface equipped for real-time issue resolution.

---

## ✨ الميزات الرئيسية | Key Features

### 🏪 أولاً: بوابة لوحة تحكم المتجر (Vendor Dashboard)
* **إدارة المنتجات الكاملة (CRUD):** إضافة، تعديل، وحذف المنتجات بسهولة مع رفع الصور سحابياً.
* **التحكم اللحظي بالمتجر:** إمكانية فتح أو إغلاق المتجر لاستقبال الطلبات بنقرة واحدة بناءً على توفر الخدمة.
* **مركز الإحصائيات المتقدمة:** عرض رسوم بيانية وتحليلات دقيقة للطلبات (المقبولة، المكتملة، والمرفوضة)، بالإضافة إلى تتبع أداء ونسبة الطلبات أسبوعياً.
* **إدارة نزاعات الاستلام:** واجهة مخصصة للتعامل مع بلاغات المناديب بشأن وجود خلل أو نقص في استلام عنصر معين من الطلب لضمان الشفافية.

### 🚴 ثانياً: بوابة نظام المندوب الذكي (Courier System)
* **بوابة التوجيه الذكي:** واجهة ديناميكية عند الدخول لتحديد هوية المستخدم وتوجيهه (متجر أم مندوب) مع نظام مصادقة آمن (تسجيل وإنشاء حساب).
* **التجميع الجغرافي اللوجستي:** نظام ذكي يقوم بتجمع المتاجر التي لديها طلبات جاهزة **حسب كل منطقة**، مما يسهل على المندوب خط سير الرحلة وتوفير الوقت والجهد.
* **إدارة عهدة المنتجات:** واجهة مخصصة تعرض للمندوب قائمة المنتجات الموجودة في حوزته حالياً والتي قام باستلامها من المتاجر قبل التوجه لتسليمها النهائي للزبائن.
* **تتبع وإدارة الشحنات:** فرز الواجهات بين "الطلبات الجاهزة للاستلام من المتاجر" و "الطلبات الجاهزة للتوصيل النهائي للزبون".

---

## 🏗️ البنية البرمجية والتقنيات | Tech Stack & Architecture

تم الحفاظ على نفس البنية التقنية الصلبة لضمان التوافق التام والتزامن اللحظي بين التطبيقين:

* **إدارة الحالة (State Management):** الاعتماد على **GetX** لضمان خفة التطبيق وسرعة استجابة واجهات الإحصائيات والرسوم البيانية.
* **التحكم الآمن (Cloud Functions):** تتم جميع عمليات تعديل حالات عناصر الطلب والعمليات المالية الحساسة عبر **Firebase Cloud Functions** لضمان أمان البيانات ومنع التلاعب وحفظ حقوق الأطراف الثلاثة (المتجر، المندوب، والزبون).
* **قاعدة البيانات والتخزين:** استخدام **Cloud Firestore** للمزامنة الفورية لحالات الطلب، و **Firebase Storage** لإدارة صور المنتجات المضافة حديثاً وبلاغات التوصيل.

---

## 📱 منظومة التطبيقات المتكاملة | Multi-App Ecosystem

هذا التطبيق يدمج دورين حيويين، وهو جزء من منظومة تشمل:
1. **تطبيق المستخدم (User App):** لتصفح المنتجات والشراء والتتبع اللحظي.
2. **تطبيق المتاجر والمناديب (Vendor & Courier App):** (هذا المستودع) لإدارة المبيعات، واللوجستيات الميدانية.
3. **لوحة تحكم الإدارة (Admin Dashboard):** للفصل في النزاعات، ومراقبة الإحصائيات العامة للمنظومة.

---

## 📸 واجهات التطبيق | App Screenshots

### 🔑 التوثيق وبوابة التوجيه (Auth & Routing)
| واجهة تحديد الهوية (متجر/مندوب) | تسجيل الدخول | إنشاء حساب جديد | التحقق من البريد | حالة الحساب |
|:---:|:---:|:---:|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/7afba32f-2109-495f-baa6-117500e8c001" width="160" /> | <img src="https://github.com/user-attachments/assets/674e5809-e78a-490d-bc96-a078f25df72a" width="160" /> | <img src="https://github.com/user-attachments/assets/c331acf7-e5c3-46a2-a4be-9c2ebc0af0d2" width="160" /> | <img src="https://github.com/user-attachments/assets/adfcb06d-5656-47c0-bfac-e1a2c39fc866" width="160" /> | <img src="https://github.com/user-attachments/assets/44b4f908-101f-4c66-b86f-32dd831f42ba" width="160" /> |

### 🏪 واجهات إدارة المتجر (Vendor Screenshots)
| عرض وإدارة المنتجات | إضافة وتعديل منتج جديد | الإحصائيات العامة والرسوم البيانية | تقارير الأداء الأسبوعية |
|:---:|:---:|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/8815e5a0-e179-4729-a9a5-224ae81a61ed" width="160" /> | <img src="https://github.com/user-attachments/assets/940196e4-e75c-4db6-a2bc-092c57e5bb8b" width="160" /> | <img src="https://github.com/user-attachments/assets/4abca3f8-5bff-4e3d-82a9-d7ca61412df7" width="160" /> | <img src="https://github.com/user-attachments/assets/f68925f3-6166-4990-b97f-1c24731bb23f" width="160" /> |
| <img src="https://github.com/user-attachments/assets/df5972c8-5e2f-44d0-9967-13afa51ec9d0" width="160" /> | <img src="https://github.com/user-attachments/assets/343c494b-b495-45e6-9ec3-773513fdb677" width="160" /> | <img src="https://github.com/user-attachments/assets/521d2792-ac00-4c7d-b79e-6c1d1b294103" width="160" /> | <img src="https://github.com/user-attachments/assets/229cb050-b71f-4fc1-aa14-ae68b057a13c" width="160" /> |
| <img src="https://github.com/user-attachments/assets/5d2be07d-3a5a-4e83-8e79-d70045f4556d" width="160" /> | <img src="https://github.com/user-attachments/assets/d7794d0b-a8b4-4438-9042-86faeb07ff78" width="160" /> | <img src="https://github.com/user-attachments/assets/c3ca338f-aac3-4a5b-8dbd-0dee4b0232ff" width="160" /> | <img src="https://github.com/user-attachments/assets/ce6b864f-9b49-4389-92c2-80176a1a80a3" width="160" /> |

### 🛠️ إدارة الطلبات والحساب (Orders & Profile Setup)
| إدارة الطلبات الواردة | تفاصيل حالة الطلب | حساب المتجر والتحكم بالحالة | مركز إشعارات الإدارة |
|:---:|:---:|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/d097f1a7-77ac-465d-90ac-d5ff57317f85" width="160" /> | <img src="https://github.com/user-attachments/assets/af6b0b42-d93c-4a78-bd72-ddcff4901e8b" width="160" /> | <img src="https://github.com/user-attachments/assets/6f95b04d-4bc9-443e-846e-5c0a46a25693" width="160" /> | <img src="https://github.com/user-attachments/assets/c1e117fb-ab13-43c2-b45f-9b02592f43a4" width="160" /> |

### 🚴 واجهات نظام المندوب واللوجستيات (Courier & Logistics)
| فرز الطلبات وتجميع المناطق | واجهة العهدة والمنتجات المستلمة | تفاصيل التوصيل والزبون | الملف الشخصي للمندوب |
|:---:|:---:|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/47647404-f3a9-494c-95fe-64cafb83bee3" width="160" /> | <img src="https://github.com/user-attachments/assets/c0f7dde9-25d0-4562-a2e9-b4d4861f5ded" width="160" /> | <img src="https://github.com/user-attachments/assets/5f7b1cd7-a9c7-47ba-877b-c1ce7552905d" width="160" /> | <img src="https://github.com/user-attachments/assets/3d7f0d29-d710-459a-bd63-b2b4a25f964a" width="160" /> |

---

## 🚀 التشغيل المحلي | Installation & Setup

1. **تحميل المشروع (Clone the repository):**
   ```bash
   git clone [https://github.com/abosharekhosama-afk/stores-delivery-management.git](https://github.com/abosharekhosama-afk/stores-delivery-management.git)
