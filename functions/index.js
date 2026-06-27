
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https"); // تأكد من استيراد onCall
const { onDocumentWritten } = require("firebase-functions/v2/firestore"); // 🌟 تأكد من استيراد onDocumentWritten

const admin = require("firebase-admin");

if (admin.apps.length === 0) {
    admin.initializeApp();
}

const db = admin.firestore();
// دالة مساعدة لجلب مرجع الإحصائيات العامة
const getGlobalRef = () => admin.firestore().collection("SystemSettings").doc("globalStats");
/**
 * دالة مساعدة مركزية لحفظ الإشعارات في الكولكشن الفرعي المناسب
 */
async function logNotification(targetType, targetId, notificationData) {
    // targetType: "Users" أو "Stores"
    await admin.firestore()
        .collection(targetType)
        .doc(targetId)
        .collection("Notifications")
        .add({
            ...notificationData,
            isRead: false,
            isOpened: false, // الشرط الذي طلبته لمنع الحذف
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
}

/**
 * دالة مساعدة تدعم الترانزاكشن لحفظ الإشعار
 */
function logNotificationWithTransaction(transaction, targetType, targetId, notificationData) {
    const notificationRef = admin.firestore()
        .collection(targetType)
        .doc(targetId)
        .collection("Notifications")
        .doc(); // ننشئ مرجع مستند جديد (بدون حفظه بعد)

    transaction.set(notificationRef, {
        ...notificationData,
        isRead: false,
        isOpened: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}



// 2. الدالة المساعدة لإرسال إشعار الـ FCM الفوري مع ميزة الصلاحية لـ 48 ساعة
async function sendFcmNotification(userId, title, body, orderId, type = "order_status", netProfit = null) {
    try {
        // جلب التوكن الخاص بجهاز العميل من مستند المستخدم
        const userDoc = await db.collection("User").doc(userId).get();
        if (!userDoc.exists) return;
        
        const fcmToken = userDoc.data().fcmToken;
        if (!fcmToken) {
            console.log(`ℹ️ No FCM Token found for user: ${userId}`);
            return;
        }

        const message = {
            token: fcmToken,
            notification: {
                title: title,
                body: body,
            },
            data: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                orderId: orderId,
                type: type // جعل الـ type ديناميكي (مثل vendor_order أو order_status)
            },
            // 🌟 إعدادات أندرويد المتقدمة لضمان الاستيقاظ والصوت العالي لمدة 48 ساعة
            android: {
                priority: "high", // أولوية قصوى لكسر وضع توفير الطاقة
                ttl: 172800000,   // 48 ساعة بالميلي ثانية
                notification: {
                    channelId: "high_importance_channel", // القناة الحساسة في فلاتر
                    defaultSound: true,
                    defaultVibrateTimings: true,
                    clickAction: "FLUTTER_NOTIFICATION_CLICK"
                }
            },
            // 🌟 إعدادات آيفون (APNs) لضمان المحاولة ووصول الصوت العالي
            apns: {
                headers: {
                    "apns-priority": "10", // أولوية قصوى لنظام iOS
                    "apns-expiration": (Math.floor(Date.now() / 1000) + 172800).toString(), // انتهاء الصلاحية بعد 48 ساعة
                },
                payload: {
                    aps: {
                        alert: {
                            title: title,
                            body: netProfit ? `${body}. ربحك الصافي: ${netProfit.toFixed(2)} شيكل` : body
                        },
                        sound: "default",
                        badge: 1
                    }
                }
            }
        };

        await admin.messaging().send(message);
        console.log(`⚡ FCM Notification sent successfully to user ${userId}`);
    } catch (fcmError) {
        console.error("❌ Failed to send FCM delivery:", fcmError);
    }
}


/**
 * 🌟 الدالة المركزية الموحدة والمطورة لإرسال وحفظ الإشعارات (إصدار 48 ساعة + حماية الحذف)
 * تجمع بين الحفظ في الفايرستور والإرسال الفوري لـ FCM بدلاً من تشتيت الكود
 */
async function sendUnifiedNotification({ targetType, targetId, title, body, dataPayload = {}, isCritical = false, skipFirestoreSave = false }) {
    try {
        // 1️⃣ خطوة الحفظ التوثيقي في الفايرستور لمنع الضياع من قاعدة البيانات
      if (!skipFirestoreSave) { 
        const notificationData = {
            title: title,
            body: body,
            type: dataPayload.type || "GENERAL",
            mainOrderId: dataPayload.orderId || "",
            isRead: false,
            isOpened: false,     // الشرط المانع للحذف من التطبيق
            isCritical: isCritical, // علم حرج لتطبيق الفلاتر لجعله غير قابل للمسح بالسحب (Ongoing)
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        await admin.firestore()
            .collection(targetType)
            .doc(targetId)
            .collection("Notifications")
            .add(notificationData);

        console.log(`💾 Notification logged in Firestore for ${targetType} (${targetId})`);
      }
        // 2️⃣ خطوة جلب الـ FCM Token الخاص بالجهاز المستهدف بشكل ديناميكي
        // يدعم جلب التوكن سواء كان المستهدف زبون (User) أو متجر (Stores) أو مندوب (DeliveryDrivers)
        const collectionName = targetType === "User" ? "User" : targetType;
        const targetDoc = await db.collection(collectionName).doc(targetId).get();
        
        if (!targetDoc.exists) return;
        const fcmToken = targetDoc.data().fcmToken;
        
        if (!fcmToken) {
            console.log(`ℹ️ No FCM Token found for ${targetType}: ${targetId}`);
            return;
        }

        // 3️⃣ بناء الحمولة المتقدمة لـ FCM لضمان البقاء 48 ساعة والحماية من التجاهل
        const message = {
            token: fcmToken,
            notification: {
                title: title,
                body: body,
            },
            data: {
                ...dataPayload,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                isCritical: isCritical.toString() // يقرأها الفلاتر لتعيين أسلوب عرض ثابت وصارم
            },
            android: {
                priority: "high",      // كسر أوضاع خمول البطارية (Doze Mode) فوراً
                ttl: 172800000,        // ⏰ الصمود والمحاولة المستمرة لمدة 48 ساعة كاملة بالملي ثانية
                notification: {
                    channelId: isCritical ? "critical_alerts_channel" : "high_importance_channel", 
                    defaultSound: true,
                    defaultVibrateTimings: true,
                    clickAction: "FLUTTER_NOTIFICATION_CLICK",
                    sticky: isCritical, // يمنع حذف الإشعار بالسحب اليدوي في بعض إصدارات أندرويد المدعومة
                }
            },
            apns: {
                headers: {
                    "apns-priority": "10", // أولوية قصوى فورية لـ iOS
                    "apns-expiration": (Math.floor(Date.now() / 1000) + 172800).toString(), // ⏰ وقت انتهاء الصلاحية بعد 48 ساعة للآيفون
                },
                payload: {
                    aps: {
                        alert: { title, body },
                        sound: "default",
                        badge: 1
                    }
                }
            }
        };

        const response = await admin.messaging().send(message);
        console.log(`⚡ FCM Notification pushed successfully! ID: ${response}`);

    } catch (error) {
        // يتم التقاط الخطأ بشكل معزول لضمان عدم تعطل العمليات المالية والـ Transactions الأساسية بالسيرفر
        console.error("❌ Failed in centralized sendUnifiedNotification:", error);
    }
}



/*
async function sendFcmNotification(userId, title, body, orderId) {
    try {
        // جلب التوكن الخاص بجهاز العميل من مستند المستخدم
        const userDoc = await db.collection("User").doc(userId).get();
        if (!userDoc.exists) return;
        
        const fcmToken = userDoc.data().fcmToken; // تأكد من اسم حقل التوكن لديك في كوليكشن User
        if (!fcmToken) {
            console.log(`ℹ️ No FCM Token found for user: ${userId}`);
            return;
        }

        const message = {
            token: fcmToken,
            notification: {
                title: title,
                body: body,
            },
            data: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                orderId: orderId,
                type: "order_status"
            },
            // 🌟 ضبط صلاحية الإشعار لمدة 48 ساعة (48 * 3600 = 172800 ثانية)
            android: {
                ttl: 172800 * 1000, // بالملي ثانية في كود الأندرويد
                notification: {
                    clickAction: "FLUTTER_NOTIFICATION_CLICK"
                }
            },
            apns: {
                headers: {
                    "apns-expiration": Math.floor(Date.now() / 1000 + 172800).toString() // بروتوكول آيفون للأوقات الطويلة
                }
            }
        };

        await admin.messaging().send(message);
        console.log(`⚡ FCM Notification sent successfully to user ${userId}`);
    } catch (fcmError) {
        // نضعها في catch منفصلة حتى لا يتسبب فشل شبكة هاتف العميل في تدمير الـ Transaction بالكامل
        console.error("❌ Failed to send FCM delivery:", fcmError);
    }
}
*/



// 🛠️ دالة مساعدة لتحويل النصوص الزمنية ISO8601 إلى كائنات Timestamp حقيقية للفايرستور
function convertStringTimestampsToTimestamp(obj) {
    if (obj === null || obj === undefined) return obj;

    // إذا كان العنصر نصاً ويطابق صيغة تاريخ ISO8601 أو صيغة تاريخ كاملة
    if (typeof obj === "string") {
        const dateParsed = Date.parse(obj);
        // نتحقق أن النص يمثل تاريخاً صالحاً وليس نصاً عادياً، وأنه يحتوي على مؤشرات الوقت
        if (!isNaN(dateParsed) && (obj.includes("-") || obj.includes(":"))) {
            return admin.firestore.Timestamp.fromDate(new Date(dateParsed));
        }
    }

    // إذا كان مصفوفة، نقوم بفحص عناصرها
    if (Array.isArray(obj)) {
        return obj.map(item => convertStringTimestampsToTimestamp(item));
    }

    // إذا كان كائناً (Object/Map)، نقوم بفحص مفاتيح الحقول داخله بشكل تكراري
    if (typeof obj === "object") {
        const processedObj = {};
        for (const key in obj) {
            if (obj.hasOwnProperty(key)) {
                processedObj[key] = convertStringTimestampsToTimestamp(obj[key]);
            }
        }
        return processedObj;
    }

    return obj;
}

/**
 * 1. دالة تقسيم الطلب الرئيسي إلى طلبات متاجر (تلقائية عند الدفع)
 */


exports.splitOrderOnPayment = onDocumentWritten("Orders/{orderId}", async (event) => {
    // 1. التحقق من وجود بيانات (تجنب الأخطاء في حال تم حذف المستند)
    if (!event.data || !event.data.after.exists) return null;

    const beforeData = event.data.before.exists ? event.data.before.data() : null;
    const afterData = event.data.after.data();
    const db = admin.firestore();
    const mainOrderId = event.params.orderId;

    // 2. التحقق من حقل التقسيم لمنع التكرار (isSplit) - خط الدفاع الأول والأقوى
    if (afterData.isSplit === true) {
        console.log(`ℹ️ Order ${mainOrderId} is already split. Skipping.`);
        return null;
    }

    // 3. صياغة الشرط المرن والذكي:
    // الحالة أ: تحول من انتظار الدفع البنكي إلى مدفوع (تعديل مستند)
    const isPaidFromBank = beforeData && beforeData.Status === "pendingPayment" && afterData.Status === "pending";
    
    // الحالة ب: تم إنشاء الطلب مباشرة بحالة pending (دفع محفظة فوري - مستند جديد)
    const isPaidFromWalletDirectly = (!beforeData && afterData.Status === "pending");

    // إذا تحقق أي من الشرطين، نقوم بعملية الفرز المالي والتقسيم
    if (isPaidFromBank || isPaidFromWalletDirectly) {
        console.log(`🚀 Processing split for Order: ${mainOrderId} | Reason: ${isPaidFromBank ? 'Bank Paid (Update)' : 'Wallet Paid (Create)'}`);
        
        // جلب المنتجات مع معالجة حالة الأحرف
        const items = afterData.Items || afterData.items || [];
        const storeGroups = {};

        // تجميع الأصناف حسب المتجر
        items.forEach(item => {
            const sId = item.storeId || item.StoreId;
            if (sId) {
                if (!storeGroups[sId]) storeGroups[sId] = [];
                storeGroups[sId].push(item);
            }
        });

        // إذا كانت السلة فارغة لسبب ما
        if (Object.keys(storeGroups).length === 0) {
            console.log(`⚠️ No store groups found for order ${mainOrderId}`);
            return null;
        }

        const batch = db.batch();
        const storeIds = Object.keys(storeGroups);

        storeIds.forEach((storeId, index) => {
            const storeItems = storeGroups[storeId];
            
            // توليد اللاحقة الرقمية (01، 02...)
            const storeSuffix = String(index + 1).padStart(2, '0');
            const customStoreOrderId = `${mainOrderId}${storeSuffix}`;
            
            const storeOrderRef = db.collection("StoreOrders").doc(customStoreOrderId);
            const pickupCode = (Math.floor(100000 + Math.random() * 900000)).toString();

            batch.set(storeOrderRef, {
                Id: customStoreOrderId,
                MainOrderId: mainOrderId,
                StoreId: storeId,
                Items: storeItems,
                Status: "pending",
                OrderDate: admin.firestore.FieldValue.serverTimestamp(),
                UserAddress: afterData.Address || afterData.userAddress || {},
                UserId: afterData.UserId || afterData.userId,
                PickupCode: pickupCode,
            });
            
            console.log(`🎯 Generated StoreOrder ID: ${customStoreOrderId} for Store: ${storeId}`);
        });

        // تحديث الطلب الرئيسي: إضافة حقل isSplit لضمان عدم التكرار نهائياً تحت أي ظرف
        batch.update(event.data.after.ref, { 
            isSplit: true,
            splitAt: admin.firestore.FieldValue.serverTimestamp() 
        });

        try {
            await batch.commit();
            console.log(`✅ Order ${mainOrderId} split into ${Object.keys(storeGroups).length} stores successfully.`);
        } catch (error) {
            console.error("❌ Batch Commit Error:", error);
        }
    }

    return null;
});

/*
exports.splitOrderOnPayment = onDocumentUpdated("Orders/{orderId}", async (event) => {
    // التحقق من وجود بيانات (تجنب الأخطاء في حال تم حذف المستند)
    if (!event.data || !event.data.after.exists) return null;

    const beforeData = event.data.before.exists ? event.data.before.data() : null;
    const afterData = event.data.after.data();
    const db = admin.firestore();
    const mainOrderId = event.params.orderId;

    // 1. التحقق من حقل التقسيم لمنع التكرار (isSplit)
    const isAlreadySplit = afterData.isSplit === true;

    if (isAlreadySplit) {
        console.log(`ℹ️ Order ${mainOrderId} is already split. Skipping.`);
        return null;
    }

    // 2. صياغة الشرط الجديد المرن والمحمي:
    // الحالة أ: تحول من انتظار الدفع البنكي إلى مدفوع (pending)
    const isPaidFromBank = beforeData && beforeData.Status === "pendingPayment" && afterData.Status === "pending";
    
    // الحالة ب: تم إنشاء الطلب مباشرة بحالة (pending) عبر المحفظة ولم يكن هناك مستند قديم
    const isPaidFromWalletDirectly = (!beforeData || beforeData.Status === undefined) && afterData.Status === "pending";

    // إذا تحقق أي من الشرطين، نقوم بعملية الفرز المالي والتقسيم
    if (isPaidFromBank || isPaidFromWalletDirectly) {
        console.log(`🚀 Processing split for Order: ${mainOrderId} | Reason: ${isPaidFromBank ? 'Bank Paid' : 'Wallet Paid'}`);
        
        // جلب المنتجات مع معالجة حالة الأحرف (تأكد من مطابقة الحقل في الفايرستور Items أو items)
        const items = afterData.Items || afterData.items || [];
        const storeGroups = {};

        // تجميع الأصناف حسب المتجر
        items.forEach(item => {
            const sId = item.storeId || item.StoreId;
            if (sId) {
                if (!storeGroups[sId]) storeGroups[sId] = [];
                storeGroups[sId].push(item);
            }
        });

        // إذا كانت السلة فارغة لسبب ما، لا داعي لعمل Batch فارغ
        if (Object.keys(storeGroups).length === 0) {
            console.log(`⚠️ No store groups found for order ${mainOrderId}`);
            return null;
        }

        const batch = db.batch();

        // تحويل مفاتيح المتاجر إلى مصفوفة للتمكن من استخدام الـ Index الرقمي
        const storeIds = Object.keys(storeGroups);

        storeIds.forEach((storeId, index) => {
            const storeItems = storeGroups[storeId];
            
            // 🌟 1. توليد الـ اللاحقة الرقمية (مثال: 01، 02، 03) لشكل منسق وثابت الطول
            const storeSuffix = String(index + 1).padStart(2, '0');
            
            // 🌟 2. تركيب المعرف الرقمي النقي الفريد (رقم الطلب الرئيسي + اللاحقة الرقمية)
            // مثال: إذا كان الرئيسي 540254594، يصبح الفرعي 54025459401
            const customStoreOrderId = `${mainOrderId}${storeSuffix}`;
            
            const storeOrderRef = db.collection("StoreOrders").doc(customStoreOrderId);
            const pickupCode = (Math.floor(100000 + Math.random() * 900000)).toString();

            batch.set(storeOrderRef, {
                Id: customStoreOrderId, // المعرف الرقمي النقي الجديد والمريح للمناديب والتجار
                MainOrderId: mainOrderId,
                StoreId: storeId,
                Items: storeItems,
                Status: "pending",
                OrderDate: admin.firestore.FieldValue.serverTimestamp(),
                UserAddress: afterData.Address || afterData.userAddress || {},
                UserId: afterData.UserId || afterData.userId,
                PickupCode: pickupCode,
            });
            
            console.log(`🎯 Generated Clean Numeric StoreOrder ID: ${customStoreOrderId} for Store: ${storeId}`);
        });

        // تحديث الطلب الرئيسي: إضافة حقل isSplit لضمان عدم التكرار نهائياً تحت أي ظرف
        batch.update(event.data.after.ref, { 
            isSplit: true,
            splitAt: admin.firestore.FieldValue.serverTimestamp() 
        });

        try {
            await batch.commit();
            console.log(`✅ Order ${mainOrderId} split into ${Object.keys(storeGroups).length} stores successfully.`);
        } catch (error) {
            console.error("❌ Batch Commit Error:", error);
        }
    }

    return null;
});
*/

/*
exports.splitOrderOnPayment = onDocumentUpdated("Orders/{orderId}", async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    const db = admin.firestore();

    // الشرط: تغير الحالة من انتظار دفع إلى "pending" 
    // مع فحص حقل isSplit (حتى لو لم يكن موجوداً في المستند سيعتبر undefined وبالتالي !isAlreadySplit ستكون true)
    const isPaidNow = beforeData.Status === "pendingPayment" && afterData.Status === "pending";
    const isAlreadySplit = afterData.isSplit === true;

    if (isPaidNow && !isAlreadySplit) {
        console.log(`🚀 Processing split for Order: ${event.params.orderId}`);
        
        const items = afterData.Items || [];
        const storeGroups = {};

        // تجميع الأصناف حسب المتجر
        items.forEach(item => {
            const sId = item.storeId || item.StoreId;
            if (!storeGroups[sId]) storeGroups[sId] = [];
            storeGroups[sId].push(item);
        });

        const batch = db.batch();

        // إنشاء مستندات StoreOrders
        Object.keys(storeGroups).forEach(storeId => {
            const storeItems = storeGroups[storeId];
            const storeOrderRef = db.collection("StoreOrders").doc();
            const pickupCode = (Math.floor(100000 + Math.random() * 900000)).toString();

            batch.set(storeOrderRef, {
                MainOrderId: event.params.orderId,
                StoreId: storeId,
                Items: storeItems,
                Status: "pending",
                OrderDate: admin.firestore.FieldValue.serverTimestamp(),
                UserAddress: afterData.Address  || {},
                UserId: afterData.UserId,
                PickupCode: pickupCode,
            });
        });

        // تحديث الطلب الرئيسي: إضافة حقل isSplit لضمان عدم التكرار أبداً
        batch.update(event.data.after.ref, { 
            isSplit: true,
            splitAt: admin.firestore.FieldValue.serverTimestamp() 
        });

        try {
            await batch.commit();
            console.log(`✅ Order ${event.params.orderId} split into ${Object.keys(storeGroups).length} stores.`);
        } catch (error) {
            console.error("❌ Batch Commit Error:", error);
        }
    }
    return null;
});*/




/**
 * 1. عند إنشاء طلب: حساب الأرباح، تحديث المحفظة، وإشعار التاجر
 */
exports.onStoreOrderCreated = onDocumentCreated("StoreOrders/{storeOrderId}", async (event) => {
    const orderData = event.data.data();
    const storeId = (orderData.StoreId || "").trim();
    if (!storeId) return console.error("❌ StoreId missing.");

    const items = orderData.Items || [];
    let totalOrderAmount = 0;
    items.forEach(item => {
        totalOrderAmount += (parseFloat(item.price) || 0) * (parseInt(item.Quantity) || 1);
    });

    try {
        const storeRef = admin.firestore().collection("Stores").doc(storeId);
        const storeDoc = await storeRef.get();
        if (!storeDoc.exists) return;

        const commissionRate = storeDoc.data().commissionRate || 2; 
        const netProfit = totalOrderAmount * (1 - (commissionRate / 100));

        // تحديث محفظة المتجر وتسجيل المعاملة
        await storeRef.update({ 
            "wallet.pendingBalance": admin.firestore.FieldValue.increment(netProfit) ,
            "totalOrders": admin.firestore.FieldValue.increment(1) // تحديث الإحصائيات
        });

        // تحديث الإحصائيات العامة للمنصة
        await getGlobalRef().set({
            totalOrders: admin.firestore.FieldValue.increment(1),
            totalPotentialRevenue: admin.firestore.FieldValue.increment(totalOrderAmount)
        }, { merge: true });

        // تسجيل المعاملة في الفايرستور
        await admin.firestore().collection("Transactions").add({
            storeId,
            orderId: event.params.storeOrderId,
            amount: netProfit,
            type: "order_revenue",
            status: "pending",
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // 🌟 استدعاء الدالة الموحدة الجديدة (تغنيك عن سطور الـ FCM والـ logNotification السابقة بالكامل)
        const title = "طلب جديد وارد! 🛍️";
        const body = `وصلك طلب جديد. ربحك الصافي: ${netProfit.toFixed(2)} شيكل`;

        await sendUnifiedNotification({
            targetType: "Stores", // تحديد نوع المستهدف (كوليكشن المتجر)
            targetId: storeId,
            title: title,
            body: body,
            dataPayload: { 
                orderId: event.params.storeOrderId, 
                type: "vendor_order" 
            },
            isCritical: true // 🔥 تفعيل وضع الأهمية القصوى (صمود 48 ساعة + منع الحذف من هاتف التاجر إلا بالنقر)
        });

    } catch (error) {
        console.error("🔥 Error in onStoreOrderCreated:", error);
    }
});

/*
exports.onStoreOrderCreated = onDocumentCreated("StoreOrders/{storeOrderId}", async (event) => {
    const orderData = event.data.data();
    const storeId = (orderData.StoreId || "").trim();
    if (!storeId) return console.error("❌ StoreId missing.");

    const items = orderData.Items || [];
    let totalOrderAmount = 0;
    items.forEach(item => {
        totalOrderAmount += (parseFloat(item.price) || 0) * (parseInt(item.Quantity) || 1);
    });

    try {
        const storeRef = admin.firestore().collection("Stores").doc(storeId);
        const storeDoc = await storeRef.get();
        if (!storeDoc.exists) return;

        const commissionRate = storeDoc.data().commissionRate || 2; 
        const netProfit = totalOrderAmount * (1 - (commissionRate / 100));

        // تحديث محفظة المتجر وتسجيل المعاملة
        await storeRef.update({ 
            "wallet.pendingBalance": admin.firestore.FieldValue.increment(netProfit) ,
            "totalOrders": admin.firestore.FieldValue.increment(1) // تحديث الإحصائيات
        });

        // تحديث الإحصائيات العامة للمنصة
        await getGlobalRef().set({
            totalOrders: admin.firestore.FieldValue.increment(1),
            totalPotentialRevenue: admin.firestore.FieldValue.increment(totalOrderAmount)
        }, { merge: true });


        await admin.firestore().collection("Transactions").add({
            storeId,
            orderId: event.params.storeOrderId,
            amount: netProfit,
            type: "order_revenue",
            status: "pending",
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // إشعار التاجر (تخزين + FCM)
        const title = "طلب جديد وارد! 🛍️";
        const body = `وصلك طلب جديد. ربحك الصافي: ${netProfit.toFixed(2)} شيكل`;
        
        await logNotification("Stores", storeId, { title, body, type: "NEW_ORDER", orderId: event.params.storeOrderId });

        const fcmToken = storeDoc.data().fcmToken;
        if (fcmToken) {
            
                const message ={
                token: fcmToken,
                notification: { title, body },
                data: { orderId: event.params.storeOrderId, type: "vendor_order" },
                // إعدادات أندرويد لضمان المحاولة لمدة 48 ساعة
        android: {
            priority: "high",
            ttl: 172800000, // 48 ساعة بالميلي ثانية
            notification: {
                channelId: "high_importance_channel",
                defaultSound: true,
                defaultVibrateTimings: true,
            }
        },
        // إعدادات آيفون لضمان المحاولة لمدة 48 ساعة
        apns: {
            headers: {
                "apns-priority": "10",
                "apns-expiration": (Math.floor(Date.now() / 1000) + (48 * 3600)).toString(), // وقت الانتهاء بعد 48 ساعة
            },
            payload: {
                aps: {
                    alert: {
                        title: "طلب جديد وارد! 🛍️",
                        body: `وصلك طلب جديد. ربحك الصافي: ${netProfit.toFixed(2)} شيكل`
                    },
                    sound: "default",
                    badge: 1
                }
            }
        }
            };
            // إرسال الرسالة مع معالجة الخطأ
    await admin.messaging().send(message)
        .then((response) => {
            console.log('✅ Successfully sent message:', response);
        })
        .catch((error) => {
            console.error('❌ Error sending FCM message:', error);
        });
        }

        
    } catch (error) {
        console.error("🔥 Error in onStoreOrderCreated:", error);
    }
});
*/
/**
 * 2. عند تحديث الطلب: معالجة الرفض (إرجاع مالي + إشعار زبون) وتحرير الأموال عند التوصيل
 */
exports.onStoreOrderUpdated = onDocumentUpdated("StoreOrders/{storeOrderId}", async (event) => {
    const newData = event.data.after.data();
    const previousData = event.data.before.data();
    const storeId = newData.StoreId;
    const userId = newData.UserId;
    const mainOrderId = newData.MainOrderId;
    const newItems = [...(newData.Items || [])];
    const oldItems = previousData.Items || [];
    const statusBefore = previousData.Status;
    const statusAfter = newData.Status;

    try {
        const storeRef = admin.firestore().collection("Stores").doc(storeId);
        const globalRef = getGlobalRef();
        const userRef = admin.firestore().collection('User').doc(userId);
        const userSnap = await userRef.get();
        
        // --- 1. إحصائيات القبول والرفض الكلية ---
        if (statusAfter === "accepted" && statusBefore !== "accepted") {
            await storeRef.set({ acceptedOrders: admin.firestore.FieldValue.increment(1) }, { merge: true });
            await globalRef.set({ acceptedOrders: admin.firestore.FieldValue.increment(1) }, { merge: true });
        } else if (statusAfter === "rejected" && statusBefore !== "rejected") {
            await storeRef.set({ rejectedOrders: admin.firestore.FieldValue.increment(1) }, { merge: true });
            await globalRef.set({ rejectedOrders: admin.firestore.FieldValue.increment(1) }, { merge: true });   
        }

        // --- 2 + 3. الدمج المالي المركزي لمرحلة الرفض ومزامنة الشحن الكلي ---
        let totalNetToDeductFromStore = 0;
        let totalGrossToReturnToUser = 0;
        const rejectedItemsToProcess = [];

        const storeDoc = await storeRef.get();
        const commRate = storeDoc.exists ? (storeDoc.data().commissionRate || 2) : 2;

        // تجميع السلع المرفوضة حديثاً في هذا التحديث
        for (const item of newItems) {
            const oldItem = oldItems.find(o => o.productId === item.productId);
            if (item.itemStatus === "rejected" && (!oldItem || oldItem.itemStatus !== "rejected") && !item.refunded) {
                const itemGross = (parseFloat(item.price) || 0) * (parseInt(item.Quantity) || item.quantity || 1);
                const itemNet = itemGross * (1 - (commRate / 100));
                
                rejectedItemsToProcess.push({ item, itemGross, itemNet });
                totalNetToDeductFromStore += itemNet;
                totalGrossToReturnToUser += itemGross;
                
                item.refunded = true; 
            }
        }

        // 🌟 إطلاق الترانزاكشن المركزي الموحد لإدارة كافة الحسابات (المنتجات + الشحن)
        if (rejectedItemsToProcess.length > 0 && mainOrderId) {
            const mainOrderRef = admin.firestore().collection("Orders").doc(mainOrderId);
            let shouldSendRejectionFcm = false;
            let finalUserRefundText = "";

            await admin.firestore().runTransaction(async (transaction) => {
                // قراءة مستند الطلب الرئيسي بشكل آمن داخل الترانزاكشن لمنع التضارب
                const mainOrderDoc = await transaction.get(mainOrderRef);
                if (!mainOrderDoc.exists) return;

                const mainOrderData = mainOrderDoc.data();
                let mainItems = mainOrderData.Items || [];
                let additionalRefundForMain = 0;
                let shippingRefundAmount = 0;
                let shouldRefundShipping = false;

                // تحديث حالات المنتجات داخل مصفوفة الطلب الرئيسي وتجهيز مبالغ الرد الكلية
                mainItems = mainItems.map(mItem => {
                    const updated = newItems.find(ni => ni.productId === mItem.productId);
                    if (updated && updated.itemStatus !== mItem.itemStatus) {
                        if (updated.itemStatus === "rejected" && mItem.itemStatus !== "rejected") {
                            additionalRefundForMain += (parseFloat(mItem.price) || 0) * (parseInt(mItem.Quantity) || mItem.quantity || 1);
                        }
                        return { ...mItem, itemStatus: updated.itemStatus };
                    }
                    return mItem;
                });

                // 🎯 الفحص الحاسم: هل مات الطلب بالكامل الآن؟
                const isAllOrderItemsDead = mainItems.every(item => 
                    item.itemStatus === "rejected" || item.itemStatus === "cancelled"
                );
                const currentShippingAmount = parseFloat(mainOrderData.ShippingAmount) || 0;

                // إذا مات الطلب كلياً ورسوم الشحن لم تُرد بعد، ندرجها فوراً في نفس عملية الرد للعميل!
                if (isAllOrderItemsDead && currentShippingAmount > 0) {
                    shouldRefundShipping = true;
                    shippingRefundAmount = currentShippingAmount;
                    totalGrossToReturnToUser += shippingRefundAmount; // 🌟 إضافة الشحن لصافي مستردات العميل الكلية فوراً
                }

                // 💸 تحديث رصيد محفظة المستخدم الإجمالي (منتجات + شحن إن وجد) في حركة واحدة
                transaction.update(userRef, {
                    walletBalance: admin.firestore.FieldValue.increment(Number(totalGrossToReturnToUser.toFixed(2)))
                });

                // خصم صافي الأرباح المعلقة من محفظة المتجر
                transaction.update(storeRef, {
                    "wallet.pendingBalance": admin.firestore.FieldValue.increment(-Number(totalNetToDeductFromStore.toFixed(2)))
                });

                // إنشاء حركات مستندات المرتجعات للسلع المرفوضة
                for (const entry of rejectedItemsToProcess) {
                    const userTransRef = userRef.collection('Transactions').doc();
                    transaction.set(userTransRef, {
                        id: userTransRef.id,
                        orderId: mainOrderId,
                        amount: entry.itemGross,
                        type: 'refund',
                        status: 'completed',
                        date: admin.firestore.FieldValue.serverTimestamp(),
                        description: `مرتجع منتج غير متوفر: ${entry.item.Title}`,
                        productId: entry.item.productId
                    });

                    const storeTransRef = admin.firestore().collection("Transactions").doc();
                    transaction.set(storeTransRef, {
                        storeId: storeId,
                        orderId: event.params.storeOrderId,
                        amount: -entry.itemNet,
                        type: "refund",
                        status: "completed",
                        productId: entry.item.productId,
                        productName: entry.item.Title,
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                    });

                    const adminRefundRef = admin.firestore().collection("RejectedRefunds").doc();
                    transaction.set(adminRefundRef, {
                        refundId: adminRefundRef.id,
                        orderId: mainOrderId,
                        storeOrderId: event.params.storeOrderId,
                        userId: userId,
                        userName: `${userSnap.data()?.FirstName || ""} ${userSnap.data()?.LastName || ""}`.trim() || "زبون غير معروف",
                        userPhone: userSnap.data()?.PhoneNumber || "",
                        bankAccount: userSnap.data()?.BankNoumber || "",
                        bankType: userSnap.data()?.BankName || "",
                        bankAccountName: userSnap.data()?.BankAccountName || "",
                        productId: entry.item.productId,
                        productName: entry.item.Title,
                        amountToRefund: entry.itemGross,
                        status: "pending",
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        storeId: storeId,
                    });
                }

                // 🚚 إذا تم استرداد الشحن، ننشئ له وثيقة حركة مالية منفصلة في كوليكشن المستخدم للشفافية
                if (shouldRefundShipping) {
                    const shippingTransRef = userRef.collection('Transactions').doc();
                    transaction.set(shippingTransRef, {
                        id: shippingTransRef.id,
                        orderId: mainOrderId,
                        amount: shippingRefundAmount,
                        type: 'refund',
                        status: 'completed',
                        date: admin.firestore.FieldValue.serverTimestamp(),
                        description: `إرجاع رسوم التوصيل (الطلب مرفوض/ملغي بالكامل)`
                    });
                }

                // بناء حمولة تحديث مستند الطلب الرئيسي (Orders) بشكل نهائي وثابت
                const updatePayload = { Items: mainItems };
                if (shouldRefundShipping) {
                    updatePayload.ShippingAmount = 0; // تصفير حقل الشحن لمنع تكرار العملية
                }
                if (additionalRefundForMain > 0) {
                    updatePayload.RejectedAmount = admin.firestore.FieldValue.increment(additionalRefundForMain);
                }

                // تحديث مستند الطلب الرئيسي داخل الترانزاكشن لضمان الثبات والسرعة
                transaction.update(mainOrderRef, updatePayload);

                // إعداد نص الإشعار للتوصيل لاحقاً بشكل موحد
                finalUserRefundText = shouldRefundShipping 
                    ? `تم إرجاع مبالغ المنتجات مع رسوم التوصيل (₪${totalGrossToReturnToUser.toFixed(2)}) لمحفظتك لعدم توفر الطلب.`
                    : `تم إرجاع مبلغ ₪${totalGrossToReturnToUser.toFixed(2)} لمحفظتك عن منتجات مرفوضة.`;

                // تسجيل إشعار النظام الموحد داخل الترانزاكشن لقاعدة البيانات لحماية التوافقية
                logNotificationWithTransaction(transaction, "User", userId, {
                    title: "تحديث بخصوص المرتجعات 💰",
                    body: finalUserRefundText,
                    type: "REJECTION",
                    mainOrderId
                });
                
                shouldSendRejectionFcm = true;
            });

            // تحديث مستند طلب المتجر (StoreOrders) الفرعي بوضع علم الخصم المالي (refunded = true)
            await event.data.after.ref.update({ Items: newItems });

            // 🌟 إرسال الإشعار المالي الموحد عبر الـ FCM (صمود 48 ساعة وحذف مشروط بالنقرة)
            if (shouldSendRejectionFcm) {
                await sendUnifiedNotification({
                    targetType: "User",
                    targetId: userId,
                    title: "تحديث بخصوص المرتجعات 💰",
                    body: finalUserRefundText,
                    dataPayload: { orderId: mainOrderId, type: "REJECTION" },
                    isCritical: true // حماية الإشعار المالي من المسح العشوائي
                });
            }
        } 

        // --- 4. مزامنة الحالة العامة للطلب الرئيسي (تحديث الحالات: shipped, delivered, rejected) ---
        if (mainOrderId) {
            const mainOrderRef = admin.firestore().collection("Orders").doc(mainOrderId);
            const mainOrderDoc = await mainOrderRef.get();
            
            if (mainOrderDoc.exists) {
                const allSubOrdersSnapshot = await admin.firestore()
                    .collection("StoreOrders")
                    .where("MainOrderId", "==", mainOrderId)
                    .get();

                const subOrdersDocs = allSubOrdersSnapshot.docs;

                const checkAllStoresMetCondition = (allowedStatuses) => {
                    const normalizedAllowed = allowedStatuses.map(s => s.toLowerCase());
                    return subOrdersDocs.every(doc => normalizedAllowed.includes((doc.data().Status || "").toLowerCase()));
                };

                let newGlobalStatus = null;
                let notifyUser = false;
                let notificationTitle = "";
                let notificationBody = "";
                let notificationType = "";

                if (checkAllStoresMetCondition(["shipped", "rejected"]) && subOrdersDocs.some(d => (d.data().Status || "").toLowerCase() === "shipped")) {
                    newGlobalStatus = "shipped";
                    notifyUser = true;
                    notificationTitle = "طلبك في الطريق! 🚚";
                    notificationBody = "جميع المتاجر سلمت أغراضك وهي الآن مع المندوب للشحن.";
                    notificationType = "ORDER_SHIPPED";
                }
                else if (checkAllStoresMetCondition(["readyForPickup", "shipped", "rejected"])) {
                    newGlobalStatus = "readyForPickup";
                }
                else if (checkAllStoresMetCondition(["delivered", "rejected"]) && subOrdersDocs.some(d => (d.data().Status || "").toLowerCase() === "delivered")) {
                    newGlobalStatus = "delivered";
                    notifyUser = true;
                    notificationTitle = "تم توصيل طلبك بنجاح! 🎉";
                    notificationBody = "سُعدنا بخدمتك، نتمنى أن نكون عند حسن ظنك دائماً.";
                    notificationType = "ORDER_DELIVERED";
                }
                else if (checkAllStoresMetCondition(["rejected"])) {
                    newGlobalStatus = "rejected";
                    notifyUser = true;
                    notificationTitle = "نعتذر منك، تم إلغاء الطلب بالكامل 🛑";
                    notificationBody = "تم إلغاء الطلب بالكامل لعدم توفر العناصر، وتم رد مبالغ المنتجات مع رسوم التوصيل لمحفظتك.";
                    notificationType = "ORDER_REJECTED";
                }
                else if (subOrdersDocs.some(d => (d.data().Status || "").toLowerCase() === "accepted")) {
                    if (mainOrderDoc.data().Status === "pending" || mainOrderDoc.data().Status === "pendingPayment") {
                        newGlobalStatus = "accepted";
                    }
                }

                if (newGlobalStatus && newGlobalStatus !== mainOrderDoc.data().Status) {
                    await mainOrderRef.update({ Status: newGlobalStatus });

                    // 🌟 استبدال الكود القديم بالكامل بالدالة الموحدة لإرسال تحديثات الحالة للمستخدم
                    if (notifyUser) {
                        await sendUnifiedNotification({
                            targetType: "User",
                            targetId: userId,
                            title: notificationTitle,
                            body: notificationBody,
                            dataPayload: { orderId: mainOrderId, type: notificationType },
                            isCritical: true // تفعيل ميزة التثبيت لضمان رؤية العميل لحالة شحن طلباته الحساسة
                        });
                    }
                }
            }
        }

        // --- 5. إشعار المناديب (Ready for Pickup) ---
        const currentNormalizedStatus = (newData.Status || "").toLowerCase();
        const previousNormalizedStatus = (previousData.Status || "").toLowerCase();

        if (currentNormalizedStatus === "readyforpickup" && previousNormalizedStatus !== "readyforpickup") {
            const driversSnapshot = await admin.firestore().collection("DeliveryDrivers").where("isActive", "==", true).get();
            if (!driversSnapshot.empty) {
                const storeName = storeDoc.data()?.storName || "متجر";
                const nTitle = "طلب جديد جاهز 📦";
                const nBody = `المتجر ${storeName} بانتظار استلام الطلب.`;

                // 🌟 توحيد إشعار المندوبين المتوازي بـ 48 ساعة كاملة لضمان وصول الطلب حتى لو كانت هواتفهم مغلقة
                const driverPromises = driversSnapshot.docs.map(doc => {
                    return sendUnifiedNotification({
                        targetType: "DeliveryDrivers",
                        targetId: doc.id,
                        title: nTitle,
                        body: nBody,
                        dataPayload: { 
                            orderId: event.params.storeOrderId, 
                            type: "NEW_ORDER_AVAILABLE",
                            storeId: storeId 
                        },
                        isCritical: false // المناديب تكفيهم القنوات العامة السريعة دون التثبيت الدائم
                    });
                });
                await Promise.all(driverPromises);
            }
        }

    } catch (error) {
        console.error("🔥 Error in onStoreOrderUpdated:", error);
    }
});





/*
exports.onStoreOrderUpdated = onDocumentUpdated("StoreOrders/{storeOrderId}", async (event) => {
    const newData = event.data.after.data();
    const previousData = event.data.before.data();
    const storeId = newData.StoreId;
    const userId = newData.UserId;
    const mainOrderId = newData.MainOrderId;
    const newItems = [...(newData.Items || [])];
    const oldItems = previousData.Items || [];
    const statusBefore = previousData.Status;
    const statusAfter = newData.Status;

    try {
        const storeRef = admin.firestore().collection("Stores").doc(storeId);
        const globalRef = getGlobalRef();
        const userRef = admin.firestore().collection('User').doc(userId);
        const userSnap = await userRef.get();
        
        // --- 1. إحصائيات القبول والرفض الكلية ---
        if (statusAfter === "accepted" && statusBefore !== "accepted") {
            await storeRef.set({ acceptedOrders: admin.firestore.FieldValue.increment(1) }, { merge: true });
            await globalRef.set({ acceptedOrders: admin.firestore.FieldValue.increment(1) }, { merge: true });
        } else if (statusAfter === "rejected" && statusBefore !== "rejected") {
            await storeRef.set({ rejectedOrders: admin.firestore.FieldValue.increment(1) }, { merge: true });
            await globalRef.set({ rejectedOrders: admin.firestore.FieldValue.increment(1) }, { merge: true });   
        }

        // --- 2 + 3. الدمج المالي المركزي لمرحلة الرفض ومزامنة الشحن الكلي ---
        let totalNetToDeductFromStore = 0;
        let totalGrossToReturnToUser = 0;
        const rejectedItemsToProcess = [];

        const storeDoc = await storeRef.get();
        const commRate = storeDoc.exists ? (storeDoc.data().commissionRate || 2) : 2;

        // تجميع السلع المرفوضة حديثاً في هذا التحديث
        for (const item of newItems) {
            const oldItem = oldItems.find(o => o.productId === item.productId);
            if (item.itemStatus === "rejected" && (!oldItem || oldItem.itemStatus !== "rejected") && !item.refunded) {
                const itemGross = (parseFloat(item.price) || 0) * (parseInt(item.Quantity) || item.quantity || 1);
                const itemNet = itemGross * (1 - (commRate / 100));
                
                rejectedItemsToProcess.push({ item, itemGross, itemNet });
                totalNetToDeductFromStore += itemNet;
                totalGrossToReturnToUser += itemGross;
                
                item.refunded = true; 
            }
        }

        // 🌟 إطلاق الترانزاكشن المركزي الموحد لإدارة كافة الحسابات (المنتجات + الشحن)
        if (rejectedItemsToProcess.length > 0 && mainOrderId) {
            const mainOrderRef = admin.firestore().collection("Orders").doc(mainOrderId);

            await admin.firestore().runTransaction(async (transaction) => {
                // قراءة مستند الطلب الرئيسي بشكل آمن داخل الترانزاكشن لمنع التضارب
                const mainOrderDoc = await transaction.get(mainOrderRef);
                if (!mainOrderDoc.exists) return;

                const mainOrderData = mainOrderDoc.data();
                let mainItems = mainOrderData.Items || [];
                let additionalRefundForMain = 0;
                let shippingRefundAmount = 0;
                let shouldRefundShipping = false;

                // تحديث حالات المنتجات داخل مصفوفة الطلب الرئيسي وتجهيز مبالغ الرد الكلية
                mainItems = mainItems.map(mItem => {
                    const updated = newItems.find(ni => ni.productId === mItem.productId);
                    if (updated && updated.itemStatus !== mItem.itemStatus) {
                        if (updated.itemStatus === "rejected" && mItem.itemStatus !== "rejected") {
                            additionalRefundForMain += (parseFloat(mItem.price) || 0) * (parseInt(mItem.Quantity) || mItem.quantity || 1);
                        }
                        return { ...mItem, itemStatus: updated.itemStatus };
                    }
                    return mItem;
                });

                // 🎯 الفحص الحاسم: هل مات الطلب بالكامل الآن؟
                const isAllOrderItemsDead = mainItems.every(item => 
                    item.itemStatus === "rejected" || item.itemStatus === "cancelled"
                );
                const currentShippingAmount = parseFloat(mainOrderData.ShippingAmount) || 0;

                // إذا مات الطلب كلياً ورسوم الشحن لم تُرد بعد، ندرجها فوراً في نفس عملية الرد للعميل!
                if (isAllOrderItemsDead && currentShippingAmount > 0) {
                    shouldRefundShipping = true;
                    shippingRefundAmount = currentShippingAmount;
                    totalGrossToReturnToUser += shippingRefundAmount; // 🌟 إضافة الشحن لصافي مستردات العميل الكلية فوراً
                }

                // 💸 تحديث رصيد محفظة المستخدم الإجمالي (منتجات + شحن إن وجد) في حركة واحدة
                transaction.update(userRef, {
                    walletBalance: admin.firestore.FieldValue.increment(Number(totalGrossToReturnToUser.toFixed(2)))
                });

                // خصم صافي الأرباح المعلقة من محفظة المتجر
                transaction.update(storeRef, {
                    "wallet.pendingBalance": admin.firestore.FieldValue.increment(-Number(totalNetToDeductFromStore.toFixed(2)))
                });

                // إنشاء حركات مستندات المرتجعات للسلع المرفوضة
                for (const entry of rejectedItemsToProcess) {
                    const userTransRef = userRef.collection('Transactions').doc();
                    transaction.set(userTransRef, {
                        id: userTransRef.id,
                        orderId: mainOrderId,
                        amount: entry.itemGross,
                        type: 'refund',
                        status: 'completed',
                        date: admin.firestore.FieldValue.serverTimestamp(),
                        description: `مرتجع منتج غير متوفر: ${entry.item.Title}`,
                        productId: entry.item.productId
                    });

                    const storeTransRef = admin.firestore().collection("Transactions").doc();
                    transaction.set(storeTransRef, {
                        storeId: storeId,
                        orderId: event.params.storeOrderId,
                        amount: -entry.itemNet,
                        type: "refund",
                        status: "completed",
                        productId: entry.item.productId,
                        productName: entry.item.Title,
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                    });

                    const adminRefundRef = admin.firestore().collection("RejectedRefunds").doc();
                    transaction.set(adminRefundRef, {
                        refundId: adminRefundRef.id,
                        orderId: mainOrderId,
                        storeOrderId: event.params.storeOrderId,
                        userId: userId,
                        userName: `${userSnap.data()?.FirstName || ""} ${userSnap.data()?.LastName || ""}`.trim() || "زبون غير معروف",
                        userPhone: userSnap.data()?.PhoneNumber || "",
                        bankAccount: userSnap.data()?.BankNoumber || "",
                        bankType: userSnap.data()?.BankName || "",
                        bankAccountName: userSnap.data()?.BankAccountName || "",
                        productId: entry.item.productId,
                        productName: entry.item.Title,
                        amountToRefund: entry.itemGross,
                        status: "pending",
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        storeId: storeId,
                    });
                }

                // 🚚 إذا تم استرداد الشحن، ننشئ له وثيقة حركة مالية منفصلة في كوليكشن المستخدم للشفافية
                if (shouldRefundShipping) {
                    const shippingTransRef = userRef.collection('Transactions').doc();
                    transaction.set(shippingTransRef, {
                        id: shippingTransRef.id,
                        orderId: mainOrderId,
                        amount: shippingRefundAmount,
                        type: 'refund',
                        status: 'completed',
                        date: admin.firestore.FieldValue.serverTimestamp(),
                        description: `إرجاع رسوم التوصيل (الطلب مرفوض/ملغي بالكامل)`
                    });
                }

                // بناء حمولة تحديث مستند الطلب الرئيسي (Orders) بشكل نهائي وثابت
                const updatePayload = { Items: mainItems };
                if (shouldRefundShipping) {
                    updatePayload.ShippingAmount = 0; // تصفير حقل الشحن لمنع تكرار العملية
                }
                if (additionalRefundForMain > 0) {
                    updatePayload.RejectedAmount = admin.firestore.FieldValue.increment(additionalRefundForMain);
                }

                // تحديث مستند الطلب الرئيسي داخل الترانزاكشن لضمان الثبات والسرعة
                transaction.update(mainOrderRef, updatePayload);

                // تسجيل إشعار النظام الموحد داخل الترانزاكشن لقاعدة البيانات
                logNotificationWithTransaction(transaction, "User", userId, {
                    title: "تحديث بخصوص المرتجعات 💰",
                    body: shouldRefundShipping 
                        ? `تم إرجاع مبالغ المنتجات مع رسوم التوصيل (₪${totalGrossToReturnToUser.toFixed(2)}) لمحفظتك لعدم توفر الطلب.`
                        : `تم إرجاع مبلغ ₪${totalGrossToReturnToUser.toFixed(2)} لمحفظتك عن منتجات مرفوضة.`,
                    type: "REJECTION",
                    mainOrderId
                });
            });

            // تحديث مستند طلب المتجر (StoreOrders) الفرعي بوضع علم الخصم المالي (refunded = true)
            await event.data.after.ref.update({ Items: newItems });

            // إرسال الإشعار الفوري لهاتف المستخدم عبر الـ FCM خارج حظر الترانزاكشن
            const fcmToken = userSnap.data()?.fcmToken;
            if (fcmToken) {
                await admin.messaging().send({
                    token: fcmToken,
                    notification: { 
                        title: "إرجاع مبالغ وتحديث طلب", 
                        body: "تم إرجاع مبالغ المنتجات غير المتوفرة ورسوم الشحن إلى محفظتك بنجاح." 
                    },
                    data: { orderId: mainOrderId, type: "REJECTION" }
                }).catch(e => console.error("FCM Error:", e));
            }
        } 

        // --- 4. مزامنة الحالة العامة للطلب الرئيسي (تحديث الحالات: shipped, delivered, rejected) ---
        if (mainOrderId) {
            const mainOrderRef = admin.firestore().collection("Orders").doc(mainOrderId);
            const mainOrderDoc = await mainOrderRef.get();
            
            if (mainOrderDoc.exists) {
                const allSubOrdersSnapshot = await admin.firestore()
                    .collection("StoreOrders")
                    .where("MainOrderId", "==", mainOrderId)
                    .get();

                const subOrdersDocs = allSubOrdersSnapshot.docs;

                const checkAllStoresMetCondition = (allowedStatuses) => {
                    const normalizedAllowed = allowedStatuses.map(s => s.toLowerCase());
                    return subOrdersDocs.every(doc => normalizedAllowed.includes((doc.data().Status || "").toLowerCase()));
                };

                let newGlobalStatus = null;
                let notifyUser = false;
                let notificationTitle = "";
                let notificationBody = "";
                let notificationType = "";

                if (checkAllStoresMetCondition(["shipped", "rejected"]) && subOrdersDocs.some(d => (d.data().Status || "").toLowerCase() === "shipped")) {
                    newGlobalStatus = "shipped";
                    notifyUser = true;
                    notificationTitle = "طلبك في الطريق! 🚚";
                    notificationBody = "جميع المتاجر سلمت أغراضك وهي الآن مع المندوب للشحن.";
                    notificationType = "ORDER_SHIPPED";
                }
                else if (checkAllStoresMetCondition(["readyForPickup", "shipped", "rejected"])) {
                    newGlobalStatus = "readyForPickup";
                }
                else if (checkAllStoresMetCondition(["delivered", "rejected"]) && subOrdersDocs.some(d => (d.data().Status || "").toLowerCase() === "delivered")) {
                    newGlobalStatus = "delivered";
                    notifyUser = true;
                    notificationTitle = "تم توصيل طلبك بنجاح! 🎉";
                    notificationBody = "سُعدنا بخدمتك، نتمنى أن نكون عند حسن ظنك دائماً.";
                    notificationType = "ORDER_DELIVERED";
                }
                else if (checkAllStoresMetCondition(["rejected"])) {
                    newGlobalStatus = "rejected";
                    notifyUser = true;
                    notificationTitle = "نعتذر منك، تم إلغاء الطلب بالكامل 🛑";
                    notificationBody = "تم إلغاء الطلب بالكامل لعدم توفر العناصر، وتم رد مبالغ المنتجات مع رسوم التوصيل لمحفظتك.";
                    notificationType = "ORDER_REJECTED";
                }
                else if (subOrdersDocs.some(d => (d.data().Status || "").toLowerCase() === "accepted")) {
                    if (mainOrderDoc.data().Status === "pending" || mainOrderDoc.data().Status === "pendingPayment") {
                        newGlobalStatus = "accepted";
                    }
                }

                if (newGlobalStatus && newGlobalStatus !== mainOrderDoc.data().Status) {
                    await mainOrderRef.update({ Status: newGlobalStatus });

                    if (notifyUser) {
                        await logNotification("User", userId, { 
                            title: notificationTitle, 
                            body: notificationBody, 
                            type: notificationType, 
                            mainOrderId 
                        });
                        
                        const freshUserSnap = await userRef.get();
                        if (freshUserSnap.data()?.fcmToken) {
                            await admin.messaging().send({
                                token: freshUserSnap.data().fcmToken,
                                notification: { title: notificationTitle, body: notificationBody },
                                data: { orderId: mainOrderId, type: notificationType }
                            }).catch(e => console.error("FCM Global Sync Error:", e));
                        }
                    }
                }
            }
        }

        // --- 5. إشعار المناديب (Ready for Pickup) ---
        const currentNormalizedStatus = (newData.Status || "").toLowerCase();
        const previousNormalizedStatus = (previousData.Status || "").toLowerCase();

        if (currentNormalizedStatus === "readyforpickup" && previousNormalizedStatus !== "readyforpickup") {
            const driversSnapshot = await admin.firestore().collection("DeliveryDrivers").where("isActive", "==", true).get();
            if (!driversSnapshot.empty) {
                const storeName = storeDoc.data()?.storName || "متجر";
                const nTitle = "طلب جديد جاهز 📦";
                const nBody = `المتجر ${storeName} بانتظار استلام الطلب.`;

                const driverPromises = driversSnapshot.docs.map(doc => {
                    const dToken = doc.data().fcmToken;
                    const p = [logNotification("DeliveryDrivers", doc.id, { title: nTitle, body: nBody, type: "NEW_ORDER_AVAILABLE", orderId: event.params.storeOrderId, storeId })];
                    if (dToken) p.push(admin.messaging().send({ token: dToken, notification: { title: nTitle, body: nBody }, data: { orderId: event.params.storeOrderId, type: "NEW_ORDER_AVAILABLE" , storeId } }));
                    return Promise.all(p);
                });
                await Promise.all(driverPromises);
            }
        }

    } catch (error) {
        console.error("🔥 Error in onStoreOrderUpdated:", error);
    }
});*/











exports.onMainOrderDelivered = onDocumentUpdated("Orders/{mainOrderId}", async (event) => {
    const newData = event.data.after.data();
    const previousData = event.data.before.data();

    if (newData.Status === "delivered" && previousData.Status !== "delivered") {
        const mainOrderId = event.params.mainOrderId;

        try {
            const storeOrdersSnapshot = await admin.firestore()
                .collection("StoreOrders")
                .where("MainOrderId", "==", mainOrderId)
                .get();

            const batch = admin.firestore().batch();
            
            // ✅ 1. تعريف متغير لجمع أرباح المنصة بالكامل من هذا الطلب
            let totalOrderNetProfit = 0;

            for (const storeOrderDoc of storeOrdersSnapshot.docs) {
                const storeOrderData = storeOrderDoc.data();
                const storeId = storeOrderData.StoreId;
                const items = storeOrderData.Items || [];

                const storeRef = admin.firestore().collection("Stores").doc(storeId);
                const storeDoc = await storeRef.get();
                const commRate = storeDoc.exists ? (storeDoc.data().commissionRate || 2) : 2;

                let finalStoreTotal = 0;
                items.forEach(item => {
                    if (item.itemStatus !== "rejected") {
                        finalStoreTotal += (parseFloat(item.price) || 0) * (parseInt(item.Quantity) || 1);
                    }
                });

                const finalNetProfit = Math.round((finalStoreTotal * (1 - (commRate / 100))) * 100) / 100;

                if (finalNetProfit > 0) {
                    // ✅ 2. إضافة ربح هذا المتجر للإجمالي الكلي
                    totalOrderNetProfit += finalNetProfit;

                    batch.update(storeRef, {
                        "wallet.pendingBalance": admin.firestore.FieldValue.increment(-finalNetProfit),
                        "wallet.availableBalance": admin.firestore.FieldValue.increment(finalNetProfit),
                        "wallet.totalEarnings": admin.firestore.FieldValue.increment(finalNetProfit),
                        "completedOrders": admin.firestore.FieldValue.increment(1),
                        "currentWeekSales": admin.firestore.FieldValue.increment(finalNetProfit),
                        "totalSales": admin.firestore.FieldValue.increment(finalNetProfit)
                    });

                    const transRef = admin.firestore().collection("Transactions").doc();
                    batch.set(transRef, {
                        storeId, mainOrderId, orderId: storeOrderDoc.id,
                        amount: finalNetProfit, type: "payout_cleared", status: "completed",
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                }
            }
            
            // ✅ 3. تحديث إحصائيات الإدارة العامة باستخدام الإجمالي الذي جمعناه
            const now = new Date();
            const monthKey = `${now.getFullYear()}-${now.getMonth() + 1}`;

            batch.set(getGlobalRef(), {
                completedOrders: admin.firestore.FieldValue.increment(1),
                // نستخدم المتجر الذي جمعنا فيه القيم
                [`monthlySales.${monthKey}`]: admin.firestore.FieldValue.increment(totalOrderNetProfit)
            }, { merge: true });

            await batch.commit();
            console.log(`✅ Success: Order ${mainOrderId} settled. Total Profit: ${totalOrderNetProfit}`);

        } catch (error) {
            console.error("🔥 Error in onMainOrderDelivered:", error);
        }
    }
});


/**
 * 4. تدوير المبيعات الأسبوعية (كل يوم أحد)
 */
exports.rotateWeeklySales = onSchedule("0 0 * * 0", async (event) => {
    const storesSnapshot = await admin.firestore().collection("Stores").get();
    const batch = admin.firestore().batch();
    
    storesSnapshot.docs.forEach(doc => {
        const data = doc.data();
        const currentSales = data.currentWeekSales || 0;
        batch.update(doc.ref, {
            previousWeekSales: currentSales,
            currentWeekSales: 0 
        });
    });
    
    await batch.commit();
    console.log("✅ Weekly sales rotation completed.");
});


/*
exports.onOrderCreated = onDocumentCreated("Orders/{orderId}", async (event) => {
    const orderData = event.data.data();
    if (!orderData) return;

    const paymentType = orderData.PaymentType || "";
    const status = orderData.Status || "";

    // 🚨 حارس البوابة: إذا كان الدفع كاملاً من المحفظة، فالحركة المالية تم تسجيلها بالفعل داخل الترانزاكشن
    if (paymentType === "full_wallet" && status === "pending") {
        console.log(`ℹ️ Order #${event.params.orderId} paid via wallet. Transaction already documented. Skipping.`);
        return null;
    }

    const userId = orderData.UserId;
    // في حالة الدفع المختلط (partial_mixed)، نريد فقط تسجيل المبلغ المطلوب من البنك وليس الإجمالي
    const amount = orderData.BankRequiredAmount !== undefined ? orderData.BankRequiredAmount : (orderData.TotalAmount || 0);
    
    // إذا كان المبلغ المطلوب من البنك هو 0 (مثل حالات معينة) لا داعي لتسجيل حركة دفع بنكي منتظرة
    if (amount <= 0) return null;

    const userRef = admin.firestore().collection('User').doc(userId);
    const transactionRef = userRef.collection('Transactions').doc(event.params.orderId);

    console.log(`🚀 Documenting pending bank payment for Order #${event.params.orderId}`);

    await transactionRef.set({
        id: event.params.orderId,
        amount: amount, // توثيق المبلغ الصافي المطلوب تحويله بنكياً فقط
        type: 'purchase',
        status: 'pending_payment',
        date: admin.firestore.FieldValue.serverTimestamp(),
        description: paymentType === "partial_mixed" 
            ? `المتبقي لطلب رقم #${event.params.orderId} بعد خصم المحفظة`
            : `طلب جديد رقم #${event.params.orderId} (دفع بنكي)`,
        orderId: event.params.orderId,
        senderName: orderData.SenderName || "" 
    });
});*/

/*
    exports.onOrderCreated = onDocumentCreated("Orders/{orderId}", async (event) => {
    const orderData = event.data.data();
    if (!orderData) return;

    const userId = orderData.UserId;
    const amount = orderData.TotalAmount || 0;
    const userRef = admin.firestore().collection('User').doc(userId);
    const transactionRef = userRef.collection('Transactions').doc(event.params.orderId);

    await transactionRef.set({
        id: event.params.orderId,
        amount: amount,
        type: 'purchase',
        status: 'pending_payment',
        date: admin.firestore.FieldValue.serverTimestamp(),
        description: `طلب جديد رقم #${event.params.orderId}`,
        orderId: event.params.orderId,
        senderName: orderData.SenderName || "" // الاسم الذي سنطابق عليه لاحقاً
    });
});*/




exports.processStoreWithdrawal = onCall(async (request) => {
     if (!request.auth || !request.auth.token.admin) {
         throw new HttpsError("unauthenticated", "غير مسموح لك بالقيام بهذه العملية");
     }

    const { storeId, amountToWithdraw, bankDetails, note } = request.data;
    if (!storeId || !amountToWithdraw || amountToWithdraw <= 0) {
        throw new HttpsError("invalid-argument", "بيانات السحب غير صالحة");
    }

    const storeRef = admin.firestore().collection("Stores").doc(storeId);

    try {
        await admin.firestore().runTransaction(async (transaction) => {
            const storeDoc = await transaction.get(storeRef);
            if (!storeDoc.exists) throw new HttpsError("not-found", "المتجر غير موجود");

            const wallet = storeDoc.data().wallet || {};
            const availableBalance = wallet.availableBalance || 0;

            if (availableBalance < amountToWithdraw) {
                throw new Error("رصيد التاجر غير كافٍ لإتمام هذه العملية");
            }

            // تحديث محفظة المتجر
            transaction.update(storeRef, {
                "wallet.availableBalance": admin.firestore.FieldValue.increment(-amountToWithdraw),
                "wallet.withdrawnAmount": admin.firestore.FieldValue.increment(amountToWithdraw),
                "wallet.lastWithdrawalDate": admin.firestore.FieldValue.serverTimestamp()
            });

            // تسجيل المعاملة المالية العامة
            const transactionRef = admin.firestore().collection("Transactions").doc();
            transaction.set(transactionRef, {
                id: transactionRef.id,
                storeId: storeId,
                amount: amountToWithdraw,
                type: "withdrawal", 
                status: "completed",
                description: note || `تحويل بنكي لمبلغ ${amountToWithdraw}`,
                bankDetails: bankDetails || {}, 
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // الحفظ الرسمي والوحيد للإشعار في قاعدة البيانات (داخل الترانزاكشن)
            logNotificationWithTransaction(transaction, "Stores", storeId, {
                title: "تم سحب مبلغ من محفظتك 💸",
                body: `تمت معالجة طلب تحويل مبلغ ${amountToWithdraw} شيكل إلى حسابك البنكي.`,
                type: "withdrawal",
                isOpened: false,
                isCritical: true // تضاف من أجل كود الفلاتر
            });
        });

        // 🌟 استدعاء الدالة لإرسال الـ FCM فقط دون إعادة الحفظ في قاعدة البيانات مرة أخرى
        await sendUnifiedNotification({
            targetType: "Stores",
            targetId: storeId,
            title: "عملية سحب ناجحة 💸",
            body: `تم خصم ${amountToWithdraw} شيكل من محفظتك وتحويلها للبنك وبانتظار الإيداع.`,
            dataPayload: { type: "withdrawal" },
            isCritical: true,
            skipFirestoreSave: true // 🔥 تخطي الحفظ لمنع التكرار لأننا حفظناه داخل الترانزاكشن الأعلى
        });

        return { success: true, message: "تم ارسال الأموال وتسجيل العملية بنجاح" };

    } catch (error) {
        console.error("Withdrawal Error:", error);
        throw new HttpsError("internal", error.message || "حدث خطأ أثناء معالجة السحب");
    }
});




/*
exports.processStoreWithdrawal = onCall(async (request) => {
    // 1. التحقق من الصلاحيات (يجب أن يكون المستدعي أدمن مثلاً)
     if (!request.auth || !request.auth.token.admin) {
         throw new HttpsError("unauthenticated", "غير مسموح لك بالقيام بهذه العملية");
     }

    const { storeId, amountToWithdraw,bankDetails, note } = request.data;

    // التحقق من البيانات المرسلة
    if (!storeId || !amountToWithdraw || amountToWithdraw <= 0) {
        throw new HttpsError("invalid-argument", "بيانات السحب غير صالحة");
    }

    const storeRef = admin.firestore().collection("Stores").doc(storeId);

    try {
        await admin.firestore().runTransaction(async (transaction) => {
            const storeDoc = await transaction.get(storeRef);
            
            if (!storeDoc.exists) {
                throw new HttpsError("not-found", "المتجر غير موجود");
            }

            const wallet = storeDoc.data().wallet || {};
            const availableBalance = wallet.availableBalance || 0;

            // 2. التحقق من كفاية الرصيد
            if (availableBalance < amountToWithdraw) {
                throw new Error("رصيد التاجر غير كافٍ لإتمام هذه العملية");
            }

            // 3. تحديث بيانات محفظة المتجر
            transaction.update(storeRef, {
                "wallet.availableBalance": admin.firestore.FieldValue.increment(-amountToWithdraw),
                "wallet.withdrawnAmount": admin.firestore.FieldValue.increment(amountToWithdraw),
                "wallet.lastWithdrawalDate": admin.firestore.FieldValue.serverTimestamp()
            });

            // 4. تسجيل المعاملة في الكولكشن العام للعمليات المالية
            const transactionRef = admin.firestore().collection("Transactions").doc();
            transaction.set(transactionRef, {
                id: transactionRef.id,
                storeId: storeId,
                amount: amountToWithdraw,
                type: "withdrawal", // أو "settlement"
                status: "completed",
                description: note || `تحويل بنكي لمبلغ ${amountToWithdraw}`,
                bankDetails: bankDetails || {}, // لتخزين بيانات البنك التي تم التحويل لها
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
            logNotificationWithTransaction(transaction, "Stores", storeId, {
                title: "تم سحب مبلغ من محفظتك 💸",
                body: `تمت معالجة طلب تحويل مبلغ ${amountToWithdraw} شيكل إلى حسابك البنكي.`,
                type: "withdrawal"
            });
        });

        // 5. إرسال إشعار لحظي FCM بعد نجاح الترانزاكشن
        const storeDocFinal = await storeRef.get();
        const fcmToken = storeDocFinal.data()?.fcmToken;
        if (fcmToken) {
             const  message =  {
                token: fcmToken,
                notification: {
                    title: "عملية سحب ناجحة",
                    body: `تم خصم ${amountToWithdraw} شيكل من محفظتك وتحويلها للبنك.`
                },
                data: { type: "withdrawal" },
                // إعدادات أندرويد لضمان المحاولة لمدة 48 ساعة
        android: {
            priority: "high",
            ttl: 172800000, // 48 ساعة بالميلي ثانية
            notification: {
                channelId: "high_importance_channel",
                defaultSound: true,
                defaultVibrateTimings: true,
            }
        },
        // إعدادات آيفون لضمان المحاولة لمدة 48 ساعة
        apns: {
            headers: {
                "apns-priority": "10",
                "apns-expiration": (Math.floor(Date.now() / 1000) + (48 * 3600)).toString(), // وقت الانتهاء بعد 48 ساعة
            },
            payload: {
                aps: {
                    alert: {
                        title: "عملية سحب ناجحة",
                        body: `رصيدك الان ارسل الى البنك.`
                    },
                    sound: "default",
                    badge: 1
                }
            }
        }
            };
            // إرسال الرسالة مع معالجة الخطأ
    await admin.messaging().send(message)
        .then((response) => {
            console.log('✅ Successfully sent message:', response);
        })
        .catch((error) => {
            console.error('❌ Error sending FCM message:', error);
        });
        }

        return { success: true, message: "تم ارسال الأموال وتسجيل العملية بنجاح" };

    } catch (error) {
        console.error("Withdrawal Error:", error);
        throw new HttpsError("internal", error.message || "حدث خطأ أثناء معالجة السحب");
    }
});  
*/  



exports.topUpUserWallet = onCall(async (request) => {
    // 1. التحقق من البيانات (الزبون، المبلغ، السبب)
    const { userId, amount, reason } = request.data;

    if (!request.auth) {
        throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً");
    }

    if (request.auth.token.admin !== true) {
        throw new HttpsError("permission-denied", "غير مسموح لك بشحن المحافظ، هذه الصلاحية للأدمن فقط");
    }

    if (!userId || !amount || amount <= 0) {
        throw new HttpsError("invalid-argument", "يجب تحديد مستخدم ومبلغ صحيح");
    }

    const userRef = admin.firestore().collection("User").doc(userId);

    try {
        await admin.firestore().runTransaction(async (transaction) => {
            const userDoc = await transaction.get(userRef);
            
            if (!userDoc.exists) {
                throw new Error("المستخدم غير موجود");
            }

            // 2. تحديث رصيد الزبون (walletBalance)  🛠️ تم تصحيح الإشارة لتصبح سحب رصيد سالبة  
            transaction.update(userRef, {
                walletBalance: admin.firestore.FieldValue.increment(-amount)
            });

            // 3. تسجيل المعاملة في سجل الزبون الفرعي لضمان تناسق البيانات المالية
            const userTransRef = userRef.collection('Transactions').doc();
            transaction.set(userTransRef, {
                id: userTransRef.id,
                amount: amount,
                type: 'withdrawal', // تم جعل التايب معبراً عن السحب بدلاً من الشحن
                status: 'completed',
                date: admin.firestore.FieldValue.serverTimestamp(),
                description: reason || "تحويل رصيد من قبل الإدارة",
            });

            // 4. تسجيل وثيقة الإشعار الرسمية والوحيدة في قاعدة البيانات داخل الترانزاكشن
            logNotificationWithTransaction(transaction, "User", userId, {
                title: "تم سحب رصيد من محفظتك! 💰",
                body: `تم سحب ${amount} شيكل من حسابك بنجاح.`,
                type: "withdrawal",
                isOpened: false,
                isCritical: true
            });
        });

        // 5. 🌟 استدعاء الدالة المركزية لإرسال الـ FCM مع منع التكرار في الفايرستور
        // تضمن صمود الإشعار المالي لـ 48 ساعة وحمايته من المسح عبر السحب (isCritical: true)
        const title = "تم شحن محفظتك! 💰";
        const body = `تم إضافة ${amount} شيكل إلى حسابك بنجاح، رصيدك الآن جاهز للاستخدام.`;

        await sendUnifiedNotification({
            targetType: "User", // المستهدف هو كوليكشن العميل
            targetId: userId,
            title: title,
            body: body,
            dataPayload: { 
                type: "WALLET_TOPUP" 
            },
            isCritical: true, // تفعيل الأهمية القصوى للإشعارات المالية
            skipFirestoreSave: true // 🔥 حماية الكود من التكرار لأننا قمنا بحفظه داخل الترانزاكشن بالأعلى
        });

        return { success: true, message: "تم تحديث الرصيد وإرسال الإشعارات" };

    } catch (error) {
        console.error("🔥 Error in topUpUserWallet:", error);
        throw new HttpsError("internal", error.message);
    }
});





/*
exports.topUpUserWallet = onCall(async (request) => {
    // 1. التحقق من البيانات (الزبون، المبلغ، السبب)
    const { userId, amount, reason } = request.data;

    if (!request.auth) {
        throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً");
    }


    if (request.auth.token.admin !== true) {
        throw new HttpsError("permission-denied", "غير مسموح لك بشحن المحافظ، هذه الصلاحية للأدمن فقط");
    }

    if (!userId || !amount || amount <= 0) {
        throw new HttpsError("invalid-argument", "يجب تحديد مستخدم ومبلغ صحيح");
    }

    const userRef = admin.firestore().collection("User").doc(userId);

    try {
        await admin.firestore().runTransaction(async (transaction) => {
            const userDoc = await transaction.get(userRef);
            
            if (!userDoc.exists) {
                throw new Error("المستخدم غير موجود");
            }

            // 2. تحديث رصيد الزبون (walletBalance)
            transaction.update(userRef, {
                walletBalance: admin.firestore.FieldValue.increment(-amount)
            });

            // 3. تسجيل المعاملة في سجل الزبون الفرعي
            // نستخدم نفس الهيكلية التي اعتمدناها سابقاً لضمان تناسق البيانات
            const userTransRef = userRef.collection('Transactions').doc();
            transaction.set(userTransRef, {
                id: userTransRef.id,
                amount: amount,
                type: 'withdrawal', // نوع العملية: شحن/إضافة
                status: 'completed',
                date: admin.firestore.FieldValue.serverTimestamp(),
                description: reason || "تحويل رصيد من قبل الإدارة",
                // لا يوجد orderId هنا لأنها عملية إضافة يدوية
            });

            // 4. (اختياري) تخزين إشعار للزبون ليراها في قسم التنبيهات
            // باستخدام الدالة المساعدة التي تملكها
            logNotificationWithTransaction(transaction, "User", userId, {
                title: "تم ارسال رصيد لمحفظتك 💰",
                body: `تم إضافة ${amount} شيكل إلى حسابك بنجاح.`,
                type: "withdrawal"
            });
        });

        // 5. إرسال إشعار لحظي FCM بعد نجاح الترانزاكشن
        const userDocFinal = await userRef.get();
        const fcmToken = userDocFinal.data()?.fcmToken;
        if (fcmToken) {
             const message=   {
                token: fcmToken,
                notification: {
                    title: "تم شحن محفظتك!",
                    body: `رصيدك الان ارسل الى محفظتك.`
                },
                data: { type: "WALLET_TOPUP" },
                // إعدادات أندرويد لضمان المحاولة لمدة 48 ساعة
        android: {
            priority: "high",
            ttl: 172800000, // 48 ساعة بالميلي ثانية
            notification: {
                channelId: "high_importance_channel",
                defaultSound: true,
                defaultVibrateTimings: true,
            }
        },
        // إعدادات آيفون لضمان المحاولة لمدة 48 ساعة
        apns: {
            headers: {
                "apns-priority": "10",
                "apns-expiration": (Math.floor(Date.now() / 1000) + (48 * 3600)).toString(), // وقت الانتهاء بعد 48 ساعة
            },
            payload: {
                aps: {
                    alert: {
                        title: "تم شحن محفظتك!",
                        body: `رصيدك الان ارسل الى محفظتك.`
                    },
                    sound: "default",
                    badge: 1
                }
            }
        }
            };
                    // إرسال الرسالة مع معالجة الخطأ
    await admin.messaging().send(message)
        .then((response) => {
            console.log('✅ Successfully sent message:', response);
        })
        .catch((error) => {
            console.error('❌ Error sending FCM message:', error);
        });
        }

        return { success: true, message: "تم تحديث الرصيد وإرسال الإشعارات" };

    } catch (error) {
        console.error("🔥 Error in topUpUserWallet:", error);
        throw new HttpsError("internal", error.message);
    }
});
*/


exports.confirmBankRefund = onCall(async (request) => {
    const data = request.data;
    const auth = request.auth;
    const refundId = data.refundId;
    const transactionReference = data.transactionReference;

    // 1. التحقق من الصلاحيات
    if (!auth) {
        throw new HttpsError('unauthenticated', 'يجب تسجيل الدخول أولاً');
    }
    if (!auth.token.admin) {
        throw new HttpsError("permission-denied", "غير مسموح لك بالقيام بهذه العملية");
    }

    const refundRef = admin.firestore().collection("RejectedRefunds").doc(refundId);
    let userRefForFcm;
    let finalRefundData;

    try {
        await admin.firestore().runTransaction(async (transaction) => {
            // أ. جلب بيانات مستند الرفض داخل الترانزاكشن لضمان الدقة المحاسبية
            const refundDoc = await transaction.get(refundRef);
            if (!refundDoc.exists) throw "المستند غير موجود";
            
            const refundData = refundDoc.data();
            finalRefundData = refundData; // لتخزين البيانات للاستخدام في FCM لاحقاً

            if (refundData.status === "completed") throw "العملية مكتملة مسبقاً";

            // ب. جلب بيانات المستخدم للتحقق من الرصيد
            const userRef = admin.firestore().collection("User").doc(refundData.userId);
            userRefForFcm = userRef;
            const userDoc = await transaction.get(userRef);
            
            if (!userDoc.exists) throw "مستند المستخدم غير موجود";
            
            const userWalletBalance = userDoc.data().walletBalance || 0;

            // ج. الحماية المالية: التحقق من كفاية الرصيد قبل تنفيذ أي حركة
            if (userWalletBalance < refundData.amountToRefund) {
                throw `رصيد الزبون غير كافٍ. الرصيد الحالي: ${userWalletBalance}، المطلوب: ${refundData.amountToRefund}`;
            }

            // د. تنفيذ الخصم وتحديث الحالة (عمليات ذرية متلازمة)
            transaction.update(userRef, {
                walletBalance: admin.firestore.FieldValue.increment(-refundData.amountToRefund)
            });

            transaction.update(refundRef, {
                status: "completed",
                completedAt: admin.firestore.FieldValue.serverTimestamp(),
                transactionReference: transactionReference || "N/A"
            });

            // هـ. تسجيل المعاملة المالية في سجل الزبون الداخلي
            const userTransRef = userRef.collection('Transactions').doc();
            transaction.set(userTransRef, {
                id: userTransRef.id,
                amount: -refundData.amountToRefund,
                type: 'bank_withdrawal',
                status: 'completed',
                date: admin.firestore.FieldValue.serverTimestamp(),
                description: `استلام بنكي لمرتجع: ${refundData.productName}`,
                orderId: refundData.orderId,
                reference: transactionReference || ""
            });

            // و. 🔒 تسجيل مستند الإشعار الرسمي الوحيد في قاعدة البيانات داخل الترانزاكشن مع الخصائص الكاملة
            const notificationRef = userRef.collection('Notifications').doc();
            transaction.set(notificationRef, {
                title: "تم التحويل البنكي بنجاح ✅",
                body: `تم إيداع مبلغ ${refundData.amountToRefund} في حسابك البنكي بنجاح مقابل منتج ${refundData.productName}.`,
                type: "BANK_TRANSFER_COMPLETE",
                mainOrderId: refundData.orderId || "",
                refundId: refundId,
                isRead: false,
                isOpened: false, // لمنع حذف الإشعار العشوائي بالنقرة من الفلاتر
                isCritical: true, // يطابق بنية الكود الموحد لحماية الفلاتر
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        // 2. 🌟 استدعاء الدالة المركزية الموحدة لإرسال الـ FCM فور نجاح الترانزاكشن المالي
        // الكود الموحد يضمن بقاء الإشعار لـ 48 ساعة وتحويل وضع الأندرويد والآيفون إلى (Sticky / Critical)
        const title = "تم التحويل البنكي بنجاح ✅";
        const body = `تم إيداع مبلغ ${finalRefundData.amountToRefund} شيكل في حسابك البنكي مقابل منتج ${finalRefundData.productName}.`;

        await sendUnifiedNotification({
            targetType: "User", // الكولكشن المستهدف هو كولكشن الزبائن
            targetId: finalRefundData.userId,
            title: title,
            body: body,
            dataPayload: { 
                type: "BANK_TRANSFER_COMPLETE", 
                orderId: finalRefundData.orderId || "" 
            },
            isCritical: true, // تفعيل وضع الأهمية البنكية القصوى
            skipFirestoreSave: true // 🔥 تخطي خطوة الحفظ لمنع التكرار لأننا قمنا ببنائه وحفظه داخل الترانزاكشن المالي بأمان
        });

        return { success: true, message: "تمت معالجة العملية بنجاح" };

    } catch (error) {
        console.error("Main Error in confirmBankRefund:", error);
        // رمي الخطأ بشكل مخصص وواضح ليفهمه تطبيق Flutter بشكل سليم دون مشاكل كراش
        throw new HttpsError('internal', error.toString());
    }
});


/*
exports.confirmBankRefund = onCall(async (request) => {
    const data = request.data;
    const auth = request.auth;
    const refundId = data.refundId;
    const transactionReference = data.transactionReference;

    // 1. التحقق من الصلاحيات
    if (!auth) {
        throw new HttpsError('unauthenticated', 'يجب تسجيل الدخول أولاً');
    }
    if (!auth.token.admin) {
        throw new HttpsError("permission-denied", "غير مسموح لك بالقيام بهذه العملية");
    }

    const refundRef = admin.firestore().collection("RejectedRefunds").doc(refundId);
    let userRefForFcm;
    let finalRefundData;

    try {
        await admin.firestore().runTransaction(async (transaction) => {
            // أ. جلب بيانات مستند الرفض داخل الترانزاكشن لضمان الدقة
            const refundDoc = await transaction.get(refundRef);
            if (!refundDoc.exists) throw "المستند غير موجود";
            
            const refundData = refundDoc.data();
            finalRefundData = refundData; // لتخزين البيانات للاستخدام في FCM لاحقاً

            if (refundData.status === "completed") throw "العملية مكتملة مسبقاً";

            // ب. جلب بيانات المستخدم للتحقق من الرصيد
            const userRef = admin.firestore().collection("User").doc(refundData.userId);
            userRefForFcm = userRef;
            const userDoc = await transaction.get(userRef);
            
            if (!userDoc.exists) throw "مستند المستخدم غير موجود";
            
            const userWalletBalance = userDoc.data().walletBalance || 0;

            // ج. الحماية المالية: التحقق من كفاية الرصيد
            if (userWalletBalance < refundData.amountToRefund) {
                throw `رصيد الزبون غير كافٍ. الرصيد الحالي: ${userWalletBalance}، المطلوب: ${refundData.amountToRefund}`;
            }

            // د. تنفيذ الخصم وتحديث الحالة (عمليات ذرية)
            transaction.update(userRef, {
                walletBalance: admin.firestore.FieldValue.increment(-refundData.amountToRefund)
            });

            transaction.update(refundRef, {
                status: "completed",
                completedAt: admin.firestore.FieldValue.serverTimestamp(),
                transactionReference: transactionReference || "N/A"
            });

            // هـ. تسجيل المعاملة المالية في سجل الزبون
            const userTransRef = userRef.collection('Transactions').doc();
            transaction.set(userTransRef, {
                id: userTransRef.id,
                amount: -refundData.amountToRefund,
                type: 'bank_withdrawal',
                status: 'completed',
                date: admin.firestore.FieldValue.serverTimestamp(),
                description: `استلام بنكي لمرتجع: ${refundData.productName}`,
                orderId: refundData.orderId,
                reference: transactionReference || ""
            });

            // و. تسجيل الإشعار الداخلي للزبون
            const notificationRef = userRef.collection('Notifications').doc();
            transaction.set(notificationRef, {
                title: "تم التحويل البنكي بنجاح ✅",
                body: `تم إيداع مبلغ ${refundData.amountToRefund} في حسابك البنكي بنجاح مقابل منتج ${refundData.productName}.`,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                type: "BANK_TRANSFER_COMPLETE",
                refundId: refundId
            });
        });

        // 2. إرسال إشعار FCM بعد نجاح الترانزاكشن
        const userData = await userRefForFcm.get();
        const fcmToken = userData.data()?.fcmToken;

        if (fcmToken) {
            const message = {
                token: fcmToken,
                notification: {
                    title: "عملية سحب ناجحة",
                    body: `تم خصم ${finalRefundData.amountToRefund} شيكل من محفظتك وتحويلها للبنك.`
                },
                data: { type: "withdrawal", orderId: finalRefundData.orderId },
                android: {
                    priority: "high",
                    ttl: 172800000,
                    notification: {
                        channelId: "high_importance_channel",
                        defaultSound: true,
                        defaultVibrateTimings: true,
                    }
                },
                apns: {
                    headers: {
                        "apns-priority": "10",
                        "apns-expiration": (Math.floor(Date.now() / 1000) + (48 * 3600)).toString(),
                    },
                    payload: {
                        aps: {
                            alert: {
                                title: "عملية سحب ناجحة",
                                body: `رصيدك الآن أُرسل إلى البنك.`
                            },
                            sound: "default",
                            badge: 1
                        }
                    }
                }
            };

            await admin.messaging().send(message)
                .then((res) => console.log('✅ FCM Sent:', res))
                .catch((err) => console.error('❌ FCM Error:', err));
        }

        return { success: true, message: "تمت معالجة العملية بنجاح" };

    } catch (error) {
        console.error("Main Error:", error);
        // رمي الخطأ بشكل يفهمه تطبيق Flutter
        throw new HttpsError('internal', error.toString());
    }
});
*/





exports.cancelOrderAndRefund = onCall(async (request) => {
  // 1. التحقق من هوية المستخدم (Authentication Check)
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "يجب تسجيل الدخول أولاً لتنفيذ هذه العملية."
    );
  }

  const userId = request.auth.uid;
  const { orderId } = request.data;

  // التحقق من مدخلات الدالة
  if (!orderId) {
    throw new HttpsError(
      "invalid-argument",
      "لم يتم تزويد الدالة بمعرف الطلب (orderId)."
    );
  }

  const db = admin.firestore();
  
  // تعريف المراجع (References) بداخل الفايرستور
  const orderRef = db.collection("Orders").doc(orderId);
  const userRef = db.collection("User").doc(userId);

  try {
    // جلب كافة الطلبات الفرعية للمتاجر المرتبطة بهذا الطلب الرئيسي خارج الـ Transaction لرفع الكفاءة
    const subOrdersSnapshot = await db.collection("StoreOrders")
      .where("MainOrderId", "==", orderId)
      .get();

    // تشغيل العملية التزامنية الذرية الصارمة (Transaction)
    const result = await db.runTransaction(async (transaction) => {
      
      // أ. جلب مستند الطلب وفحصه
      const orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) {
        throw new HttpsError("not-found", "الطلب المحدد غير موجود بالسجلات.");
      }

      const orderData = orderDoc.data();
      
      // التأكد من أن الطلب يخص المستخدم الحالي حمايةً للبيانات
      if (orderData.UserId !== userId) {
        throw new HttpsError("permission-denied", "غير مسموح لك بإلغاء طلب لا يخص حسابك.");
      }

      // ب. فحص حالة الطلب الكلية
      const orderStatus = orderData.Status || "";
      if (orderStatus === "completed" || orderStatus === "shipped") {
        throw new HttpsError(
          "failed-precondition",
          "لا يمكن إلغاء الطلب بالكامل، لقد تم شحن الطلب أو تسليمه بالفعل."
        );
      }

      // ج. الفحص المطور لعناصر الطلب الرئيسي (Item-Level Verification)
      const items = orderData.Items || orderData.items || [];
      
      // التأكد من أن جميع العناصر تنحصر فقط في حالات: pending, cancelled, returned
      const allowedStatuses = ["pending", "cancelled", "returned"];
      const hasUnallowedItems = items.some(item => !allowedStatuses.includes(item.itemStatus || "pending"));
      
      if (hasUnallowedItems) {
        throw new HttpsError(
          "failed-precondition",
          "تعذر الإلغاء التلقائي؛ بعض عناصر الطلب انتقلت بالفعل إلى مرحلة التجهيز أو الشحن من قبل المتاجر."
        );
      }

      // د. حساب المبالغ المرجعة للعناصر الـ pending فقط
      let refundAmount = 0;
      
      // المحفظة تشحن فقط إذا كان الطلب الأصلي مدفوعاً أو تم الخصم من المحفظة (حالة pending) وليس pendingPayment
      if (orderStatus !== "pendingPayment") {
        items.forEach(item => {
          if (item.itemStatus === "pending") {
            // حساب سعر العنصر مضروباً في كميته (مع تأمين قراءة الحقول المالية بدقة)
            const itemPrice = Number(item.price || 0);
            const itemQuantity = Number(item.quantity || 1);
            refundAmount += (itemPrice * itemQuantity);
          }
        });
      }
      
      // تقريب المبلغ المسترد محاسبياً لمرتبتين عشريتين منعاً لكسور الجافاسكريبت
      refundAmount = Number(refundAmount.toFixed(2));

      // هـ. جلب رصيد محفظة المستخدم الحالي وتجهيز الرصيد الجديد
      const userDoc = await transaction.get(userRef);
      if (!userDoc.exists) {
        throw new HttpsError("not-found", "حساب المستخدم غير موجود بالسجلات.");
      }

      const userData = userDoc.data();
      const currentBalance = Number(userData.walletBalance || 0);
      const newBalance = Number((currentBalance + refundAmount).toFixed(2));

      // 🌟 مصفوفة لتجميع بيانات المتاجر المتأثرة لإشعارها لاحقاً عبر الـ FCM
      const affectedStoresInfo = [];
      // و. تحديث الطلبات الفرعية للمتاجر المتأثرة محاسبياً وبأثر رجعي
      for (const subOrderDocSnapshot of subOrdersSnapshot.docs) {
        const subOrderRef = subOrderDocSnapshot.ref;
        const subOrderDoc = await transaction.get(subOrderRef);
        
        if (subOrderDoc.exists) {
          const subOrderData = subOrderDoc.data();
          const storeId = subOrderData.StoreId || subOrderData.storeId;
          
          let subOrderItems = subOrderData.Items || subOrderData.items || [];
          let subOrderRefundableAmount = 0;

          // تحديث الحالات داخلياً وحساب كم سيخصم من رصيد المتجر المعلق
          subOrderItems = subOrderItems.map(subItem => {
            if (subItem.itemStatus === "pending") {
              const subPrice = Number(subItem.price || 0);
              const subQty = Number(subItem.quantity || 1);
              subOrderRefundableAmount += (subPrice * subQty);
              subItem.itemStatus = "cancelled"; // نقل الـ pending إلى ملغي
            }
            return subItem;
          });

          subOrderRefundableAmount = Number(subOrderRefundableAmount.toFixed(2));

          // تحديث مستند الطلب الفرعي للمتجر
          transaction.update(subOrderRef, {
            Items: subOrderItems,
            Status: "cancelled",
            UIEventpdatedAt: admin.firestore.FieldValue.serverTimestamp()
          });

          // تحديث محفظة المتجر وخصم الرصيد المعلق فقط بقيمة العناصر التي ألغيت الآن
          if (storeId && subOrderRefundableAmount > 0) {
            const storeRef = db.collection("Stores").doc(storeId);
            const storeDoc = await transaction.get(storeRef);
            let storeFcmToken = null;
            if (storeDoc.exists) {
              const storeData = storeDoc.data();
              storeFcmToken = storeData.fcmToken || null;
              const currentWallet = storeData.wallet || {};
              const currentPendingBalance = Number(currentWallet.pendingBalance || 0);
              
              const newPendingBalance = Number(Math.max(0, currentPendingBalance - subOrderRefundableAmount).toFixed(2));

              transaction.update(storeRef, {
                "wallet.pendingBalance": newPendingBalance,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
              });

              // تسجيل حركة مالية رسمية للمتجر بالخصم
              const storeTxId = `tx_store_cancel_${orderId}_${Date.now()}`;
              const storeTransactionRef = db.collection("Transactions").doc(storeTxId);
              transaction.set(storeTransactionRef, {
                id: storeTxId,
                amount: -subOrderRefundableAmount, 
                orderId: orderId,
                storeId: storeId,
                status: "completed",
                type: "cancel_deduction",
                description: `خصم مبلغ العناصر الملغاة من الطلب رقم #${orderId}`,
                date: admin.firestore.FieldValue.serverTimestamp()
              });

              // 🔒 1. تسجيل وثيقة الإشعار التاريخية للمتجر بداخل الداتابيز بالتزامن مع الـ Transaction
            logNotificationWithTransaction(transaction, "Store", storeId, {
              title: "🚨 تم إلغاء الطلب بالكامل",
              body: `قام العميل بإلغاء الطلب الرئيسي رقم #${orderId.substring(0, 6)} بالكامل. يرجى التوقف عن تجهيز العناصر.`,
              type: "store_order_cancelled",
              mainOrderId: orderId,
              isRead: false,
              isOpened: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp()
            });


            // حفظ التوكن والمعرف لإرسال الـ FCM خارج الترانزاكشن لاحقاً
            if (storeFcmToken) {
              affectedStoresInfo.push({
                storeId: storeId,
                fcmToken: storeFcmToken
              });
            }

            }
          }
        }
      }
      
      // ز. تحديث حالات العناصر الكلية في الطلب الرئيسي (تحويل الـ pending فقط إلى cancelled)
      const updatedMainItems = items.map(item => {
        if (item.itemStatus === "pending") {
          item.itemStatus = "cancelled";
        }
        return item;
      });
      
      // تحديث الطلب الرئيسي بالكامل إلى ملغي
      transaction.update(orderRef, {
        Status: "cancelled",
        Items: updatedMainItems,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // ح. شحن محفظة المستخدم بالرصيد المرتجع الفعلي وتدوين المعاملة المالية
      transaction.update(userRef, {
        walletBalance: newBalance
      });

      // توليد معرف فريد ومستقر للـ Transaction يمنع التداخل
      const userTxId = `tx_refund_${orderId}_${Date.now()}`;
      const userTransactionRef = db.collection("User").doc(userId).collection("Transactions").doc(userTxId);

      let notifTitle = "";
      let notifBody = "";
      let notifType = "";

      if (refundAmount > 0) {
        transaction.set(userTransactionRef, {
          id: userTxId,
          orderId: orderId,
          amount: refundAmount,
          type: "refund",
          status: "completed",
          title: "إعادة مبلغ العناصر الملغاة",
          description: `تم استرداد رصيد العناصر المتبقية من الطلب رقم #${orderId} تلقائياً لإلغائه.`,
          date: admin.firestore.FieldValue.serverTimestamp()
        });

        notifTitle = "تم إلغاء الطلب واسترداد الرصيد 💰";
        notifBody = `تم إلغاء طلبك رقم #${orderId} بنجاح وإعادة مبلغ ${refundAmount} شيكل لعناصر قيد الانتظار بمحفظتك.`;
        notifType = "refund";
      } else {
        notifTitle = "تم إلغاء الطلب بنجاح ❌";
        notifBody = `بناءً على طلبك، تم إلغاء الطلب رقم #${orderId} بنجاح كونه لم ينتقل للتجهيز بعد.`;
        notifType = "cancel_order";
      }

      // 🔒 تسجيل وثيقة الإشعار الرسمية الوحيدة بداخل قاعدة البيانات متزامنة مع نجاح الترانزاكشن بالكامل
      logNotificationWithTransaction(transaction, "User", userId, {
        title: notifTitle,
        body: notifBody,
        type: notifType,
        mainOrderId: orderId,
        isRead: false,
        isOpened: false,
        isCritical: true, // لحماية منطق الفلاتر من الحذف العشوائي بالسحب
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // إرجاع البيانات الهامة لبناء الـ Push Notification فور الخروج بنجاح من الترانزاكشن
      return {
        success: true,
        refundAmount: refundAmount,
        fcmToken: userData.fcmToken || null,
        notifTitle: notifTitle,
        notifBody: notifBody,
        notifType: notifType
      };
    });

    // 2. 🌟 استدعاء الدالة المركزية الموحدة لإرسال الـ FCM فور نجاح الترانزاكشن المالي والتوثيق بالنظام
    // الكود الموحد يضمن صمود الإشعار لـ 48 ساعة كاملة وتحويل وضع الإشعار في الهاتف إلى ثابت (Sticky)
    if (result.fcmToken) {
      await sendUnifiedNotification({
        targetType: "User", // كولكشن العملاء المستهدف
        targetId: userId,
        title: result.notifTitle,
        body: result.notifBody,
        dataPayload: { 
          type: result.notifType, 
          orderId: orderId 
        },
        isCritical: true, // إشعار مالي وإداري هام يمنع الاختفاء حتى النقر
        skipFirestoreSave: true // 🔥 تخطي خطوة إعادة الحفظ لمنع التكرار لأننا قمنا ببنائه وحفظه داخل الترانزاكشن بالأعلى بأمان
      });
    }


    // ====================================================================
    // ⚡ 3. إرسال إشعارات الـ FCM الفورية والموازية إلى أجهزة أصحاب المتاجر
    // ====================================================================
    if (result.affectedStoresInfo && result.affectedStoresInfo.length > 0) {
      try {
        const storeFcmPromises = result.affectedStoresInfo.map((store) => {
          return sendUnifiedNotification({
            targetType: "Store", // كوليكشن المتاجر المستهدف
            targetId: store.storeId,
            title: "🚨 إلغاء طلب بالكامل!",
            body: `تنبيه: قام العميل بإلغاء الطلب رقم #${orderId} بالكامل. توقف عن التجهيز فوراً.`,
            dataPayload: {
              type: "store_order_cancelled",
              orderId: orderId
            },
            isCritical: true,
            skipFirestoreSave: true // تم حفظه بالداتابيز داخل الترانزاكشن بالأعلى
          });
        });

        // إطلاق كافة الإشعارات في نفس اللحظة بالتوازي لضمان الصاروخية في الأداء
        await Promise.all(storeFcmPromises);

      } catch (storeFcmError) {
        // حماية مخرجات الدالة ضد أخطاء شبكة FCM للمتاجر
        console.error("⚠️ Non-critical Error sending FCM notifications to stores:", storeFcmError);
      }
    }

    return {
      status: "success",
      message: "تم إلغاء الطلب بنجاح وتحديث الحسابات المحاسبية بالكامل.",
      refundedAmount: result.refundAmount
    };

  } catch (error) {
    console.error("خطأ في دالة cancelOrderAndRefund المطورة:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError(
      "internal",
      error.message || "حدث خطأ داخلي أثناء معالجة إلغاء الطلب المطور."
    );
  }
});





/*
exports.cancelOrderAndRefund = onCall(async (request) => {
  // 1. التحقق من هوية المستخدم (Authentication Check)
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "يجب تسجيل الدخول أولاً لتنفيذ هذه العملية."
    );
  }

  const userId = request.auth.uid;
  const { orderId } = request.data;

  // التحقق من مدخلات الدالة
  if (!orderId) {
    throw new HttpsError(
      "invalid-argument",
      "لم يتم تزويد الدالة بمعرف الطلب (orderId)."
    );
  }

  const db = admin.firestore();
  
  // تعريف المراجع (References) بداخل الفايرستور
  const orderRef = db.collection("Orders").doc(orderId);
  const userRef = db.collection("User").doc(userId);

  try {
    // جلب كافة الطلبات الفرعية للمتاجر المرتبطة بهذا الطلب الرئيسي خارج الـ Transaction
    const subOrdersSnapshot = await db.collection("StoreOrders")
      .where("MainOrderId", "==", orderId)
      .get();

    // تشغيل العملية التزامنية الذرية (Transaction)
    const result = await db.runTransaction(async (transaction) => {
      
      // أ. جلب مستند الطلب وفحصه
      const orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) {
        throw new HttpsError("not-found", "الطلب المحدد غير موجود بالسجلات.");
      }

      const orderData = orderDoc.data();
      
      // التأكد من أن الطلب يخص المستخدم الحالي
      if (orderData.UserId !== userId) {
        throw new HttpsError("permission-denied", "غير مسموح لك بإلغاء طلب لا يخص حسابك.");
      }

      // ب. فحص حالة الطلب الكلية
      const orderStatus = orderData.Status || "";
      if (orderStatus === "completed" || orderStatus === "shipped") {
        throw new HttpsError(
          "failed-precondition",
          "لا يمكن إلغاء الطلب بالكامل، لقد تم شحن الطلب أو تسليمه بالفعل."
        );
      }

      // ج. الفحص المطور لعناصر الطلب الرئيسي (Item-Level Verification)
      const items = orderData.Items || orderData.items || [];
      
      // التأكد من أن جميع العناصر تنحصر فقط في حالات: pending, cancelled, returned
      const allowedStatuses = ["pending", "cancelled", "returned"];
      const hasUnallowedItems = items.some(item => !allowedStatuses.includes(item.itemStatus || "pending"));
      
      if (hasUnallowedItems) {
        throw new HttpsError(
          "failed-precondition",
          "تعذر الإلغاء التلقائي؛ بعض عناصر الطلب انتقلت بالفعل إلى مرحلة التجهيز أو الشحن من قبل المتاجر."
        );
      }

      // د. حساب المبالغ المرجعة للعناصر الـ pending فقط
      let refundAmount = 0;
      
      // المحفظة تشحن فقط إذا كان الطلب الأصلي مدفوعاً أو تم الخصم من المحفظة (حالة pending) وليس pendingPayment
      if (orderStatus !== "pendingPayment") {
        items.forEach(item => {
          if (item.itemStatus === "pending") {
            // حساب سعر العنصر مضروباً في كميته (مع تأمين قراءة الحقول المالية بدقة)
            const itemPrice = Number(item.price || 0);
            const itemQuantity = Number(item.quantity || 1);
            refundAmount += (itemPrice * itemQuantity);
          }
        });
      }
      
      // تقريب المبلغ المسترد محاسبياً لمرتبتين عشريتين منعا لكسور الجافاسكريبت
      refundAmount = Number(refundAmount.toFixed(2));

      // هـ. جلب رصيد محفظة المستخدم الحالي وتجهيز الرصيد الجديد
      const userDoc = await transaction.get(userRef);
      if (!userDoc.exists) {
        throw new HttpsError("not-found", "حساب المستخدم غير موجود بالسجلات.");
      }

      const userData = userDoc.data();
      const currentBalance = Number(userData.walletBalance || 0);
      const newBalance = Number((currentBalance + refundAmount).toFixed(2));

      // و. تحديث الطلبات الفرعية للمتاجر المتأثرة
      for (const subOrderDocSnapshot of subOrdersSnapshot.docs) {
        const subOrderRef = subOrderDocSnapshot.ref;
        const subOrderDoc = await transaction.get(subOrderRef);
        
        if (subOrderDoc.exists) {
          const subOrderData = subOrderDoc.data();
          const storeId = subOrderData.StoreId || subOrderData.storeId;
          
          let subOrderItems = subOrderData.Items || subOrderData.items || [];
          let subOrderRefundableAmount = 0;

          // تحديث الحالات داخلياً وحساب كم سيخصم من رصيد المتجر المعلق
          subOrderItems = subOrderItems.map(subItem => {
            if (subItem.itemStatus === "pending") {
              const subPrice = Number(subItem.price || 0);
              const subQty = Number(subItem.quantity || 1);
              subOrderRefundableAmount += (subPrice * subQty);
              subItem.itemStatus = "cancelled"; // نقل الـ pending إلى ملغي
            }
            return subItem;
          });

          subOrderRefundableAmount = Number(subOrderRefundableAmount.toFixed(2));

          // تحديث مستند الطلب الفرعي للمتجر
          transaction.update(subOrderRef, {
            Items: subOrderItems,
            items: subOrderItems,
            Status: "cancelled",
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });

          // تحديث محفظة المتجر وخصم الرصيد المعلق فقط بقيمة العناصر التي ألغيت الآن
          if (storeId && subOrderRefundableAmount > 0) {
            const storeRef = db.collection("Stores").doc(storeId);
            const storeDoc = await transaction.get(storeRef);
            
            if (storeDoc.exists) {
              const storeData = storeDoc.data();
              const currentWallet = storeData.wallet || {};
              const currentPendingBalance = Number(currentWallet.pendingBalance || 0);
              
              const newPendingBalance = Number(Math.max(0, currentPendingBalance - subOrderRefundableAmount).toFixed(2));

              transaction.update(storeRef, {
                "wallet.pendingBalance": newPendingBalance,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
              });

              // تسجيل حركة مالية للمتجر (إشعار بالخصم نتيجة الإلغاء)
              const storeTxId = `tx_store_cancel_${orderId}_${Date.now()}`;
              const storeTransactionRef = db.collection("Transactions").doc(storeTxId);
              transaction.set(storeTransactionRef, {
                id: storeTxId,
                amount: -subOrderRefundableAmount, // قيمة سالبة تعبر عن الخصم من الرصيد المعلق
                orderId: orderId,
                storeId: storeId,
                status: "completed",
                type: "cancel_deduction",
                description: `خصم مبلغ العناصر الملغاة من الطلب رقم #${orderId}`,
                date: admin.firestore.FieldValue.serverTimestamp()
              });
            }
          }
        }
      }
      
      // ز. تحديث حالات العناصر الكلية في الطلب الرئيسي (تحويل الـ pending فقط إلى cancelled)
      const updatedMainItems = items.map(item => {
        if (item.itemStatus === "pending") {
          item.itemStatus = "cancelled";
        }
        return item;
      });
      
      // تحديث الطلب الرئيسي بالكامل إلى ملغي
      transaction.update(orderRef, {
        Status: "cancelled",
        Items: updatedMainItems,
        items: updatedMainItems,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // ح. شحن محفظة المستخدم بالرصيد المرتجع الفعلي وتدوين المعاملة المالية
      transaction.update(userRef, {
        walletBalance: newBalance
      });

      // توليد معرف فريد ومستقر للـ Transaction يمنع التداخل (تطبيقاً للحل السابق)
      const userTxId = `tx_refund_${orderId}_${Date.now()}`;
      const userTransactionRef = db.collection("User").doc(userId).collection("Transactions").doc(userTxId);

      if (refundAmount > 0) {
        transaction.set(userTransactionRef, {
          id: userTxId,
          orderId: orderId,
          amount: refundAmount,
          type: "refund",
          status: "completed",
          title: "إعادة مبلغ العناصر الملغاة",
          description: `تم استرداد رصيد العناصر المتبقية من الطلب رقم #${orderId} تلقائياً لإلغائه.`,
          date: admin.firestore.FieldValue.serverTimestamp()
        });

        // تسجيل الإشعار الداخلي (في قاعدة البيانات)
        logNotificationWithTransaction(transaction, "User", userId, {
          title: "تم إلغاء الطلب واسترداد الرصيد 💰",
          body: `تم إلغاء طلبك رقم #${orderId} بنجاح وإعادة مبلغ ${refundAmount} ILS لعناصر قيد الانتظار بمحفظتك.`,
          type: "refund"
        });
      } else {
        // إلغاء بدون استرداد مالي (مثل حالات الدفع عند الاستلام أو الطلب معلق الدفع بالكامل)
        logNotificationWithTransaction(transaction, "User", userId, {
          title: "تم إلغاء الطلب بنجاح ❌",
          body: `بناءً على طلبك، تم إلغاء الطلب رقم #${orderId} بنجاح كونه لم ينتقل للتجهيز بعد.`,
          type: "cancel_order"
        });
      }

      // إرجاع البيانات الهامة لبناء الـ Push Notification
      return {
        success: true,
        refundAmount: refundAmount,
        fcmToken: userData.fcmToken || null
      };
    });

    // 2. إرسال إشعار الـ Push Notification للمستخدم خارج نطاق الـ Transaction لحماية السرعة للأداء
    if (result.fcmToken) {
      const isRefunded = result.refundAmount > 0;
      const payload = {
        token: result.fcmToken,
        notification: {
          title: isRefunded ? "تم إلغاء الطلب واسترداد الرصيد 💰" : "تم إلغاء الطلب بنجاح ❌",
          body: isRefunded 
            ? `تم إلغاء طلبك بنجاح وإعادة مبلغ ${result.refundAmount} ILS إلى محفظتك الحالية.`
            : `بناءً على طلبك، تم إلغاء الطلب رقم #${orderId} بنجاح.`
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: isRefunded ? "wallet_refund" : "cancel_order",
          orderId: orderId
        }
      };

      try {
        await admin.messaging().send(payload);
        console.log(`تم إرسال إشعار الإلغاء الخارجي بنجاح للمستخدم: ${userId}`);
      } catch (fcmError) {
        console.error("فشل إرسال إشعار الـ FCM ولكن المعاملة المحاسبية تمت بنجاح:", fcmError);
      }
    }

    return {
      status: "success",
      message: "تم إلغاء الطلب بنجاح وتحديث الحسابات المحاسبية بالكامل.",
      refundedAmount: result.refundAmount
    };

  } catch (error) {
    console.error("خطأ في دالة cancelOrderAndRefund المطورة:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError(
      "internal",
      error.message || "حدث خطأ داخلي أثناء معالجة إلغاء الطلب المطور."
    );
  }
});
*/








/*
exports.cancelOrderAndRefund = onCall(async (request) => {
  // 1. التحقق من هوية المستخدم (Authentication Check)
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "يجب تسجيل الدخول أولاً لتنفيذ هذه العملية."
    );
  }

  const userId = request.auth.uid;
  const { orderId } = request.data;

  // التحقق من مدخلات الدالة
  if (!orderId) {
    throw new HttpsError(
      "invalid-argument",
      "لم يتم تزويد الدالة بمعرف الطلب (orderId)."
    );
  }

  const db = admin.firestore();
  
  // تعريف المراجع (References) بداخل الفايرستور
  const orderRef = db.collection("Orders").doc(orderId);
  const userRef = db.collection("User").doc(userId);
  const transactionRef = db.collection("User").doc(userId).collection("Transactions").doc();

  try {
    // نقوم بعمل استعلام عادي خارج الـ transaction أولاً لجلب كافة الطلبات الفرعية لهذا الطلب الرئيسي
    const subOrdersSnapshot = await db.collection("StoreOrders")
      .where("MainOrderId", "==", orderId)
      .get();

    // تشغيل العملية التزامنية الذرية (Transaction)
    const result = await db.runTransaction(async (transaction) => {
      
      // أ. جلب مستند الطلب وفحصه
      const orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) {
        throw new HttpsError("not-found", "الطلب المحدد غير موجود بالسجلات.");
      }

      const orderData = orderDoc.data();
      
      // التأكد من أن الطلب يخص المستخدم الحالي الذي استدعى الدالة
      if (orderData.UserId !== userId) {
        throw new HttpsError("permission-denied", "غير مسموح لك بإلغاء طلب لا يخص حسابك.");
      }

      // ب. فحص حالة الطلب الكلية
      const orderStatus = orderData.Status || "";
      if (orderStatus !== "pending" && orderStatus !== "pendingPayment") {
        throw new HttpsError(
          "failed-precondition",
          "لا يمكن إلغاء الطلب، لقد انتقل الطلب إلى مرحلة التجهيز أو الشحن بالفعل."
        );
      }

      // ج. فحص حالة المنتجات بداخل الطلب (تأمين قراءة الحقل بالحالتين الكابيتال والسمول)
      const items = orderData.Items || orderData.items || [];
      const isAnyProductProcessed = items.some(item => item.itemStatus !== "pending");
      if (isAnyProductProcessed) {
        throw new HttpsError(
          "failed-precondition",
          "تعذر الإلغاء تلقائياً؛ قام أحد المتاجر بقبول أو تجهيز جزء من المنتجات."
        );
      }

      // د. جلب رصيد محفظة المستخدم الحالي
      const userDoc = await transaction.get(userRef);
      if (!userDoc.exists) {
        throw new HttpsError("not-found", "حساب المستخدم غير موجود بالسجلات.");
      }

      const userData = userDoc.data();
      const currentBalance = Number(userData.walletBalance || 0);
      
      // إذا كانت الحالة بانتظار الدفع، المبلغ المسترد يكون 0 لأن المستخدم لم يدفع أصلاً
      let refundAmount = 0;
      if (orderStatus === "pending") {
        refundAmount = Number(orderData.TotalAmount || orderData.totalAmount || 0);
      }
      const newBalance = currentBalance + refundAmount;

      // هـ. [تحديث الطلبات الفرعية للمتاجر المتأثرة]
      for (const subOrderDocSnapshot of subOrdersSnapshot.docs) {
        const subOrderRef = subOrderDocSnapshot.ref;
        const subOrderDoc = await transaction.get(subOrderRef);
        
        if (subOrderDoc.exists) {
          const subOrderData = subOrderDoc.data();
          const storeId = subOrderData.StoreId || subOrderData.storeId;
          const subTotalAmount = Number(subOrderData.totalAmount || subOrderData.TotalAmount || 0);

          let subOrderItems = subOrderData.Items || subOrderData.items || [];
          
          // 1. تحويل كافة حالات العناصر داخل الطلب الفرعي لـ cancelled
          subOrderItems = subOrderItems.map(subItem => {
            subItem.itemStatus = "cancelled";
            return subItem;
          });

          // 2. تحديث الطلب الفرعي ليصبح ملغياً ومصفراً
          transaction.update(subOrderRef, {
            Items: subOrderItems,
            totalAmount: 0,
            Status: "cancelled",
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });

          // 3. تحديث محفظة المتجر وخصم الرصيد المعلق
          if (storeId && subTotalAmount > 0) {
            const storeRef = db.collection("Stores").doc(storeId);
            const storeDoc = await transaction.get(storeRef);
            
            if (storeDoc.exists) {
              const storeData = storeDoc.data();
              const currentWallet = storeData.wallet || {};
              const currentPendingBalance = Number(currentWallet.pendingBalance || 0);
              
              const newPendingBalance = Number(Math.max(0, currentPendingBalance - subTotalAmount).toFixed(2));

              transaction.update(storeRef, {
                "wallet.pendingBalance": newPendingBalance,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
              });

              // 4. تسجيل مستند المعاملة المالية الخاصة بالمتجر
              const storeTransactionRef = db.collection("Transactions").doc();
              transaction.set(storeTransactionRef, {
                id: storeTransactionRef.id,
                amount: subTotalAmount,
                orderId: orderId,
                storeId: storeId,
                status: "completed",
                type: "cancel_deduction",
                date: admin.firestore.FieldValue.serverTimestamp()
              });
            }
          }
        }
      }
      
      // و. تنفيذ التعديلات المتزامنة في مستندات المستخدم والطلب الرئيسي
      const updatedMainItems = items.map(item => {
        item.itemStatus = "cancelled";
        return item;
      });
      
      // 1. تحديث حالة الطلب الرئيسي وتصفيره وتأمين تحديث كلا الحقلين احتياطياً لحماية بنية المستند
      transaction.update(orderRef, {
        Status: "cancelled",
        Items: updatedMainItems,
        items: updatedMainItems,
        TotalAmount: 0,
        totalAmount: 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // 2. شحن المحفظة بالرصيد الجديد
      transaction.update(userRef, {
        walletBalance: newBalance
      });

      // 3. تدوين السجل المالي للعملية المحاسبية والإشعارات الداخلية
      if (refundAmount > 0) {
        transaction.set(transactionRef, {
          id: transactionRef.id,
          amount: refundAmount,
          type: "refund",
          status: "completed",
          title: "إعادة مبلغ الطلب الملغي",
          description: `تم استرداد رصيد الطلب رقم #${orderId} تلقائياً لإلغائه قبل التجهيز.`,
          date: admin.firestore.FieldValue.serverTimestamp()
        });

        logNotificationWithTransaction(transaction, "User", userId, {
          title: "تم إلغاء الطلب واسترداد الرصيد 💰",
          body: `بناءً على طلبك، تم إلغاء الطلب بنجاح وإعادة مبلغ ${refundAmount} ILS إلى محفظتك الحالية.`,
          type: "refund"
        });
      } else {
        logNotificationWithTransaction(transaction, "User", userId, {
          title: "تم إلغاء الطلب بنجاح ❌",
          body: `بناءً على طلبك، تم إلغاء الطلب غير المدفوع رقم #${orderId} بنجاح.`,
          type: "cancel_order"
        });
      }

      // إرجاع قيمة لإشعار كود فلوتر
      return {
        success: true,
        refundAmount: refundAmount,
        fcmToken: userData.fcmToken || null
      };
    });

    // 2. إرسال إشعار الـ Push Notification للمستخدم بأمان (تم حل مشكلة النطاق هنا بقراءة result.refundAmount)
    if (result.fcmToken) {
      // صياغة رسالة الإشعار ديناميكياً لتطابق منطق الدفع والمال المسترد
      const isRefunded = result.refundAmount > 0;
      const payload = {
        token: result.fcmToken,
        notification: {
          title: isRefunded ? "تم إلغاء الطلب واسترداد الرصيد 💰" : "تم إلغاء الطلب بنجاح ❌",
          body: isRefunded 
            ? `بناءً على طلبك، تم إلغاء الطلب بنجاح وإعادة مبلغ ${result.refundAmount} ILS إلى محفظتك الحالية.`
            : `بناءً على طلبك، تم إلغاء الطلب غير المدفوع رقم #${orderId} بنجاح.`
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: isRefunded ? "wallet_refund" : "cancel_order",
          orderId: orderId
        }
      };

      try {
        await admin.messaging().send(payload);
        console.log(`تم إرسال إشعار الإلغاء بنجاح للمستخدم: ${userId}`);
      } catch (fcmError) {
        console.error("فشل إرسال إشعار الـ FCM ولكن المعاملة تمت بنجاح:", fcmError);
      }
    }

    return {
      status: "success",
      message: "تم إلغاء الطلب وتحديث المحفظة بنجاح.",
      refundedAmount: result.refundAmount
    };

  } catch (error) {
    console.error("خطأ كارثي في دالة cancelOrderAndRefund:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError(
      "internal",
      error.message || "حدث خطأ داخلي في السيرفر أثناء معالجة إلغاء الطلب."
    );
  }
});
*/






exports.cancelSpecificItems = onCall({ cors: true, timeoutSeconds: 60 }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لتنفيذ هذه العملية.");
  }

  const userId = request.auth.uid;
  const { orderId, itemsToCancel } = request.data; 

  if (!orderId || !itemsToCancel || !Array.isArray(itemsToCancel)) {
    throw new HttpsError("invalid-argument", "المعطيات المرسلة غير مكتملة أو غير صالحة.");
  }

  const orderRef = db.collection("Orders").doc(orderId);
  const userRef = db.collection("User").doc(userId);

  try {
    const initialOrderDoc = await orderRef.get();
    if (!initialOrderDoc.exists) {
      throw new HttpsError("not-found", "الطلب المحدد غير موجود في سجلات النظام.");
    }

    const initialOrderData = initialOrderDoc.data();
    if (initialOrderData.UserId !== userId) {
      throw new HttpsError("permission-denied", "لا تملك الصلاحية لتعديل أو إلغاء هذا الطلب.");
    }

    // فحص حالة الدفع مع توحيد حالة الأحرف لحقل Status أو status
    const currentOrderStatusStr = String(initialOrderData.Status || initialOrderData.status || "").toLowerCase();
    const isMainOrderPaid = currentOrderStatusStr !== "pendingpayment";
    
    const initialItems = initialOrderData.Items || initialOrderData.items || [];
    const affectedStoreIds = new Set();
    
    initialItems.forEach(item => {
      const isMatched = itemsToCancel.some(target => 
        String(target.productId).trim() === String(item.productId).trim() && 
        String(target.variationId || "").trim() === String(item.VariationId || item.variationId || "").trim()
      );

      if (isMatched && item.storeId) {
        affectedStoreIds.add(String(item.storeId).trim());
      }
    });

    const storeIdsArray = Array.from(affectedStoreIds);
    const subOrderRefsMap = {}; 

    for (const storeId of storeIdsArray) {
      const subOrderSnapshot = await db.collection("StoreOrders")
        .where("MainOrderId", "==", orderId)
        .where("StoreId", "==", storeId)
        .limit(1)
        .get();

      if (!subOrderSnapshot.empty) {
        subOrderRefsMap[storeId] = subOrderSnapshot.docs[0].ref;
      }
    }

    let finalNotificationTitle = "";
    let finalNotificationBody = "";
    let userFcmToken = null;

    const result = await db.runTransaction(async (transaction) => {
      const orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) {
        throw new HttpsError("not-found", "الطلب المحدد غير موجود.");
      }
      const orderData = orderDoc.data();

      // جلب مستندات الطلبات الفرعية والمستخدم والمتاجر داخل الترانزاكشن
      const subOrderDocsMap = {};
      for (const storeId of storeIdsArray) {
        const subRef = subOrderRefsMap[storeId];
        if (subRef) {
          const sDoc = await transaction.get(subRef);
          if (sDoc.exists) {
            subOrderDocsMap[storeId] = sDoc;
          }
        }
      }

      const userDoc = await transaction.get(userRef);
      userFcmToken = userDoc.exists ? (userDoc.data().fcmToken || null) : null;

      const storeDocsMap = {};
      for (const storeId of storeIdsArray) {
        const storeRef = db.collection("Stores").doc(storeId);
        const sDoc = await transaction.get(storeRef);
        if (sDoc.exists) {
          storeDocsMap[storeId] = sDoc;
        }
      }

      let items = orderData.Items || orderData.items || [];
      let totalRefundToUser = 0;          
      let totalAmountToDeductFromInvoice = 0; 
      let storesToUpdateBalances = {}; 
      let automaticallyCancelledItems = [];
      let requestedForReviewItems = [];
      let adminReviewRequestsToSet = []; 
      let processedInThisOrder = false;
      

      for (let item of items) {
        const isTargetToCancel = itemsToCancel.some(target => 
          String(target.productId).trim() === String(item.productId).trim() && 
          String(target.variationId || "").trim() === String(item.VariationId || item.variationId || "").trim()
        );
        
        if (isTargetToCancel) {
          const itemPrice = Number(item.price || item.Price || 0);
          const itemQuantity = Number(item.Quantity || item.quantity || 1);
          const itemTotal = Number((itemPrice * itemQuantity).toFixed(2)); 
          const currentStatus = String(item.itemStatus || item.ItemStatus || "pending").toLowerCase();

          if (currentStatus === "pending" || currentStatus === "pendingpayment") {
            totalAmountToDeductFromInvoice += itemTotal;

            if (isMainOrderPaid && currentStatus === "pending") {
              totalRefundToUser += itemTotal;
              if (item.storeId) {
                const sIdStr = String(item.storeId).trim();
                storesToUpdateBalances[sIdStr] = (storesToUpdateBalances[sIdStr] || 0) + itemTotal;
              }
            }
            
            item.itemStatus = "cancelled";
            automaticallyCancelledItems.push(`${item.Title || item.title || "منتج"}`);
            processedInThisOrder = true;
          } 
          else if (["accepted", "shipped", "delivered", "processing"].includes(currentStatus)) {
            const targetStatus = (currentStatus === "accepted" || currentStatus === "processing") ? "cancellation_requested" : "return_requested";
            
            item.itemStatus = targetStatus;
            requestedForReviewItems.push(`${item.Title || item.title || "منتج"}`);

            const reviewRequestRef = db.collection("AdminReviewRequests").doc();
            adminReviewRequestsToSet.push({
              ref: reviewRequestRef,
              data: {
                id: reviewRequestRef.id,
                orderId: orderId,
                userId: userId,
                storeId: item.storeId || "",
                itemId: item.productId,
                variationId: item.VariationId || item.variationId || "",
                itemName: item.Title || item.title || "منتج",
                itemTotalAmount: itemTotal,
                requestType: (currentStatus === "accepted" || currentStatus === "processing") ? "cancel_prepared_item" : "return_shipped_item",
                status: "pending_admin_approval",
                createdAt: admin.firestore.FieldValue.serverTimestamp()
              }
            });
            processedInThisOrder = true;
          } else {
            throw new HttpsError("failed-precondition", `العنصر [${item.Title || item.title}] تمت معالجته أو إلغاؤه مسبقاً.`);
          }
        }
      }

      if (!processedInThisOrder) {
        throw new HttpsError("invalid-argument", "لم يتم مطابقة أي عناصر، يرجى التحقق من المدخلات للطلب.");
      }

      // إدخال مستندات المراجعة للإدارة إن وجدت
      adminReviewRequestsToSet.forEach(req => {
        transaction.set(req.ref, req.data);
      });

      // تحديث الطلبات الفرعية للمتاجر (StoreOrders)
      for (const storeId of storeIdsArray) {
        const subOrderDoc = subOrderDocsMap[storeId];
        const subOrderRef = subOrderRefsMap[storeId];

        if (subOrderDoc && subOrderRef) {
          const subOrderData = subOrderDoc.data();
          let subOrderItems = subOrderData.Items || subOrderData.items || [];
          let subOrderDeductionAmount = 0;
          let cancelledItemsNamesForThisStore = []; // 🌟 لتجميع أسماء المنتجات الملغاة من هذا المتجر تحديداً

          subOrderItems = subOrderItems.map(subItem => {
            const updatedItem = items.find(mainItem => 
              String(mainItem.productId).trim() === String(subItem.productId).trim() && 
              String(mainItem.VariationId || mainItem.variationId || "").trim() === String(subItem.VariationId || subItem.variationId || "").trim()
            );
            
            if (updatedItem) {
              const subItemStatus = String(subItem.itemStatus || subItem.ItemStatus || "").toLowerCase();
              if (updatedItem.itemStatus === "cancelled" && subItemStatus !== "cancelled") {
                const price = Number(subItem.price || subItem.Price || 0);
                const qty = Number(subItem.Quantity || subItem.quantity || 1);
                subOrderDeductionAmount += Number((price * qty).toFixed(2));
                // إضافة اسم المنتج لرسالة المتجر
                cancelledItemsNamesForThisStore.push(subItem.Title || subItem.title || "منتج");
              }
              subItem.itemStatus = updatedItem.itemStatus;
            }
            return subItem;
          });

          const allSubItemsCancelled = subOrderItems.every(si => String(si.itemStatus || si.ItemStatus || "").toLowerCase() === "cancelled");
          const currentSubTotal = Number(subOrderData.totalAmount || subOrderData.TotalAmount || 0);
          let newSubTotal = currentSubTotal - subOrderDeductionAmount;

          transaction.update(subOrderRef, {
            Items: subOrderItems,
            TotalAmount: newSubTotal < 0 ? 0 : Number(newSubTotal.toFixed(2)),
            totalAmount: newSubTotal < 0 ? 0 : Number(newSubTotal.toFixed(2)), // الحفاظ على الحالتين تجنباً للمشاكل
            Status: allSubItemsCancelled ? "cancelled" : (subOrderData.Status || subOrderData.status || "pending"),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });

          // 2️⃣ 🌟 صياغة وحفظ إشعار الداتابيز للمتجر إذا كان هناك إلغاء فعلي لمنتجاته
    if (cancelledItemsNamesForThisStore.length > 0) {
      const storeNotificationBody = allSubItemsCancelled 
        ? `قام العميل بإلغاء الطلب بالكامل رقم #${orderId}. يرجى التوقف عن التجهيز.`
        : `قام العميل بإلغاء عناصر من الطلب #${orderId} وهي: (${cancelledItemsNamesForThisStore.join(", ")}).`;

      logNotificationWithTransaction(transaction, "Store", storeId, {
        title: allSubItemsCancelled ? "🚨 إلغاء الطلب بالكامل" : "⚠️ إلغاء عناصر من الطلب",
        body: storeNotificationBody,
        orderId: orderId,
        type: allSubItemsCancelled ? "store_order_cancelled" : "store_item_cancelled",
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
        }
      }

      // قراءة القيم المالية بدقة مع مراعاة حالة الأحرف (PascalCase / camelCase)
      const shippingFee = Number(orderData.ShippingAmount || orderData.shippingAmount || 0);
      const currentTotal = Number(orderData.TotalAmount || orderData.totalAmount || 0);
      const currentItemsAmount = Number(orderData.ItemsAmount || orderData.itemsAmount || 0);
      const currentBankRequired = Number(orderData.BankRequiredAmount || orderData.bankRequiredAmount || 0);
      const currentWalletPaid = Number(orderData.WalletPaidAmount || orderData.walletPaidAmount || 0);

      const allItemsCancelled = items.every(item => String(item.itemStatus || item.ItemStatus || "").toLowerCase() === "cancelled");
      const hasAnyShippedProduct = items.some(item => {
        const s = String(item.itemStatus || item.ItemStatus || "").toLowerCase();
        return s === "shipped" || s === "delivered";
      });
      
      if (allItemsCancelled && !hasAnyShippedProduct && isMainOrderPaid) {
        totalRefundToUser += shippingFee;
      }

      // الحسابات المالية الجديدة الدقيقة
      let newTotalAmount = currentTotal - totalAmountToDeductFromInvoice;
      let newItemsAmount = currentItemsAmount - totalAmountToDeductFromInvoice;
      let newBankRequired = currentBankRequired;
      let newWalletPaid = currentWalletPaid;

      if (allItemsCancelled) {
        newTotalAmount = 0;
        newItemsAmount = 0;
      }

      // 💳 صياغة الإشعار وحسابات الـ المالي بناءً على حالة الدفع
      if (isMainOrderPaid) {
        finalNotificationTitle = "🚫 إلغاء منتجات وتعديل مالي";
        finalNotificationBody = `تم إلغاء منتجات من طلبك رقم #${orderId.substring(0, 6)}.`;
        
        if (totalRefundToUser > 0 && userDoc.exists) {
          finalNotificationBody += ` تم استرداد ₪${totalRefundToUser.toFixed(2)} فورياً إلى محفظتك.`;
          
          const currentBal = Number(userDoc.data().walletBalance || 0);
          transaction.update(userRef, { walletBalance: Number((currentBal + totalRefundToUser).toFixed(2)) });

          const userLogRef = userRef.collection("Transactions").doc(`refund_${orderId}_${Date.now()}`);
          transaction.set(userLogRef, {
            id: userLogRef.id,
            orderId: orderId,
            amount: totalRefundToUser, 
            type: "partial_refund",
            title: "استرداد تلقائي لمنتجات ملغاة",
            description: `تم استرداد مبلغ ₪${totalRefundToUser.toFixed(2)} فورياً لمحفظتك عن المنتجات الملغاة في الطلب #${orderId.substring(0, 6)}.`,
            date: admin.firestore.FieldValue.serverTimestamp()
          });

          newWalletPaid = currentWalletPaid - totalRefundToUser;
          if (newWalletPaid < 0) newWalletPaid = 0;

          // خصم القيم من الحسابات المعلقة للمتاجر
          for (const [storeId, amountToDeduct] of Object.entries(storesToUpdateBalances)) {
            const storeDoc = storeDocsMap[storeId];
            if (storeDoc) {
              const storeData = storeDoc.data() || {};
              const currentPending = Number((storeData.wallet && storeData.wallet.pendingBalance) || 0);
              let newPending = currentPending - amountToDeduct;
              if (newPending < 0) newPending = 0;

              transaction.update(storeDoc.ref, { 'wallet.pendingBalance': Number(newPending.toFixed(2)) });
            }
          }
        }
      } else {
        // 🏦 [الحل الجذري للطلب غير المدفوع]: خصم القيمة من حقل التحويل البنكي المطلوب وحقن القيمة الجديدة بالإشعار
        newBankRequired = currentBankRequired - totalAmountToDeductFromInvoice;
        if (newBankRequired < 0) newBankRequired = 0;

        finalNotificationTitle = "📉 تعديل قيمة طلب غير مدفوع";
        finalNotificationBody = `تم إلغاء منتجات من طلبك المعلق #${orderId.substring(0, 6)}. المبلغ المطلوب تحويله بنكياً الآن أصبح: (₪${newBankRequired.toFixed(2)}) بدلاً من ₪${currentBankRequired.toFixed(2)}.`;
      }

      if (requestedForReviewItems.length > 0) {
        finalNotificationBody += ` هناك عناصر (${requestedForReviewItems.length}) قيد المراجعة حالياً من قِبل الإدارة.`;
      }

      // 🔔 تسجيل الإشعار التاريخي داخل الـ وارد للتطبيق (Database Notification)
      if (finalNotificationTitle && finalNotificationBody) {
        logNotificationWithTransaction(transaction, "User", userId, {
          title: finalNotificationTitle,
          body: finalNotificationBody,
          orderId: orderId,
          type: "order_item_cancelled",
        });
      }

      // إنشاء جزيئية التحديث الموحدة لحماية حالة الأحرف لجميع الحقول في المستند الأساسي
      let updatePayload = {
        Items: items,
        TotalAmount: Number(newTotalAmount.toFixed(2)),
        ItemsAmount: newItemsAmount < 0 ? 0 : Number(newItemsAmount.toFixed(2)),
        WalletPaidAmount: Number(newWalletPaid.toFixed(2)), 
        BankRequiredAmount: Number(newBankRequired.toFixed(2)),
        Status: allItemsCancelled ? "cancelled" : (orderData.Status || orderData.status || "pending"),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      transaction.update(orderRef, updatePayload);

      return {
        success: true,
        refundedAmount: totalRefundToUser,
        newBankRequiredAmount: newBankRequired
      };
    });

    

    // ====================================================================
    // ⚡ 1. [إرسال إشعار الـ FCM الفوري إلى جهاز العميل/المستخدم]
    // ====================================================================
    if (userFcmToken && finalNotificationTitle && finalNotificationBody) {
        await sendFcmNotification(userId, finalNotificationTitle, finalNotificationBody, orderId, "order_status");
    }

    // ====================================================================
    // ⚡ 2. [إرسال إشعار الـ FCM الفوري إلى أجهزة المتاجر المتأثرة بالإلغاء]
    // ====================================================================
    try {
        const storeNotificationPromises = storeIdsArray.map(async (storeId) => {
            const storeDoc = storeDocsMap[storeId];
            const storeFcmToken = storeDoc?.exists ? (storeDoc.data().fcmToken || null) : null;

            // نرسل الإشعار فقط إذا كان للمتجر Token صالح على FCM
            if (storeFcmToken) {
                // جلب حالة الطلب الفرعي الحالي للمتجر لنعلم هل أُلغي كلياً أم جزئياً
                const subOrderSnapshot = await db.collection("StoreOrders")
                    .where("MainOrderId", "==", orderId)
                    .where("StoreId", "==", storeId)
                    .limit(1)
                    .get();
                    
                if (!subOrderSnapshot.empty) {
                    const subOrderStatus = String(subOrderSnapshot.docs[0].data().Status || "");
                    
                    // صياغة عنوان ونص التنبيه بناءً على حالة طلب المتجر
                    const storeFcmTitle = subOrderStatus === "cancelled" ? "🚨 إلغاء طلب كامل!" : "⚠️ تعديل وإلغاء عناصر";
                    const storeFcmBody = subOrderStatus === "cancelled"
                        ? `تنبيه: قام العميل بإلغاء الطلب رقم #${orderId} بالكامل. توقف عن التجهيز.`
                        : `تنبيه: تم إلغاء بعض المنتجات من الطلب رقم #${orderId}. يرجى مراجعة تفاصيل الطلب.`;

                    // إرسال الـ FCM للمتجر (مستخدماً المعرف الخاص به كـ Target)
                    return sendFcmNotification(storeId, storeFcmTitle, storeFcmBody, orderId, "store_order_status");
                }
            }
            return null;
        });

        // تشغيل جميع إشعارات المتاجر بالتوازي لضمان السرعة وعدم تعطيل استجابة الدالة
        await Promise.all(storeNotificationPromises);

    } catch (fcmError) {
        // حماية الدالة: لو فشل إرسال إشعار FCM لمتجر معين، لا نريد أن يفشل الطلب بالكامل أو يظهر خطأ للعميل
        console.error("⚠️ Non-critical Error sending FCM to stores:", fcmError);
    }

    return { status: "success", refundedAmount: result.refundedAmount, newBankRequiredAmount: result.newBankRequiredAmount };

  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error("CRITICAL CANCEL ITEMS SERVER ERROR:", error);
    throw new HttpsError("internal", error.message || "حدث خطأ في السيرفر أثناء معالجة إلغاء العناصر.");
  }
});




/**
 * دالة كلاود لتحديث حالة منتج معين في طلب التاجر بالتنسيق الحديث v2 (لغة جافا سكربت)
 */
exports.updateItemStatusInCloud = onCall({
    cors: true,
    timeoutSeconds: 60,
}, async (request) => {
    
    const { auth, data } = request;

    // 1. التحقق من المصادقة الأمنية
    if (!auth) {
        throw new HttpsError("unauthenticated", "عذراً، يجب تسجيل الدخول أولاً لإتمام هذه العملية.");
    }

    const { mainOrderId, productId, variationId, newStatus } = data;

    if (!mainOrderId || !productId || !newStatus) {
        throw new HttpsError("invalid-argument", "المعطيات المرسلة غير مكتملة، يرجى تزويد السيرفر بجميع المعرفات القياسية.");
    }

    // خريطة تسلسل الحالات الرسمية للتاجر
    const statusRank = {
        "pending": 0,
        "accepted": 1,
        "readyforpickup": 2, 
        "shipped": 3,
        "delivered": 4,
        "rejected": -1
    };

    const normalizedNewStatus = newStatus.trim().toLowerCase();

    if (statusRank[normalizedNewStatus] === undefined) {
        throw new HttpsError("invalid-argument", `الحالة المطلوبة (${newStatus}) غير مدعومة في نظام السلة.`);
    }

    const storeId = auth.uid;

    try {
        const storeOrdersRef = db.collection("StoreOrders");
        const querySnapshot = await storeOrdersRef
            .where("StoreId", "==", storeId)
            .where("MainOrderId", "==", String(mainOrderId).trim())
            .limit(1)
            .get();

        if (querySnapshot.empty) {
            throw new HttpsError("not-found", "لم يتم العثور على هذا الطلب في سجلات متجرك، أو انتهت صلاحية الوصول.");
        }

        const targetDocSnap = querySnapshot.docs[0];
        const storeOrderRef = targetDocSnap.ref;
        const mainOrderRef = db.collection("Orders").doc(String(mainOrderId).trim());

        // بدء الترانزاكشن الآمن
        const result = await db.runTransaction(async (transaction) => {
            
            // ------------------------------------------------------------
            // 🔥 الخطوة 1: تنفيذ جميع عمليات القراءة أولاً (Reads First)
            // ------------------------------------------------------------
            const sDoc = await transaction.get(storeOrderRef);
            if (!sDoc.exists) {
                throw new HttpsError("not-found", "تعذر جلب مستند المتجر المحدث أثناء مراجعة البيانات.");
            }

            const mainOrderDoc = await transaction.get(mainOrderRef);
            // ------------------------------------------------------------

            // الخطوة 2: فحص ومعالجة بيانات المتجر (طالما تم قراءتها وأصبحت بالذاكرة)
            const orderData = sDoc.data();
            const items = orderData.Items || [];
            let itemFound = false;
            const updatedItems = [...items];

            for (let i = 0; i < updatedItems.length; i++) {
                const currentItem = updatedItems[i];
                const isProductMatch = currentItem.productId === productId;
                
                const incomingVar = (variationId || "").trim();
                const currentVar = (currentItem.VariationId || "").trim();
                const isVariationMatch = incomingVar === currentVar;

                if (isProductMatch && isVariationMatch) {
                    itemFound = true;
                    const currentStatus = (currentItem.itemStatus || "pending").toLowerCase();

                    // 🛑 [الحماية المشددة ضد إلغاءات العميل]
                    if (currentStatus === "cancelled") {
                        throw new HttpsError(
                            "failed-precondition",
                            `عذراً، قام العميل بإلغاء هذا المنتج من الفاتورة مسبقاً، ولا يمكنك تعديل حالته حالياً.`
                        );
                    }
                    
                    if (currentStatus === "cancellation_requested" || currentStatus === "return_requested") {
                        throw new HttpsError(
                            "failed-precondition",
                            `هذا المنتج قيد المراجعة حالياً من قبل الإدارة بناءً على طلب العميل لاسترجاعه أو إلغائه.`
                        );
                    }

                    // الحماية ضد الحالات النهائية الكلاسيكية
                    if (currentStatus === "rejected" || currentStatus === "delivered") {
                        throw new HttpsError(
                            "failed-precondition",
                            `هذا المنتج مغلق نهائياً في السيرفر على حالة (${currentItem.itemStatus}).`
                        );
                    }

                    const currentIndex = statusRank[currentStatus] ?? 0;
                    const nextIndex = statusRank[normalizedNewStatus] ?? 0;

                    if (normalizedNewStatus !== "rejected" && nextIndex <= currentIndex) {
                        throw new HttpsError(
                            "failed-precondition",
                            `قواعد النظام تمنع التراجع من حالة (${currentItem.itemStatus}) إلى الحالات السابقة.`
                        );
                    }

                    updatedItems[i].itemStatus = newStatus; // حفظ الحالة الجديدة 
                    break;
                }
            }

            if (!itemFound) {
                throw new HttpsError("not-found", "لم يتم مطابقة معرف المنتج أو الفاريشن مع محتويات الفاتورة الحالية للمتجر.");
            }

            // حوسبة الحالة العامة للطلب الفرعي للمتجر
            let calculatedStoreStatus = orderData.Status || "pending";
            
            const activeItems = updatedItems.filter(item => 
                item.itemStatus !== "rejected" && 
                item.itemStatus !== "cancelled"
            );
            
            if (activeItems.length === 0) {
                const isAllCancelled = updatedItems.every(item => item.itemStatus === "cancelled");
                calculatedStoreStatus = isAllCancelled ? "cancelled" : "rejected";
            } else {
                const allAccepted = activeItems.every(item => item.itemStatus === "accepted");
                const allReady = activeItems.every(item => item.itemStatus === "readyForPickup" || item.itemStatus === "readyforpickup");
                const allShipped = activeItems.every(item => item.itemStatus === "shipped");
                const allDelivered = activeItems.every(item => item.itemStatus === "delivered");

                if (allDelivered) calculatedStoreStatus = "delivered";
                else if (allShipped) calculatedStoreStatus = "shipped";
                else if (allReady) calculatedStoreStatus = "readyForPickup"; 
                else if (allAccepted) calculatedStoreStatus = "accepted";
                else calculatedStoreStatus = "processing"; 
            }

            // الخطوة 3: إعداد كود المزامنة العكسية مع الفاتورة الرئيسية (Orders)
            let mainItemsUpdateData = null;

            if (mainOrderDoc.exists) {
                const mainOrderData = mainOrderDoc.data();
                let mainItems = mainOrderData.Items || mainOrderData.items || [];
                
                mainItems = mainItems.map(mItem => {
                    const isMainProductMatch = mItem.productId === productId;
                    const isMainVarMatch = (mItem.VariationId || "").trim() === (variationId || "").trim();
                    
                    if (isMainProductMatch && isMainVarMatch && mItem.itemStatus !== "cancelled") {
                        mItem.itemStatus = newStatus;
                    }
                    return mItem;
                });

                mainItemsUpdateData = mainItems;
            }

            // ------------------------------------------------------------
            // 🔥 الخطوة 4: تنفيذ جميع عمليات الكتابة أخيراً (Writes Last)
            // ------------------------------------------------------------
            
            // 1. تحديث مستند المتجر فرعياً
            transaction.update(storeOrderRef, {
                Items: updatedItems,
                Status: calculatedStoreStatus,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // 2. تحديث مستند العميل رئيسياً (إن وُجد)
            if (mainItemsUpdateData) {
                transaction.update(mainOrderRef, {
                    Items: mainItemsUpdateData,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }
            // ------------------------------------------------------------

            return {
                status: "success",
                message: "تم تحديث حالة المنتج وحالة المتجر والمزامنة مع الفاتورة الرئيسية بنجاح.",
                newStatus: newStatus,
                storeStatus: calculatedStoreStatus
            };
        });

        return result;

    } catch (error) {
        if (error instanceof HttpsError) throw error;
        console.error("CRITICAL SERVER ERROR IN UPDATE ITEM STATUS:", error);
        throw new HttpsError("internal", error.message || "فشل السيرفر في معالجة تحديث الطلب.");
    }
});



exports.updateItemStatusByDelivery = onCall({
    cors: true,
    timeoutSeconds: 60,
}, async (request) => {
    
    const { auth, data } = request;

    // 1. التحقق من المصادقة الأمنية
    if (!auth) {
        throw new HttpsError("unauthenticated", "عذراً، يجب تسجيل الدخول أولاً لإتمام هذه العملية.");
    }

    // 🌟 فحص ما إذا كان المستخدم الحالي هو أدمن بالنظام
    const isAdmin = auth.token && auth.token.admin === true;

    const { storeOrderId, mainOrderId, productId, variationId, newStatus } = data;

    const deliveryBoyId = auth.uid;
    if (!storeOrderId || !mainOrderId || !productId || !newStatus) {
        throw new HttpsError("invalid-argument", "المعطيات المرسلة غير مكتملة، يرجى تزويد السيرفر بجميع المعرفات.");
    }

    // 🛑 تحديث الحالات المسموحة للمندوب (الشحن، أو إثبات فشل الاستلام)
    const normalizedNewStatus = newStatus.trim();
    const allowedDeliveryStatuses = ["shipped", "pickupFailed_WaitingAction"];

    if (!allowedDeliveryStatuses.includes(normalizedNewStatus)) {
        throw new HttpsError("invalid-argument", `الحالة المطلوبة (${newStatus}) غير مصرح بها للمندوب.`);
    }

    // خريطة تسلسل الحالات الرسمية
    const statusRank = {
        "pending": 0,
        "accepted": 1,
        "readyforpickup": 2, 
        "pickupFailed_WaitingAction": 2.5, // حالة استثنائية معلقة تمنع تحرك المنتج للأمام دون تدخل
        "shipped": 3,
        "delivered": 4,
        "rejected": -1,
        "cancelled": -2
    };

    const driverRef = db.collection("DeliveryDrivers").doc(deliveryBoyId); // 💡 افترضنا هنا اسم الكوليكشن Drivers، يمكنك تعديله لـ Users إن كان مشتركاً
    const storeOrderRef = db.collection("StoreOrders").doc(String(storeOrderId).trim());
    const mainOrderRef = db.collection("Orders").doc(String(mainOrderId).trim());

    try {
        // بدء الترانزاكشن الذري الآمن لحماية الفواتير المشتركة
        const result = await db.runTransaction(async (transaction) => {
            
            // ------------------------------------------------------------
            // 🔥 الخطوة 1: تنفيذ جميع عمليات القراءة أولاً (Reads First)
            // ------------------------------------------------------------
            
            // 🛑 [فحص صلاحية وتفعيل المندوب]
            if (!isAdmin) {
                const driverDoc = await transaction.get(driverRef);
                if (!driverDoc.exists) {
                    throw new HttpsError("permission-denied", "عذراً، لم يتم العثور على حساب المندوب هذا في النظام.");
                }
                
                const driverData = driverDoc.data();
                if (driverData.role !== "driver") {
                    throw new HttpsError("permission-denied", "عذراً، هذا الحساب لا يملك صلاحيات مندوب توصيل.");
                }
                if (driverData.isActive !== true) {
                    throw new HttpsError("permission-denied", "عذراً، حساب المندوب الخاص بك غير مفعل حالياً من قبل الإدارة.");
                }
            }
            
            
            
            
            const sDoc = await transaction.get(storeOrderRef);
            if (!sDoc.exists) {
                throw new HttpsError("not-found", "لم يتم العثور على مستند طلب المتجر المحدد.");
            }

            const mainOrderDoc = await transaction.get(mainOrderRef);
            // ------------------------------------------------------------

            const orderData = sDoc.data();
            const items = orderData.Items || [];
            let itemFound = false;
            let targetItemName = "";
            const updatedItems = [...items];

            // الخطوة 2: فحص الحالات والتحقق من قواعد التراجع
            for (let i = 0; i < updatedItems.length; i++) {
                const currentItem = updatedItems[i];
                const isProductMatch = currentItem.productId === productId;
                
                const incomingVar = (variationId || "").trim();
                const currentVar = (currentItem.VariationId || "").trim();
                const isVariationMatch = incomingVar === currentVar;

                if (isProductMatch && isVariationMatch) {
                    itemFound = true;
                    targetItemName = currentItem.name || "منتج";
                    const currentStatus = (currentItem.itemStatus || "pending");

                    // حماية ضد التعديل على المنتجات المغلقة نهائياً
                    if (["cancelled", "rejected", "delivered"].includes(currentStatus)) {
                        throw new HttpsError(
                            "failed-precondition",
                            `لا يمكن تعديل حالة منتج مغلق حالياً على وضع (${currentItem.itemStatus}).`
                        );
                    }

                    // لا يمكن للمندوب اتخاذ أي إجراء (شحن أو إفشال استلام) إلا إذا جهزه المتجر أولاً
                    if (currentStatus !== "readyforpickup" && currentStatus !== "readyForPickup") {
                        throw new HttpsError(
                            "failed-precondition",
                            "لا يمكن تحديث المنتج؛ يجب أن تكون حالته الحالية (جاهز للاستلام) أولاً."
                        );
                    }

                    // حفظ الحالة الجديدة بداخل الذاكرة
                    updatedItems[i].itemStatus = newStatus; 
                    break;
                }
            }

            if (!itemFound) {
                throw new HttpsError("not-found", "لم يتم مطابقة معرف المنتج مع محتويات الفاتورة الحالية.");
            }

            // حوسبة الحالة العامة لطلب المتجر بناءً على التحديث الجديد
            let calculatedStoreStatus = orderData.Status || "pending";
            const activeItems = updatedItems.filter(item => item.itemStatus !== "rejected" && item.itemStatus !== "cancelled");
            
            if (activeItems.length > 0) {
                const allShipped = activeItems.every(item => item.itemStatus === "shipped");
                const allFailed = activeItems.every(item => item.itemStatus === "pickupFailed_WaitingAction" || item.itemStatus === "pickupFailed_WaitingAction");

                if (allShipped) calculatedStoreStatus = "shipped";
                else if (allFailed) calculatedStoreStatus = "pickupFailed_WaitingAction";
                else calculatedStoreStatus = "processing"; 
            }

            // إعداد التحديث للفاتورة الرئيسية للعميل (Orders)
            let mainItemsUpdateData = null;
            if (mainOrderDoc.exists) {
                const mainOrderData = mainOrderDoc.data();
                let mainItems = mainOrderData.Items || mainOrderData.items || [];
                
                mainItems = mainItems.map(mItem => {
                    if (mItem.productId === productId && (mItem.VariationId || "").trim() === (variationId || "").trim() && mItem.itemStatus !== "cancelled") {
                        mItem.itemStatus = newStatus; // ستتغير في العميل أيضاً إلى shipped أو pickupFailed_WaitingAction
                    }
                    return mItem;
                });
                mainItemsUpdateData = mainItems;
            }

            // ------------------------------------------------------------
            // 🔥 الخطوة 3: تنفيذ جميع عمليات الكتابة أخيراً (Writes Last)
            // ------------------------------------------------------------
            
            // 1. تحديث مستند طلب المتجر فرعياً
            transaction.update(storeOrderRef, {
                Items: updatedItems,
                Status: calculatedStoreStatus,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // 2. تحديث مستند طلب العميل رئيسياً
            if (mainItemsUpdateData) {
                transaction.update(mainOrderRef, {
                    Items: mainItemsUpdateData,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }

            // 3. صياغة وتوثيق الإشعار الداخلي المناسب بداخل قاعدة البيانات بناءً على قرار المندوب
            const customerUserId = orderData.UserId;
            let notifTitle = "";
            let notifBody = "";
            let notifType = "";

            if (normalizedNewStatus === "shipped") {
                notifTitle = "طلبك في الطريق إليك 🚚";
                notifBody = `المندوب استلم منتج [${targetItemName}] بنجاح وهو في طريقه إليك الآن.`;
                notifType = "ITEM_SHIPPED";
            } else {
                notifTitle = "تحديث بخصوص الاستلام ⚠️";
                notifBody = `أفاد المندوب بوجود تعذر في استلام منتج [${targetItemName}] من المتجر، وجاري مراجعة الطلب من الإدارة.`;
                notifType = "ITEM_PICKUP_FAILED";
            }

            /*logNotificationWithTransaction(transaction, "User", customerUserId, {
                title: notifTitle,
                body: notifBody,
                type: notifType,
                mainOrderId: mainOrderId,
                isRead: false,
                isOpened: false,
                isCritical: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });*/

            return {
                status: "success",
                userId: customerUserId,
                itemName: targetItemName,
                notifTitle: notifTitle,
                notifBody: notifBody,
                notifType: notifType
            };
        });

        // ------------------------------------------------------------
        // الخطوة 4: إرسال الـ FCM الخارجي اللحظي بعد نجاح معالجة البيانات
        // ------------------------------------------------------------
        /*await sendUnifiedNotification({
            targetType: "User",
            targetId: result.userId,
            title: result.notifTitle,
            body: result.notifBody,
            dataPayload: { type: result.notifType, orderId: mainOrderId },
            isCritical: false,
            skipFirestoreSave: true // 🔥 تخطي خطوة إعادة الحفظ لمنع التكرار
        });*/

        return { success: true, message: "تم تحديث الحالة وإشعار الأطراف المعنية بنجاح." };

    } catch (error) {
        if (error instanceof HttpsError) throw error;
        console.error("CRITICAL ERROR IN DELIVERY STATUS UPDATE:", error);
        throw new HttpsError("internal", error.message || "حدث خطأ داخلي في السيرفر.");
    }
});



exports.finalizeStoreOrderPickup = onCall({
    cors: true,
    timeoutSeconds: 60,
}, async (request) => {
    const { auth, data } = request;

    // 1. التحقق من المصادقة الأمنية
    if (!auth) {
        throw new HttpsError("unauthenticated", "عذراً، يجب تسجيل الدخول أولاً لإتمام هذه العملية.");
    }

    // 🌟 فحص ما إذا كان المستخدم الحالي هو أدمن بالنظام
    const isAdmin = auth.token && auth.token.admin === true;

    const { storeOrderId, mainOrderId, inputCode } = data;
    const deliveryBoyId = auth.uid;

    if (!storeOrderId || !mainOrderId || !inputCode) {
        throw new HttpsError("invalid-argument", "المعطيات المرسلة غير مكتملة، يرجى تزويد السيرفر بجميع المعرفات والرمز.");
    }

    const driverRef = db.collection("DeliveryDrivers").doc(deliveryBoyId); // 💡 افترضنا هنا اسم الكوليكشن Drivers، يمكنك تعديله لـ Users إن كان مشتركاً
    const storeOrderRef = db.collection("StoreOrders").doc(String(storeOrderId).trim());
    const mainOrderRef = db.collection("Orders").doc(String(mainOrderId).trim());

    try {
        // بدء الترانزاكشن الذري لحماية الحسابات اللوجستية والأمنية
        const result = await db.runTransaction(async (transaction) => {
            
            // ------------------------------------------------------------
            // 🔥 الخطوة 1: جميع عمليات القراءة أولاً (Reads First)
            // ------------------------------------------------------------
            
            
            // 🛑 [فحص صلاحية وتفعيل المندوب]
            if (!isAdmin) {
              const driverDoc = await transaction.get(driverRef);
              if (!driverDoc.exists) {
                  throw new HttpsError("permission-denied", "عذراً، لم يتم العثور على حساب المندوب هذا في النظام.");
              }
              
              const driverData = driverDoc.data();
              if (driverData.role !== "driver") {
                  throw new HttpsError("permission-denied", "عذراً، هذا الحساب لا يملك صلاحيات مندوب توصيل.");
              }
              if (driverData.isActive !== true) {
                  throw new HttpsError("permission-denied", "عذراً، حساب المندوب الخاص بك غير مفعل حالياً من قبل الإدارة.");
              }
           }
            
            
            
            
            const storeOrderDoc = await transaction.get(storeOrderRef);
            if (!storeOrderDoc.exists) {
                throw new HttpsError("not-found", "لم يتم العثور على مستند طلب المتجر المحدد.");
            }

            const mainOrderDoc = await transaction.get(mainOrderRef);
            // ------------------------------------------------------------

            const storeOrderData = storeOrderDoc.data();
            
            // 🔐 1. التحقق الآمن من الرمز على السيرفر
            const correctCode = storeOrderData.PickupCode  || "0000";
            if (String(inputCode).trim() !== String(correctCode).trim()) {
                throw new HttpsError("permission-denied", "رمز الاستلام المدخل غير صحيح، يرجى التحقق من التاجر.");
            }

            // 2. التحقق من حالة الطلب الكلية (ألا يكون منتهياً أو ملغياً مسبقاً)
            const currentStoreStatus = (storeOrderData.Status || "");
            if (["shipped", "delivered", "cancelled"].includes(currentStoreStatus)) {
                throw new HttpsError("failed-precondition", "هذا الطلب تم تحديثه مسبقاً أو إلغاؤه، لا يمكن استلامه مجدداً.");
            }

            const items = storeOrderData.Items || [];

            // 🛑 [خطوة الحماية الإضافية المخصصة التي طلبتها]
            // فحص ما إذا كان هناك أي منتج في الفاتورة لا يزال بحاجة إلى استلام يدوياً أولاً
            const hasRemainingReadyItems = items.some(item => {
                const itemStatus = (item.itemStatus || "");
                return itemStatus === "readyForPickup" ;
            });

            if (hasRemainingReadyItems) {
                throw new HttpsError(
                    "failed-precondition", 
                    "عذراً، لا يمكنك إنهاء الاستلام بالرمز؛ يجب عليك أولاً فحص وتحديث حالة جميع المنتجات الفردية إلى (تم الشحن) داخل التطبيق."
                );
            }

            // التأكد من أن الطلب يحتوي بالفعل على منتجات تم شحنها (حتى لا يتم تأكيد طلب فارغ أو كله ملغى)
            const hasShippedItems = items.some(item => (item.itemStatus || "") === "shipped");
            if (!hasShippedItems) {
                throw new HttpsError("failed-precondition", "لا توجد أي منتجات مشحونة حالياً لتأكيد استلامها بداخل هذا الطلب.");
            }

            // ------------------------------------------------------------
            // 🔥 الخطوة 2: جميع عمليات الكتابة أخيراً (Writes Last)
            // ------------------------------------------------------------
            
            // 1. تحديث مستند المتجر الكلي (المنتجات تم تحديثها مسبقاً بالقطعة فلا نعدل مصفوفة الـ Items هنا)
            transaction.update(storeOrderRef, {
                Status: "shipped",                                             // متوافق مع OrderStatus.shipped.name
                DeliveryStatus: "pickedUp",                                    // متوافق مع DeliveryStatus.pickedUp.name
                DeliveryBoyId: deliveryBoyId,                                  // ربط الطلب بالمندوب رسمياً
                pickupDate: admin.firestore.FieldValue.serverTimestamp(),      // توثيق وقت الاستلام
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // (ملاحظة: المنتجات داخل الطلب الرئيسي Orders تم تحديثها تلقائياً بالقطعة في الدالة الأولى، لذا نكتفي هنا بقفل مستند المتجر)

            // 2. توثيق الإشعار بداخل الترانزاكشن للعميل
            const customerUserId = storeOrderData.UserId;
            const storeName = storeOrderData.StoreName || "المتجر";
            const notifTitle = "شحنتك في الطريق 🚚";
            const notifBody = `أكد المندوب استلام كامل طلبك من [${storeName}]، وهو الآن في طريقه إليك.`;

            /*
            logNotificationWithTransaction(transaction, "User", customerUserId, {
                title: notifTitle,
                body: notifBody,
                type: "ORDER_SHIPPED_COMPLETELY",
                mainOrderId: mainOrderId,
                isRead: false,
                isOpened: false,
                isCritical: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });*/

            return {
                success: true,
                userId: customerUserId,
                storeName: storeName,
                notifTitle: notifTitle,
                notifBody: notifBody
            };
        });

        // ------------------------------------------------------------
        // الخطوة 3: إرسال إشعار FCM الفوري للزبون خارج الترانزاكشن
        // ------------------------------------------------------------
       /*
        await sendUnifiedNotification({
            targetType: "User",
            targetId: result.userId,
            title: result.notifTitle,
            body: result.notifBody,
            dataPayload: { type: "ORDER_SHIPPED_COMPLETELY", orderId: mainOrderId },
            isCritical: false,
            skipFirestoreSave: true
        });*/

        return { success: true, message: "تم التحقق من حماية المنتجات ومطابقة الرمز بنجاح." };

    } catch (error) {
        if (error instanceof HttpsError) throw error;
        console.error("CRITICAL ERROR IN FINALIZE PICKUP:", error);
        throw new HttpsError("internal", error.message || "حدث خطأ داخلي في السيرفر.");
    }
});




// 3. الدالة الرئيسية بعد الدمج والتحديث الشامل والمصححة محاسبياً
exports.createNewOrderWithSmartPayment = onCall({ cors: true }, async (request) => {
    const auth = request.auth;
    if (!auth) {
        throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لإتمام العملية.");
    }

    const userId = auth.uid;
    const { 
        orderId, 
        totalAmount, 
        itemsAmount, 
        shippingAmount, 
        useWallet, 
        deliveryCode, 
        senderName, 
        userAddress, 
        items 
    } = request.data;

    if (!orderId || !totalAmount || !items || items.length === 0) {
        throw new HttpsError("invalid-argument", "البيانات المرسلة غير مكتملة لإنشاء الطلب.");
    }

    const cleanAddress = convertStringTimestampsToTimestamp(userAddress);
    const cleanItems = convertStringTimestampsToTimestamp(items);

    const userRef = db.collection("User").doc(userId);
    const orderRef = db.collection("Orders").doc(orderId);

    let notificationTitle = "";
    let notificationBody = "";
    let shoulderSendNotification = false;
    let globalPaymentType = "full_bank";

    try {
        const transactionResult = await db.runTransaction(async (transaction) => {
            const userDoc = await transaction.get(userRef);
            if (!userDoc.exists) {
                throw new HttpsError("not-found", "مستند المستخدم غير معرف في النظام.");
            }

            const currentBalance = Number(userDoc.data().walletBalance || 0);
            const total = Number(totalAmount);

            // تهيئة المتغيرات المالية الأساسية
            let walletPaid = 0;
            let bankRequired = total;
            let finalOrderStatus = "pendingPayment"; 
            let localPaymentType = "full_bank";
            let walletTxStatus = "pending_payment"; 
            let transactionDescription = "";

            // 🔒 التحقق الصارم من تفعيل المحفظة ووجود رصيد حقيقي
            const isWalletEnabled = (useWallet === true || useWallet === "true") && currentBalance > 0;

            if (isWalletEnabled) {
                shoulderSendNotification = true; 

                if (currentBalance >= total) {
                    // ₪ [الحالة الأولى]: دفع كامل من رصيد المحفظة
                    walletPaid = total;
                    bankRequired = 0;
                    finalOrderStatus = "pending"; 
                    localPaymentType = "full_wallet";
                    walletTxStatus = "completed"; 

                    notificationTitle = "🎉 تم تأكيد طلبك بنجاح";
                    notificationBody = `تم خصم مبلغ ₪${walletPaid.toFixed(2)} بالكامل من محفظتك وتفعيل الطلب رقم #${orderId}. جاري التجهيز!`;
                    transactionDescription = `خصم كامل قيمة الطلب رقم #${orderId} من المحفظة`;
                } else {
                    // 🏦 + ₪ [الحالة الثانية]: دفع هجين ومختلط (محفظة + بنك)
                    walletPaid = currentBalance;
                    bankRequired = total - currentBalance;
                    finalOrderStatus = "pendingPayment"; 
                    localPaymentType = "partial_mixed";
                    walletTxStatus = "completed"; // حالة حركة المحفظة المقتطعة تعتبر مكتملة وناجحة
                    notificationTitle = "⚠️ طلبك قيد الانتظار (دفع جزئي)";
                    notificationBody = `تم خصم وحجز ₪${walletPaid.toFixed(2)} من محفظتك. يرجى تحويل المتبقي (₪${bankRequired.toFixed(2)}) بنكياً لتفعيل الطلب رقم #${orderId}.`;
                    transactionDescription = `خصم جزئي من المحفظة للطلب #${orderId} (المتبقي بنكياً: ₪${bankRequired.toFixed(2)})`;
                }

                // تحديث رصيد المحفظة الفعلي للمحتفظ بها في السيرفر فوراً
                transaction.update(userRef, {
                    walletBalance: admin.firestore.FieldValue.increment(-Number(walletPaid.toFixed(2)))
                });

            } else {
                // 🏦 [الحالة الثالثة]: دفع كامل بالتحويل البنكي الصافي (لا يمس المحفظة)
                walletPaid = 0;
                bankRequired = total;
                finalOrderStatus = "pendingPayment";
                localPaymentType = "full_bank";
                shoulderSendNotification = true; 

                notificationTitle = "📄 طلب جديد مسجل";
                notificationBody = `تم تسجيل طلبك رقم #${orderId}، بانتظار تحويل مبلغ ₪${bankRequired.toFixed(2)} بنكياً لتفعيل الطلب.`;
            }

            // تمرير النوع إلى النطاق الخارجي لاستخدامه في أخطاء وعمليات الـ FCM الإشعارية
            globalPaymentType = localPaymentType;

            // 💸 [درع الأمان المحاسبي الجذري]: تسجيل الحركة المالية في المحفظة فقط وفقط إذا تم خصم شيكل واحد أو أكثر
            if (localPaymentType !== "full_bank" && walletPaid > 0) {
                const txRef = userRef.collection("Transactions").doc(orderId);
                transaction.set(txRef, {
                    id: String(orderId),
                    orderId: String(orderId),
                    amount: -Number(walletPaid.toFixed(2)), // القيمة المخصومة فعلياً من المحفظة (سالبة دائمًا)
                    walletPaidAmount: Number(walletPaid.toFixed(2)),
                    bankRequiredAmount: Number(bankRequired.toFixed(2)),
                    type: "purchase",
                    status: walletTxStatus, 
                    description: transactionDescription,
                    senderName: String(senderName || "").trim(),
                    date: admin.firestore.FieldValue.serverTimestamp()
                });
            }

            // 🔔 تسجيل الإشعار في السجلات إذا توفرت بياناته
            if (notificationTitle && notificationBody) {
                logNotificationWithTransaction(transaction, "User", userId, {
                    title: notificationTitle,
                    body: notificationBody,
                    orderId: orderId,
                    type: walletPaid > 0 ? "wallet_payment" : "bank_payment",
                });
            }

            // بناء وحفظ مستند الطلب الرئيسي الشامل (Orders)
            transaction.set(orderRef, {
                Id: String(orderId),
                UserId: userId,
                Status: finalOrderStatus,
                TotalAmount: Number(total.toFixed(2)),
                ItemsAmount: Number(Number(itemsAmount || 0).toFixed(2)),
                ShippingAmount: Number(Number(shippingAmount || 0).toFixed(2)),
                RejectedAmount: 0.0,
                WalletPaidAmount: Number(walletPaid.toFixed(2)),    
                BankRequiredAmount: Number(bankRequired.toFixed(2)),
                PaymentType: localPaymentType,
                DeliveryCode: deliveryCode,
                DeliveryBoyId: null,
                SenderName: String(senderName || "").trim(),
                Address: cleanAddress,
                Items: cleanItems, 
                OrderDate: admin.firestore.FieldValue.serverTimestamp(),
                CreatedAt: admin.firestore.FieldValue.serverTimestamp(),
                DeliveryDate: null
            });

            return {
                success: true,
                status: finalOrderStatus,
                bankRequiredAmount: Number(bankRequired.toFixed(2)),
                paymentType: localPaymentType
            };
        });

        // إرسال الإشعار اللحظي بعد نجاح الـ Transaction بالكامل دون قفل قاعدة البيانات
        if (shoulderSendNotification) {
            await sendFcmNotification(userId, notificationTitle, notificationBody, orderId);
        }

        return transactionResult;
    } catch (error) {
        console.error("CRITICAL MAIN ORDER CREATION ERROR:", error);
        throw new HttpsError("internal", error.message || "فشلت معالجة وإنشاء الطلب الرئيسي على السيرفر.");
    }
});








/*
exports.onStoreOrderUpdated = onDocumentUpdated("StoreOrders/{storeOrderId}", async (event) => {
    const newData = event.data.after.data();
    const previousData = event.data.before.data();
    const storeId = newData.StoreId;
    const userId = newData.UserId;
    const mainOrderId = newData.MainOrderId;
    const newItems = [...(newData.Items || [])];
    const oldItems = previousData.Items || [];
    const statusBefore = previousData.Status;
    const statusAfter = newData.Status;

    try {
        const storeRef = admin.firestore().collection("Stores").doc(storeId);
        const globalRef = getGlobalRef();
        const userRef = admin.firestore().collection('User').doc(userId);
        const userSnap = await userRef.get();
        
        // --- 1. إحصائيات القبول والرفض الكلية ---
        if (statusAfter === "accepted" && statusBefore !== "accepted") {
            await storeRef.set({ acceptedOrders: admin.firestore.FieldValue.increment(1) }, { merge: true });
            await globalRef.set({ acceptedOrders: admin.firestore.FieldValue.increment(1) }, { merge: true });
        } else if (statusAfter === "rejected" && statusBefore !== "rejected") {
            await storeRef.set({ rejectedOrders: admin.firestore.FieldValue.increment(1) }, { merge: true });
            await globalRef.set({ rejectedOrders: admin.firestore.FieldValue.increment(1) }, { merge: true });   
        }

        // --- 2. معالجة رفض المنتجات المالية التقليدية ---
        let totalNetToDeductFromStore = 0;
        let totalGrossToReturnToUser = 0;
        const rejectedItemsToProcess = [];

        const storeDoc = await storeRef.get();
        const commRate = storeDoc.exists ? (storeDoc.data().commissionRate || 2) : 2;

        for (const item of newItems) {
            const oldItem = oldItems.find(o => o.productId === item.productId);
            if (item.itemStatus === "rejected" && (!oldItem || oldItem.itemStatus !== "rejected") && !item.refunded) {
                const itemGross = (parseFloat(item.price) || 0) * (parseInt(item.Quantity) || 1);
                const itemNet = itemGross * (1 - (commRate / 100));
                
                rejectedItemsToProcess.push({ item, itemGross, itemNet });
                totalNetToDeductFromStore += itemNet;
                totalGrossToReturnToUser += itemGross;
                
                item.refunded = true; 
            }
        }

        if (rejectedItemsToProcess.length > 0) {
            await admin.firestore().runTransaction(async (transaction) => {
                transaction.update(userRef, {
                    walletBalance: admin.firestore.FieldValue.increment(totalGrossToReturnToUser)
                });
                transaction.update(storeRef, {
                    "wallet.pendingBalance": admin.firestore.FieldValue.increment(-totalNetToDeductFromStore)
                });
                for (const entry of rejectedItemsToProcess) {
                    const userTransRef = userRef.collection('Transactions').doc();
                    transaction.set(userTransRef, {
                        id: userTransRef.id,
                        amount: entry.itemGross,
                        type: 'refund',
                        status: 'completed',
                        date: admin.firestore.FieldValue.serverTimestamp(),
                        description: `مرتجع: ${entry.item.Title}`,
                        orderId: mainOrderId,
                        storeOrderId: event.params.storeOrderId,
                        productId: entry.item.productId
                    });

                    const storeTransRef = admin.firestore().collection("Transactions").doc();
                    transaction.set(storeTransRef, {
                        storeId: storeId,
                        orderId: event.params.storeOrderId,
                        amount: -entry.itemNet,
                        type: "refund",
                        status: "completed",
                        productId: entry.item.productId,
                        productName: entry.item.Title,
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                    });

                    const adminRefundRef = admin.firestore().collection("RejectedRefunds").doc();
                    transaction.set(adminRefundRef, {
                        refundId: adminRefundRef.id,
                        orderId: mainOrderId,
                        storeOrderId: event.params.storeOrderId,
                        userId: userId,
                        userName: `${userSnap.data()?.firstName} ${userSnap.data()?.lastName}` || "زبون",
                        userPhone: userSnap.data()?.phoneNumber || "",
                        bankAccount: userSnap.data()?.bankAccount || "",
                        bankType: userSnap.data()?.bankType || "",
                        bankAccountName: userSnap.data()?.bankAccountName || "",
                        productId: entry.item.productId,
                        productName: entry.item.Title,
                        amountToRefund: entry.itemGross,
                        status: "pending",
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        storeId: storeId,
                    });
                }

                logNotificationWithTransaction(transaction, "User", userId, {
                    title: "تحديث بخصوص المرتجعات 💰",
                    body:`تم إرجاع ${totalGrossToReturnToUser} شيكل لمحفظتك عن منتجات مرفوضة.`,
                    type: "REJECTION",
                    mainOrderId
                });
            });

            await event.data.after.ref.update({ Items: newItems });

            const fcmToken = userSnap.data()?.fcmToken;
            if (fcmToken) {
                await admin.messaging().send({
                    token: fcmToken,
                    notification: { title: "إرجاع مبلغ", body: "تم إرجاع مبالغ المنتجات غير المتوفرة لمحفظتك." },
                    data: { orderId: mainOrderId, type: "REJECTION" }
                }).catch(e => console.error("FCM Error:", e));
            }
        } 

        // --- 3. مزامنة الطلب الرئيسي وحالة الشحن العامة (تم دمج منطق مرتجع التوصيل الذكي هنا) ---
        if (mainOrderId) {
            const mainOrderRef = admin.firestore().collection("Orders").doc(mainOrderId);
            const mainOrderDoc = await mainOrderRef.get();
            
            if (mainOrderDoc.exists) {
                const mainOrderData = mainOrderDoc.data();
                let mainItems = mainOrderData.Items || [];
                let additionalRefundForMain = 0;
                let hasChanges = false;

                mainItems = mainItems.map(mItem => {
                    const updated = newItems.find(ni => ni.productId === mItem.productId);
                    if (updated && updated.itemStatus !== mItem.itemStatus) {
                        hasChanges = true;
                        if (updated.itemStatus === "rejected" && mItem.itemStatus !== "rejected") {
                            additionalRefundForMain += (parseFloat(mItem.price) || 0) * (parseInt(mItem.Quantity) || 1);
                        }
                        return { ...mItem, itemStatus: updated.itemStatus };
                    }
                    return mItem;
                });

                if (hasChanges) {
                    const updatePayload = { Items: mainItems };
                    
                    // 🌟 [التحديث الذكي]: فحص هل الطلب أصبح خالياً تماماً من أي عناصر قابلة للشحن؟
                    // الشرط يتحقق إذا كانت "كل عناصر الطلب" إما مرفوضة من المتجر أو ملغية من الزبون
                    const isAllOrderItemsDead = mainItems.every(item => 
                    item.itemStatus === "rejected" || item.itemStatus === "cancelled"
                    );
                    const currentShippingAmount = parseFloat(mainOrderData.ShippingAmount) || 0;
                    
                    // إذا ألغي بالكامل وتكلفة التوصيل أكبر من صفر ولم يتم إرجاعها مسبقاً
                    if (isAllOrderItemsDead && currentShippingAmount > 0) {
                        console.log(`🚨 الطلب الكلي رقم ${mainOrderId} تم رفضه بالكامل. جاري رد رسوم التوصيل (₪${currentShippingAmount}) للمستخدم.`);
                        
                        // 1. إضافة قيمة التوصيل للمبلغ المسترد الكلي للعميل
                        additionalRefundForMain += currentShippingAmount;
                        
                        // 2. تصفير حقل الشحن في الطلب الرئيسي لمنع التكرار
                        updatePayload.ShippingAmount = 0;

                        // 3. إجراء معاملة مالية فورية منفصلة لإعادة ثمن الشحن لمحفظة المستخدم بالخلفية
                        await admin.firestore().runTransaction(async (shippingTransaction) => {
                            shippingTransaction.update(userRef, {
                                walletBalance: admin.firestore.FieldValue.increment(currentShippingAmount)
                            });

                            const shippingTransRef = userRef.collection('Transactions').doc();
                            shippingTransaction.set(shippingTransRef, {
                                id: shippingTransRef.id,
                                amount: currentShippingAmount,
                                type: 'refund',
                                status: 'completed',
                                date: admin.firestore.FieldValue.serverTimestamp(),
                                description: `إرجاع رسوم التوصيل (الطلب ملغي/مرفوض بالكامل)`,
                                orderId: mainOrderId,
                                storeOrderId: event.params.storeOrderId
                            });
                        });
                    }

                    if (additionalRefundForMain > 0) {
                        updatePayload.RejectedAmount = admin.firestore.FieldValue.increment(additionalRefundForMain);
                    }
                    
                    await mainOrderRef.update(updatePayload);
                }

                // تحسين منطق المزامنة الذكي للحالة الكلية للطلب الرئيسي
                const allSubOrdersSnapshot = await admin.firestore()
                    .collection("StoreOrders")
                    .where("MainOrderId", "==", mainOrderId)
                    .get();

                const subOrdersDocs = allSubOrdersSnapshot.docs;

                const checkAllStoresMetCondition = (allowedStatuses) => {
                    const normalizedAllowed = allowedStatuses.map(s => s.toLowerCase());
                    return subOrdersDocs.every(doc => normalizedAllowed.includes((doc.data().Status || "").toLowerCase()));
                };

                let newGlobalStatus = null;
                let notifyUser = false;
                let notificationTitle = "";
                let notificationBody = "";
                let notificationType = "";

                if (checkAllStoresMetCondition(["shipped", "rejected"]) && subOrdersDocs.some(d => (d.data().Status || "").toLowerCase() === "shipped")) {
                    newGlobalStatus = "shipped";
                    notifyUser = true;
                    notificationTitle = "طلبك في الطريق! 🚚";
                    notificationBody = "جميع المتاجر سلمت أغراضك وهي الآن مع المندوب للشحن.";
                    notificationType = "ORDER_SHIPPED";
                }
                else if (checkAllStoresMetCondition(["readyForPickup", "shipped", "rejected"])) {
                    newGlobalStatus = "readyForPickup";
                }
                else if (checkAllStoresMetCondition(["delivered", "rejected"]) && subOrdersDocs.some(d => (d.data().Status || "").toLowerCase() === "delivered")) {
                    newGlobalStatus = "delivered";
                    notifyUser = true;
                    notificationTitle = "تم توصيل طلبك بنجاح! 🎉";
                    notificationBody = "سُعدنا بخدمتك، نتمنى أن نكون عند حسن ظنك دائماً.";
                    notificationType = "ORDER_DELIVERED";
                }
                else if (checkAllStoresMetCondition(["rejected"])) {
                    newGlobalStatus = "rejected";
                    notifyUser = true;
                    notificationTitle = "نعتذر منك، تم إلغاء الطلب بالكامل 🛑";
                    notificationBody = "تم إلغاء الطلب بالكامل لعدم توفر العناصر، وتم رد مبالغ المنتجات مع رسوم التوصيل لمحفظتك.";
                    notificationType = "ORDER_REJECTED";
                }
                else if (subOrdersDocs.some(d => (d.data().Status || "").toLowerCase() === "accepted")) {
                    if (mainOrderDoc.data().Status === "pending" || mainOrderDoc.data().Status === "pendingPayment") {
                        newGlobalStatus = "accepted";
                    }
                }

                if (newGlobalStatus && newGlobalStatus !== mainOrderDoc.data().Status) {
                    await mainOrderRef.update({ Status: newGlobalStatus });

                    if (notifyUser) {
                        await logNotification("User", userId, { 
                            title: notificationTitle, 
                            body: notificationBody, 
                            type: notificationType, 
                            mainOrderId 
                        });
                        
                        const freshUserSnap = await userRef.get();
                        if (freshUserSnap.data()?.fcmToken) {
                            await admin.messaging().send({
                                token: freshUserSnap.data().fcmToken,
                                notification: { title: notificationTitle, body: notificationBody },
                                data: { orderId: mainOrderId, type: notificationType }
                            }).catch(e => console.error("FCM Global Sync Error:", e));
                        }
                    }
                }
            }
        }

        // --- 4. إشعار المناديب (Ready for Pickup) ---
        const currentNormalizedStatus = (newData.Status || "").toLowerCase();
        const previousNormalizedStatus = (previousData.Status || "").toLowerCase();

        if (currentNormalizedStatus === "readyforpickup" && previousNormalizedStatus !== "readyforpickup") {
            const driversSnapshot = await admin.firestore().collection("DeliveryDrivers").where("isActive", "==", true).get();
            if (!driversSnapshot.empty) {
                const storeName = storeDoc.data()?.storName || "متجر";
                const nTitle = "طلب جديد جاهز 📦";
                const nBody = `المتجر ${storeName} بانتظار استلام الطلب.`;

                const driverPromises = driversSnapshot.docs.map(doc => {
                    const dToken = doc.data().fcmToken;
                    const p = [logNotification("DeliveryDrivers", doc.id, { title: nTitle, body: nBody, type: "NEW_ORDER_AVAILABLE", orderId: event.params.storeOrderId, storeId })];
                    if (dToken) p.push(admin.messaging().send({ token: dToken, notification: { title: nTitle, body: nBody }, data: { orderId: event.params.storeOrderId, type: "NEW_ORDER_AVAILABLE" , storeId } }));
                    return Promise.all(p);
                });
                await Promise.all(driverPromises);
            }
        }

    } catch (error) {
        console.error("🔥 Error in onStoreOrderUpdated:", error);
    }
});
*/





/*
exports.onStoreOrderUpdated = onDocumentUpdated("StoreOrders/{storeOrderId}", async (event) => {
    const newData = event.data.after.data();
    const previousData = event.data.before.data();
    const storeId = newData.StoreId;
    const userId = newData.UserId;
    const mainOrderId = newData.MainOrderId;
    const newItems = [...(newData.Items || [])];
    const oldItems = previousData.Items || [];
    const statusBefore = previousData.Status;
    const statusAfter = newData.Status;

    try {
        const storeRef = admin.firestore().collection("Stores").doc(storeId);
        const globalRef = getGlobalRef();
        const userRef = admin.firestore().collection('User').doc(userId);
        const userSnap = await userRef.get();
        
        // --- 1. إحصائيات القبول والرفض الكلية ---
        if (statusAfter === "accepted" && statusBefore !== "accepted") {
            await storeRef.set({ acceptedOrders: admin.firestore.FieldValue.increment(1) }, { merge: true });
            await globalRef.set({ acceptedOrders: admin.firestore.FieldValue.increment(1) }, { merge: true });
        } else if (statusAfter === "rejected" && statusBefore !== "rejected") {
            await storeRef.set({ rejectedOrders: admin.firestore.FieldValue.increment(1) }, { merge: true });
            await globalRef.set({ rejectedOrders: admin.firestore.FieldValue.increment(1) }, { merge: true });   
        }

        // --- 2. معالجة رفض المنتجات المالية ---
        let totalNetToDeductFromStore = 0;
        let totalGrossToReturnToUser = 0;
        const rejectedItemsToProcess = [];

        const storeDoc = await storeRef.get();
        const commRate = storeDoc.exists ? (storeDoc.data().commissionRate || 2) : 2;

        for (const item of newItems) {
            const oldItem = oldItems.find(o => o.productId === item.productId);
            if (item.itemStatus === "rejected" && (!oldItem || oldItem.itemStatus !== "rejected") && !item.refunded) {
                const itemGross = (parseFloat(item.price) || 0) * (parseInt(item.Quantity) || 1);
                const itemNet = itemGross * (1 - (commRate / 100));
                
                rejectedItemsToProcess.push({ item, itemGross, itemNet });
                totalNetToDeductFromStore += itemNet;
                totalGrossToReturnToUser += itemGross;
                
                item.refunded = true; 
            }
        }

        if (rejectedItemsToProcess.length > 0) {
            await admin.firestore().runTransaction(async (transaction) => {
                transaction.update(userRef, {
                    walletBalance: admin.firestore.FieldValue.increment(totalGrossToReturnToUser)
                });
                transaction.update(storeRef, {
                    "wallet.pendingBalance": admin.firestore.FieldValue.increment(-totalNetToDeductFromStore)
                });
                for (const entry of rejectedItemsToProcess) {
                    const userTransRef = userRef.collection('Transactions').doc();
                    transaction.set(userTransRef, {
                        id: userTransRef.id,
                        amount: entry.itemGross,
                        type: 'refund',
                        status: 'completed',
                        date: admin.firestore.FieldValue.serverTimestamp(),
                        description: `مرتجع: ${entry.item.Title}`,
                        orderId: mainOrderId,
                        storeOrderId: event.params.storeOrderId,
                        productId: entry.item.productId
                    });

                    const storeTransRef = admin.firestore().collection("Transactions").doc();
                    transaction.set(storeTransRef, {
                        storeId: storeId,
                        orderId: event.params.storeOrderId,
                        amount: -entry.itemNet,
                        type: "refund",
                        status: "completed",
                        productId: entry.item.productId,
                        productName: entry.item.Title,
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                    });

                    const adminRefundRef = admin.firestore().collection("RejectedRefunds").doc();
                    transaction.set(adminRefundRef, {
                        refundId: adminRefundRef.id,
                        orderId: mainOrderId,
                        storeOrderId: event.params.storeOrderId,
                        userId: userId,
                        userName: `${userSnap.data()?.firstName} ${userSnap.data()?.lastName}` || "زبون",
                        userPhone: userSnap.data()?.phoneNumber || "",
                        bankAccount: userSnap.data()?.bankAccount || "",
                        bankType: userSnap.data()?.bankType || "",
                        bankAccountName: userSnap.data()?.bankAccountName || "",
                        productId: entry.item.productId,
                        productName: entry.item.Title,
                        amountToRefund: entry.itemGross,
                        status: "pending",
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        storeId: storeId,
                    });
                }

                logNotificationWithTransaction(transaction, "User", userId, {
                    title: "تحديث بخصوص المرتجعات 💰",
                    body:`تم إرجاع ${totalGrossToReturnToUser} شيكل لمحفظتك عن منتجات مرفوضة.`,
                    type: "REJECTION",
                    mainOrderId
                });
            });

            await event.data.after.ref.update({ Items: newItems });

            const fcmToken = userSnap.data()?.fcmToken;
            if (fcmToken) {
                await admin.messaging().send({
                    token: fcmToken,
                    notification: { title: "إرجاع مبلغ", body: "تم إرجاع مبالغ المنتجات غير المتوفرة لمحفظتك." },
                    data: { orderId: mainOrderId, type: "REJECTION" }
                }).catch(e => console.error("FCM Error:", e));
            }
        } 

        // --- 3. مزامنة الطلب الرئيسي وحالة الشحن العامة ---
        if (mainOrderId) {
            const mainOrderRef = admin.firestore().collection("Orders").doc(mainOrderId);
            const mainOrderDoc = await mainOrderRef.get();
            
            if (mainOrderDoc.exists) {
                let mainItems = mainOrderDoc.data().Items || [];
                let additionalRefundForMain = 0;
                let hasChanges = false;

                mainItems = mainItems.map(mItem => {
                    const updated = newItems.find(ni => ni.productId === mItem.productId);
                    if (updated && updated.itemStatus !== mItem.itemStatus) {
                        hasChanges = true;
                        if (updated.itemStatus === "rejected" && mItem.itemStatus !== "rejected") {
                            additionalRefundForMain += (parseFloat(mItem.price) || 0) * (parseInt(mItem.Quantity) || 1);
                        }
                        return { ...mItem, itemStatus: updated.itemStatus };
                    }
                    return mItem;
                });

                if (hasChanges) {
                    const updatePayload = { Items: mainItems };
                    if (additionalRefundForMain > 0) {
                        updatePayload.RejectedAmount = admin.firestore.FieldValue.increment(additionalRefundForMain);
                    }
                    await mainOrderRef.update(updatePayload);
                }

                // 🌟 تحسين منطق المزامنة الذكي للحالة الكلية للطلب الرئيسي 🌟
                // إزالة شرط المقارنة الضيق ليعمل الفحص دائماً عند حدوث أي تعديل في مستند المتجر
                const allSubOrdersSnapshot = await admin.firestore()
                    .collection("StoreOrders")
                    .where("MainOrderId", "==", mainOrderId)
                    .get();

                const subOrdersDocs = allSubOrdersSnapshot.docs;

                // دالة مساعدة مرنة تفحص الحالات دون حساسية لحجم الحروف البنائية لـ readyForPickup
                const checkAllStoresMetCondition = (allowedStatuses) => {
                    const normalizedAllowed = allowedStatuses.map(s => s.toLowerCase());
                    return subOrdersDocs.every(doc => normalizedAllowed.includes((doc.data().Status || "").toLowerCase()));
                };

                let newGlobalStatus = null;
                let notifyUser = false;
                let notificationTitle = "";
                let notificationBody = "";
                let notificationType = "";

                // 1. حالة الشحن (Shipped): إذا أصبحت كل المتاجر مشحونة أو مرفوضة
                if (checkAllStoresMetCondition(["shipped", "rejected"]) && subOrdersDocs.some(d => (d.data().Status || "").toLowerCase() === "shipped")) {
                    newGlobalStatus = "shipped";
                    notifyUser = true;
                    notificationTitle = "طلبك في الطريق! 🚚";
                    notificationBody = "جميع المتاجر سلمت أغراضك وهي الآن مع المندوب للشحن.";
                    notificationType = "ORDER_SHIPPED";
                }
                // 2. حالة الجاهزية للاستلام (Ready for Pickup)
                else if (checkAllStoresMetCondition(["readyForPickup", "shipped", "rejected"])) {
                    newGlobalStatus = "readyForPickup";
                }
                // 3. حالة التوصيل النهائي (Delivered)
                else if (checkAllStoresMetCondition(["delivered", "rejected"]) && subOrdersDocs.some(d => (d.data().Status || "").toLowerCase() === "delivered")) {
                    newGlobalStatus = "delivered";
                    notifyUser = true;
                    notificationTitle = "تم توصيلطلبك بنجاح! 🎉";
                    notificationBody = "سُعدنا بخدمتك، نتمنى أن نكون عند حسن ظنك دائماً.";
                    notificationType = "ORDER_DELIVERED";
                }
                // 4. حالة الرفض الكلي (Rejected)
                else if (checkAllStoresMetCondition(["rejected"])) {
                    newGlobalStatus = "rejected";
                    notifyUser = true;
                    notificationTitle = "نعتذر منك، تم رفض الطلب 🛑";
                    notificationBody = "تم إلغاء الطلب من قِبل المتاجر لعدم توفر العناصر، وتم رد المبالغ لمحفظتك.";
                    notificationType = "ORDER_REJECTED";
                }
                // 5. حالة قيد التجهيز المفتوحة (accepted / processing)
                else if (subOrdersDocs.some(d => (d.data().Status || "").toLowerCase() === "accepted")) {
                    if (mainOrderDoc.data().Status === "pending" || mainOrderDoc.data().Status === "pendingPayment") {
                        newGlobalStatus = "accepted";
                    }
                }

                // تحديث الحالة الكلية للطلب الرئيسي في قاعدة البيانات فوراً
                if (newGlobalStatus && newGlobalStatus !== mainOrderDoc.data().Status) {
                    await mainOrderRef.update({ Status: newGlobalStatus });

                    if (notifyUser) {
                        await logNotification("User", userId, { 
                            title: notificationTitle, 
                            body: notificationBody, 
                            type: notificationType, 
                            mainOrderId 
                        });
                        
                        const freshUserSnap = await userRef.get();
                        if (freshUserSnap.data()?.fcmToken) {
                            await admin.messaging().send({
                                token: freshUserSnap.data().fcmToken,
                                notification: { title: notificationTitle, body: notificationBody },
                                data: { orderId: mainOrderId, type: notificationType }
                            }).catch(e => console.error("FCM Global Sync Error:", e));
                        }
                    }
                }
            }
        }

        // --- 4. إشعار المناديب (Ready for Pickup) ---
        const currentNormalizedStatus = (newData.Status || "").toLowerCase();
        const previousNormalizedStatus = (previousData.Status || "").toLowerCase();

        if (currentNormalizedStatus === "readyforpickup" && previousNormalizedStatus !== "readyforpickup") {
            const driversSnapshot = await admin.firestore().collection("DeliveryDrivers").where("isActive", "==", true).get();
            if (!driversSnapshot.empty) {
                const storeName = storeDoc.data()?.storName || "متجر";
                const nTitle = "طلب جديد جاهز 📦";
                const nBody = `المتجر ${storeName} بانتظار استلام الطلب.`;

                const driverPromises = driversSnapshot.docs.map(doc => {
                    const dToken = doc.data().fcmToken;
                    const p = [logNotification("DeliveryDrivers", doc.id, { title: nTitle, body: nBody, type: "NEW_ORDER_AVAILABLE", orderId: event.params.storeOrderId, storeId })];
                    if (dToken) p.push(admin.messaging().send({ token: dToken, notification: { title: nTitle, body: nBody }, data: { orderId: event.params.storeOrderId, type: "NEW_ORDER_AVAILABLE" , storeId } }));
                    return Promise.all(p);
                });
                await Promise.all(driverPromises);
            }
        }

    } catch (error) {
        console.error("🔥 Error in onStoreOrderUpdated:", error);
    }
});
*/




/*
exports.onStoreOrderUpdated = onDocumentUpdated("StoreOrders/{storeOrderId}", async (event) => {
    const newData = event.data.after.data();
    const previousData = event.data.before.data();
    const storeId = newData.StoreId;
    const userId = newData.UserId;
    const mainOrderId = newData.MainOrderId;
    const newItems = [...(newData.Items || [])];
    const oldItems = previousData.Items || [];
    const statusBefore = previousData.Status;
    const statusAfter = newData.Status;

    try {
        const storeRef = admin.firestore().collection("Stores").doc(storeId);
        const globalRef = getGlobalRef();
        const userRef = admin.firestore().collection('User').doc(userId);
        const userSnap = await userRef.get();
        // --- 1. إحصائيات القبول والرفض الكلية ---
        if (statusAfter === "accepted" && statusBefore !== "accepted") {
            await storeRef.set({ 
             acceptedOrders: admin.firestore.FieldValue.increment(1) 
            }, { merge: true });

            await globalRef.set({ 
                acceptedOrders: admin.firestore.FieldValue.increment(1) 
            }, { merge: true });
        } else if (statusAfter === "rejected" && statusBefore !== "rejected") {
            await storeRef.set({ 
             rejectedOrders: admin.firestore.FieldValue.increment(1) 
            }, { merge: true });

             await globalRef.set({ 
                rejectedOrders: admin.firestore.FieldValue.increment(1) 
            }, { merge: true });   
        }

        // --- 2. معالجة رفض المنتجات (العملية المالية والذرية) ---
        let totalNetToDeductFromStore = 0;
        let totalGrossToReturnToUser = 0;
        const rejectedItemsToProcess = [];

        // جلب نسبة العموله مرة واحدة
        const storeDoc = await storeRef.get();
        const commRate = storeDoc.exists ? (storeDoc.data().commissionRate || 2) : 2;

        for (const item of newItems) {
            const oldItem = oldItems.find(o => o.productId === item.productId);
            // التحقق الدقيق: الحالة مرفوضة + لم تكن مرفوضة سابقاً + لم يتم إرجاع المبلغ مسبقاً
            if (item.itemStatus === "rejected" && (!oldItem || oldItem.itemStatus !== "rejected") && !item.refunded) {
                const itemGross = (parseFloat(item.price) || 0) * (parseInt(item.Quantity) || 1);
                const itemNet = itemGross * (1 - (commRate / 100));
                
                rejectedItemsToProcess.push({ item, itemGross, itemNet });
                totalNetToDeductFromStore += itemNet;
                totalGrossToReturnToUser += itemGross;
                
                // وسم المنتج داخل المصفوفة لمنع التكرار في الاستدعاءات القادمة
                item.refunded = true; 
            }
        }

        if (rejectedItemsToProcess.length > 0) {
            await admin.firestore().runTransaction(async (transaction) => {
                // أ. تحديث الأرصدة
                transaction.update(userRef, {
                    walletBalance: admin.firestore.FieldValue.increment(totalGrossToReturnToUser)
                });
                transaction.update(storeRef, {
                    "wallet.pendingBalance": admin.firestore.FieldValue.increment(-totalNetToDeductFromStore)
                });
                // ب. تسجيل المعاملات المالية (للزبون وللمتجر)
                for (const entry of rejectedItemsToProcess) {
                    // سجل الزبون
                    const userTransRef = userRef.collection('Transactions').doc();
                    transaction.set(userTransRef, {
                        id: userTransRef.id,
                        amount: entry.itemGross,
                        type: 'refund',
                        status: 'completed',
                        date: admin.firestore.FieldValue.serverTimestamp(),
                        description: `مرتجع: ${entry.item.Title}`,
                        orderId: mainOrderId,
                        storeOrderId: event.params.storeOrderId,
                        productId: entry.item.productId
                    });

                    // سجل المتجر العام
                    const storeTransRef = admin.firestore().collection("Transactions").doc();
                    transaction.set(storeTransRef, {
                        storeId: storeId,
                        orderId: event.params.storeOrderId,
                        amount: -entry.itemNet,
                        type: "refund",
                        status: "completed",
                        productId: entry.item.productId,
                        productName: entry.item.Title,
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                    });

                    // --- الجديد: و. تسجيل مستند في كولكشن rejected_refunds لإدارة الإدارة ---
                    // هذا المستند هو الذي سيظهر في واجهة الإدارة التي صممناها (Admin App)
                    const adminRefundRef = admin.firestore().collection("RejectedRefunds").doc();
                    transaction.set(adminRefundRef, {
                        refundId: adminRefundRef.id,
                        orderId: mainOrderId,
                        storeOrderId: event.params.storeOrderId,
                        userId: userId,
                        userName: `${userSnap.data()?.firstName} ${userSnap.data()?.lastName}` || "زبون",
                        userPhone: userSnap.data()?.phoneNumber || "",
                        bankAccount: userSnap.data()?.bankAccount || "",
                        bankType: userSnap.data()?.bankType || "",
                        bankAccountName: userSnap.data()?.bankAccountName || "",
                        productId: entry.item.productId,
                        productName: entry.item.Title,
                        amountToRefund: entry.itemGross, // المبلغ الكامل الذي يجب أن يتأكد المدير من وصوله للزبون
                        status: "pending", // تبدأ بانتظار تأكيد المدير
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        storeId: storeId,
                    });
                }

                // ج. تخزين إشعار الزبون في الترانزاكشن
                logNotificationWithTransaction(transaction, "User", userId, {
                    title: "تحديث بخصوص المرتجعات 💰",
                    body:`تم إرجاع ${totalGrossToReturnToUser} شيكل لمحفظتك عن منتجات مرفوضة.`,
                    type: "REJECTION",
                    mainOrderId
                });
            });

            // د. تحديث مستند المتجر بكلمة refunded: true لمنع التكرار نهائياً
            await event.data.after.ref.update({ Items: newItems });

            // هـ. إرسال إشعار لحظي FCM
            const fcmToken = userSnap.data()?.fcmToken;
            if (fcmToken) {
                await admin.messaging().send({
                    token: fcmToken,
                    notification: { title: "إرجاع مبلغ", body: "تم إرجاع مبالغ المنتجات غير المتوفرة لمحفظتك." },
                    data: { orderId: mainOrderId, type: "REJECTION" }
                }).catch(e => console.error("FCM Error:", e));
            }
        } 

        // --- 3. مزامنة الطلب الرئيسي وحالة الشحن ---
        if (mainOrderId) {
            const mainOrderRef = admin.firestore().collection("Orders").doc(mainOrderId);
            const mainOrderDoc = await mainOrderRef.get();
            
            if (mainOrderDoc.exists) {
                let mainItems = mainOrderDoc.data().Items || [];
                let additionalRefundForMain = 0;
                let hasChanges = false;

                mainItems = mainItems.map(mItem => {
                    const updated = newItems.find(ni => ni.productId === mItem.productId);
                    if (updated && updated.itemStatus !== mItem.itemStatus) {
                        hasChanges = true;
                        if (updated.itemStatus === "rejected" && mItem.itemStatus !== "rejected") {
                            additionalRefundForMain += (parseFloat(mItem.price) || 0) * (parseInt(mItem.Quantity) || 1);
                        }
                        return { ...mItem, itemStatus: updated.itemStatus };
                    }
                    return mItem;
                });

                if (hasChanges) {
                    const updatePayload = { Items: mainItems };
                    if (additionalRefundForMain > 0) {
                        updatePayload.RejectedAmount = admin.firestore.FieldValue.increment(additionalRefundForMain);
                    }
                    // فحص الحقل الفعلي المستخدم في المستند الرئيسي تجنباً لمشاكل التضارب
                    if (mainOrderDoc.data().Items !== undefined) updatePayload.Items = mainItems;
                    else updatePayload.Items = mainItems;

                    if (additionalRefundForMain > 0) {
                        updatePayload.RejectedAmount = admin.firestore.FieldValue.increment(additionalRefundForMain);
                    }
                    await mainOrderRef.update(updatePayload);
                }

                // --- منطق المزامنة الذكي للحالة الكلية للطلب ---
                if (statusAfter !== statusBefore) {
                    // جلب جميع الطلبات الفرعية المرتبطة بهذا الطلب الكلي لمعرفة حالاتها
                    const allSubOrdersSnapshot = await admin.firestore()
                        .collection("StoreOrders")
                        .where("MainOrderId", "==", mainOrderId)
                        .get();

                    const subOrdersDocs = allSubOrdersSnapshot.docs;

                    // دالة مساعدة لفحص هل جميع المتاجر أنهت أو وصلت للمرحلة المطلوبة
                    const checkAllStoresMetCondition = (allowedStatuses) => {
                        return subOrdersDocs.every(doc => allowedStatuses.includes(doc.data().Status));
                    };

                    let newGlobalStatus = null;
                    let notifyUser = false;
                    let notificationTitle = "";
                    let notificationBody = "";
                    let notificationType = "";

                    // 1. حالة الشحن (Shipped): إذا أصبحت كل المتاجر مشحونة أو مرفوضة
                    if (statusAfter === "shipped" && checkAllStoresMetCondition(["shipped", "rejected"])) {
                        newGlobalStatus = "shipped";
                        notifyUser = true;
                        notificationTitle = "طلبك في الطريق! 🚚";
                        notificationBody = "جميع المتاجر سلمت أغراضك وهي الآن مع المندوب للشحن.";
                        notificationType = "ORDER_SHIPPED";
                    }
                    // 2. حالة الجاهزية للاستلام (Ready for Pickup): إذا أصبحت كل المتاجر جاهزة أو مرفوضة/مشحونة
                    else if (statusAfter === "readyForPickup" && checkAllStoresMetCondition(["readyForPickup", "shipped", "rejected"])) {
                        newGlobalStatus = "readyForPickup";
                    }
                    // 3. حالة التوصيل النهائي (Delivered): إذا تم تسليم كافة الطلبات الفرعية بنجاح للزبون
                    else if (statusAfter === "delivered" && checkAllStoresMetCondition(["delivered", "rejected"])) {
                        newGlobalStatus = "delivered";
                        notifyUser = true;
                        notificationTitle = "تم توصيل طلبك بنجاح! 🎉";
                        notificationBody = "سُعدنا بخدمتك، نتمنى أن نكون عند حسن ظنك دائماً.";
                        notificationType = "ORDER_DELIVERED";
                    }
                    // 4. حالة الرفض الكلي (Rejected): إذا رفضت جميع المتاجر تلبية الطلب
                    else if (statusAfter === "rejected" && checkAllStoresMetCondition(["rejected"])) {
                        newGlobalStatus = "rejected";
                        notifyUser = true;
                        notificationTitle = "نعتذر منك، تم رفض الطلب 🛑";
                        notificationBody = "تم إلغاء الطلب من قِبل المتاجر لعدم توفر العناصر، وتم رد المبالغ لمحفظتك.";
                        notificationType = "ORDER_REJECTED";
                    }
                    // 5. حالة قيد التجهيز (Processing): إذا بدأت المتاجر بالعمل ولم يتم الشحن بعد
                    else if (statusAfter === "accepted" && mainOrderDoc.data().Status === "pending") {
                        // ينتقل الطلب الرئيسي لـ processing بمجرد أن يبدأ أول متجر بتجهيزه
                        newGlobalStatus = "accepted";
                    }

                    // تحديث الحالة الكلية في مستند Orders إذا تحقق أي شرط من الأعلى
                    if (newGlobalStatus) {
                        await mainOrderRef.update({ Status: newGlobalStatus });

                        // إرسال الإشعارات والـ FCM للمستخدم عند حدوث الحالات الأساسية المقترنة بالإشعار
                        if (notifyUser) {
                            await logNotification("User", userId, { 
                                title: notificationTitle, 
                                body: notificationBody, 
                                type: notificationType, 
                                mainOrderId 
                            });
                            
                            const freshUserSnap = await userRef.get();
                            if (freshUserSnap.data()?.fcmToken) {
                                await admin.messaging().send({
                                    token: freshUserSnap.data().fcmToken,
                                    notification: { title: notificationTitle, body: notificationBody },
                                    data: { orderId: mainOrderId, type: notificationType }
                                }).catch(e => console.error("FCM Global Sync Error:", e));
                            }
                        }
                    }
                }
            }
        }

        // --- 4. إشعار المناديب (Ready for Pickup) ---
        if (newData.Status === "readyForPickup" && previousData.Status !== "readyForPickup") {
            const driversSnapshot = await admin.firestore().collection("DeliveryDrivers").where("isActive", "==", true).get();
            if (!driversSnapshot.empty) {
                const storeName = storeDoc.data()?.storName || "متجر";
                const nTitle = "طلب جديد جاهز 📦";
                const nBody = `المتجر ${storeName} بانتظار استلام الطلب.`;

                const driverPromises = driversSnapshot.docs.map(doc => {
                    const dToken = doc.data().fcmToken;
                    const p = [logNotification("DeliveryDrivers", doc.id, { title: nTitle, body: nBody, type: "NEW_ORDER_AVAILABLE", orderId: event.params.storeOrderId, storeId })];
                    if (dToken) p.push(admin.messaging().send({ token: dToken, notification: { title: nTitle, body: nBody }, data: { orderId: event.params.storeOrderId, type: "NEW_ORDER_AVAILABLE" , storeId } }));
                    return Promise.all(p);
                });
                await Promise.all(driverPromises);
            }
        }

    } catch (error) {
        console.error("🔥 Error in onStoreOrderUpdated:", error);
    }
});*/








/*
exports.cancelSpecificItems = onCall({ cors: true, timeoutSeconds: 60 }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لتنفيذ هذه العملية.");
  }

  const userId = request.auth.uid;
  const { orderId, itemsToCancel } = request.data; 

  if (!orderId || !itemsToCancel || !Array.isArray(itemsToCancel)) {
    throw new HttpsError("invalid-argument", "المعطيات المرسلة غير مكتملة أو غير صالحة.");
  }

  const orderRef = db.collection("Orders").doc(orderId);
  const userRef = db.collection("User").doc(userId);

  try {
    const initialOrderDoc = await orderRef.get();
    if (!initialOrderDoc.exists) {
      throw new HttpsError("not-found", "الطلب المحدد غير موجود في سجلات النظام.");
    }

    const initialOrderData = initialOrderDoc.data();
    if (initialOrderData.UserId !== userId) {
      throw new HttpsError("permission-denied", "لا تملك الصلاحية لتعديل أو إلغاء هذا الطلب.");
    }

    const isMainOrderPaid = String(initialOrderData.Status || "").toLowerCase() !== "pendingpayment";
    const initialItems = initialOrderData.Items || [];
    const affectedStoreIds = new Set();
    
    initialItems.forEach(item => {
      const isMatched = itemsToCancel.some(target => 
        String(target.productId).trim() === String(item.productId).trim() && 
        String(target.variationId || "").trim() === String(item.VariationId || "").trim()
      );

      if (isMatched && item.storeId) {
        affectedStoreIds.add(String(item.storeId).trim());
      }
    });

    const storeIdsArray = Array.from(affectedStoreIds);
    const subOrderRefsMap = {}; 

    for (const storeId of storeIdsArray) {
      const subOrderSnapshot = await db.collection("StoreOrders")
        .where("MainOrderId", "==", orderId)
        .where("StoreId", "==", storeId)
        .limit(1)
        .get();

      if (!subOrderSnapshot.empty) {
        subOrderRefsMap[storeId] = subOrderSnapshot.docs[0].ref;
      }
    }

    // متغيرات لتجهيز نصوص الإشعارات وإرسالها خارج الترانزاكشن
    let finalNotificationTitle = "";
    let finalNotificationBody = "";
    let userFcmToken = null;

    const result = await db.runTransaction(async (transaction) => {
      const orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) {
        throw new HttpsError("not-found", "الطلب المحدد غير موجود.");
      }
      const orderData = orderDoc.data();

      const subOrderDocsMap = {};
      for (const storeId of storeIdsArray) {
        const subRef = subOrderRefsMap[storeId];
        if (subRef) {
          const sDoc = await transaction.get(subRef);
          if (sDoc.exists) {
            subOrderDocsMap[storeId] = sDoc;
          }
        }
      }

      const userDoc = await transaction.get(userRef);
      userFcmToken = userDoc.exists ? (userDoc.data().fcmToken || null) : null;

      const storeDocsMap = {};
      for (const storeId of storeIdsArray) {
        const storeRef = db.collection("Stores").doc(storeId);
        const sDoc = await transaction.get(storeRef);
        if (sDoc.exists) {
          storeDocsMap[storeId] = sDoc;
        }
      }

      let items = orderData.Items || [];
      let totalRefundToUser = 0;          
      let totalAmountToDeductFromInvoice = 0; 
      let storesToUpdateBalances = {}; 
      let automaticallyCancelledItems = [];
      let requestedForReviewItems = [];
      let adminReviewRequestsToSet = []; 
      let processedInThisOrder = false;

      for (let item of items) {
        const isTargetToCancel = itemsToCancel.some(target => 
          String(target.productId).trim() === String(item.productId).trim() && 
          String(target.variationId || "").trim() === String(item.VariationId || "").trim()
        );
        
        if (isTargetToCancel) {
          const itemPrice = Number(item.price || 0);
          const itemQuantity = Number(item.Quantity || 1);
          const itemTotal = Number((itemPrice * itemQuantity).toFixed(2)); 
          const currentStatus = String(item.itemStatus || "pending").toLowerCase();

          if (currentStatus === "pending" || currentStatus === "pendingpayment") {
            totalAmountToDeductFromInvoice += itemTotal;

            if (isMainOrderPaid && currentStatus === "pending") {
              totalRefundToUser += itemTotal;
              if (item.storeId) {
                const sIdStr = String(item.storeId).trim();
                storesToUpdateBalances[sIdStr] = (storesToUpdateBalances[sIdStr] || 0) + itemTotal;
              }
            }
            
            item.itemStatus = "cancelled";
            automaticallyCancelledItems.push(`${item.Title || "منتج"}`);
            processedInThisOrder = true;
          } 
          else if (["accepted", "shipped", "delivered", "processing"].includes(currentStatus)) {
            const targetStatus = (currentStatus === "accepted" || currentStatus === "processing") ? "cancellation_requested" : "return_requested";
            
            item.itemStatus = targetStatus;
            requestedForReviewItems.push(`${item.Title || "منتج"}`);

            const reviewRequestRef = db.collection("AdminReviewRequests").doc();
            adminReviewRequestsToSet.push({
              ref: reviewRequestRef,
              data: {
                id: reviewRequestRef.id,
                orderId: orderId,
                userId: userId,
                storeId: item.storeId || "",
                itemId: item.productId,
                variationId: item.VariationId,
                itemName: item.Title || "منتج",
                itemTotalAmount: itemTotal,
                requestType: (currentStatus === "accepted" || currentStatus === "processing") ? "cancel_prepared_item" : "return_shipped_item",
                status: "pending_admin_approval",
                createdAt: admin.firestore.FieldValue.serverTimestamp()
              }
            });
            processedInThisOrder = true;
          } else {
            throw new HttpsError("failed-precondition", `العنصر [${item.Title}] تمت معالجته أو إلغاؤه مسبقاً.`);
          }
        }
      }

      if (!processedInThisOrder) {
        throw new HttpsError("invalid-argument", "لم يتم مطابقة أي عناصر، يرجى التحقق من المدخلات للطلب.");
      }

      adminReviewRequestsToSet.forEach(req => {
        transaction.set(req.ref, req.data);
      });

      for (const storeId of storeIdsArray) {
        const subOrderDoc = subOrderDocsMap[storeId];
        const subOrderRef = subOrderRefsMap[storeId];

        if (subOrderDoc && subOrderRef) {
          const subOrderData = subOrderDoc.data();
          let subOrderItems = subOrderData.Items || [];
          let subOrderDeductionAmount = 0;

          subOrderItems = subOrderItems.map(subItem => {
            const updatedItem = items.find(mainItem => 
              String(mainItem.productId).trim() === String(subItem.productId).trim() && 
              String(mainItem.VariationId || "").trim() === String(subItem.VariationId || "").trim()
            );
            
            if (updatedItem) {
              if (updatedItem.itemStatus === "cancelled" && String(subItem.itemStatus).toLowerCase() !== "cancelled") {
                const price = Number(subItem.price || 0);
                const qty = Number(subItem.Quantity || 1);
                subOrderDeductionAmount += Number((price * qty).toFixed(2));
              }
              subItem.itemStatus = updatedItem.itemStatus;
            }
            return subItem;
          });

          const allSubItemsCancelled = subOrderItems.every(si => String(si.itemStatus).toLowerCase() === "cancelled");
          const newSubTotal = Number(subOrderData.totalAmount || 0) - subOrderDeductionAmount;

          transaction.update(subOrderRef, {
            Items: subOrderItems,
            totalAmount: newSubTotal < 0 ? 0 : Number(newSubTotal.toFixed(2)),
            Status: allSubItemsCancelled ? "cancelled" : (subOrderData.Status || "pending"),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      }

      const shippingFee = Number(orderData.ShippingAmount || 0);
      const allItemsCancelled = items.every(item => String(item.itemStatus).toLowerCase() === "cancelled");
      const hasAnyShippedProduct = items.some(item => {
        const s = String(item.itemStatus).toLowerCase();
        return s === "shipped" || s === "delivered";
      });
      
      if (allItemsCancelled && !hasAnyShippedProduct && isMainOrderPaid) {
        totalRefundToUser += shippingFee;
      }

      // 💳 [المنطق المالي والمحاسبي المحمي]:
      if (isMainOrderPaid) {
        finalNotificationTitle = "🚫 إلغاء منتجات وتعديل مالي";
        finalNotificationBody = `تم إلغاء منتجات من طلبك رقم #${orderId.substring(0, 6)}.`;
        
        // تسجيل الحركة المالية للمحفظة فقط وفقط إذا كان الطلب مدفوعاً وهناك مستردات فعليّة
        if (totalRefundToUser > 0 && userDoc.exists) {
          finalNotificationBody += ` تم استرداد ₪${totalRefundToUser.toFixed(2)} فورياً إلى محفظتك.`;
          
          const currentBal = Number(userDoc.data().walletBalance || 0);
          transaction.update(userRef, { walletBalance: Number((currentBal + totalRefundToUser).toFixed(2)) });

          const userLogRef = userRef.collection("Transactions").doc(`refund_${orderId}_${Date.now()}`);
          transaction.set(userLogRef, {
            id: userLogRef.id,
            orderId: orderId,
            amount: totalRefundToUser, 
            type: "partial_refund",
            title: "استرداد تلقائي لمنتجات ملغاة",
            description: `تم استرداد مبلغ ₪${totalRefundToUser.toFixed(2)} فورياً لمحفظتك عن المنتجات الملغاة في الطلب #${orderId.substring(0, 6)}.`,
            date: admin.firestore.FieldValue.serverTimestamp()
          });

          for (const [storeId, amountToDeduct] of Object.entries(storesToUpdateBalances)) {
            const storeDoc = storeDocsMap[storeId];
            if (storeDoc) {
              const storeData = storeDoc.data() || {};
              const currentPending = Number((storeData.wallet && storeData.wallet.pendingBalance) || 0);
              let newPending = currentPending - amountToDeduct;
              if (newPending < 0) newPending = 0;

              transaction.update(storeDoc.ref, { 'wallet.pendingBalance': Number(newPending.toFixed(2)) });
            }
          }
        }
      } else {
        // الطلب غير مدفوع (pendingPayment): نكتفي بتحديث نصوص الإشعارات للمستخدم دون لمس كوليكشن الـ Transactions نهائياً
        finalNotificationTitle = "📉 تعديل قيمة طلب غير مدفوع";
        finalNotificationBody = `تم إلغاء منتجات من طلبك المعلق #${orderId.substring(0, 6)}. تم تحديث الفاتورة وخصم ₪${totalAmountToDeductFromInvoice.toFixed(2)} من إجمالي المبلغ المطلوب تحويله.`;
      }

      if (requestedForReviewItems.length > 0) {
        finalNotificationBody += ` هناك عناصر (${requestedForReviewItems.length}) أرسلت مراجعة للإدارة للموافقة عليها لأنها قيد التجهيز أو الشحن.`;
      }

      // 🔔 [تسجيل الإشعار التاريخي في قاعدة البيانات] للتوثيق في صندوق وارد التطبيق
      if (finalNotificationTitle && finalNotificationBody) {
        logNotificationWithTransaction(transaction, "User", userId, {
          title: finalNotificationTitle,
          body: finalNotificationBody,
          orderId: orderId,
          type: "order_item_cancelled",
        });
      }

      let currentTotal = Number(orderData.totalAmount || 0);
      let newTotalAmount = currentTotal - totalAmountToDeductFromInvoice;
      if (allItemsCancelled) newTotalAmount = 0;

      let currentWalletPaid = Number(orderData.WalletPaidAmount || 0);
      let newWalletPaid = currentWalletPaid;
      
      if (isMainOrderPaid && totalRefundToUser > 0) {
        newWalletPaid = currentWalletPaid - totalRefundToUser;
        if (newWalletPaid < 0) newWalletPaid = 0;
      }

      let updatePayload = {
        Items: items,
        totalAmount: newTotalAmount < 0 ? 0 : Number(newTotalAmount.toFixed(2)),
        WalletPaidAmount: Number(newWalletPaid.toFixed(2)), 
        Status: allItemsCancelled ? "cancelled" : (orderData.Status || "pending"),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      if (!isMainOrderPaid) {
        let currentBankRequired = Number(orderData.BankRequiredAmount || 0);
        let newBankRequired = currentBankRequired - totalAmountToDeductFromInvoice;
        updatePayload.BankRequiredAmount = newBankRequired < 0 ? 0 : Number(newBankRequired.toFixed(2));
      }

      transaction.update(orderRef, updatePayload);

      return {
        success: true,
        refundedAmount: totalRefundToUser,
        allItemsCancelled: allItemsCancelled,
        automaticallyCancelledItems: automaticallyCancelledItems,
        requestedForReviewItems: requestedForReviewItems
      };
    });

    // ⚡ [إرسال إشعار FCM الفوري على هاتف العميل]
    if (userFcmToken && finalNotificationTitle && finalNotificationBody) {
        await sendFcmNotification(userId, finalNotificationTitle, finalNotificationBody, orderId, "order_status");
    }

    return { status: "success", refundedAmount: result.refundedAmount };

  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error("CRITICAL CANCEL ITEMS SERVER ERROR:", error);
    throw new HttpsError("internal", error.message || "حدث خطأ في السيرفر أثناء معالجة إلغاء العناصر.");
  }
});
*/








/*
exports.cancelSpecificItems = onCall({ cors: true, timeoutSeconds: 60 }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لتنفيذ هذه العملية.");
  }

  const userId = request.auth.uid;
  const { orderId, itemsToCancel } = request.data; 

  if (!orderId || !itemsToCancel || !Array.isArray(itemsToCancel)) {
    throw new HttpsError("invalid-argument", "المعطيات المرسلة غير مكتملة أو غير صالحة.");
  }

  const orderRef = db.collection("Orders").doc(orderId);
  const userRef = db.collection("User").doc(userId);

  try {
    const initialOrderDoc = await orderRef.get();
    if (!initialOrderDoc.exists) {
      throw new HttpsError("not-found", "الطلب المحدد غير موجود في سجلات النظام.");
    }

    const initialOrderData = initialOrderDoc.data();
    if (initialOrderData.UserId !== userId) {
      throw new HttpsError("permission-denied", "لا تملك الصلاحية لتعديل أو إلغاء هذا الطلب.");
    }

    const isMainOrderPaid = String(initialOrderData.Status || "").toLowerCase() !== "pendingpayment";
    const initialItems = initialOrderData.Items || [];
    const affectedStoreIds = new Set();
    
    initialItems.forEach(item => {
      const isMatched = itemsToCancel.some(target => 
        String(target.productId).trim() === String(item.productId).trim() && 
        String(target.variationId || "").trim() === String(item.VariationId || "").trim()
      );

      if (isMatched && item.storeId) {
        affectedStoreIds.add(String(item.storeId).trim());
      }
    });

    const storeIdsArray = Array.from(affectedStoreIds);
    const subOrderRefsMap = {}; 

    for (const storeId of storeIdsArray) {
      const subOrderSnapshot = await db.collection("StoreOrders")
        .where("MainOrderId", "==", orderId)
        .where("StoreId", "==", storeId)
        .limit(1)
        .get();

      if (!subOrderSnapshot.empty) {
        subOrderRefsMap[storeId] = subOrderSnapshot.docs[0].ref;
      }
    }
    

    const result = await db.runTransaction(async (transaction) => {
      const orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) {
        throw new HttpsError("not-found", "الطلب المحدد غير موجود.");
      }
      const orderData = orderDoc.data();

      const subOrderDocsMap = {};
      for (const storeId of storeIdsArray) {
        const subRef = subOrderRefsMap[storeId];
        if (subRef) {
          const sDoc = await transaction.get(subRef);
          if (sDoc.exists) {
            subOrderDocsMap[storeId] = sDoc;
          }
        }
      }

      const userDoc = await transaction.get(userRef);

      const storeDocsMap = {};
      for (const storeId of storeIdsArray) {
        const storeRef = db.collection("Stores").doc(storeId);
        const sDoc = await transaction.get(storeRef);
        if (sDoc.exists) {
          storeDocsMap[storeId] = sDoc;
        }
      }

      let items = orderData.Items || [];
      let totalRefundToUser = 0;          
      let totalAmountToDeductFromInvoice = 0; 
      let storesToUpdateBalances = {}; 
      let automaticallyCancelledItems = [];
      let requestedForReviewItems = [];
      let adminReviewRequestsToSet = []; 
      let processedInThisOrder = false;

      for (let item of items) {
        const isTargetToCancel = itemsToCancel.some(target => 
          String(target.productId).trim() === String(item.productId).trim() && 
          String(target.variationId || "").trim() === String(item.VariationId || "").trim()
        );
        
        if (isTargetToCancel) {
          const itemPrice = Number(item.price || 0);
          const itemQuantity = Number(item.Quantity || 1);
          const itemTotal = Number((itemPrice * itemQuantity).toFixed(2)); 
          const currentStatus = String(item.itemStatus || "pending").toLowerCase();

          if (currentStatus === "pending" || currentStatus === "pendingpayment") {
            totalAmountToDeductFromInvoice += itemTotal;

            if (isMainOrderPaid && currentStatus === "pending") {
              totalRefundToUser += itemTotal;
              if (item.storeId) {
                const sIdStr = String(item.storeId).trim();
                storesToUpdateBalances[sIdStr] = (storesToUpdateBalances[sIdStr] || 0) + itemTotal;
              }
            }
            
            item.itemStatus = "cancelled";
            automaticallyCancelledItems.push(`${item.Title || "منتج"} (${item.VariationId || "بدون تعديل"})`);
            processedInThisOrder = true;
          } 
          else if (["accepted", "shipped", "delivered", "processing"].includes(currentStatus)) {
            const targetStatus = (currentStatus === "accepted" || currentStatus === "processing") ? "cancellation_requested" : "return_requested";
            
            item.itemStatus = targetStatus;
            requestedForReviewItems.push(`${item.Title || "منتج"} (${item.VariationId || "بدون تعديل"})`);

            const reviewRequestRef = db.collection("AdminReviewRequests").doc();
            adminReviewRequestsToSet.push({
              ref: reviewRequestRef,
              data: {
                id: reviewRequestRef.id,
                orderId: orderId,
                userId: userId,
                storeId: item.storeId || "",
                itemId: item.productId,
                variationId: item.VariationId,
                itemName: item.Title || "منتج",
                itemTotalAmount: itemTotal,
                requestType: (currentStatus === "accepted" || currentStatus === "processing") ? "cancel_prepared_item" : "return_shipped_item",
                status: "pending_admin_approval",
                createdAt: admin.firestore.FieldValue.serverTimestamp()
              }
            });
            processedInThisOrder = true;
          } else {
            throw new HttpsError("failed-precondition", `العنصر [${item.Title}] تمت معالجته أو إلغاؤه مسبقاً.`);
          }
        }
      }

      if (!processedInThisOrder) {
        throw new HttpsError("invalid-argument", "لم يتم مطابقة أي عناصر، يرجى التحقق من المدخلات للطلب.");
      }

      adminReviewRequestsToSet.forEach(req => {
        transaction.set(req.ref, req.data);
      });

      for (const storeId of storeIdsArray) {
        const subOrderDoc = subOrderDocsMap[storeId];
        const subOrderRef = subOrderRefsMap[storeId];

        if (subOrderDoc && subOrderRef) {
          const subOrderData = subOrderDoc.data();
          let subOrderItems = subOrderData.Items || [];
          let subOrderDeductionAmount = 0;

          subOrderItems = subOrderItems.map(subItem => {
            const updatedItem = items.find(mainItem => 
              String(mainItem.productId).trim() === String(subItem.productId).trim() && 
              String(mainItem.VariationId || "").trim() === String(subItem.VariationId || "").trim()
            );
            
            if (updatedItem) {
              if (updatedItem.itemStatus === "cancelled" && String(subItem.itemStatus).toLowerCase() !== "cancelled") {
                const price = Number(subItem.price || 0);
                const qty = Number(subItem.Quantity || 1);
                subOrderDeductionAmount += Number((price * qty).toFixed(2));
              }
              subItem.itemStatus = updatedItem.itemStatus;
            }
            return subItem;
          });

          const allSubItemsCancelled = subOrderItems.every(si => String(si.itemStatus).toLowerCase() === "cancelled");
          const newSubTotal = Number(subOrderData.totalAmount || 0) - subOrderDeductionAmount;

          transaction.update(subOrderRef, {
            Items: subOrderItems,
            totalAmount: newSubTotal < 0 ? 0 : Number(newSubTotal.toFixed(2)),
            Status: allSubItemsCancelled ? "cancelled" : (subOrderData.Status || "pending"),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      }

      const shippingFee = Number(orderData.ShippingAmount || 0);
      const allItemsCancelled = items.every(item => String(item.itemStatus).toLowerCase() === "cancelled");
      const hasAnyShippedProduct = items.some(item => {
        const s = String(item.itemStatus).toLowerCase();
        return s === "shipped" || s === "delivered";
      });
      
      if (allItemsCancelled && !hasAnyShippedProduct && isMainOrderPaid) {
        totalRefundToUser += shippingFee;
      }

      if (totalRefundToUser > 0 && isMainOrderPaid && userDoc.exists) {
        const currentBal = Number(userDoc.data().walletBalance || 0);
        transaction.update(userRef, { walletBalance: Number((currentBal + totalRefundToUser).toFixed(2)) });

        const userLogRef = userRef.collection("Transactions").doc();
        transaction.set(userLogRef, {
          id: userLogRef.id,
          orderId: orderId,
          amount: totalRefundToUser, 
          type: "partial_refund",
          title: "استرداد تلقائي لمنتجات ملغاة",
          description: `تم استرداد مبلغ ₪${totalRefundToUser.toFixed(2)} فورياً لمحفظتك عن المنتجات الملغاة في الطلب #${orderId.substring(0, 6)}.`,
          date: admin.firestore.FieldValue.serverTimestamp()
        });

        for (const [storeId, amountToDeduct] of Object.entries(storesToUpdateBalances)) {
          const storeDoc = storeDocsMap[storeId];
          if (storeDoc) {
            const storeData = storeDoc.data() || {};
            const currentPending = Number((storeData.wallet && storeData.wallet.pendingBalance) || 0);
            let newPending = currentPending - amountToDeduct;
            if (newPending < 0) newPending = 0;

            transaction.update(storeDoc.ref, { 'wallet.pendingBalance': Number(newPending.toFixed(2)) });
          }
        }
      }

      let currentTotal = Number(orderData.totalAmount || 0);
      let newTotalAmount = currentTotal - totalAmountToDeductFromInvoice;
      if (allItemsCancelled) newTotalAmount = 0;

      // 💳 [الموازنة الحسابية الذكية]: تعديل المبالغ المدفوعة بالمحفظة والبنك داخل وثيقة الفاتورة الرئيسية
      let currentWalletPaid = Number(orderData.WalletPaidAmount || 0);
      let newWalletPaid = currentWalletPaid;
      
      if (isMainOrderPaid && totalRefundToUser > 0) {
        // إذا كان الطلب مدفوعاً بواسطة المحفظة، نقوم بخفض القيمة المسجلة في الفاتورة بمقدار ما تم إرجاعه للعميل حماية للتقارير المالية للآدمن
        newWalletPaid = currentWalletPaid - totalRefundToUser;
        if (newWalletPaid < 0) newWalletPaid = 0;
      }

      let updatePayload = {
        Items: items,
        totalAmount: newTotalAmount < 0 ? 0 : Number(newTotalAmount.toFixed(2)),
        WalletPaidAmount: Number(newWalletPaid.toFixed(2)), // حماية التقارير والمزامنة
        Status: allItemsCancelled ? "cancelled" : (orderData.Status || "pending"),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      if (!isMainOrderPaid) {
        let currentBankRequired = Number(orderData.BankRequiredAmount || 0);
        let newBankRequired = currentBankRequired - totalAmountToDeductFromInvoice;
        updatePayload.BankRequiredAmount = newBankRequired < 0 ? 0 : Number(newBankRequired.toFixed(2));
      }

      transaction.update(orderRef, updatePayload);

      return {
        success: true,
        refundedAmount: totalRefundToUser,
        allItemsCancelled: allItemsCancelled,
        automaticallyCancelledItems: automaticallyCancelledItems,
        requestedForReviewItems: requestedForReviewItems,
        fcmToken: userDoc.exists ? (userDoc.data().fcmToken || null) : null
      };
    });

    return { status: "success", refundedAmount: result.refundedAmount };

  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error("CRITICAL CANCEL ITEMS SERVER ERROR:", error);
    throw new HttpsError("internal", error.message || "حدث خطأ في السيرفر أثناء معالجة إلغاء العناصر.");
  }
});
*/








/*
exports.cancelSpecificItems = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لتنفيذ هذه العملية.");
  }

  const userId = request.auth.uid;
  const { orderId, itemsToCancel } = request.data; 

  if (!orderId || !itemsToCancel || !Array.isArray(itemsToCancel)) {
    throw new HttpsError("invalid-argument", "المعطيات المرسلة غير مكتملة أو غير صالحة.");
  }

  const db = admin.firestore();
  const orderRef = db.collection("Orders").doc(orderId);
  const userRef = db.collection("User").doc(userId);

  try {
    const initialOrderDoc = await orderRef.get();
    if (!initialOrderDoc.exists) {
      throw new HttpsError("not-found", "الطلب المحدد غير موجود في سجلات النظام.");
    }

    const initialOrderData = initialOrderDoc.data();
    if (initialOrderData.UserId !== userId) {
      throw new HttpsError("permission-denied", "لا تملك الصلاحية لتعديل أو إلغاء هذا الطلب.");
    }

    // فحص هل الطلب الرئيسي مدفوع فعلياً؟ (حماية استباقية صارمة)
    const isMainOrderPaid = String(initialOrderData.Status || "").toLowerCase() !== "pendingpayment";

    const initialItems = initialOrderData.Items || [];
    const affectedStoreIds = new Set();
    
    initialItems.forEach(item => {
      const isMatched = itemsToCancel.some(target => 
        target.productId === item.productId && 
        target.variationId === item.VariationId
      );

      if (isMatched && item.storeId) {
        affectedStoreIds.add(String(item.storeId).trim());
      }
    });

    const storeIdsArray = Array.from(affectedStoreIds);
    const subOrderRefsMap = {}; 

    for (const storeId of storeIdsArray) {
      const subOrderSnapshot = await db.collection("StoreOrders")
        .where("MainOrderId", "==", orderId)
        .where("StoreId", "==", storeId)
        .limit(1)
        .get();

      if (!subOrderSnapshot.empty) {
        subOrderRefsMap[storeId] = subOrderSnapshot.docs[0].ref;
      }
    }

    // بدء الترانزاكشن المحمي محاسبياً
    const result = await db.runTransaction(async (transaction) => {
      const orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) {
        throw new HttpsError("not-found", "الطلب المحدد غير موجود.");
      }
      const orderData = orderDoc.data();

      const subOrderDocsMap = {};
      for (const storeId of storeIdsArray) {
        const subRef = subOrderRefsMap[storeId];
        if (subRef) {
          const sDoc = await transaction.get(subRef);
          if (sDoc.exists) {
            subOrderDocsMap[storeId] = sDoc;
          }
        }
      }

      const userDoc = await transaction.get(userRef);

      const storeDocsMap = {};
      for (const storeId of storeIdsArray) {
        const storeRef = db.collection("Stores").doc(storeId);
        const sDoc = await transaction.get(storeRef);
        if (sDoc.exists) {
          storeDocsMap[storeId] = sDoc;
        }
      }

      let items = orderData.Items || [];
      let totalRefundToUser = 0;          // الأموال التي ستعاد للمحفظة فعلياً
      let totalAmountToDeductFromInvoice = 0; // الأموال التي ستخصم من الفاتورة الإجمالية
      let storesToUpdateBalances = {}; 
      let automaticallyCancelledItems = [];
      let requestedForReviewItems = [];
      let adminReviewRequestsToSet = []; 
      let processedInThisOrder = false;

      for (let item of items) {
        const isTargetToCancel = itemsToCancel.some(target => 
          target.productId === item.productId && 
          target.variationId === item.VariationId
        );
        
        if (isTargetToCancel) {
          const itemPrice = Number(item.price || 0);
          const itemQuantity = Number(item.quantity || 1);
          const itemTotal = itemPrice * itemQuantity; // 🎯 حساب التكلفة الإجمالية بضرب السعر في الكمية
          const currentStatus = String(item.itemStatus || "pending").toLowerCase();

          // المسار الأول: بانتظار التجهيز أو انتظار الدفع
          if (currentStatus === "pending" || currentStatus === "pendingpayment") {
            
            // 🎯 تحديث الفاتورة يتم في الحالتين (لأن العنصر حُذف وتكلفة الطلب الكلية يجب أن تقل)
            totalAmountToDeductFromInvoice += itemTotal;

            // 🌟 القفل المالي: لا يتم رد أي أموال للمحفظة إلا إذا كان الطلب الرئيسي مدفوعاً ومؤكداً مسبقاً
            if (isMainOrderPaid && currentStatus === "pending") {
              totalRefundToUser += itemTotal;
              if (item.storeId) {
                const sIdStr = String(item.storeId).trim();
                storesToUpdateBalances[sIdStr] = (storesToUpdateBalances[sIdStr] || 0) + itemTotal;
              }
            }
            
            item.itemStatus = "cancelled";
            automaticallyCancelledItems.push(`${item.Title || "منتج"} (${item.VariationId || "بدون تعديل"})`);
            processedInThisOrder = true;
          } 
          // المسار الثاني: قيد التحضير أو الشحن (يتطلب موافقة الإدارة)
          else if (["accepted", "shipped", "delivered", "processing"].includes(currentStatus)) {
            const targetStatus = (currentStatus === "accepted" || currentStatus === "processing") ? "cancellation_requested" : "return_requested";
            
            item.itemStatus = targetStatus;
            requestedForReviewItems.push(`${item.Title || "منتج"} (${item.VariationId || "بدون تعديل"})`);

            const reviewRequestRef = db.collection("AdminReviewRequests").doc();
            adminReviewRequestsToSet.push({
              ref: reviewRequestRef,
              data: {
                id: reviewRequestRef.id,
                orderId: orderId,
                userId: userId,
                storeId: item.storeId || "",
                itemId: item.productId,
                variationId: item.VariationId,
                itemName: item.Title || "منتج",
                itemTotalAmount: itemTotal,
                requestType: (currentStatus === "accepted" || currentStatus === "processing") ? "cancel_prepared_item" : "return_shipped_item",
                status: "pending_admin_approval",
                createdAt: admin.firestore.FieldValue.serverTimestamp()
              }
            });
            processedInThisOrder = true;
          } else {
            throw new HttpsError("failed-precondition", `العنصر [${item.Title}] تمت معالجته أو إلغاؤه مسبقاً.`);
          }
        }
      }

      if (!processedInThisOrder) {
        throw new HttpsError("invalid-argument", "لم يتم مطابقة أي عناصر، يرجى التحقق من المدخلات.");
      }

      // حفظ طلبات مراجعة الإدارة
      adminReviewRequestsToSet.forEach(req => {
        transaction.set(req.ref, req.data);
      });

      // 3️⃣ تحديث الطلبات الفرعية (StoreOrders) بالمطابقة الحرفية الصارمة والكميات الحقيقية
      for (const storeId of storeIdsArray) {
        const subOrderDoc = subOrderDocsMap[storeId];
        const subOrderRef = subOrderRefsMap[storeId];

        if (subOrderDoc && subOrderRef) {
          const subOrderData = subOrderDoc.data();
          let subOrderItems = subOrderData.Items || [];
          let subOrderDeductionAmount = 0;

          subOrderItems = subOrderItems.map(subItem => {
            const updatedItem = items.find(mainItem => 
              mainItem.productId === subItem.productId && 
              mainItem.VariationId === subItem.VariationId
            );
            
            if (updatedItem) {
              // إذا تحول إلى ملغي، نخصم سعره * كميته من إجمالي الطلب الفرعي للمتجر
              if (updatedItem.itemStatus === "cancelled" && String(subItem.itemStatus).toLowerCase() !== "cancelled") {
                const price = Number(subItem.price || 0);
                const qty = Number(subItem.quantity || 1);
                subOrderDeductionAmount += (price * qty);
              }
              subItem.itemStatus = updatedItem.itemStatus;
            }
            return subItem;
          });

          const allSubItemsCancelled = subOrderItems.every(si => String(si.itemStatus).toLowerCase() === "cancelled");
          const newSubTotal = Number(subOrderData.totalAmount || 0) - subOrderDeductionAmount;

          transaction.update(subOrderRef, {
            Items: subOrderItems,
            totalAmount: newSubTotal < 0 ? 0 : Number(newSubTotal.toFixed(2)),
            Status: allSubItemsCancelled ? "cancelled" : (subOrderData.Status || "pending"),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      }

      // معالجة مصاريف الشحن الكلية والتحقق من إلغاء كامل الطلب
      const shippingFee = Number(orderData.ShippingAmount || 0);
      const allItemsCancelled = items.every(item => String(item.itemStatus).toLowerCase() === "cancelled");
      const hasAnyShippedProduct = items.some(item => {
        const s = String(item.itemStatus).toLowerCase();
        return s === "shipped" || s === "delivered";
      });
      
      // لا يتم رد تكلفة الشحن للمحفظة إلا إذا كان الطلب الكلي مدفوعاً أصلاً
      if (allItemsCancelled && !hasAnyShippedProduct && isMainOrderPaid) {
        totalRefundToUser += shippingFee;
      }

      // 🌟 تطبيق زيادة رصيد المحفظة الفعلي (فقط إذا كانت قيمة الرد أكبر من صفر والطلب مدفوع)
      if (totalRefundToUser > 0 && isMainOrderPaid && userDoc.exists) {
        const currentBal = Number(userDoc.data().walletBalance || 0);
        transaction.update(userRef, { walletBalance: Number((currentBal + totalRefundToUser).toFixed(2)) });

        const userLogRef = userRef.collection("Transactions").doc();
        transaction.set(userLogRef, {
          id: userLogRef.id,
          orderId: orderId,
          amount: totalRefundToUser, // قيمة موجبة كـ Refund
          type: "partial_refund",
          title: "استرداد تلقائي لمنتجات ملغاة",
          description: `تم استرداد مبلغ ₪${totalRefundToUser.toFixed(2)} فورياً لمحفظتك عن المنتجات الملغاة في الطلب #${orderId.substring(0, 6)}.`,
          date: admin.firestore.FieldValue.serverTimestamp()
        });

        // تحديث الرصيد المعلق (Pending) الخاص بالتجار
        for (const [storeId, amountToDeduct] of Object.entries(storesToUpdateBalances)) {
          const storeDoc = storeDocsMap[storeId];
          if (storeDoc) {
            const storeData = storeDoc.data() || {};
            const currentPending = Number((storeData.wallet && storeData.wallet.pendingBalance) || 0);
            let newPending = currentPending - amountToDeduct;
            if (newPending < 0) newPending = 0;

            transaction.update(storeDoc.ref, { 'wallet.pendingBalance': Number(newPending.toFixed(2)) });
          }
        }
      }

      // 🎯 [تحديث الفاتورة البنكية الذكي]: إذا كان الطلب غير مدفوع (pendingPayment)، نقوم بتحديث الـ BankRequiredAmount أيضاً
      let currentTotal = Number(orderData.totalAmount || 0);
      let newTotalAmount = currentTotal - totalAmountToDeductFromInvoice;
      if (allItemsCancelled) newTotalAmount = 0;

      let updatePayload = {
        Items: items,
        totalAmount: newTotalAmount < 0 ? 0 : Number(newTotalAmount.toFixed(2)),
        Status: allItemsCancelled ? "cancelled" : (orderData.Status || "pending"),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // إذا كان بانتظار الدفع، نعدل القيمة المطلوبة للتحويل البنكي فوراً في الفاتورة لكي يرى العميل السعر الجديد في التطبيق!
      if (!isMainOrderPaid) {
        let currentBankRequired = Number(orderData.BankRequiredAmount || 0);
        let newBankRequired = currentBankRequired - totalAmountToDeductFromInvoice;
        updatePayload.BankRequiredAmount = newBankRequired < 0 ? 0 : Number(newBankRequired.toFixed(2));
      }

      transaction.update(orderRef, updatePayload);

      return {
        success: true,
        refundedAmount: totalRefundToUser,
        allItemsCancelled: allItemsCancelled,
        automaticallyCancelledItems: automaticallyCancelledItems,
        requestedForReviewItems: requestedForReviewItems,
        fcmToken: userDoc.exists ? (userDoc.data().fcmToken || null) : null
      };
    });

    return { status: "success", refundedAmount: result.refundedAmount };

  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", error.message || "حدث خطأ في السيرفر.");
  }
});
*/




/*
exports.cancelSpecificItems = onCall(async (request) => {
  
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لتنفيذ هذه العملية.");
  }

  const userId = request.auth.uid;
  const { orderId, itemsToCancel } = request.data; 
  // المتوقع حرفياً من التطبيق: itemsToCancel: [{ productId: "177...", variationId: "بني" }]

  if (!orderId || !itemsToCancel || !Array.isArray(itemsToCancel)) {
    throw new HttpsError("invalid-argument", "المعطيات المرسلة غير مكتملة أو غير صالحة.");
  }

  const db = admin.firestore();
  const orderRef = db.collection("Orders").doc(orderId);
  const userRef = db.collection("User").doc(userId);

  try {
    const initialOrderDoc = await orderRef.get();
    if (!initialOrderDoc.exists) {
      throw new HttpsError("not-found", "الطلب المحدد غير موجود في سجلات النظام.");
    }

    const initialOrderData = initialOrderDoc.data();
    if (initialOrderData.UserId !== userId) {
      throw new HttpsError("permission-denied", "لا تملك الصلاحية لتعديل أو إلغاء هذا الطلب.");
    }

    const initialItems = initialOrderData.Items || [];
    const affectedStoreIds = new Set();
    
    // 1️⃣ فحص المطابقة الحرفية المباشرة لاستخراج المتاجر المتأثرة
    initialItems.forEach(item => {
      const isMatched = itemsToCancel.some(target => 
        target.productId === item.productId && 
        target.variationId === item.VariationId // مقارنة مباشرة بين الحقلين القادم والمخزن
      );

      if (isMatched && item.storeId) {
        affectedStoreIds.add(String(item.storeId).trim());
      }
    });

    const storeIdsArray = Array.from(affectedStoreIds);
    const subOrderRefsMap = {}; 

    for (const storeId of storeIdsArray) {
      const subOrderSnapshot = await db.collection("StoreOrders")
        .where("MainOrderId", "==", orderId)
        .where("StoreId", "==", storeId)
        .limit(1)
        .get();

      if (!subOrderSnapshot.empty) {
        subOrderRefsMap[storeId] = subOrderSnapshot.docs[0].ref;
      }
    }

    // 2️⃣ بدء الترانزاكشن
    const result = await db.runTransaction(async (transaction) => {
      
      const orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) {
        throw new HttpsError("not-found", "الطلب المحدد غير موجود في سجلات النظام.");
      }
      const orderData = orderDoc.data();

      const subOrderDocsMap = {};
      for (const storeId of storeIdsArray) {
        const subRef = subOrderRefsMap[storeId];
        if (subRef) {
          const sDoc = await transaction.get(subRef);
          if (sDoc.exists) {
            subOrderDocsMap[storeId] = sDoc;
          }
        }
      }

      const userDoc = await transaction.get(userRef);

      const storeDocsMap = {};
      for (const storeId of storeIdsArray) {
        const storeRef = db.collection("Stores").doc(storeId);
        const sDoc = await transaction.get(storeRef);
        if (sDoc.exists) {
          storeDocsMap[storeId] = sDoc;
        }
      }

      // المعالجة والحسابات الكلية
      let items = orderData.Items || [];
      let totalRefundToUser = 0;
      let storesToUpdateBalances = {}; 
      let automaticallyCancelledItems = [];
      let requestedForReviewItems = [];
      let adminReviewRequestsToSet = []; 
      let processedInThisOrder = false;

      for (let item of items) {
        // 2️⃣ فحص المطابقة الحرفية الصارمة داخل السلة الرئيسية
        const isTargetToCancel = itemsToCancel.some(target => 
          target.productId === item.productId && 
          target.variationId === item.VariationId
        );
        
        if (isTargetToCancel) {
          const itemPrice = Number(item.price || 0);
          const itemQuantity = Number(item.quantity || 1);
          const itemTotal = itemPrice * itemQuantity;
          const currentStatus = String(item.itemStatus || "pending").toLowerCase();

          // المسار الأول: بانتظار التجهيز أو انتظار الدفع
          if (currentStatus === "pending" || currentStatus === "pendingpayment") {
            if (currentStatus === "pending") {
              totalRefundToUser += itemTotal;
              if (item.storeId) {
                const sIdStr = String(item.storeId).trim();
                storesToUpdateBalances[sIdStr] = (storesToUpdateBalances[sIdStr] || 0) + itemTotal;
              }
            }
            
            item.itemStatus = "cancelled";
            automaticallyCancelledItems.push(`${item.Title || "منتج"} (${item.VariationId || "بدون تعديل"})`);
            processedInThisOrder = true;
          } 
          // المسار الثاني: قيد التحضير أو الشحن
          else if (["accepted", "shipped", "delivered", "processing"].includes(currentStatus)) {
            const targetStatus = (currentStatus === "accepted" || currentStatus === "processing") ? "cancellation_requested" : "return_requested";
            
            item.itemStatus = targetStatus;
            requestedForReviewItems.push(`${item.Title || "منتج"} (${item.VariationId || "بدون تعديل"})`);

            const reviewRequestRef = db.collection("AdminReviewRequests").doc();
            adminReviewRequestsToSet.push({
              ref: reviewRequestRef,
              data: {
                id: reviewRequestRef.id,
                orderId: orderId,
                userId: userId,
                storeId: item.storeId || "",
                itemId: item.productId,
                variationId: item.VariationId,
                itemName: item.Title || "منتج",
                itemTotalAmount: itemTotal,
                requestType: (currentStatus === "accepted" || currentStatus === "processing") ? "cancel_prepared_item" : "return_shipped_item",
                status: "pending_admin_approval",
                createdAt: admin.firestore.FieldValue.serverTimestamp()
              }
            });
            processedInThisOrder = true;
          } else {
            throw new HttpsError("failed-precondition", `العنصر [${item.Title}] تمت معالجته أو إلغاؤه مسبقاً.`);
          }
        }
      }

      if (!processedInThisOrder) {
        throw new HttpsError("invalid-argument", "لم يتم مطابقة أي عناصر عينية، يرجى التحقق من المدخلات.");
      }

      // تحديث طلبات الإدارة
      adminReviewRequestsToSet.forEach(req => {
        transaction.set(req.ref, req.data);
      });

      // 3️⃣ تحديث الطلبات الفرعية (StoreOrders) بالمطابقة الحرفية المباشرة
      for (const storeId of storeIdsArray) {
        const subOrderDoc = subOrderDocsMap[storeId];
        const subOrderRef = subOrderRefsMap[storeId];

        if (subOrderDoc && subOrderRef) {
          const subOrderData = subOrderDoc.data();
          let subOrderItems = subOrderData.Items || [];
          let subOrderRefundAmount = 0;

          subOrderItems = subOrderItems.map(subItem => {
            // البحث المطابق تماماً حرفياً بدون دالات تغيير نصوص
            const updatedItem = items.find(mainItem => 
              mainItem.productId === subItem.productId && 
              mainItem.VariationId === subItem.VariationId
            );
            
            if (updatedItem) {
              if (updatedItem.itemStatus === "cancelled" && (String(subItem.itemStatus).toLowerCase() === "pending" || String(subItem.itemStatus).toLowerCase() === "pendingpayment")) {
                const price = Number(subItem.price || 0);
                const qty = Number(subItem.quantity || 1);
                subOrderRefundAmount += (price * qty);
              }
              subItem.itemStatus = updatedItem.itemStatus;
            }
            return subItem;
          });

          const allSubItemsCancelled = subOrderItems.every(si => String(si.itemStatus).toLowerCase() === "cancelled");
          const newSubTotal = Number(subOrderData.totalAmount || 0) - subOrderRefundAmount;

          transaction.update(subOrderRef, {
            Items: subOrderItems,
            totalAmount: newSubTotal < 0 ? 0 : newSubTotal,
            Status: allSubItemsCancelled ? "cancelled" : (subOrderData.Status || "pending"),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      }

      // حسابات الشحن الإجمالية ومحفظة المستخدم والتاجر
      const shippingFee = Number(orderData.ShippingAmount || 0);
      const allItemsCancelled = items.every(item => String(item.itemStatus).toLowerCase() === "cancelled");
      const hasAnyShippedProduct = items.some(item => {
        const s = String(item.itemStatus).toLowerCase();
        return s === "shipped" || s === "delivered";
      });
      
      let shippingFeeRefunded = 0;
      const isMainOrderPaid = String(orderData.Status || "").toLowerCase() !== "pendingpayment";

      if (allItemsCancelled && !hasAnyShippedProduct && isMainOrderPaid) {
        totalRefundToUser += shippingFee;
        shippingFeeRefunded = shippingFee;
      }

      if (totalRefundToUser > 0 && userDoc.exists) {
        const currentBal = Number(userDoc.data().walletBalance || 0);
        transaction.update(userRef, { walletBalance: currentBal + totalRefundToUser });

        const userLogRef = db.collection("User").doc(userId).collection("Transactions").doc();
        transaction.set(userLogRef, {
          id: userLogRef.id,
          amount: totalRefundToUser,
          type: "partial_refund",
          title: "استرداد تلقائي لمنتجات معلقة",
          description: `تم استرداد مبلغ المنتجات الملغاة فورياً للطلب #${orderId.substring(0, 6)}.`,
          date: admin.firestore.FieldValue.serverTimestamp()
        });

        for (const [storeId, amountToDeduct] of Object.entries(storesToUpdateBalances)) {
          const storeDoc = storeDocsMap[storeId];
          if (storeDoc) {
            const storeData = storeDoc.data() || {};
            const currentPending = Number((storeData.wallet && storeData.wallet.pendingBalance) || 0);
            let newPending = currentPending - amountToDeduct;
            if (newPending < 0) newPending = 0;

            transaction.update(storeDoc.ref, { 'wallet.pendingBalance': newPending });
          }
        }
      }

      let totalAmountToDeductFromInvoice = 0;
      items.forEach(it => {
        const wasTarget = itemsToCancel.some(t => t.productId === it.productId && t.variationId === it.VariationId);
        if (wasTarget && it.itemStatus === "cancelled") {
          totalAmountToDeductFromInvoice += (Number(it.price || 0) * Number(it.quantity || 1));
        }
      });
      
      if (allItemsCancelled) {
        totalAmountToDeductFromInvoice = Number(orderData.totalAmount || 0);
      }

      const newTotalAmount = Number(orderData.totalAmount || 0) - totalAmountToDeductFromInvoice;
      
      transaction.update(orderRef, {
        Items: items,
        totalAmount: newTotalAmount < 0 ? 0 : newTotalAmount,
        Status: allItemsCancelled ? "cancelled" : (orderData.Status || "pending"),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return {
        success: true,
        refundedAmount: totalRefundToUser,
        allItemsCancelled: allItemsCancelled,
        automaticallyCancelledItems: automaticallyCancelledItems,
        requestedForReviewItems: requestedForReviewItems,
        fcmToken: userDoc.exists ? (userDoc.data().fcmToken || null) : null
      };
    });

    // إرسال الإشعارات (اختياري وبنفس آليتك السابقة)
    return { status: "success", refundedAmount: result.refundedAmount };

  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", error.message || "حدث خطأ في السيرفر.");
  }
});
*/









/*
exports.updateItemStatusInCloud = onCall({
    cors: true,
    timeoutSeconds: 60,
}, async (request) => {
    
    const { auth, data } = request;

    // 1. التحقق من المصادقة الأمنية
    if (!auth) {
        throw new HttpsError("unauthenticated", "عذراً، يجب تسجيل الدخول أولاً لإتمام هذه العملية.");
    }

    const { mainOrderId, productId, variationId, newStatus } = data;

    if (!mainOrderId || !productId || !newStatus) {
        throw new HttpsError("invalid-argument", "المعطيات المرسلة غير مكتملة، يرجى تزويد السيرفر بجميع المعرفات القياسية.");
    }

    // خريطة تسلسل الحالات الرسمية للتاجر
    const statusRank = {
        "pending": 0,
        "accepted": 1,
        "readyforpickup": 2, 
        "shipped": 3,
        "delivered": 4,
        "rejected": -1
    };

    const normalizedNewStatus = newStatus.trim().toLowerCase();

    if (statusRank[normalizedNewStatus] === undefined) {
        throw new HttpsError("invalid-argument", `الحالة المطلوبة (${newStatus}) غير مدعومة في نظام السلة.`);
    }

    const storeId = auth.uid;

    try {
        const storeOrdersRef = db.collection("StoreOrders");
        const querySnapshot = await storeOrdersRef
            .where("StoreId", "==", storeId)
            .where("MainOrderId", "==", String(mainOrderId).trim())
            .limit(1)
            .get();

        if (querySnapshot.empty) {
            throw new HttpsError("not-found", "لم يتم العثور على هذا الطلب في سجلات متجرك، أو انتهت صلاحية الوصول.");
        }

        const targetDocSnap = querySnapshot.docs[0];
        const storeOrderRef = targetDocSnap.ref;
        const mainOrderRef = db.collection("Orders").doc(String(mainOrderId).trim());

        // بدء الترانزاكشن الآمن
        const result = await db.runTransaction(async (transaction) => {
            
            const sDoc = await transaction.get(storeOrderRef);
            if (!sDoc.exists) {
                throw new HttpsError("not-found", "تعذر جلب مستند المتجر المحدث أثناء مراجعة البيانات.");
            }

            const orderData = sDoc.data();
            const items = orderData.Items || [];
            let itemFound = false;
            const updatedItems = [...items];

            for (let i = 0; i < updatedItems.length; i++) {
                const currentItem = updatedItems[i];
                const isProductMatch = currentItem.productId === productId;
                
                const incomingVar = (variationId || "").trim();
                const currentVar = (currentItem.VariationId || "").trim();
                const isVariationMatch = incomingVar === currentVar;

                if (isProductMatch && isVariationMatch) {
                    itemFound = true;
                    const currentStatus = (currentItem.itemStatus || "pending").toLowerCase();

                    // 🛑 [الحماية المشددة ضد إلغاءات العميل]
                    if (currentStatus === "cancelled") {
                        throw new HttpsError(
                            "failed-precondition",
                            `عذراً، قام العميل بإلغاء هذا المنتج من الفاتورة مسبقاً، ولا يمكنك تعديل حالته حالياً.`
                        );
                    }
                    
                    if (currentStatus === "cancellation_requested" || currentStatus === "return_requested") {
                        throw new HttpsError(
                            "failed-precondition",
                            `هذا المنتج قيد المراجعة حالياً من قبل الإدارة بناءً على طلب العميل لاسترجاعه أو إلغائه.`
                        );
                    }

                    // الحماية ضد الحالات النهائية الكلاسيكية
                    if (currentStatus === "rejected" || currentStatus === "delivered") {
                        throw new HttpsError(
                            "failed-precondition",
                            `هذا المنتج مغلق نهائياً في السيرفر على حالة (${currentItem.itemStatus}).`
                        );
                    }

                    const currentIndex = statusRank[currentStatus] ?? 0;
                    const nextIndex = statusRank[normalizedNewStatus] ?? 0;

                    if (normalizedNewStatus !== "rejected" && nextIndex <= currentIndex) {
                        throw new HttpsError(
                            "failed-precondition",
                            `قواعد النظام تمنع التراجع من حالة (${currentItem.itemStatus}) إلى الحالات السابقة.`
                        );
                    }

                    updatedItems[i].itemStatus = newStatus; // حفظ الحالة الجديدة القادمة من تطبيق التاجر
                    break;
                }
            }

            if (!itemFound) {
                throw new HttpsError("not-found", "لم يتم مطابقة معرف المنتج أو الفاريشن مع محتويات الفاتورة الحالية للمتجر.");
            }

            // 🌟 [المنطق المطور لحوسبة الحالة العامة للطلب الفرعي للمتجر]
            let calculatedStoreStatus = orderData.Status || "pending";
            
            // استثناء الـ rejected والـ cancelled تماماً من الحسابات النشطة للتاجر
            const activeItems = updatedItems.filter(item => 
                item.itemStatus !== "rejected" && 
                item.itemStatus !== "cancelled"
            );
            
            if (activeItems.length === 0) {
                // إذا ألغيت أو رُفضت جميع المنتجات، يصبح الطلب الفرعي للمتجر ملغياً/مرفوضاً بالكامل
                const isAllCancelled = updatedItems.every(item => item.itemStatus === "cancelled");
                calculatedStoreStatus = isAllCancelled ? "cancelled" : "rejected";
            } else {
                // فحص الحالات السائدة للمنتجات النشطة المتبقية داخل المتجر
                const allAccepted = activeItems.every(item => item.itemStatus === "accepted");
                const allReady = activeItems.every(item => item.itemStatus === "readyForPickup" || item.itemStatus === "readyforpickup");
                const allShipped = activeItems.every(item => item.itemStatus === "shipped");
                const allDelivered = activeItems.every(item => item.itemStatus === "delivered");

                if (allDelivered) calculatedStoreStatus = "delivered";
                else if (allShipped) calculatedStoreStatus = "shipped";
                else if (allReady) calculatedStoreStatus = "readyForPickup"; 
                else if (allAccepted) calculatedStoreStatus = "accepted";
                else calculatedStoreStatus = "processing"; // حالة مختلطة تعني قيد التجهيز
            }

            // 1. تحديث مستند الطلب الفرعي للمتجر
            transaction.update(storeOrderRef, {
                Items: updatedItems,
                items: updatedItems,
                Status: calculatedStoreStatus,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // 2. 🔥 المزامنة العكسية: تحديث حالة هذا المنتج في الطلب الرئيسي (Orders) لكي يرى العميل تحديثات التاجر فوراً
            const mainOrderDoc = await transaction.get(mainOrderRef);
            if (mainOrderDoc.exists) {
                const mainOrderData = mainOrderDoc.data();
                let mainItems = mainOrderData.Items || mainOrderData.items || [];
                
                mainItems = mainItems.map(mItem => {
                    const isMainProductMatch = mItem.productId === productId;
                    const isMainVarMatch = (mItem.VariationId || "").trim() === (variationId || "").trim();
                    
                    // نقوم بالتحديث فقط إذا تطابق المنتج ولم يكن ملغياً من قبل العميل
                    if (isMainProductMatch && isMainVarMatch && mItem.itemStatus !== "cancelled") {
                        mItem.itemStatus = newStatus;
                    }
                    return mItem;
                });

                transaction.update(mainOrderRef, {
                    Items: mainItems,
                    items: mainItems,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }

            return {
                status: "success",
                message: "تم تحديث حالة المنتج وحالة المتجر والمزامنة مع الفاتورة الرئيسية بنجاح.",
                newStatus: newStatus,
                storeStatus: calculatedStoreStatus
            };
        });

        return result;

    } catch (error) {
        if (error instanceof HttpsError) throw error;
        console.error("CRITICAL SERVER ERROR IN UPDATE ITEM STATUS:", error);
        throw new HttpsError("internal", error.message || "فشل السيرفر في معالجة تحديث الطلب.");
    }
});
*/








/*exports.updateItemStatusInCloud = onCall({
    cors: true,
    timeoutSeconds: 60,
}, async (request) => {
    
    const { auth, data } = request;

    // 1. التحقق من المصادقة الأمنية
    if (!auth) {
        throw new HttpsError("unauthenticated", "عذراً، يجب تسجيل الدخول أولاً لإتمام هذه العملية.");
    }

    const { mainOrderId, productId, variationId, newStatus } = data;

    if (!mainOrderId || !productId || !newStatus) {
        throw new HttpsError("invalid-argument", "المعطيات المرسلة غير مكتملة، يرجى تزويد السيرفر بجميع المعرفات القياسية.");
    }

    // خريطة تسلسل الحالات
    const statusRank = {
        "pending": 0,
        "accepted": 1,
        "readyforpickup": 2, 
        "shipped": 3,
        "delivered": 4,
        "rejected": -1
    };

    const normalizedNewStatus = newStatus.trim().toLowerCase();

    if (statusRank[normalizedNewStatus] === undefined) {
        throw new HttpsError("invalid-argument", `الحالة المطلوبة (${newStatus}) غير مدعومة في نظام السلة.`);
    }

    const storeId = auth.uid;

    try {
        const storeOrdersRef = db.collection("StoreOrders");
        const querySnapshot = await storeOrdersRef
            .where("StoreId", "==", storeId)
            .where("MainOrderId", "==", String(mainOrderId).trim())
            .limit(1)
            .get();

        if (querySnapshot.empty) {
            throw new HttpsError("not-found", "لم يتم العثور على هذا الطلب في سجلات متجرك، أو انتهت صلاحية الوصول.");
        }

        const targetDocSnap = querySnapshot.docs[0];
        const storeOrderRef = targetDocSnap.ref;

        // بدء الترانزاكشن الآمن
        const result = await db.runTransaction(async (transaction) => {
            
            const sDoc = await transaction.get(storeOrderRef);
            if (!sDoc.exists) {
                throw new HttpsError("not-found", "تعذر جلب المستند المحدث أثناء مراجعة البيانات.");
            }

            const orderData = sDoc.data();
            const items = orderData.Items || [];
            let itemFound = false;
            const updatedItems = [...items];

            for (let i = 0; i < updatedItems.length; i++) {
                const currentItem = updatedItems[i];
                const isProductMatch = currentItem.productId === productId;
                
                const incomingVar = (variationId || "").trim();
                const currentVar = (currentItem.VariationId || "").trim();
                const isVariationMatch = incomingVar === currentVar;

                if (isProductMatch && isVariationMatch) {
                    itemFound = true;
                    const currentStatus = (currentItem.itemStatus || "pending").toLowerCase();

                    if (currentStatus === "rejected" || currentStatus === "delivered") {
                        throw new HttpsError(
                            "failed-precondition",
                            `هذا المنتج مغلق نهائياً في السيرفر على حالة (${currentItem.itemStatus}).`
                        );
                    }

                    const currentIndex = statusRank[currentStatus] ?? 0;
                    const nextIndex = statusRank[normalizedNewStatus] ?? 0;

                    if (normalizedNewStatus !== "rejected" && nextIndex <= currentIndex) {
                        throw new HttpsError(
                            "failed-precondition",
                            `قواعد النظام تمنع التراجع من حالة (${currentItem.itemStatus}) إلى الحالات السابقة.`
                        );
                    }

                    updatedItems[i].itemStatus = newStatus; // حفظ الحالة بالتسمية الأصلية القادمة من التطبيق
                    break;
                }
            }

            if (!itemFound) {
                throw new HttpsError("not-found", "لم يتم مطابقة معرف المنتج أو الفاريشن مع محتويات الفاتورة الحالية.");
            }

            // 🌟 [المنطق الجديد]: حوسبة الحالة العامة للطلب الفرعي للمتجر تلقائياً بناءً على عناصر السلة 🌟
            let calculatedStoreStatus = orderData.Status || "pending";
            
            const activeItems = updatedItems.filter(item => item.itemStatus !== "rejected");
            
            if (activeItems.length === 0) {
                // إذا تم رفض جميع المنتجات، يصبح الطلب الفرعي للمتجر مرفوضاً بالكامل
                calculatedStoreStatus = "rejected";
            } else {
                // فحص الحالات السائدة للمنتجات النشطة داخل المتجر
                const allAccepted = activeItems.every(item => item.itemStatus === "accepted");
                const allReady = activeItems.every(item => item.itemStatus === "readyForPickup" || item.itemStatus === "readyforpickup");
                const allShipped = activeItems.every(item => item.itemStatus === "shipped");
                const allDelivered = activeItems.every(item => item.itemStatus === "delivered");

                if (allDelivered) calculatedStoreStatus = "delivered";
                else if (allShipped) calculatedStoreStatus = "shipped";
                else if (allReady) calculatedStoreStatus = "readyForPickup"; 
                else if (allAccepted) calculatedStoreStatus = "accepted";
            }

            // تحديث المستند بالحالة الجديدة للمنتجات + الحالة العامة الجديدة للمتجر
            transaction.update(storeOrderRef, {
                Items: updatedItems,
                Status: calculatedStoreStatus, // مزامنة الحالة العامة للمتجر لتشغيل الـ Trigger بنجاح
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            return {
                status: "success",
                message: "تم تحديث حالة المنتج وحالة المتجر العامة بنجاح.",
                newStatus: newStatus,
                storeStatus: calculatedStoreStatus
            };
        });

        return result;

    } catch (error) {
        if (error instanceof HttpsError) throw error;
        console.error("CRITICAL SERVER ERROR:", error);
        throw new HttpsError("internal", error.message || "فشل السيرفر في معالجة تحديث الطلب.");
    }
});
*/




/*
// 3. الدالة الرئيسية بعد الدمج والتحديث الشامل
exports.createNewOrderWithSmartPayment = onCall({ cors: true }, async (request) => {
    const auth = request.auth;
    if (!auth) {
        throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لإتمام العملية.");
    }

    const userId = auth.uid;
    const { 
        orderId, 
        totalAmount, 
        itemsAmount, 
        shippingAmount, 
        useWallet, 
        deliveryCode, 
        senderName, 
        userAddress, 
        items 
    } = request.data;

    if (!orderId || !totalAmount || !items || items.length === 0) {
        throw new HttpsError("invalid-argument", "البيانات المرسلة غير مكتملة لإنشاء الطلب.");
    }

    const cleanAddress = convertStringTimestampsToTimestamp(userAddress);
    const cleanItems = convertStringTimestampsToTimestamp(items);

    const userRef = db.collection("User").doc(userId);
    const orderRef = db.collection("Orders").doc(orderId);

    let notificationTitle = "";
    let notificationBody = "";
    let shoulderSendNotification = false;
    let paymentType = "full_bank";

    try {
        const transactionResult = await db.runTransaction(async (transaction) => {
            const userDoc = await transaction.get(userRef);
            if (!userDoc.exists) {
                throw new HttpsError("not-found", "مستند المستخدم غير معرف في النظام.");
            }

            const currentBalance = Number(userDoc.data().walletBalance || 0);
            const total = Number(totalAmount);

            let walletPaid = 0;
            let bankRequired = total;
            let finalStatus = "pendingPayment"; 
            paymentType = "full_bank";
            let txStatus = "pending_payment"; 
            let transactionDescription = "";

            // 🔒 تأكيد صارم ومحصن: تحويل قيمة useWallet إلى Boolean حقيقي وفحص وجود رصيد فعلي أكبر من صفر
            const isWalletEnabled = (useWallet === true || useWallet === "true") && currentBalance > 0;

            if (isWalletEnabled) {
                shoulderSendNotification = true; 

                if (currentBalance >= total) {
                    // [الحالة الأولى]: دفع كامل من رصيد المحفظة ₪
                    walletPaid = total;
                    bankRequired = 0;
                    finalStatus = "pending"; 
                    paymentType = "full_wallet";
                    txStatus = "completed"; 

                    notificationTitle = "🎉 تم تأكيد طلبك بنجاح";
                    notificationBody = `تم خصم مبلغ ₪${walletPaid} بالكامل من محفظتك وتفعيل الطلب رقم #${orderId}. جاري التجهيز!`;
                    transactionDescription = `خصم كامل قيمة الطلب رقم #${orderId} من المحفظة`;
                } else {
                    // [الحالة الثانية]: دفع هجين ومختلط (محفظة ₪ + بنك)
                    walletPaid = currentBalance;
                    bankRequired = total - currentBalance;
                    finalStatus = "pendingPayment"; 
                    paymentType = "partial_mixed";
                    txStatus = "completed"; 

                    notificationTitle = "⚠️ طلبك قيد الانتظار (دفع جزئي)";
                    notificationBody = `تم حجز ₪${walletPaid} من محفظتك. يرجى تحويل المتبقي (₪${bankRequired}) بنكياً لتفعيل الطلب رقم #${orderId}.`;
                    transactionDescription = `خصم جزئي للطلب #${orderId} (متبقي شحن بنكي: ₪${bankRequired})`;
                }

                // خصم القيمة المأخوذة من محفظة المستخدم فوراً
                transaction.update(userRef, {
                    walletBalance: admin.firestore.FieldValue.increment(-Number(walletPaid.toFixed(2)))
                });
            } else {
                // 🏦 [الحالة الثالثة]: دفع كامل بالتحويل البنكي الصافي
                walletPaid = 0;
                bankRequired = total;
                finalStatus = "pendingPayment";
                paymentType = "full_bank";
                shoulderSendNotification = true; 
                notificationTitle = "📄 طلب جديد مسجل";
                notificationBody = `تم تسجيل طلبك رقم #${orderId}، بانتظار تحويل مبلغ ₪${bankRequired} بنكياً لتفعيل الطلب.`;
            }

            // 💸 [درع الأمان المحاسبي المطور]: حظر قطعي وصارم لحالة الـ full_bank من دخول السجلات المالية للمحفظة
            if (paymentType !== "full_bank" && walletPaid > 0) {
                const txRef = userRef.collection("Transactions").doc(orderId);
                transaction.set(txRef, {
                    id: orderId,
                    orderId: orderId,
                    amount: -Number(walletPaid.toFixed(2)), // دائمًا سالبة لأنها حركة سحب وشراء من المحفظة
                    walletPaidAmount: Number(walletPaid.toFixed(2)),
                    bankRequiredAmount: Number(bankRequired.toFixed(2)),
                    type: "purchase",
                    status: txStatus, 
                    description: transactionDescription,
                    senderName: String(senderName || "").trim(),
                    date: admin.firestore.FieldValue.serverTimestamp()
                });
            }

            // 🔔 تسجيل الإشعار التاريخي في كوليكشن الإشعارات بشكل مستقل لتوثيق الحالة في صندوق الوارد
            if (notificationTitle && notificationBody) {
                logNotificationWithTransaction(transaction, "User", userId, {
                    title: notificationTitle,
                    body: notificationBody,
                    orderId: orderId,
                    type: walletPaid > 0 ? "wallet_payment" : "bank_payment",
                });
            }

            // بناء وحفظ مستند الطلب الرئيسي الشامل (Orders)
            transaction.set(orderRef, {
                Id: orderId,
                UserId: userId,
                Status: finalStatus,
                TotalAmount: Number(total.toFixed(2)),
                ItemsAmount: Number(Number(itemsAmount || 0).toFixed(2)),
                ShippingAmount: Number(Number(shippingAmount || 0).toFixed(2)),
                RejectedAmount: 0.0,
                WalletPaidAmount:  Number(walletPaid.toFixed(2)),    
                BankRequiredAmount: Number(bankRequired.toFixed(2)),
                PaymentType: paymentType,
                DeliveryCode: deliveryCode,
                DeliveryBoyId: null,
                SenderName: String(senderName || "").trim(),
                Address: cleanAddress,
                Items: cleanItems, 
                OrderDate: admin.firestore.FieldValue.serverTimestamp(),
                CreatedAt: admin.firestore.FieldValue.serverTimestamp(),
                DeliveryDate : null
            });

            return {
                success: true,
                status: finalStatus,
                bankRequiredAmount: bankRequired,
                paymentType: paymentType
            };
        });

        if (shoulderSendNotification) {
            await sendFcmNotification(userId, notificationTitle, notificationBody, orderId);
        }

        return transactionResult;
    } catch (error) {
        console.error("CRITICAL MAIN ORDER CREATION ERROR:", error);
        throw new HttpsError("internal", error.message || "فشلت معالجة وإنشاء الطلب الرئيسي على السيرفر.");
    }
});
*/









/*
exports.createNewOrderWithSmartPayment = onCall({ cors: true }, async (request) => {
    const auth = request.auth;
    if (!auth) {
        throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لإتمام العملية.");
    }

    const userId = auth.uid;
    const { 
        orderId, 
        totalAmount, 
        itemsAmount, 
        shippingAmount, 
        useWallet, 
        deliveryCode, 
        senderName, 
        userAddress, 
        items 
    } = request.data;

    if (!orderId || !totalAmount || !items || items.length === 0) {
        throw new HttpsError("invalid-argument", "البيانات المرسلة غير مكتملة لإنشاء الطلب.");
    }

    // تنظيف البيانات وإعادة تحويل أي تاريخ نصي داخل العنوان أو المنتجات إلى Timestamp حقيقي
    const cleanAddress = convertStringTimestampsToTimestamp(userAddress);
    const cleanItems = convertStringTimestampsToTimestamp(items);

    const userRef = db.collection("User").doc(userId);
    const orderRef = db.collection("Orders").doc(orderId);

    let notificationTitle = "";
    let notificationBody = "";
    let shoulderSendNotification = false;
    let paymentType = "full_bank";

    try {
        const transactionResult = await db.runTransaction(async (transaction) => {
            const userDoc = await transaction.get(userRef);
            if (!userDoc.exists) {
                throw new HttpsError("not-found", "مستند المستخدم غير معرف في النظام.");
            }

            const currentBalance = Number(userDoc.data().walletBalance || 0);
            const total = Number(totalAmount);

            let walletPaid = 0;
            let bankRequired = total;
            let finalStatus = "pendingPayment"; 
            paymentType = "full_bank";
            let txStatus = "pending_payment"; 
            let transactionDescription = "";

            // 🔒 تأكيد صارم ومحصن: تحويل قيمة useWallet إلى Boolean حقيقي وفحص وجود رصيد فعلي أكبر من صفر
            const isWalletEnabled = (useWallet === true || useWallet === "true") && currentBalance > 0;

            if (isWalletEnabled) {
                shoulderSendNotification = true; // سيتم إصدار إشعار مالي لوجود حركة محفظة

                if (currentBalance >= total) {
                    // [الحالة الأولى]: دفع كامل من رصيد المحفظة ₪
                    walletPaid = total;
                    bankRequired = 0;
                    finalStatus = "pending"; 
                    paymentType = "full_wallet";
                    txStatus = "completed"; 

                    notificationTitle = "🎉 تم تأكيد طلبك بنجاح";
                    notificationBody = `تم خصم مبلغ ₪${walletPaid} بالكامل من محفظتك وتفعيل الطلب رقم #${orderId}. جاري التجهيز!`;
                    transactionDescription = `خصم كامل قيمة الطلب رقم #${orderId} من المحفظة`;
                } else {
                    // [الحالة الثانية]: دفع هجين ومختلط (محفظة ₪ + بنك)
                    walletPaid = currentBalance;
                    bankRequired = total - currentBalance;
                    finalStatus = "pendingPayment"; 
                    paymentType = "partial_mixed";
                    txStatus = "completed"; // العملية الفرعية للمحفظة اكتملت (تم الخصم بنجاح)

                    notificationTitle = "⚠️ طلبك قيد الانتظار (دفع جزئي)";
                    notificationBody = `تم حجز ₪${walletPaid} من محفظتك. يرجى تحويل المتبقي (₪${bankRequired}) بنكياً لتفعيل الطلب رقم #${orderId}.`;
                    transactionDescription = `خصم جزئي للطلب #${orderId} (متبقي شحن بنكي: ₪${bankRequired})`;
                }

                // خصم القيمة المأخوذة من محفظة المستخدم فوراً بناءً على الحسابات الدقيقة
                transaction.update(userRef, {
                    walletBalance: admin.firestore.FieldValue.increment(-Number(walletPaid.toFixed(2)))
                });
            } else {
                // 🏦 [الحالة الثالثة]: دفع كامل بالتحويل البنكي الصافي
                walletPaid = 0;
                bankRequired = total;
                finalStatus = "pendingPayment";
                paymentType = "full_bank";
                shoulderSendNotification = true; // تفعيلها لإشعار المستخدم ببيانات التحويل المطلوبة
                
                notificationTitle = "📄 طلب جديد مسجل";
                notificationBody = `تم تسجيل طلبك رقم #${orderId}، بانتظار تحويل مبلغ ₪${bankRequired} بنكياً لتفعيل الطلب.`;
            }

            // 💸 [درع الأمان المحاسبي]: توثيق المعاملة المالية في سجل حركات المحفظة فقط وفقط إذا تم الخصم فعلياً
            if (walletPaid > 0 && paymentType !== "full_bank") {
                const txRef = userRef.collection("Transactions").doc(orderId);
                transaction.set(txRef, {
                    id: orderId,
                    orderId: orderId,
                    amount: -Number(walletPaid.toFixed(2)), // تخزين القيمة السالبة للمبلغ المستقطع من المحفظة بدقة
                    walletPaidAmount: Number(walletPaid.toFixed(2)),
                    bankRequiredAmount: Number(bankRequired.toFixed(2)),
                    type: "purchase",
                    status: txStatus, 
                    description: transactionDescription,
                    senderName: String(senderName || "").trim(),
                    date: admin.firestore.FieldValue.serverTimestamp()
                });
            }

            // 🔔 تسجيل الإشعار التاريخي في كوليكشن الإشعارات بشكل مستقل لتوثيق الحالة في صندوق الوارد للتطبيق
            if (notificationTitle && notificationBody) {
                logNotificationWithTransaction(transaction, "User", userId, {
                    title: notificationTitle,
                    body: notificationBody,
                    orderId: orderId,
                    type: walletPaid > 0 ? "wallet_payment" : "bank_payment",
                });
            }

            // بناء وحفظ مستند الطلب الرئيسي الشامل (Orders) للأرشفة والمتابعة من قبل الإدارة
            transaction.set(orderRef, {
                Id: orderId,
                UserId: userId,
                Status: finalStatus,
                TotalAmount: Number(total.toFixed(2)),
                ItemsAmount: Number(Number(itemsAmount || 0).toFixed(2)),
                ShippingAmount: Number(Number(shippingAmount || 0).toFixed(2)),
                RejectedAmount: 0.0,
                WalletPaidAmount:  Number(walletPaid.toFixed(2)),    
                BankRequiredAmount: Number(bankRequired.toFixed(2)),
                PaymentType: paymentType,
                DeliveryCode: deliveryCode,
                DeliveryBoyId: null,
                SenderName: String(senderName || "").trim(),
                Address: cleanAddress,
                Items: cleanItems, 
                OrderDate: admin.firestore.FieldValue.serverTimestamp(),
                CreatedAt: admin.firestore.FieldValue.serverTimestamp(),
                DeliveryDate : null
            });

            return {
                success: true,
                status: finalStatus,
                bankRequiredAmount: bankRequired,
                paymentType: paymentType
            };
        });

        // خطوة الأمان المالي والاستباقية: نرسل الإشعار الفوري لهاتف العميل بعد نجاح الصفقة التامة
        if (shoulderSendNotification) {
            await sendFcmNotification(userId, notificationTitle, notificationBody, orderId);
        }

        return transactionResult;
    } catch (error) {
        console.error("CRITICAL MAIN ORDER CREATION ERROR:", error);
        throw new HttpsError("internal", error.message || "فشلت معالجة وإنشاء الطلب الرئيسي على السيرفر.");
    }
});
*/







/*
exports.createNewOrderWithSmartPayment = onCall({ cors: true }, async (request) => {
    const auth = request.auth;
    if (!auth) {
        throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لإتمام العملية.");
    }

    const userId = auth.uid;
    const { 
        orderId, 
        totalAmount, 
        itemsAmount, 
        shippingAmount, 
        useWallet, 
        deliveryCode, 
        senderName, 
        userAddress, 
        items 
    } = request.data;

    if (!orderId || !totalAmount || !items || items.length === 0) {
        throw new HttpsError("invalid-argument", "البيانات المرسلة غير مكتملة لإنشاء الطلب.");
    }

    // تنظيف البيانات وإعادة تحويل أي تاريخ نصي داخل العنوان أو المنتجات إلى Timestamp حقيقي
    const cleanAddress = convertStringTimestampsToTimestamp(userAddress);
    const cleanItems = convertStringTimestampsToTimestamp(items);

    const userRef = db.collection("User").doc(userId);
    const orderRef = db.collection("Orders").doc(orderId);

    let notificationTitle = "";
    let notificationBody = "";
    let shoulderSendNotification = false;
    let paymentType = "full_bank";

    try {
        const transactionResult = await db.runTransaction(async (transaction) => {
            const userDoc = await transaction.get(userRef);
            if (!userDoc.exists) {
                throw new HttpsError("not-found", "مستند المستخدم غير معرف في النظام.");
            }

            const currentBalance = Number(userDoc.data().walletBalance || 0);
            const total = Number(totalAmount);

            let walletPaid = 0;
            let bankRequired = total;
            let finalStatus = "pendingPayment"; 
            paymentType = "full_bank";
            let txStatus = "pending_payment"; 
            let transactionDescription = "";

            // منطق الفرز المالي وحسابات خصم الرصيد الذكي
            if (useWallet && currentBalance > 0) {
                shoulderSendNotification = true; // سيتم إصدار إشعار مالي لوجود حركة محفظة

                if (currentBalance >= total) {
                    // [الحالة الأولى]: دفع كامل من رصيد المحفظة ₪
                    walletPaid = total;
                    bankRequired = 0;
                    finalStatus = "pending"; 
                    paymentType = "full_wallet";
                    txStatus = "completed"; 

                    notificationTitle = "🎉 تم تأكيد طلبك بنجاح";
                    notificationBody = `تم خصم مبلغ ₪${walletPaid} بالكامل من محفظتك وتفعيل الطلب رقم #${orderId}. جاري التجهيز!`;
                    transactionDescription = `خصم كامل قيمة الطلب رقم #${orderId} من المحفظة`;
                } else {
                    // [الحالة الثانية]: دفع هجين ومختلط (محفظة ₪ + بنك)
                    walletPaid = currentBalance;
                    bankRequired = total - currentBalance;
                    finalStatus = "pendingPayment"; 
                    paymentType = "partial_mixed";
                    txStatus = "completed"; // العملية الفرعية للمحفظة اكتملت (تم الخصم بنجاح)

                    notificationTitle = "⚠️ طلبك قيد الانتظار (دفع جزئي)";
                    notificationBody = `تم حجز ₪${walletPaid} من محفظتك. يرجى تحويل المتبقي (₪${bankRequired}) بنكياً لتفعيل الطلب رقم #${orderId}.`;
                    transactionDescription = `خصم جزئي للطلب #${orderId} (متبقي شحن بنكي: ₪${bankRequired})`;
                }

                // خصم القيمة المأخوذة من محفظة المستخدم فوراً
                transaction.update(userRef, {
                    walletBalance: admin.firestore.FieldValue.increment(-walletPaid)
                });
            } else {
                // [الحالة الثالثة]: دفع كامل بالتحويل البنكي
                walletPaid = 0;
                bankRequired = total;
                finalStatus = "pendingPayment";
                paymentType = "full_bank";
                shoulderSendNotification = true; // تفعيلها لإشعار المستخدم ببيانات التحويل المطلوبة
                
                notificationTitle = "📄 طلب جديد مسجل";
                notificationBody = `تم تسجيل طلبك رقم #${orderId}، بانتظار تحويل مبلغ ₪${bankRequired} بنكياً لتفعيل الطلب.`;
            }

            // 🌟 [الإصلاح المالي الجذري]: توثيق المعاملة المالية في سجل حركات المحفظة فقط وفقط إذا تأثرت المحفظة
            // 💸 1. توثيق المعاملة المالية في سجل حركات المحفظة (فقط وفقط إذا تأثرت المحفظة)
if (walletPaid > 0) {
    const txRef = userRef.collection("Transactions").doc(orderId);
    transaction.set(txRef, {
        id: orderId,
        orderId: orderId,
        amount: -walletPaid, // خصم قيمة المحفظة المستغلة فقط
        walletPaidAmount: walletPaid,
        bankRequiredAmount: bankRequired,
        type: "purchase",
        status: txStatus, 
        description: transactionDescription,
        senderName: String(senderName || "").trim(),
        date: admin.firestore.FieldValue.serverTimestamp()
    });
}

// 🔔 2. تسجيل الإشعار في كوليكشن الإشعارات (لكل الحالات لتوثيق حالة الطلب في صندوق الوارد)
if (notificationTitle && notificationBody) {
    logNotificationWithTransaction(transaction, "User", userId, {
        title: notificationTitle,
        body: notificationBody,
        orderId: orderId,
        type: walletPaid > 0 ? "wallet_payment" : "bank_payment",
    });
}

            // بناء وحفظ مستند الطلب الرئيسي الشامل (Orders) للأرشفة والمتابعة من قبل الإدارة
            transaction.set(orderRef, {
                Id: orderId,
                UserId: userId,
                Status: finalStatus,
                TotalAmount: Number(total.toFixed(2)),
                ItemsAmount: Number(Number(itemsAmount || 0).toFixed(2)),
                ShippingAmount: Number(Number(shippingAmount || 0).toFixed(2)),
                RejectedAmount: 0.0,
                WalletPaidAmount:  Number(walletPaid.toFixed(2)),    
                BankRequiredAmount: Number(bankRequired.toFixed(2)),
                PaymentType: paymentType,
                DeliveryCode: deliveryCode,
                DeliveryBoyId: null,
                SenderName: String(senderName || "").trim(),
                Address: cleanAddress,
                Items: cleanItems, 
                OrderDate: admin.firestore.FieldValue.serverTimestamp(),
                CreatedAt: admin.firestore.FieldValue.serverTimestamp(),
                DeliveryDate : null
            });

            return {
                success: true,
                status: finalStatus,
                bankRequiredAmount: bankRequired,
                paymentType: paymentType
            };
        });

        // خطوة الأمان المالي الاستباقية: نرسل الإشعار الفوري لهاتف العميل بعد نجاح الصفقة التامة
        if (shoulderSendNotification) {
            await sendFcmNotification(userId, notificationTitle, notificationBody, orderId);
        }

        return transactionResult;
    } catch (error) {
        console.error("CRITICAL MAIN ORDER CREATION ERROR:", error);
        throw new HttpsError("internal", error.message || "فشلت معالجة وإنشاء الطلب الرئيسي على السيرفر.");
    }
});
*/






/*
exports.createNewOrderWithSmartPayment = onCall({ cors: true }, async (request) => {
    const auth = request.auth;
    if (!auth) {
        throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لإتمام العملية.");
    }

    const userId = auth.uid;
    const { 
        orderId, 
        totalAmount, 
        itemsAmount, 
        shippingAmount, 
        useWallet, 
        deliveryCode, 
        senderName, 
        userAddress, 
        items 
    } = request.data;

    if (!orderId || !totalAmount || !items || items.length === 0) {
        throw new HttpsError("invalid-argument", "البيانات المرسلة غير مكتملة لإنشاء الطلب.");
    }

    // 🎯 السحر هنا: تنظيف البيانات وإعادة تحويل أي تاريخ نصي داخل العنوان أو المنتجات إلى Timestamp حقيقي
    const cleanAddress = convertStringTimestampsToTimestamp(userAddress);
    const cleanItems = convertStringTimestampsToTimestamp(items);

    const userRef = db.collection("User").doc(userId);
    const orderRef = db.collection("Orders").doc(orderId);

    // متغيرات خارج الترانزاكشن للاحتفاظ بنص الإشعار لإرساله عبر الـ FCM لاحقاً عند نجاح الحفظ
    let notificationTitle = "";
    let notificationBody = "";
    let shoulderSendNotification = false;
    let paymentType = "full_bank";

    try {
        const transactionResult = await db.runTransaction(async (transaction) => {
            const userDoc = await transaction.get(userRef);
            if (!userDoc.exists) {
                throw new HttpsError("not-found", "مستند المستخدم غير معرف في النظام.");
            }

            const currentBalance = Number(userDoc.data().walletBalance || 0);
            const total = Number(totalAmount);

            let walletPaid = 0;
            let bankRequired = total;
            let finalStatus = "pendingPayment"; 
            paymentType = "full_bank";
            let txStatus = "pending_payment"; 

            // منطق الفرز المالي وحسابات خصم الرصيد
            if (useWallet && currentBalance > 0) {
                shoulderSendNotification = true; // سيتم إصدار إشعار مالي لوجود حركة محفظة

                if (currentBalance >= total) {
                    // [الحالة الأولى]: دفع كامل من رصيد المحفظة ₪
                    walletPaid = total;
                    bankRequired = 0;
                    finalStatus = "pending"; 
                    paymentType = "full_wallet";
                    txStatus = "completed"; 

                    notificationTitle = "🎉 تم تأكيد طلبك بنجاح";
                    notificationBody = `تم خصم مبلغ ₪${walletPaid} بالكامل من محفظتك وتفعيل الطلب رقم #${orderId}. جاري التجهيز!`;
                } else {
                    // [الحالة الثانية]: دفع هجين ومختلط (محفظة ₪ + بنك)
                    walletPaid = currentBalance;
                    bankRequired = total - currentBalance;
                    finalStatus = "pendingPayment"; 
                    paymentType = "partial_mixed";
                    txStatus = "pending_payment"; 

                    notificationTitle = "⚠️ طلبك قيد الانتظار (دفع جزئي)";
                    notificationBody = `تم حجز ₪${walletPaid} من محفظتك. يرجى تحويل المتبقي (₪${bankRequired}) بنكياً لتفعيل الطلب رقم #${orderId}.`;
                }

                // خصم القيمة المأخوذة من محفظة المستخدم فوراً
                transaction.update(userRef, {
                    walletBalance: admin.firestore.FieldValue.increment(-walletPaid)
                });
            } else {
                // [الحالة الثالثة]: دفع كامل بالتحويل البنكي
                walletPaid = 0;
                bankRequired = total;
                finalStatus = "pendingPayment";
                paymentType = "full_bank";
                shoulderSendNotification = false; // لا توجد حركة محفظة، كود الفواتير التقليدي يتعامل معها أو يمكنك تفعيلها كالتالي:
                
                notificationTitle = "📄 طلب جديد مسجل";
                notificationBody = `تم تسجيل طلبك رقم #${orderId}، بانتظار تحويل مبلغ ₪${bankRequired} بنكياً لتفعيل الطلب.`;
            }

            // توثيق المعاملة المالية في سجل حركات المحفظة
            if (useWallet && walletPaid > 0) {
                const txRef = userRef.collection("Transactions").doc(orderId);
                transaction.set(txRef, {
                    id: orderId,
                    orderId: orderId,
                    amount: total, 
                    walletPaidAmount: walletPaid,
                    bankRequiredAmount: bankRequired,
                    type: "purchase",
                    status: txStatus, 
                    description: notificationBody,
                    senderName: String(senderName || "").trim(),
                    date: admin.firestore.FieldValue.serverTimestamp()
                });

                // 🔔 استدعاء الدالة المساعدة المخصصة لتسجيل الإشعار في كوليكشن المطور (Notifications) داخل الـ Transaction
                logNotificationWithTransaction(transaction, "User", userId, {
                    title: notificationTitle,
                    body: notificationBody,
                    orderId: orderId,
                    type: "wallet_payment",
                });
            }

            // بناء وحفظ مستند الطلب الرئيسي (Orders)
            transaction.set(orderRef, {
                Id: orderId,
                UserId: userId,
                Status: finalStatus,
                TotalAmount: Number(total.toFixed(2)),
                ItemsAmount: Number(itemsAmount.toFixed(2) || 0),
                ShippingAmount: Number(shippingAmount.toFixed(2) || 0),
                RejectedAmount: 0.0,
                WalletPaidAmount:  Number(walletPaid.toFixed(2)),    
                BankRequiredAmount: Number(bankRequired.toFixed(2)),
                PaymentType: paymentType,
                DeliveryCode: deliveryCode,
                DeliveryBoyId: null,
                SenderName: String(senderName || "").trim(),
                Address: cleanAddress,
                Items: cleanItems, 
                OrderDate: admin.firestore.FieldValue.serverTimestamp(),
                CreatedAt: admin.firestore.FieldValue.serverTimestamp(),
                DeliveryDate : null
            });

            return {
                success: true,
                status: finalStatus,
                bankRequiredAmount: bankRequired,
                paymentType: paymentType
            };
        });

        // 6. خطوة الأمان المالي الاستباقية: نرسل الإشعار عبر الـ FCM بعد إتمام الترانزاكشن بنجاح (خارج الـ Transaction Block)
        // هذا يمنع تعليق قاعدة البيانات ويضمن وصول الإشعار فقط إذا حُفظت الأموال فعلياً
        if (shoulderSendNotification || paymentType === "full_bank") {
            await sendFcmNotification(userId, notificationTitle, notificationBody, orderId);
        }

        return transactionResult;
    } catch (error) {
        console.error("CRITICAL MAIN ORDER CREATION ERROR:", error);
        throw new HttpsError("internal", error.message || "فشلت معالجة وإنشاء الطلب الرئيسي على السيرفر.");
    }
});
*/




/*
exports.createNewOrderWithSmartPayment = onCall({ cors: true }, async (request) => {
    // 1. التحقق الأمني من هوية المستخدم المسجل
    const auth = request.auth;
    if (!auth) {
        throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لإتمام العملية.");
    }

    const userId = auth.uid;
    const { 
        orderId, 
        totalAmount, 
        itemsAmount, 
        shippingAmount, 
        useWallet, 
        deliveryCode, 
        senderName, 
        userAddress, 
        items 
    } = request.data;

    // التحقق من المدخلات الأساسية قبل فتح المعاملة
    if (!orderId || !totalAmount || !items || items.length === 0) {
        throw new HttpsError("invalid-argument", "البيانات المرسلة غير مكتملة لإنشاء الطلب.");
    }

    const userRef = db.collection("User").doc(userId);
    const orderRef = db.collection("Orders").doc(orderId);

    try {
        // 2. تشغيل الترانزاكشن لضمان حماية الرصيد ومنع الإنفاق المزدوج
        const transactionResult = await db.runTransaction(async (transaction) => {
            
            // جلب مستند المستخدم الحالي للتأكد من رصيد محفظته الحقيقي من السيرفر
            const userDoc = await transaction.get(userRef);
            if (!userDoc.exists) {
                throw new HttpsError("not-found", "مستند المستخدم غير معرف في النظام.");
            }

            const currentBalance = Number(userDoc.data().walletBalance || 0);
            const total = Number(totalAmount);

            let walletPaid = 0;
            let bankRequired = total;
            let finalStatus = "pendingPayment"; // الحالة الافتراضية بانتظار إشعار البنك
            let paymentType = "full_bank";

            // 3. منطق الفرز المالي وحسابات خصم الرصيد
            if (useWallet && currentBalance > 0) {
                if (currentBalance >= total) {
                    // [الحالة الأولى]: دفع كامل من رصيد المحفظة
                    walletPaid = total;
                    bankRequired = 0;
                    finalStatus = "pending"; // مفعّل فوراً (لا ينتظر البنك)
                    paymentType = "full_wallet";
                } else {
                    // [الحالة الثانية]: دفع هجين ومختلط (محفظة + متبقي للبنك)
                    walletPaid = currentBalance;
                    bankRequired = total - currentBalance;
                    finalStatus = "pendingPayment"; // معلق ماليًا بانتظار تحويل الباقي
                    paymentType = "partial_mixed";
                }

                // خصم القيمة المأخوذة من محفظة المستخدم فوراً داخل الترانزاكشن
                transaction.update(userRef, {
                    walletBalance: admin.firestore.FieldValue.increment(-walletPaid)
                });

                // توثيق حركة الخصم المالي في سجل حركات محفظة هذا العميل
                const txRef = userRef.collection("Transactions").doc(orderId);
                transaction.set(txRef, {
                    id: txRef.id,
                    amount: walletPaid,
                    type: "purchase",
                    description: `خصم مبلغ ₪${walletPaid} مقابل تثبيت الطلب الرئيسي رقم #${orderId}`,
                    date: admin.firestore.FieldValue.serverTimestamp()
                });
            } else {
                // [الحالة الثالثة]: دفع كامل بالتحويل البنكي
                walletPaid = 0;
                bankRequired = total;
                finalStatus = "pendingPayment";
                paymentType = "full_bank";
            }

            // 4. بناء وحفظ مستند الطلب الرئيسي (Orders) فقط بالتسميات الحرفية لمشروعك
            transaction.set(orderRef, {
                Id: orderId,
                UserId: userId,
                Status: finalStatus,
                TotalAmount: total,
                ItemsAmount: Number(itemsAmount || 0),
                ShippingAmount: Number(shippingAmount || 0),
                RejectedAmount: 0.0,
                WalletPaidAmount: walletPaid,     // توثيق المبلغ المخصوم من المحفظة
                BankRequiredAmount: bankRequired, // توثيق المبلغ المتبقي والمطلوب من البنك
                PaymentType: paymentType,
                DeliveryCode: deliveryCode,
                DeliveryBoyId: null,
                SenderName: String(senderName || "").trim(),
                Address: userAddress,
                Items: items, // مصفوفة المنتجات الكاملة في الطلب الرئيسي
                OrderDate: admin.firestore.FieldValue.serverTimestamp(),
                CreatedAt: admin.firestore.FieldValue.serverTimestamp(),
                DeliveryDate : null
            });

            // إرجاع النتيجة للتطبيق ليتعامل مع الـ UI بناءً على الموقف المالي للطلب
            return {
                success: true,
                status: finalStatus,
                bankRequiredAmount: bankRequired,
                paymentType: paymentType
            };
        });
        // 3️⃣ إرجاع نتيجة الـ Transaction النهائية لتصل بشكل سليم إلى كود الفلاتر وعرض شاشة النجاح
        return transactionResult;
    } catch (error) {
        console.error("CRITICAL MAIN ORDER CREATION ERROR:", error);
        throw new HttpsError("internal", error.message || "فشلت معالجة وإنشاء الطلب الرئيسي على السيرفر.");
    }
});
*/



/*
exports.updateItemStatusInCloud = onCall({
    cors: true,
    timeoutSeconds: 60,
}, async (request) => {
    
    const { auth, data } = request;

    // 1. التحقق من المصادقة الأمنية
    if (!auth) {
        throw new HttpsError("unauthenticated", "عذراً، يجب تسجيل الدخول أولاً لإتمام هذه العملية.");
    }

    const { mainOrderId, productId, variationId, newStatus } = data;

    // التحقق من اكتمال المدخلات الأساسية القادمة من التطبيق
    if (!mainOrderId || !productId || !newStatus) {
        throw new HttpsError("invalid-argument", "المعطيات المرسلة غير مكتملة، يرجى تزويد السيرفر بجميع المعرفات القياسية.");
    }

    // خريطة تسلسل الحالات (دعم الحروف الكبيرة والصغيرة لضمان عدم حدوث خطأ)
    const statusRank = {
        "pending": 0,
        "accepted": 1,
        "readyforpickup": 2,
        "readyforpickup": 2, // دعم الحالتين تلقائياً
        "shipped": 3,
        "delivered": 4,
        "rejected": -1
    };

    // تحويل الحالة القادمة لحروف صغيرة لتفادي أخطاء السيرفر عند المقارنة
    const normalizedNewStatus = newStatus.trim().toLowerCase();

    if (statusRank[normalizedNewStatus] === undefined) {
        throw new HttpsError("invalid-argument", `الحالة المطلوبة (${newStatus}) غير مدعومة في نظام السلة.`);
    }

    const storeId = auth.uid;

    try {
        // جلب مستند المتجر اعتماداً على البنية الحرفية في داتابيز Firestore لديك
        const storeOrdersRef = db.collection("StoreOrders");
        const querySnapshot = await storeOrdersRef
            .where("StoreId", "==", storeId)
            .where("MainOrderId", "==", String(mainOrderId).trim()) // مطابقة حقل المستند حرفياً
            .limit(1)
            .get();

        if (querySnapshot.empty) {
            throw new HttpsError("not-found", "لم يتم العثور على هذا الطلب في سجلات متجرك، أو انتهت صلاحية الوصول.");
        }

        const targetDocSnap = querySnapshot.docs[0];
        const storeOrderRef = targetDocSnap.ref;

        // بدء الترانزاكشن الآمن
        const result = await db.runTransaction(async (transaction) => {
            
            const sDoc = await transaction.get(storeOrderRef);
            if (!sDoc.exists) {
                throw new HttpsError("not-found", "تعذر جلب المستند المحدث أثناء مراجعة البيانات.");
            }

            const orderData = sDoc.data();
            const items = orderData.Items || [];
            let itemFound = false;
            const updatedItems = [...items];

            for (let i = 0; i < updatedItems.length; i++) {
                const currentItem = updatedItems[i];

                const isProductMatch = currentItem.productId === productId;
                
                // معالجة الفاريشن الحرفية الذكية: السلسلة الفارغة تنظف وتطابق تلقائياً
                const incomingVar = (variationId || "").trim();
                const currentVar = (currentItem.VariationId || "").trim();
                const isVariationMatch = incomingVar === currentVar;

                if (isProductMatch && isVariationMatch) {
                    itemFound = true;

                    const currentStatus = (currentItem.itemStatus || "pending").toLowerCase();

                    // الحالات النهائية المغلقة
                    if (currentStatus === "rejected" || currentStatus === "delivered") {
                        throw new HttpsError(
                            "failed-precondition",
                            `هذا المنتج مغلق نهائياً في السيرفر على حالة (${currentItem.itemStatus}).`
                        );
                    }

                    const currentIndex = statusRank[currentStatus] ?? 0;
                    const nextIndex = statusRank[normalizedNewStatus] ?? 0;

                    // منع التراجع للخلف خطياً
                    if (normalizedNewStatus !== "rejected" && nextIndex <= currentIndex) {
                        throw new HttpsError(
                            "failed-precondition",
                            `قواعد النظام تمنع التراجع من حالة (${currentItem.itemStatus}) إلى الحالات السابقة.`
                        );
                    }

                    // حفظ الحالة بالشكل النصي المعتمد في تطبيقك (مثال: readyForPickup التسمية الأصلية)
                    updatedItems[i].itemStatus = newStatus;
                    break;
                }
            }

            if (!itemFound) {
                throw new HttpsError("not-found", "لم يتم مطابقة معرف المنتج أو الفاريشن مع محتويات الفاتورة الحالية.");
            }

            // تحديث المستند
            transaction.update(storeOrderRef, {
                Items: updatedItems,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            return {
                status: "success",
                message: "تم تحديث حالة المنتج بنجاح وتوثيق الحركة تزامعياً.",
                newStatus: newStatus
            };
        });

        return result;

    } catch (error) {
        if (error instanceof HttpsError) throw error;
        console.error("CRITICAL SERVER ERROR:", error);
        throw new HttpsError("internal", error.message || "فشل السيرفر في معالجة تحديث الطلب.");
    }
});*/






/*
exports.cancelSpecificItems = onCall(async (request) => {
  
  // 1. فحص أمان التوثيق
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لتنفيذ هذه العملية.");
  }

  const userId = request.auth.uid;
  const { orderId, itemsToCancel } = request.data; 
  // [تحديث]: ننتظر هنا قائمة كائنات هيكلها كالتالي:
  // itemsToCancel: [{ productId: "177...", variationId: "احمر-قطن" }]

  if (!orderId || !itemsToCancel || !Array.isArray(itemsToCancel)) {
    throw new HttpsError("invalid-argument", "المعطيات المرسلة غير مكتملة أو غير صالحة.");
  }

  const db = admin.firestore();
  const orderRef = db.collection("Orders").doc(orderId);
  const userRef = db.collection("User").doc(userId);

  try {
    // جلب مستند الطلب الرئيسي بشكل سريع خارج الترانزاكشن لاستخراج المتاجر المتأثرة
    const initialOrderDoc = await orderRef.get();
    if (!initialOrderDoc.exists) {
      throw new HttpsError("not-found", "الطلب المحدد غير موجود في سجلات النظام.");
    }

    const initialOrderData = initialOrderDoc.data();
    if (initialOrderData.UserId !== userId) {
      throw new HttpsError("permission-denied", "لا تملك الصلاحية لتعديل أو إلغاء هذا الطلب.");
    }

    const initialItems = initialOrderData.Items || [];
    const affectedStoreIds = new Set();
    
    // التحقق والمطابقة بالاعتماد على الـ productId والـ variationId معاً
    initialItems.forEach(item => {
      const pId = String(item.productId || "").trim();
      const vId = String(item.VariationId || "").trim();

      const isMatched = itemsToCancel.some(target => 
        String(target.productId || "").trim() === pId && 
        String(target.variationId || "").trim() === vId
      );

      if (isMatched && item.storeId) {
        affectedStoreIds.add(String(item.storeId).trim());
      }
    });

    const storeIdsArray = Array.from(affectedStoreIds);
    const subOrderRefsMap = {}; 

    for (const storeId of storeIdsArray) {
      const subOrderSnapshot = await db.collection("StoreOrders")
        .where("MainOrderId", "==", orderId)
        .where("StoreId", "==", storeId)
        .limit(1)
        .get();

      if (!subOrderSnapshot.empty) {
        subOrderRefsMap[storeId] = subOrderSnapshot.docs[0].ref;
      }
    }

    // 2️⃣ بدء تشغيل العملية التزامنية الذرية (Transaction)
    const result = await db.runTransaction(async (transaction) => {
      
      // 🟩 [مرحلة القراءات فقط - ALL READS FIRST] 🟩
      const orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) {
        throw new HttpsError("not-found", "الطلب المحدد غير موجود في سجلات النظام.");
      }
      const orderData = orderDoc.data();

      const subOrderDocsMap = {};
      for (const storeId of storeIdsArray) {
        const subRef = subOrderRefsMap[storeId];
        if (subRef) {
          const sDoc = await transaction.get(subRef);
          if (sDoc.exists) {
            subOrderDocsMap[storeId] = sDoc;
          }
        }
      }

      const userDoc = await transaction.get(userRef);

      const storeDocsMap = {};
      for (const storeId of storeIdsArray) {
        const storeRef = db.collection("Stores").doc(storeId);
        const sDoc = await transaction.get(storeRef);
        if (sDoc.exists) {
          storeDocsMap[storeId] = sDoc;
        }
      }

      // 🟨 [مرحلة المعالجة والحسابات - PROCESSING] 🟨
      let items = orderData.Items || [];
      let totalRefundToUser = 0; // الأموال التي ستعاد فعلياً للعميل (للمدفوع فقط)
      let storesToUpdateBalances = {}; 
      let automaticallyCancelledItems = [];
      let requestedForReviewItems = [];
      let adminReviewRequestsToSet = []; 
      let processedInThisOrder = false;

      for (let item of items) {
        const pId = String(item.productId || "").trim();
        const vId = String(item.VariationId || "").trim();

        // فحص المطابقة المزدوجة (المنتج + الفاريشن المحددة)
        const isTargetToCancel = itemsToCancel.some(target => 
          String(target.productId || "").trim() === pId && 
          String(target.variationId || "").trim() === vId
        );
        
        if (isTargetToCancel) {
          const itemPrice = Number(item.price || 0);
          const itemQuantity = Number(item.quantity || 1);
          const itemTotal = itemPrice * itemQuantity;
          const currentStatus = String(item.itemStatus || "pending").toLowerCase();

          // المسار الأول: بانتظار التجهيز أو انتظار الدفع
          if (currentStatus === "pending" || currentStatus === "pendingpayment") {
            
            // 💡 [حل مشكلة المالية]: حساب المسترد يتم فقط إذا كان العميل قد دفع فعلاً (حالة pending)
            if (currentStatus === "pending") {
              totalRefundToUser += itemTotal;
              
              if (item.storeId) {
                const sIdStr = String(item.storeId).trim();
                storesToUpdateBalances[sIdStr] = (storesToUpdateBalances[sIdStr] || 0) + itemTotal;
              }
            }
            
            // في كلتا الحالتين يتم تغيير الحالة إلى ملغي في السجلات وتعديل قيمة الطلب
            item.itemStatus = "cancelled";
            automaticallyCancelledItems.push(`${item.Title || "منتج"} (${vId})`);
            processedInThisOrder = true;
          } 
          // المسار الثاني: تم القبول، قيد التحضير، أو تم الشحن
          else if (["accepted", "shipped", "delivered", "processing"].includes(currentStatus)) {
            const targetStatus = (currentStatus === "accepted" || currentStatus === "processing") ? "cancellation_requested" : "return_requested";
            
            item.itemStatus = targetStatus;
            requestedForReviewItems.push(`${item.Title || "منتج"} (${vId})`);

            const reviewRequestRef = db.collection("AdminReviewRequests").doc();
            adminReviewRequestsToSet.push({
              ref: reviewRequestRef,
              data: {
                id: reviewRequestRef.id,
                orderId: orderId,
                userId: userId,
                storeId: item.storeId || "",
                itemId: pId,
                variationId: vId,
                itemName: item.Title || "منتج",
                itemTotalAmount: itemTotal,
                requestType: (currentStatus === "accepted" || currentStatus === "processing") ? "cancel_prepared_item" : "return_shipped_item",
                status: "pending_admin_approval",
                createdAt: admin.firestore.FieldValue.serverTimestamp()
              }
            });
            processedInThisOrder = true;
          } else {
            throw new HttpsError("failed-precondition", `العنصر [${item.Title} - ${vId}] تمت معالجته أو إلغاؤه مسبقاً.`);
          }
        }
      }

      if (!processedInThisOrder) {
        throw new HttpsError("invalid-argument", "لم يتم مطابقة أي عناصر، يرجى التحقق من الخصائص والحالة.");
      }

      // 🟥 [مرحلة الكتابة والتحديث النهائي - ALL WRITES LAST] 🟥

      // 1. طلبات الإدارة
      adminReviewRequestsToSet.forEach(req => {
        transaction.set(req.ref, req.data);
      });

      // 2. تحديث الطلبات الفرعية (StoreOrders)
      for (const storeId of storeIdsArray) {
        const subOrderDoc = subOrderDocsMap[storeId];
        const subOrderRef = subOrderRefsMap[storeId];

        if (subOrderDoc && subOrderRef) {
          const subOrderData = subOrderDoc.data();
          let subOrderItems = subOrderData.Items || [];
          let subOrderRefundAmount = 0;

          subOrderItems = subOrderItems.map(subItem => {
            const subPId = String(subItem.productId || "").trim();
            const subVId = String(subItem.VariationId || "").trim();

            // العثور على العنصر المطابق من المصفوفة الرئيسية المعدلة بالاعتماد على الأب والفاريشن
            const updatedItem = items.find(mainItem => 
              String(mainItem.productId || "").trim() === subPId && 
              String(mainItem.VariationId || "").trim() === subVId
            );
            
            if (updatedItem) {
              // تعديل حسابات الطلب الفرعي بناء على ما إذا كان ملغياً وكان قيد الانتظار مدفوعاً
              if (updatedItem.itemStatus === "cancelled" && String(subItem.itemStatus).toLowerCase() === "pending") {
                const price = Number(subItem.price || 0);
                const qty = Number(subItem.quantity || 1);
                subOrderRefundAmount += (price * qty);
              }
              // لتعديل الفاتورة العامة حتى لو لم يكن مدفوعاً نحدث الحالة
              if (updatedItem.itemStatus === "cancelled" && String(subItem.itemStatus).toLowerCase() === "pendingpayment") {
                const price = Number(subItem.price || 0);
                const qty = Number(subItem.quantity || 1);
                subOrderRefundAmount += (price * qty); 
              }
              subItem.itemStatus = updatedItem.itemStatus;
            }
            return subItem;
          });

          const allSubItemsCancelled = subOrderItems.every(si => String(si.itemStatus).toLowerCase() === "cancelled");
          const newSubTotal = Number(subOrderData.totalAmount || 0) - subOrderRefundAmount;

          transaction.update(subOrderRef, {
            Items: subOrderItems,
            totalAmount: newSubTotal < 0 ? 0 : newSubTotal,
            Status: allSubItemsCancelled ? "cancelled" : (subOrderData.Status || "pending"),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      }

      // 3. حسابات تكلفة التوصيل (المستردة في حال إلغاء الطلب بالكامل وكان مدفوعاً)
      const shippingFee = Number(orderData.ShippingAmount || 0);
      const allItemsCancelled = items.every(item => String(item.itemStatus).toLowerCase() === "cancelled");
      const hasAnyShippedProduct = items.some(item => {
        const s = String(item.itemStatus).toLowerCase();
        return s === "shipped" || s === "delivered";
      });
      
      let shippingFeeRefunded = 0;
      // لا يتم رد رسوم الشحن إلا إذا كان الطلب الرئيسي مدفوعاً (وليس معلق الدفع)
      const isMainOrderPaid = String(orderData.Status || "").toLowerCase() !== "pendingpayment";

      if (allItemsCancelled && !hasAnyShippedProduct && isMainOrderPaid) {
        totalRefundToUser += shippingFee;
        shippingFeeRefunded = shippingFee;
      }

      // 4. تحديث محفظة المستخدم (تتم فقط إذا كان هناك مسترد مالي فعلي totalRefundToUser > 0)
      if (totalRefundToUser > 0 && userDoc.exists) {
        const currentBal = Number(userDoc.data().walletBalance || 0);
        transaction.update(userRef, {
          walletBalance: currentBal + totalRefundToUser
        });

        const userLogRef = db.collection("User").doc(userId).collection("Transactions").doc();
        transaction.set(userLogRef, {
          id: userLogRef.id,
          amount: totalRefundToUser,
          type: "partial_refund",
          title: "استرداد تلقائي لمنتجات معلقة",
          description: `تم استرداد مبلغ المنتجات المدفوعة والملغاة فورياً للطلب #${orderId.substring(0, 6)}. (شامل التوصيل المسترد: ${shippingFeeRefunded})`,
          date: admin.firestore.FieldValue.serverTimestamp()
        });

        // 5. خصم الأرصدة المعلقة من محافظ التجار المتأثرين بالمنتجات المدفوعة فقط
        for (const [storeId, amountToDeduct] of Object.entries(storesToUpdateBalances)) {
          const storeDoc = storeDocsMap[storeId];
          if (storeDoc) {
            const storeData = storeDoc.data() || {};
            const currentPending = Number((storeData.wallet && storeData.wallet.pendingBalance) || 0);
            let newPending = currentPending - amountToDeduct;
            if (newPending < 0) newPending = 0;

            transaction.update(storeDoc.ref, {
              'wallet.pendingBalance': newPending
            });

            const storeLogRef = db.collection("Transactions").doc();
            transaction.set(storeLogRef, {
              id: storeLogRef.id,
              amount: -amountToDeduct,
              type: "order_item_cancelled",
              title: "خصم إلغاء فوري من زبون",
              description: `سحب مالي لإلغاء تلقائي قبل التجهيز للطلب رقم #${orderId}.`,
              date: admin.firestore.FieldValue.serverTimestamp()
            });
          }
        }
      }

      // 6. تحديث مستند الطلب الرئيسي الكلي (يتم خصم القيمة الإجمالية للمنتج من الفاتورة دائماً)
      // لمعرفة القيمة المخصومة الكلية من الفاتورة (سواء مدفوعة أو غير مدفوعة):
      let totalAmountToDeductFromInvoice = 0;
      items.forEach(it => {
        const pId = String(it.productId || "").trim();
        const vId = String(it.VariationId || "").trim();
        const wasTarget = itemsToCancel.some(t => String(t.productId || "").trim() === pId && String(t.variationId || "").trim() === vId);
        
        // إذا ألغي الآن وكان معلقاً أو غير مدفوع نخصمه من الفاتورة الكلية للطلب
        if (wasTarget && it.itemStatus === "cancelled") {
          totalAmountToDeductFromInvoice += (Number(it.price || 0) * Number(it.quantity || 1));
        }
      });
      
      if (allItemsCancelled) {
        totalAmountToDeductFromInvoice = Number(orderData.totalAmount || 0); // تصفير الفاتورة بالكامل
      }

      const newTotalAmount = Number(orderData.totalAmount || 0) - totalAmountToDeductFromInvoice;
      
      transaction.update(orderRef, {
        Items: items,
        totalAmount: newTotalAmount < 0 ? 0 : newTotalAmount,
        Status: allItemsCancelled ? "cancelled" : (orderData.Status || "pending"),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return {
        success: true,
        refundedAmount: totalRefundToUser,
        allItemsCancelled: allItemsCancelled,
        automaticallyCancelledItems: automaticallyCancelledItems,
        requestedForReviewItems: requestedForReviewItems,
        fcmToken: userDoc.exists ? (userDoc.data().fcmToken || null) : null
      };
    });

    // 3️⃣ إرسال إشعارات FCM
    if (result.fcmToken) {
      let notificationBody = "";
      if (result.automaticallyCancelledItems.length > 0 && result.requestedForReviewItems.length > 0) {
        notificationBody = `تم تحديث الطلب وإلغاء بعض الخصائص، وتم تحويل المنتجات المجهزة للمراجعة.`;
      } else if (result.automaticallyCancelledItems.length > 0) {
        notificationBody = `تم إلغاء العناصر المحددة وتحديث الفاتورة بنجاح. المبلغ المعاد للمحفظة: ${result.refundedAmount} شيكل.`;
      } else {
        notificationBody = `تم إرسال طلب إلغاء العناصر المحددة للمسؤول للمراجعة.`;
      }

      const payload = {
        token: result.fcmToken,
        notification: {
          title: result.allItemsCancelled ? "تم إلغاء طلبك بالكامل 🛑" : "تعديل عناصر الطلب 🛍️",
          body: notificationBody
        },
        data: { 
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: "partial_refund_update",
          orderId: orderId
        }
      };
      
      await admin.messaging().send(payload).catch(e => console.error("فشل إرسال إشعار FCM:", e));
    }

    return { 
      status: "success",
      refundedAmount: result.refundedAmount,
      cancelledCount: result.automaticallyCancelledItems.length,
      reviewCount: result.requestedForReviewItems.length
    };

  } catch (error) {
    console.error("خطأ بداخل دالة cancelSpecificItems المحدثة:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError(
      "internal",
      error.message || "حدث خطأ غير متوقع بداخل الخادم أثناء معالجة إلغاء السلة الجزئي."
    );
  }
});
*/






 








/*exports.updateItemStatusInCloud = onCall({
    cors: true,
    timeoutSeconds: 60,
}, async (request) => {
    
    const { auth, data } = request;

    // 1. التحقق من تسجيل الدخول والمصادقة الأمنية
    if (!auth) {
        throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لإتمام هذه العملية.");
    }

    const { mainOrderId, productId, variationId, newStatus } = data;

    // التحقق من اكتمال المدخلات الأساسية القادمة من التطبيق
    if (!mainOrderId || !productId || !newStatus) {
        throw new HttpsError("invalid-argument", "البيانات المرسلة غير مكتملة، يرجى تزويد السيرفر بجميع المعرفات.");
    }

    // 2. خريطة تسلسل الحالات القياسية (مطابقة تماماً لـ _statusOrder الخاصة بك)
    const statusRank = {
        "pending": 0,        // جديد / قيد الانتظار
        "accepted": 1,       // مقبول / قيد التجهيز
        "readyForPickup": 2, // جاهز للاستلام
        "delivered": 3,      // تم التسليم (حالة نهائية)
        "rejected": -1       // مرفوض (حالة نهائية)
    };

    // التحقق من أن الحالة المطلوبة مدعومة وموجودة في الخريطة
    if (!Object.keys(statusRank).includes(newStatus)) {
        throw new HttpsError("invalid-argument", `الحالة المطلوبة (${newStatus}) غير معرفة في النظام.`);
    }

    // الاعتماد على معرف المستخدم الموثق كـ StoreId لمنع التلاعب بين المتاجر
    const storeId = auth.uid;

    try {
        // تنفيذ العملية داخل Transaction لضمان سلامة البيانات ومنع التداخل
        const result = await db.runTransaction(async (transaction) => {
            
            // البحث عن مستند الطلب الخاص بالمتجر الحالي وبمعرف الطلب الرئيسي
            const storeOrdersRef = db.collection("StoreOrders");
            const query = storeOrdersRef
                .where("StoreId", "==", storeId)
                .where("mainOrderId", "==", mainOrderId)
                .limit(1);

            const querySnapshot = await transaction.get(query);

            if (querySnapshot.empty) {
                throw new HttpsError("not-found", "لم يتم العثور على طلب المتجر المطلوب أو لا تملك صلاحية الوصول إليه.");
            }

            const storeOrderDoc = querySnapshot.docs[0];
            const storeOrderRef = storeOrderDoc.ref;
            const orderData = storeOrderDoc.data();

            const items = orderData.Items || [];
            let itemFound = false;
            const updatedItems = [...items];

            // المرور على المنتجات لتحديد المنتج والخيار المطلوب بدقة
            for (let i = 0; i < updatedItems.length; i++) {
                const currentItem = updatedItems[i];

                // التحقق من تطابق الـ productId والـ VariationId (إن وجد)
                const isProductMatch = currentItem.productId === productId;
                const isVariationMatch = variationId ? currentItem.VariationId === variationId : true;

                if (isProductMatch && isVariationMatch) {
                    itemFound = true;

                    // قراءة الحالة الحالية المخزنة على السيرفر
                    const currentStatus = currentItem.itemStatus || "pending";

                    // 🛡️ [قاعدة الحالات النهائية]: يمنع تعديل منتج تم رفضه أو تسليمه بالفعل
                    if (currentStatus === "rejected" || currentStatus === "delivered") {
                        throw new HttpsError(
                            "failed-precondition",
                            `عذراً، لا يمكن تعديل منتج حالته الحالية مغلقة نهائياً وهي: (${currentStatus}).`
                        );
                    }

                    const currentIndex = statusRank[currentStatus] ?? 0;
                    const nextIndex = statusRank[newStatus] ?? 0;

                    // 🛡️ [قاعدة التسلسل الخطي الصارم]: يمنع العودة للخلف (إلا إذا كانت الحالة رفض)
                    if (newStatus !== "rejected" && nextIndex <= currentIndex) {
                        throw new HttpsError(
                            "failed-precondition",
                            `خطأ في التسلسل الحركي: لا يمكن التراجع من حالة (${currentStatus}) إلى حالة (${newStatus}).`
                        );
                    }

                    // تحديث حقل الحالة الفرعي للمنتج المستهدف داخل المصفوفة
                    updatedItems[i].itemStatus = newStatus;
                    break;
                }
            }

            if (!itemFound) {
                throw new HttpsError("not-found", "المنتج أو الخيار المحدد غير موجود في عناصر هذا الطلب.");
            }

            // 3. حفظ المصفوفة المحدثة بالكامل مع طابع زمني للسيرفر
            transaction.update(storeOrderRef, {
                Items: updatedItems,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            return {
                status: "success",
                message: "تم تحديث حالة المنتج بنجاح وتأمين العملية تسلسلياً كلياً.",
                newStatus: newStatus
            };
        });

        return result;

    } catch (error) {
        // إذا كان الخطأ مسبق الصنع من نوع HttpsError قم بتقديمه مباشرة للمستخدم
        if (error instanceof HttpsError) throw error;
        // معالجة الأخطاء غير المتوقعة بشكل عام ونظيف
        throw new HttpsError("internal", error.message || "حدث خطأ غير متوقع أثناء معالجة الطلب في السيرفر.");
    }
});*/





/*
exports.cancelSpecificItems = onCall(async (request) => {
  
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لتنفيذ هذه العملية.");
  }

  const userId = request.auth.uid;
  const { orderId, itemIdsToCancel } = request.data; 

  if (!orderId || !itemIdsToCancel || !Array.isArray(itemIdsToCancel)) {
    throw new HttpsError("invalid-argument", "المعطيات المرسلة غير مكتملة أو غير صالحة.");
  }

  const formattedItemIds = itemIdsToCancel.map(id => String(id).trim());

  const db = admin.firestore();
  const orderRef = db.collection("Orders").doc(orderId);
  const userRef = db.collection("User").doc(userId);

  try {
    // 1️⃣ جلب مستند الطلب الرئيسي بشكل سريع خارج الترانزاكشن لاستخراج المتاجر المتأثرة
    const initialOrderDoc = await orderRef.get();
    if (!initialOrderDoc.exists) {
      throw new HttpsError("not-found", "الطلب المحدد غير موجود في سجلات النظام.");
    }

    const initialOrderData = initialOrderDoc.data();
    if (initialOrderData.UserId !== userId) {
      throw new HttpsError("permission-denied", "لا تملك الصلاحية لتعديل أو إلغاء هذا الطلب.");
    }

    const initialItems = initialOrderData.Items || [];
    const affectedStoreIds = new Set();
    
    initialItems.forEach(item => {
      const pId = String(item.productId || "").trim();
      if (formattedItemIds.includes(pId)) {
        if (item.storeId) affectedStoreIds.add(String(item.storeId).trim());
      }
    });

    const storeIdsArray = Array.from(affectedStoreIds);
    const subOrderRefsMap = {}; 

    for (const storeId of storeIdsArray) {
      const subOrderSnapshot = await db.collection("StoreOrders")
        .where("MainOrderId", "==", orderId)
        .where("StoreId", "==", storeId)
        .limit(1)
        .get();

      if (!subOrderSnapshot.empty) {
        subOrderRefsMap[storeId] = subOrderSnapshot.docs[0].ref;
      }
    }

    // 2️⃣ بدء تشغيل العملية التزامنية الذرية (Transaction)
    const result = await db.runTransaction(async (transaction) => {
      
      // 🟩 [مرحلة القراءات فقط - ALL READS FIRST] 🟩
      
      // أ. قراءة الطلب الرئيسي
      const orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) {
        throw new HttpsError("not-found", "الطلب المحدد غير موجود في سجلات النظام.");
      }
      const orderData = orderDoc.data();

      // ب. قراءة الطلبات الفرعية بشكل مسبق وتخزين سناب شوت لها
      const subOrderDocsMap = {};
      for (const storeId of storeIdsArray) {
        const subRef = subOrderRefsMap[storeId];
        if (subRef) {
          const sDoc = await transaction.get(subRef);
          if (sDoc.exists) {
            subOrderDocsMap[storeId] = sDoc;
          }
        }
      }

      // ج. قراءة مستند الزبون
      const userDoc = await transaction.get(userRef);

      // د. قراءة مستندات التجار والمتاجر المتأثرة مسبقاً قبل أي عملية كتابة
      const storeDocsMap = {};
      for (const storeId of storeIdsArray) {
        const storeRef = db.collection("Stores").doc(storeId);
        const sDoc = await transaction.get(storeRef);
        if (sDoc.exists) {
          storeDocsMap[storeId] = sDoc;
        }
      }

      // 🟨 [مرحلة المعالجة والحسابات - PROCESSING] 🟨
      
      let items = orderData.Items || [];
      let totalRefundToUser = 0;
      let storesToUpdateBalances = {}; 
      let automaticallyCancelledItems = [];
      let requestedForReviewItems = [];
      let adminReviewRequestsToSet = []; // مصفوفة مؤقتة لحفظ طلبات الإدارة لتأجيل كتابتها
      let processedInThisOrder = false;

      for (let item of items) {
        const pId = String(item.productId || "").trim();
        
        if (formattedItemIds.includes(pId)) {
          const itemPrice = Number(item.price || 0);
          const itemQuantity = Number(item.quantity || 1);
          const itemTotal = itemPrice * itemQuantity;
          const currentStatus = String(item.itemStatus || "pending").toLowerCase();

          // المسار الأول: تعليق أو انتظار الدفع (إلغاء فوري)
          if (currentStatus === "pending" || currentStatus === "pendingpayment") {
            totalRefundToUser += itemTotal;
            item.itemStatus = "cancelled";
            automaticallyCancelledItems.push(item.Title || "منتج");

            if (item.storeId) {
              const sIdStr = String(item.storeId).trim();
              storesToUpdateBalances[sIdStr] = (storesToUpdateBalances[sIdStr] || 0) + itemTotal;
            }
            processedInThisOrder = true;
          } 
          // المسار الثاني: قيد التحضير أو الشحن (مراجعة الإدارة)
          else if (["accepted", "shipped", "delivered", "processing"].includes(currentStatus)) {
            const targetStatus = (currentStatus === "accepted" || currentStatus === "processing") ? "cancellation_requested" : "return_requested";
            
            item.itemStatus = targetStatus;
            requestedForReviewItems.push(item.Title || "منتج");

            // بدلاً من التحديث المباشر، نخزن البيانات في مصفوفة مؤقتة لنكتبها في مرحلة الـ Writes
            const reviewRequestRef = db.collection("AdminReviewRequests").doc();
            adminReviewRequestsToSet.push({
              ref: reviewRequestRef,
              data: {
                id: reviewRequestRef.id,
                orderId: orderId,
                userId: userId,
                storeId: item.storeId || "",
                itemId: pId,
                itemName: item.Title || "منتج",
                itemTotalAmount: itemTotal,
                requestType: (currentStatus === "accepted" || currentStatus === "processing") ? "cancel_prepared_item" : "return_shipped_item",
                status: "pending_admin_approval",
                createdAt: admin.firestore.FieldValue.serverTimestamp()
              }
            });
            processedInThisOrder = true;
          } else {
            throw new HttpsError("failed-precondition", `المنتج [${item.Title || pId}] تمت معالجته أو إلغاؤه مسبقاً.`);
          }
        }
      }

      if (!processedInThisOrder) {
        throw new HttpsError("invalid-argument", "لم يتم مطابقة أي عناصر، يرجى التحقق من حالة المنتجات.");
      }

      // 🟥 [مرحلة الكتابة والتحديث النهائي - ALL WRITES LAST] 🟥

      // 1. كتابة طلبات الإدارة المؤجلة إن وُجدت
      adminReviewRequestsToSet.forEach(req => {
        transaction.set(req.ref, req.data);
      });

      // 2. تحديث مستندات الطلبات الفرعية (StoreOrders) المتوفرة لدينا سناب شوت لها مسبقاً
      for (const storeId of storeIdsArray) {
        const subOrderDoc = subOrderDocsMap[storeId];
        const subOrderRef = subOrderRefsMap[storeId];

        if (subOrderDoc && subOrderRef) {
          const subOrderData = subOrderDoc.data();
          let subOrderItems = subOrderData.Items || [];
          let subOrderRefundAmount = 0;

          subOrderItems = subOrderItems.map(subItem => {
            const subPId = String(subItem.productId || "").trim();
            const updatedItem = items.find(mainItem => String(mainItem.productId || "").trim() === subPId);
            
            if (updatedItem) {
              if (updatedItem.itemStatus === "cancelled" && String(subItem.itemStatus).toLowerCase() === "pending") {
                const price = Number(subItem.price || 0);
                const qty = Number(subItem.quantity || 1);
                subOrderRefundAmount += (price * qty);
              }
              subItem.itemStatus = updatedItem.itemStatus;
            }
            return subItem;
          });

          const allSubItemsCancelled = subOrderItems.every(si => String(si.itemStatus).toLowerCase() === "cancelled");
          const newSubTotal = Number(subOrderData.totalAmount || 0) - subOrderRefundAmount;

          transaction.update(subOrderRef, {
            Items: subOrderItems,
            totalAmount: newSubTotal < 0 ? 0 : newSubTotal,
            Status: allSubItemsCancelled ? "cancelled" : (subOrderData.Status || "pending"),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      }

      // 3. حسابات تكلفة التوصيل
      const shippingFee = Number(orderData.ShippingAmount || 0);
      const allItemsCancelled = items.every(item => String(item.itemStatus).toLowerCase() === "cancelled");
      const hasAnyShippedProduct = items.some(item => {
        const s = String(item.itemStatus).toLowerCase();
        return s === "shipped" || s === "delivered";
      });
      let shippingFeeRefunded = 0;

      if (allItemsCancelled && !hasAnyShippedProduct) {
        totalRefundToUser += shippingFee;
        shippingFeeRefunded = shippingFee;
      }

      // 4. تحديث محفظة المستخدم واللوغ الخاص به
      if (totalRefundToUser > 0 && userDoc.exists) {
        const currentBal = Number(userDoc.data().walletBalance || 0);
        transaction.update(userRef, {
          walletBalance: currentBal + totalRefundToUser
        });

        const userLogRef = db.collection("User").doc(userId).collection("Transactions").doc();
        transaction.set(userLogRef, {
          id: userLogRef.id,
          amount: totalRefundToUser,
          type: "partial_refund",
          title: "استرداد تلقائي لمنتجات معلقة",
          description: `تم استرداد مبلغ المنتجات الملغاة فورياً للطلب #${orderId.substring(0, 6)}. (شامل التوصيل المسترد: ${shippingFeeRefunded})`,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // 5. خصم الأرصدة المعلقة من محافظ التجار
        for (const [storeId, amountToDeduct] of Object.entries(storesToUpdateBalances)) {
          const storeDoc = storeDocsMap[storeId];
          if (storeDoc) {
            const storeData = storeDoc.data() || {};
            const currentPending = Number((storeData.wallet && storeData.wallet.pendingBalance) || 0);
            let newPending = currentPending - amountToDeduct;
            if (newPending < 0) newPending = 0;

            transaction.update(storeDoc.ref, {
              'wallet.pendingBalance': newPending
            });

            const storeLogRef = db.collection("Transactions").doc();
            transaction.set(storeLogRef, {
              id: storeLogRef.id,
              amount: -amountToDeduct,
              type: "order_item_cancelled",
              title: "خصم إلغاء فوري من زبون",
              description: `سحب مالي لإلغاء تلقائي قبل التجهيز للطلب رقم #${orderId}.`,
              createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
          }
        }
      }

      // 6. تحديث مستند الطلب الرئيسي الخاتم
      const newTotalAmount = Number(orderData.totalAmount || 0) - totalRefundToUser;
      transaction.update(orderRef, {
        Items: items,
        totalAmount: newTotalAmount < 0 ? 0 : newTotalAmount,
        Status: allItemsCancelled ? "cancelled" : (orderData.Status || "pending"),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return {
        success: true,
        refundedAmount: totalRefundToUser,
        allItemsCancelled: allItemsCancelled,
        automaticallyCancelledItems: automaticallyCancelledItems,
        requestedForReviewItems: requestedForReviewItems,
        fcmToken: userDoc.exists ? (userDoc.data().fcmToken || null) : null
      };
    });

    // 3️⃣ إرسال إشعارات FCM اللحظية خارج الترانزاكشن تماماً
    if (result.fcmToken) {
      let notificationBody = "";
      if (result.automaticallyCancelledItems.length > 0 && result.requestedForReviewItems.length > 0) {
        notificationBody = `تم إلغاء بعض المنتجات واسترداد ${result.refundedAmount}، وتم تحويل الباقي للمسؤول للمراجعة.`;
      } else if (result.automaticallyCancelledItems.length > 0) {
        notificationBody = `تم إلغاء المنتجات المحددة وإعادة مبلغ ${result.refundedAmount} إلى محفظتك بنجاح.`;
      } else {
        notificationBody = `تم إرسال طلب إلغاء/إرجاع المنتجات للمسؤول للمراجعة وسيتم الرد عليك فور فحصها.`;
      }

      const payload = {
        token: result.fcmToken,
        notification: {
          title: result.allItemsCancelled ? "تم إلغاء الطلب بالكامل 🛑" : "تحديث حالة إلغاء منتجات 🛍️",
          body: notificationBody
        },
        data: { 
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: "partial_refund_update",
          orderId: orderId
        }
      };
      
      await admin.messaging().send(payload).catch(e => console.error("فشل إرسال إشعار FCM للمستخدم:", e));
    }

    return { 
      status: "success",
      refundedAmount: result.refundedAmount,
      cancelledCount: result.automaticallyCancelledItems.length,
      reviewCount: result.requestedForReviewItems.length
    };

  } catch (error) {
    console.error("خطأ كارثي حدث بداخل دالة cancelSpecificItems المحدثة:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError(
      "internal",
      error.message || "حدث خطأ غير متوقع بداخل الخادم أثناء معالجة إلغاء السلة الجزئي."
    );
  }
});
*/





/*
exports.cancelSpecificItems = onCall(async (request) => {
  
  // 1. فحص أمان: التحقق من توثيق المستخدم
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لتنفيذ هذه العملية.");
  }

  const userId = request.auth.uid;
  const { orderId, itemIdsToCancel } = request.data; 

  // فحص أمان للمدخلات
  if (!orderId || !itemIdsToCancel || !Array.isArray(itemIdsToCancel)) {
    throw new HttpsError("invalid-argument", "المعطيات المرسلة غير مكتملة أو غير صالحة.");
  }

  // تحويل المعرفات المرسلة إلى نصوص لضمان مطابقة الأنواع بنسبة 100%
  const formattedItemIds = itemIdsToCancel.map(id => String(id).trim());

  const db = admin.firestore();
  const orderRef = db.collection("Orders").doc(orderId);
  const userRef = db.collection("User").doc(userId);

  try {
    // 1️⃣ جلب مستند الطلب الرئيسي بشكل سريع خارج الترانزاكشن لاستخراج المتاجر المتأثرة
    const initialOrderDoc = await orderRef.get();
    if (!initialOrderDoc.exists) {
      throw new HttpsError("not-found", "الطلب المحدد غير موجود في سجلات النظام.");
    }

    const initialOrderData = initialOrderDoc.data();
    if (initialOrderData.UserId !== userId) {
      throw new HttpsError("permission-denied", "لا تملك الصلاحية لتعديل أو إلغاء هذا الطلب.");
    }

    const initialItems = initialOrderData.Items || [];
    const affectedStoreIds = new Set();
    
    initialItems.forEach(item => {
      const pId = String(item.productId || "").trim();
      if (formattedItemIds.includes(pId)) {
        if (item.storeId) affectedStoreIds.add(String(item.storeId).trim());
      }
    });

    // 2️⃣ جلب مراجع مستندات الـ StoreOrders الفرعية بناءً على المتاجر المتأثرة
    const storeIdsArray = Array.from(affectedStoreIds);
    const subOrderRefsMap = {}; 

    for (const storeId of storeIdsArray) {
      const subOrderSnapshot = await db.collection("StoreOrders")
        .where("MainOrderId", "==", orderId)
        .where("StoreId", "==", storeId)
        .limit(1)
        .get();

      if (!subOrderSnapshot.empty) {
        subOrderRefsMap[storeId] = subOrderSnapshot.docs[0].ref;
      }
    }

    // 3️⃣ بدء تشغيل العملية التزامنية الذرية (Transaction) بأمان مطلق
    const result = await db.runTransaction(async (transaction) => {
      
      const orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) {
        throw new HttpsError("not-found", "الطلب المحدد غير موجود في سجلات النظام.");
      }

      const orderData = orderDoc.data();
      let items = orderData.Items || [];
      
      let totalRefundToUser = 0;
      let storesToUpdate = {}; 
      let automaticallyCancelledItems = [];
      let requestedForReviewItems = [];
      let processedInThisOrder = false;

      // تعديل جوهري: استخدام حلقة for...of المحمية والمنتظرة بدلاً من forEach
      for (let item of items) {
        const pId = String(item.productId || "").trim();
        
        if (formattedItemIds.includes(pId)) {
          const itemPrice = Number(item.price || 0);
          const itemQuantity = Number(item.quantity || 1);
          const itemTotal = itemPrice * itemQuantity;
          const currentStatus = String(item.itemStatus || "pending").toLowerCase();

          // المسار الأول: الطلب بانتظار المراجعة أو الدفع المعلق (إلغاء فوري وتلقائي)
          if (currentStatus === "pending" || currentStatus === "pendingpayment") {
            totalRefundToUser += itemTotal;
            item.itemStatus = "cancelled";
            automaticallyCancelledItems.push(item.Title || "منتج");

            if (item.storeId) {
              const sIdStr = String(item.storeId).trim();
              storesToUpdate[sIdStr] = (storesToUpdate[sIdStr] || 0) + itemTotal;
            }
            processedInThisOrder = true;
          } 
          // المسار الثاني: الطلب قيد التحضير أو الشحن (طلب مراجعة من الإدارة)
          else if (["accepted", "shipped", "delivered", "processing"].includes(currentStatus)) {
            const targetStatus = (currentStatus === "accepted" || currentStatus === "processing") ? "cancellation_requested" : "return_requested";
            
            item.itemStatus = targetStatus;
            requestedForReviewItems.push(item.Title || "منتج");

            const reviewRequestRef = db.collection("AdminReviewRequests").doc();
            transaction.set(reviewRequestRef, {
              id: reviewRequestRef.id,
              orderId: orderId,
              userId: userId,
              storeId: item.storeId || "",
              itemId: pId,
              itemName: item.Title || "منتج",
              itemTotalAmount: itemTotal,
              requestType: (currentStatus === "accepted" || currentStatus === "processing") ? "cancel_prepared_item" : "return_shipped_item",
              status: "pending_admin_approval",
              createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
            processedInThisOrder = true;
          } 
          else {
            throw new HttpsError("failed-precondition", `المنتج [${item.Title || pId}] تمت معالجته أو إلغاؤه مسبقاً.`);
          }
        }
      }

      if (!processedInThisOrder) {
        throw new HttpsError("invalid-argument", "لم يتم مطابقة أي عناصر، يرجى التحقق من حالة المنتجات.");
      }

      // تحديث الطلبات الفرعية (StoreOrders) بشكل متزامن وآمن داخل الـ Transaction
      for (const storeId of storeIdsArray) {
        const subOrderRef = subOrderRefsMap[storeId];

        if (subOrderRef) {
          const subOrderDoc = await transaction.get(subOrderRef);
          
          if (subOrderDoc.exists) {
            const subOrderData = subOrderDoc.data();
            let subOrderItems = subOrderData.Items || [];
            let subOrderRefundAmount = 0;

            subOrderItems = subOrderItems.map(subItem => {
              const subPId = String(subItem.productId || "").trim();
              const updatedItem = items.find(mainItem => String(mainItem.productId || "").trim() === subPId);
              
              if (updatedItem) {
                if (updatedItem.itemStatus === "cancelled" && String(subItem.itemStatus).toLowerCase() === "pending") {
                  const price = Number(subItem.price || 0);
                  const qty = Number(subItem.quantity || 1);
                  subOrderRefundAmount += (price * qty);
                }
                subItem.itemStatus = updatedItem.itemStatus;
              }
              return subItem;
            });

            const allSubItemsCancelled = subOrderItems.every(si => String(si.itemStatus).toLowerCase() === "cancelled");
            const newSubTotal = Number(subOrderData.totalAmount || 0) - subOrderRefundAmount;

            transaction.update(subOrderRef, {
              Items: subOrderItems,
              totalAmount: newSubTotal < 0 ? 0 : newSubTotal,
              Status: allSubItemsCancelled ? "cancelled" : (subOrderData.Status || "pending"),
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
          }
        }
      }

      // حسابات تكلفة التوصيل
      const shippingFee = Number(orderData.ShippingAmount || 0);
      const allItemsCancelled = items.every(item => String(item.itemStatus).toLowerCase() === "cancelled");
      const hasAnyShippedProduct = items.some(item => {
        const s = String(item.itemStatus).toLowerCase();
        return s === "shipped" || s === "delivered";
      });
      let shippingFeeRefunded = 0;

      if (allItemsCancelled && !hasAnyShippedProduct) {
        totalRefundToUser += shippingFee;
        shippingFeeRefunded = shippingFee;
      }

      // قراءة وتحديث مستند الزبون والمحفظة بشكل آمن متزامن
      const userDoc = await transaction.get(userRef);
      if (totalRefundToUser > 0 && userDoc.exists) {
        const currentBal = Number(userDoc.data().walletBalance || 0);
        transaction.update(userRef, {
          walletBalance: currentBal + totalRefundToUser
        });

        const userLogRef = db.collection("User").doc(userId).collection("Transactions").doc();
        transaction.set(userLogRef, {
          id: userLogRef.id,
          amount: totalRefundToUser,
          type: "partial_refund",
          title: "استرداد تلقائي لمنتجات معلقة",
          description: `تم استرداد مبلغ المنتجات الملغاة فورياً للطلب #${orderId.substring(0, 6)}. (شامل التوصيل المسترد: ${shippingFeeRefunded})`,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // الحركة العكسية للتجار مع جلب وفحص المستند لحمايته من الـ undefined
        for (const [storeId, amountToDeduct] of Object.entries(storesToUpdate)) {
          const storeRef = db.collection("Stores").doc(storeId);
          const storeDoc = await transaction.get(storeRef);
          
          if (storeDoc.exists) {
            const storeData = storeDoc.data() || {};
            const currentPending = Number((storeData.wallet && storeData.wallet.pendingBalance) || 0);
            let newPending = currentPending - amountToDeduct;
            if (newPending < 0) newPending = 0;

            transaction.update(storeRef, {
              'wallet.pendingBalance': newPending
            });

            const storeLogRef = db.collection("Stores").doc(storeId).collection("Transactions").doc();
            transaction.set(storeLogRef, {
              id: storeLogRef.id,
              amount: -amountToDeduct,
              type: "order_item_cancelled",
              title: "خصم إلغاء فوري من زبون",
              description: `سحب مالي لإلغاء تلقائي قبل التجهيز للطلب رقم #${orderId}.`,
              createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
          }
        }
      }

      // تحديث مستند الطلب الرئيسي النهائي
      const newTotalAmount = Number(orderData.totalAmount || 0) - totalRefundToUser;
      transaction.update(orderRef, {
        Items: items,
        totalAmount: newTotalAmount < 0 ? 0 : newTotalAmount,
        Status: allItemsCancelled ? "cancelled" : (orderData.Status || "pending"),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return {
        success: true,
        refundedAmount: totalRefundToUser,
        allItemsCancelled: allItemsCancelled,
        automaticallyCancelledItems: automaticallyCancelledItems,
        requestedForReviewItems: requestedForReviewItems,
        fcmToken: userDoc.exists ? (userDoc.data().fcmToken || null) : null
      };
    });

    // 4. نظام الإشعارات اللحظية FCM
    if (result.fcmToken) {
      let notificationBody = "";
      if (result.automaticallyCancelledItems.length > 0 && result.requestedForReviewItems.length > 0) {
        notificationBody = `تم إلغاء بعض المنتجات واسترداد ${result.refundedAmount}، وتم تحويل الباقي للمسؤول للمراجعة.`;
      } else if (result.automaticallyCancelledItems.length > 0) {
        notificationBody = `تم إلغاء المنتجات المحددة وإعادة مبلغ ${result.refundedAmount} إلى محفظتك بنجاح.`;
      } else {
        notificationBody = `تم إرسال طلب إلغاء/إرجاع المنتجات للمسؤول للمراجعة وسيتم الرد عليك فور فحصها.`;
      }

      const payload = {
        token: result.fcmToken,
        notification: {
          title: result.allItemsCancelled ? "تم إلغاء الطلب بالكامل 🛑" : "تحديث حالة إلغاء منتجات 🛍️",
          body: notificationBody
        },
        data: { 
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: "partial_refund_update",
          orderId: orderId
        }
      };
      
      await admin.messaging().send(payload).catch(e => console.error("فشل إرسال إشعار FCM للمستخدم:", e));
    }

    return { 
      status: "success",
      refundedAmount: result.refundedAmount,
      cancelledCount: result.automaticallyCancelledItems.length,
      reviewCount: result.requestedForReviewItems.length
    };

  } catch (error) {
    console.error("خطأ كارثي حدث بداخل دالة cancelSpecificItems المحدثة:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError(
      "internal",
      error.message || "حدث خطأ غير متوقع بداخل الخادم أثناء معالجة إلغاء السلة الجزئي."
    );
  }
});*/









/*
exports.cancelOrderAndRefund = onCall(async (request) => {
  // 1. التحقق من هوية المستخدم (Authentication Check)
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "يجب تسجيل الدخول أولاً لتنفيذ هذه العملية."
    );
  }

  const userId = request.auth.uid;
  const { orderId } = request.data;

  // التحقق من مدخلات الدالة
  if (!orderId) {
    throw new HttpsError(
      "invalid-argument",
      "لم يتم تزويد الدالة بمعرف الطلب (orderId)."
    );
  }

  const db = admin.firestore();
  
  // تعريف المراجع (References) بداخل الفايرستور
  const orderRef = db.collection("Orders").doc(orderId);
  const userRef = db.collection("User").doc(userId);
  const transactionRef = db.collection("User").doc(userId).collection("Transactions").doc();

  try {

// نقوم بعمل استعلام عادي خارج الـ transaction أولاً لجلب كافة الطلبات الفرعية لهذا الطلب الرئيسي
      const subOrdersSnapshot = await db.collection("StoreOrders")
        .where("MainOrderId", "==", orderId)
        .get();

    // تشغيل العملية التزامنية الذرية (Transaction)
    const result = await db.runTransaction(async (transaction) => {
      
      // أ. جلب مستند الطلب وفحصه
      const orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) {
        throw new HttpsError("not-found", "الطلب المحدد غير موجود بالسجلات.");
      }

      const orderData = orderDoc.data();
      
      // التأكد من أن الطلب يخص المستخدم الحالي الذي استدعى الدالة (أمان إضافي)
      if (orderData.UserId !== userId) {
        throw new HttpsError("permission-denied", "غير مسموح لك بإلغاء طلب لا يخص حسابك.");
      }

      // ب. فحص حالة الطلب الكلية
      const orderStatus = orderData.Status || "";
      if (orderStatus !== "pending" && orderStatus !== "pendingPayment") {
        throw new HttpsError(
          "failed-precondition",
          "لا يمكن إلغاء الطلب، لقد انتقل الطلب إلى مرحلة التجهيز أو الشحن بالفعل."
        );
      }

      // ج. فحص حالة المنتجات بداخل الطلب
      const items = orderData.items || [];
      const isAnyProductProcessed = items.some(item => item.itemStatus !== "pending");
      if (isAnyProductProcessed) {
        throw new HttpsError(
          "failed-precondition",
          "تعذر الإلغاء تلقائياً؛ قام أحد المتاجر بقبول أو تجهيز جزء من المنتجات."
        );
      }

      // د. جلب رصيد محفظة المستخدم الحالي
      const userDoc = await transaction.get(userRef);
      if (!userDoc.exists) {
        throw new HttpsError("not-found", "حساب المستخدم غير موجود بالسجلات.");
      }

      const userData = userDoc.data();
      const currentBalance = Number(userData.walletBalance || 0);
      // [تطوير ذكي]: إذا كانت الحالة بانتظار الدفع، المبلغ المسترد يكون 0 لأن المستخدم لم يدفع أصلاً
      let refundAmount = 0;
      if (orderStatus === "pending") {
        refundAmount = Number(orderData.TotalAmount || orderData.totalAmount || 0);
      }
      const newBalance = currentBalance + refundAmount;

      // هـ. [تحديث الطلبات الفرعية للمتاجر المتأثرة] لضمان التزامن المحاسبي واللوجستي
      // نجمع كل الـ StoreIds الموجودة في الطلب
     
      // جلب وتحديث مستندات المتاجر الفرعية
      // نمر على كل المستندات الفرعية الناتجة لتحديثها تزامناً داخل الـ Transaction
      for (const subOrderDocSnapshot of subOrdersSnapshot.docs) {
        const subOrderRef = subOrderDocSnapshot.ref;
        const subOrderDoc = await transaction.get(subOrderRef);
        
        if (subOrderDoc.exists) {
          const subOrderData = subOrderDoc.data();
          const storeId = subOrderData.StoreId || subOrderData.storeId;
          const subTotalAmount = Number(subOrderData.totalAmount || subOrderData.TotalAmount || 0);

          let subOrderItems = subOrderData.Items || subOrderData.items || [];
          
          // 1. تحويل كافة حالات العناصر داخل الطلب الفرعي لـ cancelled
          subOrderItems = subOrderItems.map(subItem => {
            subItem.itemStatus = "cancelled";
            return subItem;
          });

          // 2. تحديث الطلب الفرعي ليصبح ملغياً ومصفراً
          transaction.update(subOrderRef, {
            Items: subOrderItems,
            totalAmount: 0,
            Status: "cancelled",
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });

          // 3. تحديث محفظة المتجر وخصم الرصيد المعلق وتسجيل المعاملة الماليّة له
          if (storeId && subTotalAmount > 0) {
            const storeRef = db.collection("Stores").doc(storeId);
            const storeDoc = await transaction.get(storeRef);
            
            if (storeDoc.exists) {
              const storeData = storeDoc.data();
              const currentWallet = storeData.wallet || {};
              const currentPendingBalance = Number(currentWallet.pendingBalance || 0);
              
              // احتساب الرصيد المعلق الجديد بعد الخصم مع التقريب لمنع الكسور العشرية الطويلة
              const newPendingBalance = Number(Math.max(0, currentPendingBalance - subTotalAmount).toFixed(2));

              // تحديث حقل الـ wallet المدمج (Map Update) لضمان عدم مسح باقي الحقول المتواجدة داخله
              transaction.update(storeRef, {
                "wallet.pendingBalance": newPendingBalance,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
              });

              // 4. تسجيل مستند المعاملة المالية الخاصة بالمتجر في كولكشن مستقل
              // (قم بتعديل اسم الكولكشن 'Transactions' للاسم المعتمد ببرروعك إن كان مختلفاً)
              const storeTransactionRef = db.collection("Transactions").doc();
              transaction.set(storeTransactionRef, {
                id: storeTransactionRef.id,
                amount: subTotalAmount,
                orderId: orderId,
                storeId: storeId,
                status: "completed",
                type: "cancel_deduction", // نوع العملية: خصم بسبب الإلغاء
                createdAt: admin.firestore.FieldValue.serverTimestamp()
              });
            }
          }
        }
      }
      
      
      // هـ. تنفيذ التعديلات المتزامنة في قاعدة البيانات
      // و. تنفيذ التعديلات المتزامنة في مستندات المستخدم والطلب الرئيسي
      // تحديث حالة عناصر الطلب الرئيسي الكلية إلى ملغية
      const updatedMainItems = items.map(item => {
        item.itemStatus = "cancelled";
        return item;
      });
      
      // 1. تحديث حالة الطلب إلى ملغي
      transaction.update(orderRef, {
        Status: "cancelled",
        items: updatedMainItems,
        TotalAmount: 0, // تصفير إجمالي الطلب الرئيسي بعد استرداد الأموال
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // 2. شحن المحفظة بالرصيد الجديد
      transaction.update(userRef, {
        walletBalance: newBalance
      });

      // 3. تدوين السجل المالي للعملية المحاسبية
      if (refundAmount > 0) {
        transaction.set(transactionRef, {
          id: transactionRef.id,
          amount: refundAmount,
          type: "refund",
          status: "completed",
          title: "إعادة مبلغ الطلب الملغي",
          description: `تم استرداد رصيد الطلب رقم #${orderId} تلقائياً لإلغائه قبل التجهيز.`,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

         logNotificationWithTransaction(transaction, "User", userId, {
                title: "تم إلغاء الطلب واسترداد الرصيد 💰",
                body: `بناءً على طلبك، تم إلغاء الطلب بنجاح وإعادة مبلغ ${refundAmount} ILS إلى محفظتك الحالية.`,
                type: "refund"
            });
        }else {
        // إشعار داخلي عادي بالإلغاء بدون ذكر شحن المحفظة
          logNotificationWithTransaction(transaction, "User", userId, {
            title: "تم إلغاء الطلب بنجاح ❌",
            body: `بناءً على طلبك، تم إلغاء الطلب غير المدفوع رقم #${orderId} بنجاح.`,
            type: "cancel_order"
          });
        }
      // إرجاع قيمة لإشعار كود فلوتر بالمبلغ المسترد وحساب التوكن للإشعار
      return {
        success: true,
        refundAmount: refundAmount,
        fcmToken: userData.fcmToken || null // نفترض وجود حقل fcmToken في مستند المستخدم لارسال الإشعار
      };
    });

    // 2. إرسال إشعار الـ Push Notification للمستخدم (خارج الـ Transaction لضمان سرعته وعدم تعطيل القاعدة)
    if (result.fcmToken) {
      const payload = {
        token: result.fcmToken,
        notification: {
          title: "تم إلغاء الطلب واسترداد الرصيد 💰",
          body: `بناءً على طلبك، تم إلغاء الطلب بنجاح وإعادة مبلغ ${refundAmount} ILS إلى محفظتك الحالية.`
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: "wallet_refund",
          orderId: orderId
        }
      };

      try {
        await admin.messaging().send(payload);
        console.log(`تم إرسال إشعار الإلغاء بنجاح للمستخدم: ${userId}`);
      } catch (fcmError) {
        // نسجل خطأ الإشعار في الـ Logs فقط، ولا نُفشل العملية المالية لأجله لأن الرصيد استُرد بالفعل
        console.error("فشل إرسال إشعار الـ FCM:", fcmError);
      }
    }

    return {
      status: "success",
      message: "تم إلغاء الطلب وتحديث المحفظة بنجاح.",
      refundedAmount: result.refundAmount
    };

  } catch (error) {
    console.error("خطأ كارثي في دالة cancelOrderAndRefund:", error);
    
    // إذا كان الخطأ تم صياغته مسبقاً كـ HttpsError أعد تمريره كما هو ليظهر بوضوح في فلوتر
    if (error instanceof HttpsError) {
      throw error;
    }
    
    // أي خطأ غير متوقع من السيرفر يتم صياغته كـ Internal Error لحماية تفاصيل الـ Stack trace
    throw new HttpsError(
      "internal",
      error.message || "حدث خطأ داخلي في السيرفر أثناء معالجة إلغاء الطلب."
    );
  }
});*/










/*
// تصدير دالة إلغاء منتجات معينة للطلب لكي يستطيع تطبيق فلوتر استدعاءها بأمان
exports.cancelSpecificItems = onCall(async (request) => {
  
  // 1. فحص أمان: التحقق من أن المستخدم قام بتسجيل الدخول في التطبيق وله هوية موثقة
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لتنفيذ هذه العملية.");
  }

  const userId = request.auth.uid;
  const { orderId, itemIdsToCancel } = request.data; 

  // فحص أمان للمدخلات
  if (!orderId || !itemIdsToCancel || !Array.isArray(itemIdsToCancel)) {
    throw new HttpsError("invalid-argument", "المعطيات المرسلة غير مكتملة أو غير صالحة.");
  }

  const db = admin.firestore();
  const orderRef = db.collection("Orders").doc(orderId);
  const userRef = db.collection("User").doc(userId);

  try {
    // 1️⃣ [حل المشكلة الأولى]: جلب مستند الطلب بشكل سريع خارج الترانزاكشن فقط لاستخراج معرفات المتاجر المتأثرة
    const initialOrderDoc = await orderRef.get();
    if (!initialOrderDoc.exists) {
      throw new HttpsError("not-found", "الطلب المحدد غير موجود في سجلات النظام.");
    }

    const initialOrderData = initialOrderDoc.data();
    if (initialOrderData.UserId !== userId) {
      throw new HttpsError("permission-denied", "لا تملك الصلاحية لتعديل أو إلغاء هذا الطلب.");
    }

    // استخراج المتاجر المتأثرة بالمنتجات المطلوب إلغاؤها فعلياً
    const initialItems = initialOrderData.Items || [];
    const affectedStoreIds = new Set();
    initialItems.forEach(item => {
      if (itemIdsToCancel.includes(item.productId)) {
        affectedStoreIds.add(item.storeId);
      }
    });

    // 2️⃣ [حل المشكلة الثانية]: جلب مراجع مستندات الـ StoreOrders الفرعية بناءً على المتاجر المتأثرة دون تمرير استعلامات للترانزاكشن
    const storeIdsArray = Array.from(affectedStoreIds);
    const subOrderRefsMap = {}; 

    for (const storeId of storeIdsArray) {
      const subOrderSnapshot = await db.collection("StoreOrders")
        .where("MainOrderId", "==", orderId)
        .where("StoreId", "==", storeId)
        .limit(1)
        .get();

      if (!subOrderSnapshot.empty) {
        // نكتفي بحفظ المرجع (Ref) فقط لنقوم بقراءته الحية والآمنة تزامناً بالداخل
        subOrderRefsMap[storeId] = subOrderSnapshot.docs[0].ref;
      }
    }

    // 3️⃣ بدء تشغيل العملية التزامنية الذرية بأمان مطلق الآن
    const result = await db.runTransaction(async (transaction) => {
      
      // أ. القراءة المتزامنة لمستند الطلب الرئيسي للتأكد من عدم تغير الحالات أثناء الجلب الخارجي
      const orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) {
        throw new HttpsError("not-found", "الطلب المحدد غير موجود في سجلات النظام.");
      }

      const orderData = orderDoc.data();
      let items = orderData.Items || [];
      // 🛠️ [أسطر تتبع مضافة لكشف المشكلة في Firebase Console]
      console.log("=== بدء تتبع دالة إلغاء المنتجات ===");
      console.log("المعرفات المرسلة من فلوتر (itemIdsToCancel):", JSON.stringify(itemIdsToCancel));
      console.log("أنواع بيانات المعرفات المرسلة من فلوتر:", itemIdsToCancel.map(id => typeof id));
      console.log("المعطيات المتواجدة داخل الفايرستور للطلب:");
      items.forEach(it => {
        console.log(`- منتج: [${it.Title}], الـ ID المخزن: [${it.productId}]  حالته الحالية: [${it.itemStatus}]`);
      });
      console.log("=====================================");
      let totalRefundToUser = 0;
      let storesToUpdate = {}; 
      
      let automaticallyCancelledItems = [];
      let requestedForReviewItems = [];
      
      // ب. المرور بحلقة تكرار على جميع المنتجات المتوفرة بداخل مصفوفة الطلب الأصلي
      items.forEach((item) => {
        if (itemIdsToCancel.includes(item.productId)) {
          
          const itemPrice = Number(item.price || 0);
          const itemQuantity = Number(item.quantity || 1);
          const itemTotal = itemPrice * itemQuantity;

          // --- [المسار الأول]: إذا كان المنتج ما زال بانتظار المراجعة (إلغاء تلقائي وفوري) ---
          if (item.itemStatus === "pending") {
            totalRefundToUser += itemTotal;
            item.itemStatus = "cancelled";
            automaticallyCancelledItems.push(item.Title);

            const storeId = item.storeId; 
            if (!storesToUpdate[storeId]) {
              storesToUpdate[storeId] = 0;
            }
            storesToUpdate[storeId] += itemTotal;
          } 
          
          // --- [المسار الثاني]: إذا كان المنتج قيد التحضير أو تم شحنه أو تسليمه (مسار المسؤول المعلق) ---
          else if (item.itemStatus === "accepted" || item.itemStatus === "shipped" || item.itemStatus === "delivered") {
            const previousStatus = item.itemStatus;
            item.itemStatus = (previousStatus === "accepted") ? "cancellation_requested" : "return_requested";
            requestedForReviewItems.push(item.Title);

            const reviewRequestRef = db.collection("AdminReviewRequests").doc();
            transaction.set(reviewRequestRef, {
              id: reviewRequestRef.id,
              orderId: orderId,
              userId: userId,
              storeId: item.storeId,
              itemId: item.productId,
              itemName: item.Title,
              itemTotalAmount: itemTotal,
              requestType: (previousStatus === "accepted") ? "cancel_prepared_item" : "return_shipped_item",
              status: "pending_admin_approval",
              createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
          } 
          
          else {
            throw new HttpsError("failed-precondition", `المنتج [${item.Title}] تمت معالجته أو إلغاؤه مسبقاً.`);
          }
        }
      });

      if (automaticallyCancelledItems.length === 0 && requestedForReviewItems.length === 0) {
        throw new HttpsError("invalid-argument", "لم يتم معالجة أي عناصر، يرجى التحقق من حالة المنتجات.");
      }

      // --- [منطق تحديث الطلبات الفرعية - المصحح والمحمي بالكامل] ---
      for (const storeId of storeIdsArray) {
        const subOrderRef = subOrderRefsMap[storeId];

        if (subOrderRef) {
          // جلب المستند بشكل حي ومتزامن 100% داخل الـ Transaction باستخدام الـ Ref المباشر
          const subOrderDoc = await transaction.get(subOrderRef);
          
          if (subOrderDoc.exists) {
            const subOrderData = subOrderDoc.data();
            let subOrderItems = subOrderData.Items || [];
            let subOrderRefundAmount = 0;

            // تحديث حالة المنتجات داخل الطلب الفرعي بناءً على التحديثات التي تمت في الطلب الرئيسي
            subOrderItems = subOrderItems.map(subItem => {
              const updatedItem = items.find(mainItem => mainItem.productId === subItem.productId);
              if (updatedItem) {
                if (updatedItem.itemStatus === "cancelled" && subItem.itemStatus === "pending") {
                  const price = Number(subItem.price || 0);
                  const qty = Number(subItem.quantity || 1);
                  subOrderRefundAmount += (price * qty);
                }
                subItem.itemStatus = updatedItem.itemStatus;
              }
              return subItem;
            });

            const allSubItemsCancelled = subOrderItems.every(subItem => subItem.itemStatus === "cancelled");
            const newSubTotal = Number(subOrderData.totalAmount || 0) - subOrderRefundAmount;

            transaction.update(subOrderRef, {
              Items: subOrderItems,
              totalAmount: newSubTotal < 0 ? 0 : newSubTotal,
              Status: allSubItemsCancelled ? "cancelled" : (subOrderData.Status || "pending"),
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
          }
        }
      }

      // ج. [منطق معالجة تكلفة التوصيل المحاسبي]
      const shippingFee = Number(orderData.ShippingAmount || 0);
      const allItemsCancelled = items.every(item => item.itemStatus === "cancelled");
      const hasAnyShippedProduct = items.some(item => item.itemStatus === "shipped" || item.itemStatus === "delivered");
      let shippingFeeRefunded = 0;

      if (allItemsCancelled) {
        if (hasAnyShippedProduct) {
          shippingFeeRefunded = 0; 
        } else {
          totalRefundToUser += shippingFee;
          shippingFeeRefunded = shippingFee;
        }
      }

      // د. قراءة مستند الزبون وتحديث المحفظة بشكل متزامن
      const userDoc = await transaction.get(userRef);
      
      if (totalRefundToUser > 0) {
        const currentBuf = Number(userDoc.data().walletBalance || 0);
        transaction.update(userRef, {
          walletBalance: currentBuf + totalRefundToUser
        });

        const userLogRef = db.collection("User").doc(userId).collection("Transactions").doc();
        transaction.set(userLogRef, {
          id: userLogRef.id,
          amount: totalRefundToUser,
          type: "partial_refund",
          title: "استرداد تلقائي لمنتجات معلقة",
          description: `تم استرداد مبلغ المنتجات الملغاة فورياً للطلب #${orderId.substring(0, 6)}. (شامل التوصيل المسترد: ${shippingFeeRefunded})`,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // هـ. [الحركة العكسية للتجار]
        for (const [storeId, amountToDeduct] of Object.entries(storesToUpdate)) {
          const storeRef = db.collection("Stores").doc(storeId);
          const storeDoc = await transaction.get(storeRef);
          
          if (storeDoc.exists) {
            const storeData = storeDoc.data() || {};
            const currentPending = Number((storeData.wallet && storeData.wallet.pendingBalance) || 0);
            let newPending = currentPending - amountToDeduct;
            if (newPending < 0) newPending = 0;

            transaction.update(storeRef, {
              'wallet.pendingBalance': newPending
            });

            const storeLogRef = db.collection("Stores").doc(storeId).collection("Transactions").doc();
            transaction.set(storeLogRef, {
              id: storeLogRef.id,
              amount: -amountToDeduct,
              type: "order_item_cancelled",
              title: "خصم إلغاء فوري من زبون",
              description: `سحب مالي لإلغاء تلقائي قبل التجهيز للطلب رقم #${orderId}.`,
              createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
          }
        }
      }

      // و. [تحديث مستند الطلب الرئيسي]
      const newTotalAmount = Number(orderData.totalAmount || 0) - totalRefundToUser;
      transaction.update(orderRef, {
        Items: items, // تم تصحيح مسمى الحقل ليتوافق مع الـ Items في الفايرستور (الحرف الأول كابيتال)
        totalAmount: newTotalAmount < 0 ? 0 : newTotalAmount,
        Status: allItemsCancelled ? "cancelled" : (orderData.Status || "pending"),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return {
        success: true,
        refundedAmount: totalRefundToUser,
        allItemsCancelled: allItemsCancelled,
        automaticallyCancelledItems: automaticallyCancelledItems,
        requestedForReviewItems: requestedForReviewItems,
        fcmToken: userDoc.data().fcmToken || null
      };
    });

    // 3. [نظام الإشعارات اللحظية الحية (FCM)]
    if (result.fcmToken) {
      let notificationBody = "";
      if (result.automaticallyCancelledItems.length > 0 && result.requestedForReviewItems.length > 0) {
        notificationBody = `تم إلغاء بعض المنتجات واسترداد ${result.refundedAmount}، وتم تحويل الباقي للمسؤول للمراجعة.`;
      } else if (result.automaticallyCancelledItems.length > 0) {
        notificationBody = `تم إلغاء المنتجات المحددة وإعادة مبلغ ${result.refundedAmount} إلى محفظتك بنجاح.`;
      } else {
        notificationBody = `تم إرسال طلب إلغاء/إرجاع المنتجات للمسؤول للمراجعة وسيتم الرد عليك فور فحصها.`;
      }

      const payload = {
        token: result.fcmToken,
        notification: {
          title: result.allItemsCancelled ? "تم إلغاء الطلب بالكامل 🛑" : "تحديث حالة إلغاء منتجات 🛍️",
          body: notificationBody
        },
        data: { 
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: "partial_refund_update",
          orderId: orderId
        }
      };
      
      await admin.messaging().send(payload).catch(e => console.error("فشل إرسال إشعار FCM للمستخدم:", e));
    }

    return { 
      status: "success",
      refundedAmount: result.refundedAmount,
      cancelledCount: result.automaticallyCancelledItems.length,
      reviewCount: result.requestedForReviewItems.length
    };

  } catch (error) {
    console.error("خطأ كارثي حدث بداخل دالة cancelSpecificItems المحدثة:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError(
      "internal",
      error.message || "حدث خطأ غير متوقع بداخل الخادم أثناء معالجة إلغاء السلة الجزئي."
    );
  }
});*/






exports.processAdminItemCancellation = onCall(async (request) => {
    // 1. التحقق من صلاحيات الأمان
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لتنفيذ هذه العملية.");
    }

    const { storeOrderId, productId, action, adminNotes } = request.data;

    // التحقق من المدخلات الأساسية
    if (!storeOrderId || !productId || !action) {
        throw new HttpsError("invalid-argument", "المعطيات ناقصة. يجب تزويد (storeOrderId, productId, action).");
    }

    if (!["approve", "reject"].includes(action)) {
        throw new HttpsError("invalid-argument", "العملية (action) يجب أن تكون إما 'approve' أو 'reject'.");
    }

    try {
        const storeOrderRef = admin.firestore().collection("StoreOrders").doc(storeOrderId);
        
        // استخدام Transaction لضمان ذرية وتناسق البيانات ومنع التداخل المالي
        const result = await admin.firestore().runTransaction(async (transaction) => {
            const storeOrderDoc = await transaction.get(storeOrderRef);

            if (!storeOrderDoc.exists) {
                throw new HttpsError("not-found", "لم يتم العثور على مستند الطلب الفرعي للمتجر.");
            }

            const storeOrderData = storeOrderDoc.data();
            const mainOrderId = storeOrderData.MainOrderId;
            const storeId = storeOrderData.StoreId;
            const userId = storeOrderData.UserId;

            // تحديد اسم مصفوفة العناصر (حروف كبيرة أم صغيرة) داخل الطلب الفرعي وتأمين الجلب للطرفين
            const subItemsKey = storeOrderData.Items !== undefined ? "Items" : "items";
            let subItems = [...(storeOrderData[subItemsKey] || [])];

            const subItemIndex = subItems.findIndex(item => (item.productId === productId) || (item.productId === productId));
            if (subItemIndex === -1) {
                throw new HttpsError("not-found", "المنتج المطلوب غير موجود ضمن هذا الطلب الفرعي.");
            }

            const targetItem = subItems[subItemIndex];
            const currentStatus = targetItem.itemStatus;

            // حصر الدالة في الحالتين المطلوبتين فقط
            if (currentStatus !== "cancellation_requested" && currentStatus !== "return_requested") {
                return { success: false, message: `هذه الدالة تعالج فقط طلبات الإلغاء والإرجاع. الحالة الحالية للمنتج: ${currentStatus}` };
            }

            const storeRef = admin.firestore().collection("Stores").doc(storeId);
            const storeDoc = await transaction.get(storeRef);
            const commRate = storeDoc.exists ? (storeDoc.data().commissionRate || 2) : 2;

            let totalGrossToReturnToUser = 0;
            let totalNetToDeductFromStore = 0;
            let isCancellation = currentStatus === "cancellation_requested";

            // ==========================================
            // 📌 القسم الأول: معالجة حالة طلب الإلغاء (cancellation_requested)
            // ==========================================
            if (isCancellation) {
                if (action === "approve") {
                    targetItem.itemStatus = "cancelled"; // تصحيح: توحيدها بحرفين ll لتطابق النظام

                    // الحسبة المالية لإرجاع المستحقات (إذا لم يتم إرجاعها سابقاً)
                    if (!targetItem.refunded) {
                        totalGrossToReturnToUser = (parseFloat(targetItem.price) || 0) * (parseInt(targetItem.Quantity || targetItem.quantity) || 1);
                        // حساب الصافي بدقة مع تقريبه لمنع الكسور العشرية المشوهة لقاعدة البيانات
                        const rawNet = totalGrossToReturnToUser * (1 - (commRate / 100));
                        totalNetToDeductFromStore = Number(parseFloat(rawNet).toFixed(2));
                        targetItem.refunded = true;
                    }
                } else if (action === "reject") {
                    targetItem.itemStatus = "accepted"; // في حالة الرفض يعود المنتج إلى "جاري التجهيز"
                }
            }
            // ==========================================
            // 📌 القسم الثاني: معالجة حالة طلب الإرجاع (return_requested)
            // ==========================================
            else { 
                if (action === "approve") {
                    targetItem.itemStatus = "returned"; // تحويل الحالة إلى مرجع من قبل الزبون

                    if (!targetItem.refunded) {
                        totalGrossToReturnToUser = (parseFloat(targetItem.price) || 0) * (parseInt(targetItem.Quantity || targetItem.quantity) || 1);
                        const rawNet = totalGrossToReturnToUser * (1 - (commRate / 100));
                        totalNetToDeductFromStore = Number(parseFloat(rawNet).toFixed(2));
                        targetItem.refunded = true;
                    }
                } else if (action === "reject") {
                    targetItem.itemStatus = "delivered"; // في حالة الرفض يعود لوضعه الطبيعي "تم التسليم"
                }
            }

            targetItem.adminCancelNotes = adminNotes || "";

            // 1. تحديث مصفوفة العناصر داخل مستند الطلب الفرعي للمتجر (وحماية تحديث كلا الحقلين احتياطياً)
            transaction.update(storeOrderRef, { 
                Items: subItems,
            });

            // 2. تحديث ومزامنة المنتج والمبلغ الكلي داخل الطلب الرئيسي للزبون (Orders)
            if (mainOrderId) {
                const mainOrderRef = admin.firestore().collection("Orders").doc(mainOrderId);
                const mainOrderDoc = await transaction.get(mainOrderRef);

                if (mainOrderDoc.exists) {
                    const mainOrderData = mainOrderDoc.data();
                    const mainItemsKey = mainOrderData.Items !== undefined ? "Items" : "items";
                    let mainItems = [...(mainOrderData[mainItemsKey] || [])];

                    mainItems = mainItems.map(mItem => {
                        if (mItem.productId === productId || mItem.productId === productId) {
                            return { 
                                ...mItem, 
                                itemStatus: targetItem.itemStatus, 
                                refunded: targetItem.refunded || mItem.refunded || false,
                                adminCancelNotes: adminNotes || ""
                            };
                        }
                        return mItem;
                    });

                    const mainUpdatePayload = {};
                    mainUpdatePayload[mainItemsKey] = mainItems;

                    // إذا تمت الموافقة، يتم زيادة حقل المبالغ المسترجعة في الطلب الرئيسي حسب نوع العملية
                    if (action === "approve" && totalGrossToReturnToUser > 0) {
                        if (isCancellation) {
                            mainUpdatePayload.CanceledAmount = admin.firestore.FieldValue.increment(totalGrossToReturnToUser);
                        } else {
                            mainUpdatePayload.ReturnedAmount = admin.firestore.FieldValue.increment(totalGrossToReturnToUser);
                        }
                    }

                    transaction.update(mainOrderRef, mainUpdatePayload);
                }
            }

            // 3. إجراء العمليات المالية وتسجيل الحركات (في حال وافق الأدمن وكان هناك مبالغ مسترجعة)
            if (action === "approve" && totalGrossToReturnToUser > 0) {
                const userRef = admin.firestore().collection("User").doc(userId);
                
                // أ. زيادة رصيد محفظة الزبون بالمبلغ الكامِل
                transaction.update(userRef, {
                    walletBalance: admin.firestore.FieldValue.increment(totalGrossToReturnToUser)
                });

                // ب. خصم المبلغ الصافي (بعد العموله) من رصيد التاجر المعلق بشكل آمن رياضياً
                const negativeDeduction = -1 * totalNetToDeductFromStore;
                transaction.update(storeRef, {
                    "wallet.pendingBalance": admin.firestore.FieldValue.increment(negativeDeduction)
                });

                // ج. تسجيل العملية المالية في سجل حركات الزبون الفرعي
                const userTransRef = userRef.collection("Transactions").doc();
                transaction.set(userTransRef, {
                    id: userTransRef.id,
                    amount: totalGrossToReturnToUser,
                    type: isCancellation ? "cancel_refund" : "return_refund",
                    status: "completed",
                    date: admin.firestore.FieldValue.serverTimestamp(),
                    description: isCancellation 
                        ? `مرتجع لإلغاء منتج: ${targetItem.Title || targetItem.name || 'منتج غير محدد'}`
                        : `مرتجع لإرجاع منتج: ${targetItem.Title || targetItem.name || 'منتج غير محدد'}`,
                    orderId: mainOrderId || "",
                    storeOrderId: storeOrderId,
                    productId: productId
                });

                // د. تسجيل العملية المالي في سجل حركات النظام العام للمتاجر
                const storeTransRef = admin.firestore().collection("Transactions").doc();
                transaction.set(storeTransRef, {
                    id: storeTransRef.id,
                    storeId: storeId,
                    orderId: mainOrderId || "",
                    storeOrderId: storeOrderId,
                    amount: negativeDeduction,
                    type: isCancellation ? "cancel_refund" : "return_refund",
                    status: "completed",
                    productId: productId,
                    productName: targetItem.Title || targetItem.name || 'منتج غير محدد',
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }

            return {
                success: true,
                action,
                isCancellation,
                userId,
                storeId,
                productName: targetItem.Title || targetItem.name || 'منتج غير محدد',
                amount: totalGrossToReturnToUser,
                message: "تمت معالجة العنصر بنجاح داخل الترانزاكشن."
            };
        });

        // 4. فحص الحالات الكلية وتحديث حالة مستندات الطلبات (خارج الترانزاكشن)
        if (result.success && result.isCancellation && result.action === "approve") {
            const freshStoreOrderSnap = await storeOrderRef.get();
            const freshStoreOrderData = freshStoreOrderSnap.data();
            const itemsKey = freshStoreOrderData.Items !== undefined ? "Items" : "items";
            const currentSubItems = freshStoreOrderData[itemsKey] || [];

            // تصحيح: الفحص الآن يشمل المسمى الصحيح والموحد بالـ ll
            const allItemsCanceledOrRejected = currentSubItems.every(item => ["cancelled", "rejected"].includes(item.itemStatus));

            if (allItemsCanceledOrRejected) {
                await storeOrderRef.update({ Status: "rejected" });

                const mainOrderId = freshStoreOrderData.MainOrderId;
                if (mainOrderId) {
                    const allSubOrdersSnapshot = await admin.firestore()
                        .collection("StoreOrders")
                        .where("MainOrderId", "==", mainOrderId)
                        .get();

                    const allStoresRejected = allSubOrdersSnapshot.docs.every(doc => doc.data().Status === "rejected");
                    
                    if (allStoresRejected) {
                        await admin.firestore().collection("Orders").doc(mainOrderId).update({ Status: "rejected" });
                    }
                }
            }
        }

        // 5. بناء وإرسال الإشعارات لكل جهة (الزبون والمتجر)
        if (result.success && result.userId) {
            const userRef = admin.firestore().collection("User").doc(result.userId);
            const userSnap = await userRef.get();
            const fcmToken = userSnap.data()?.fcmToken;

            const storeSnap = await admin.firestore().collection("Stores").doc(result.storeId).get();
            const storeFcmToken = storeSnap.data()?.fcmToken;

            let uTitle = "", uBody = "", uType = "";
            let sTitle = "", sBody = "";

            if (result.isCancellation) {
                if (result.action === "approve") {
                    uTitle = "قبول طلب الإلغاء 🛍️";
                    uBody = `وافقت الإدارة على إلغاء [${result.productName}] وتم رد ${result.amount} شيكل لمحفظتك.`;
                    uType = "ITEM_CANCEL_APPROVED";

                    sTitle = "إلغاء منتج من طلب 🛑";
                    sBody = `قامت الإدارة بالموافقة على إلغاء منتج [${result.productName}] من الطلب بناء على رغبة الزبون.`;
                } else {
                    uTitle = "تحديث بخصوص طلب الإلغاء ⚠️";
                    uBody = `تم رفض طلب إلغاء منتج [${result.productName}] من قِبل الإدارة وسيتم استكمال تجهيزه وشحنه لك.`;
                    uType = "ITEM_CANCEL_REJECTED";
                }
            } else {
                if (result.action === "approve") {
                    uTitle = "قبول طلب الإرجاع 🔄";
                    uBody = `وافقت الإدارة على إرجاع منتج [${result.productName}] وتم إيداع ${result.amount} شيكل في محفظتك.`;
                    uType = "ITEM_RETURN_APPROVED";

                    sTitle = "مرتجع من زبون 🔄";
                    sBody = `تمت الموافقة من قِبل الإدارة على إرجاع منتج [${result.productName}] وتم تسوية الحساب المالي للمتجر.`;
                } else {
                    uTitle = "تحديث بخصوص طلب الإرجاع ⚠️";
                    uBody = `تم رفض طلب إرجاع منتج [${result.productName}] من قِبل الإدارة.`;
                    uType = "ITEM_RETURN_REJECTED";
                }
            }

            // أ. حفظ الإشعار للزبون في الفايرستور
            await userRef.collection("Notifications").add({
                title: uTitle, 
                body: uBody, 
                type: uType, 
                mainOrderId: storeOrderId || "", 
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // ب. إرسال FCM للزبون
            if (fcmToken) {
                await admin.messaging().send({
                    token: fcmToken, 
                    notification: { title: uTitle, body: uBody }, 
                    data: { orderId: storeOrderId || "", type: uType }
                }).catch(e => console.error("Customer FCM Error:", e));
            }

            // ج. إرسال FCM للمتجر في حالة الموافقة
            if (result.action === "approve" && storeFcmToken) {
                await admin.messaging().send({
                    token: storeFcmToken, 
                    notification: { title: sTitle, body: sBody }, 
                    data: { storeOrderId: storeOrderId, type: "STORE_FINANCIAL_UPDATE" }
                }).catch(e => console.error("Store FCM Error:", e));
            }
        }

        return { success: true, message: "تم إنهاء معالجة الطلب وتحديث الحسابات والإشعارات بنجاح." };

    } catch (error) {
        console.error("🔥 Error in processAdminItemCancellation:", error);
        if (error instanceof HttpsError) throw error;
        throw new HttpsError("internal", "حدث خطأ داخلي أثناء معالجة الطلب.");
    }
});



/*
// تصدير دالة إلغاء منتجات معينة للطلب لكي يستطيع تطبيق فلوتر استدعاءها بأمان
exports.cancelSpecificItems = onCall(async (request) => {
  
  // 1. فحص أمان: التحقق من أن المستخدم قام بتسجيل الدخول في التطبيق وله هوية موثقة
  if (!request.auth) {
    // إذا لم يكن مسجلاً، يتم رفع خطأ يمنع إكمال الكود ويبلغ واجهة المستخدم
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لتنفيذ هذه العملية.");
  }

  // استخراج الـ ID الفريد الخاص بالزبون الحالي الذي قام بطلب الإلغاء من بيانات الهوية
  const userId = request.auth.uid;
  // تفكيك البيانات القادمة من فلوتر: استخراج ID الطلب، ومصفوفة الـ IDs للمنتجات المراد إلغاؤها
  const { orderId, itemIdsToCancel } = request.data; 

  // فحص أمان للمدخلات: التأكد من إرسال ID الطلب وأن المنتجات المرسلة عبارة عن مصفوفة (قائمة)
  if (!orderId || !itemIdsToCancel || !Array.isArray(itemIdsToCancel)) {
    // إذا كانت المعطيات ناقصة يتم إيقاف العملية وإرجاع خطأ ببيانات غير صالحة
    throw new HttpsError("invalid-argument", "المعطيات المرسلة غير مكتملة أو غير صالحة.");
  }

  // إنشاء متغير للوصول إلى قاعدة بيانات الفايرستور (Firestore) بداخل السيرفر
  const db = admin.firestore();
  // إنشاء مرجع يشير مباشرة إلى مستند الطلب المحدد داخل كوليكشن Orders
  const orderRef = db.collection("Orders").doc(orderId);
  // إنشاء مرجع يشير مباشرة إلى مستند الزبون الحالي داخل كوليكشن Users
  const userRef = db.collection("User").doc(userId);

  try {

    // 1️⃣ أولاً: جلب المستندات الفرعية ومعرفاتها خارج الـ Transaction تماماً (قبل السطر await db.runTransaction)
const storeIdsArray = Array.from(affectedStoreIds);
const subOrderRefsMap = {}; // خريطة لربط الـ storeId بالـ Document Reference الفعلي وحفظ بياناته

for (const storeId of storeIdsArray) {
  const subOrderSnapshot = await db.collection("StoreOrders")
    .where("MainOrderId", "==", orderId)
    .where("StoreId", "==", storeId)
    .limit(1)
    .get();

  if (!subOrderSnapshot.empty) {
    // حفظ مرجع المستند وبياناته الحالية للوصول إليها داخل الترانزاكشن بـ ID مباشر
    subOrderRefsMap[storeId] = {
      ref: subOrderSnapshot.docs[0].ref,
      data: subOrderSnapshot.docs[0].data()
    };
  }
}



    
    // بدء تشغيل عملية تزامنية ذرية (Transaction) لضمان تنفيذ كل الخطوات معاً أو فشلها معاً لحماية الأموال
    const result = await db.runTransaction(async (transaction) => {
      
      // أ. قراءة مستند الطلب بشكل حي ومباشر من داخل الـ Transaction للتحقق من أحدث البيانات بالسيرفر
      const orderDoc = await transaction.get(orderRef);
      // إذا كان مستند الطلب غير موجود في قاعدة البيانات بالكامل
      if (!orderDoc.exists) {
        // نرفع خطأ يفيد بعدم العثور على الطلب ويوقف بقية المعاملات الماليّة
        throw new HttpsError("not-found", "الطلب المحدد غير موجود في سجلات النظام.");
      }

      // استخراج البيانات الفعلية للطلب على هيئة جافا سكريبت Object
      const orderData = orderDoc.data();
      // فحص أمان صارم: التأكد من أن حقل الـ UserId في الطلب يطابق تماماً الـ ID الخاص بالمستخدم الحالي
      if (orderData.UserId !== userId) {
        // إذا كانا غير متطابقين، يتم منع التلاعب وإيقاف العملية بخطأ انتهاك الصلاحيات
        throw new HttpsError("permission-denied", "لا تملك الصلاحية لتعديل أو إلغاء هذا الطلب.");
      }

      // استخراج مصفوفة المنتجات من داخل الطلب، وإذا كانت فارغة نضع مصفوفة فارغة بشكل افتراضي
      let items = orderData.Items || [];
      // متغير محاسبي لتجميع إجمالي المبالغ المستردة التي ستعود لمحفظة الزبون فوراً
      let totalRefundToUser = 0;
      // كائن (Object) فارغ لتجميع وتخزين المبالغ التي يجب سحبها من كل متجر (storeId) بناءً على حقوله
      let storesToUpdate = {}; 
      
      // مصفوفة نصية لحفظ أسماء المنتجات التي تم إلغاؤها فورياً لاستخدامها في الإشعارات
      let automaticallyCancelledItems = [];
      // مصفوفة نصية لحفظ أسماء المنتجات التي تم تحويلها لطلب مراجعة معلق للمسؤول
      let requestedForReviewItems = [];
      // [جديد]: مصفوفة لتجميع وتتبع معرفات المتاجر (storeId) التي تأثرت منتجاتها بطلب الإلغاء الحالي
      let affectedStoreIds = new Set();
      
      
      // ب. المرور بحلقة تكرار (Loop) على جميع المنتجات المتوفرة بداخل مصفوفة الطلب الأصلي
      items.forEach((item) => {
        // التحقق مما إذا كان المنتج الحالي في الحلقة متواصلاً مع القائمة المطلوبة للإلغاء من العميل
        if (itemIdsToCancel.includes(item.id)) {
          
          // تحويل سعر المنتج إلى رقم عشري آمن، ووضع 0 إذا واجهنا قيمة فارغة
          const itemPrice = Number(item.price || 0);
          // تحويل كمية المنتج المطلوبة إلى رقم، ووضع 1 بشكل افتراضي إن لم توجد
          const itemQuantity = Number(item.quantity || 1);
          // حساب المعادلة الحسابية الكلية للمنتج الحالي (السعر مضروباً في الكمية)
          const itemTotal = itemPrice * itemQuantity;
          // إضافة الـ storeId الخاص بالمنتج المتأثر إلى الـ Set لمنع التكرار
          affectedStoreIds.add(item.storeId);

          // --- [المسار الأول]: إذا كان المنتج ما زال بانتظار المراجعة (إلغاء تلقائي وفوري) ---
          if (item.itemStatus === "pending") {
            // إضافة القيمة المالية للمنتج الحالي إلى إجمالي رصيد استرداد الزبون
            totalRefundToUser += itemTotal;
            // تحديث حالة هذا المنتج بعينه بداخل المصفوفة إلى "ملغي"
            item.itemStatus = "cancelled";
            // إضافة اسم المنتج إلى قائمة الملغيات فورياً لإبلاغ العميل بها
            automaticallyCancelledItems.push(item.name);

            // استخراج معرف المتجر (storeId) الخاص بهذا المنتج بالتحديد
            const storeId = item.storeId; 
            // إذا لم نقم بإنشاء حصة ماليّة مسبقة لهذا المتجر بداخل كائن التحديث
            if (!storesToUpdate[storeId]) {
              // نقوم بتهيئتها بوضع القيمة الصفرية كبداية حسابية
              storesToUpdate[storeId] = 0;
            }
            // نجمع ونضيف القيمة المالية للمنتج الحالي إلى إجمالي المبالغ التي ستُخصم من هذا المتجر
            storesToUpdate[storeId] += itemTotal;
          } 
          
          // --- [المسار الثاني]: إذا كان المنتج قيد التحضير أو تم شحنه أو تسليمه (مسار المسؤول المعلق) ---
          else if (item.itemStatus === "accepted" || item.itemStatus === "shipped" || item.itemStatus === "delivered") {
            // حفظ الحالة الأصلية للمنتج قبل تعديلها لمعرفة المسار اللوجستي
            const previousStatus = item.itemStatus;
            // تحديث حالة المنتج داخل المصفوفة: إذا كان قيد التحضير يصبح "طلب إلغاء"، وإذا كان مشحوناً يصبح "طلب إرجاع"
            item.itemStatus = (previousStatus === "accepted") ? "cancellation_requested" : "return_requested";
            // إضافة اسم المنتج لقائمة طلبات المراجعة الموجهة للإدارة
            requestedForReviewItems.push(item.name);

            // إنشاء مستند جديد فريد وتلقائي بداخل كوليكشن طلبات مراجعة المسؤول (AdminReviewRequests)
            const reviewRequestRef = db.collection("AdminReviewRequests").doc();
            // وضع وحقن تفاصيل الطلب المعلق بداخل المستند الجديد لكي تظهر للأدمن في لوحة التحكم لاحقاً
            transaction.set(reviewRequestRef, {
              id: reviewRequestRef.id, // تخزين المعرف الفريد للطلب المعلق
              orderId: orderId, // ربطه بـ ID الطلب الرئيسي للرجوع إليه
              userId: userId, // ربطه بـ ID الزبون صاحب التذكرة
              storeId: item.storeId, // ربط المتجر المعني (storeId) بالطلب لمعرفة الخصم العائد عليه
              itemId: item.id, // تخزين الـ ID الفريد للمنتج بداخل السلة
              itemName: item.name, // تخزين اسم المنتج
              itemTotalAmount: itemTotal, // تخزين القيمة المالية المستهدفة بالمراجعة
              // تحديد نوع المعاملة: إما إلغاء تجهيز أو إرجاع مشحون بناءً على حالته السابقة
              requestType: (previousStatus === "accepted") ? "cancel_prepared_item" : "return_shipped_item",
              status: "pending_admin_approval", // وضع حالة أولية للطلب كـ (قيد انتظار موافقة المسؤول)
              createdAt: admin.firestore.FieldValue.serverTimestamp() // تسجيل توقيت الخادم لإنشاء الطلب
            });
          } 
          
          // في حال كان المنتج قد ألغي مسبقاً أو دخل في حالة غير مدعومة بالنظام
          else {
            // نرفع خطأ يفيد بتعارض البيانات لإيقاف المعاملة فوراً ومنع التكرار
            throw new HttpsError("failed-precondition", `المنتج [${item.name}] تمت معالجته أو إلغاؤه مسبقاً.`);
          }
        }
      });

      // بعد انتهاء الفحص بالكامل، إذا تبين أن مصفوفتي العمليات فارغتان تماماً (أي لم يتطابق أي منتج)
      if (automaticallyCancelledItems.length === 0 && requestedForReviewItems.length === 0) {
        // نوقف العملية لعدم وجود أي عناصر صالحة للإجراء بداخل المعطيات المرسلة
        throw new HttpsError("invalid-argument", "لم يتم معالجة أي عناصر، يرجى التحقق من حالة المنتجات.");
      }


      // --- [منطق تحديث الطلبات الفرعية - Sub Orders الجديد] ---
      // تحويل الـ Set إلى مصفوفة عادية للمرور على المتاجر المتأثرة واحداً تلو الآخر

      for (const storeId of storeIdsArray) {
        // البحث عن مستند الطلب الفرعي الذي يربط هذا الطلب الرئيسي بـ storeId الحالي للمتجر
        const subOrderInfo = subOrderRefsMap[storeId];

        // جلب المستند الفرعي من القاعدة تزامناً داخل الـ Transaction
        const subOrderSnapshot = await transaction.get(subOrderQuery);

        // إذا تم العثور على الطلب الفرعي المرتبط بالمتجر
        if (subOrderInfo) {
          const subOrderDoc = subOrderSnapshot.docs[0];
          const subOrderRef = subOrderDoc.ref;
          const subOrderData = subOrderDoc.data();

          // جلب مصفوفة المنتجات الخاصة بهذا المتجر فقط من الطلب الفرعي
          let subOrderItems = subOrderData.Items || [];
          let subOrderRefundAmount = 0;

          // تحديث حالة المنتجات داخل الطلب الفرعي بناءً على التحديثات التي تمت في الطلب الرئيسي
          subOrderItems = subOrderItems.map(subItem => {
            // البحث عن نفس المنتج في المصفوفة العامة الكبيرة المحدثة للطلب الرئيسي
            const updatedItem = items.find(mainItem => mainItem.id === subItem.id);
            if (updatedItem) {
              // إذا كان حالة المنتج الجديد ملغى فورياً، نحسب قيمته لخصمها من إجمالي الطلب الفرعي
              if (updatedItem.itemStatus === "cancelled" && subItem.itemStatus === "pending") {
                const price = Number(subItem.price || 0);
                const qty = Number(subItem.quantity || 1);
                subOrderRefundAmount += (price * qty);
              }
              // نسخ الحالة المحدثة (cancelled / cancellation_requested / return_requested) إلى الطلب الفرعي
              subItem.itemStatus = updatedItem.itemStatus;
            }
            return subItem;
          });

          // فحص هل أصبحت جميع منتجات هذا المتجر بالتحديد في الطلب الفرعي ملغاة بالكامل؟
          const allSubItemsCancelled = subOrderItems.every(subItem => subItem.itemStatus === "cancelled");
          // حساب إجمالي المبلغ الجديد المتبقي لهذا المتجر في طلبه الفرعي
          const newSubTotal = Number(subOrderData.totalAmount || 0) - subOrderRefundAmount;

          // تحديث مستند الطلب الفرعي الخاص بالمتجر مباشرة بالحالات والقيم الجديدة ليعرضها في تطبيق المتجر فوراً
          transaction.update(subOrderRef, {
            Items: subOrderItems,
            totalAmount: newSubTotal < 0 ? 0 : newSubTotal,
            // إذا ألغيت منتجات المتجر كلها، تتحول حالة طلبه الفرعي لـ cancelled، وإلا يحافظ على حالته الحالية (مثل shipped)
            Status: allSubItemsCancelled ? "cancelled" : (subOrderData.Status || "pending"),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      }
      // --- [نهاية منطق تحديث الطلبات الفرعية] ---



      // ج. [منطق معالجة تكلفة التوصيل المحاسبي]: استخراج رسوم التوصيل وتحويلها لرقم
      const shippingFee = Number(orderData.ShippingAmount || 0);
      // فحص منطقي: هل أصبحت جميع عناصر الطلب الكلية حالتها ملغاة (cancelled) الآن؟
      const allItemsCancelled = items.every(item => item.itemStatus === "cancelled");
      // فحص منطقي: هل هناك أي منتج آخر بداخل الطلب تم شحنه أو تسليمه للعميل مسبقاً؟
      const hasAnyShippedProduct = items.some(item => item.itemStatus === "shipped" || item.itemStatus === "delivered");

      // متغير لتتبع كم من رسوم الشحن سنعيده للزبون في محفظته
      let shippingFeeRefunded = 0;

      // إذا كانت جميع المنتجات بلا استثناء أصبحت ملغاة بالكامل
      if (allItemsCancelled) {
        // إذا تبين أن هناك شحنات سابقة خرجت واستلمت بالفعل وتكلفت النقل للعميل
        if (hasAnyShippedProduct) {
          // رسوم التوصيل استُهلكت في الرحلة الأولى، وبالتالي لا تُرد للزبون ويتم تصفير قيمة شحن المرتجع
          shippingFeeRefunded = 0; 
        } else {
          // الطلب ألغي بالكامل وهو في مرحلة الانتظار قبل تحرك أي مندوب، بالتالي نرد الشحن بالكامل للزبون
          totalRefundToUser += shippingFee;
          // تسجيل قيمة رسوم الشحن المستردة لحفظها في تدوين المعاملة المالية
          shippingFeeRefunded = shippingFee;
        }
      }

      // د. قراءة مستند الزبون لقراءة المحفظة الحالية قبل التعديل لضمان التزامن
      const userDoc = await transaction.get(userRef);
      
      // إذا كانت القيمة المالية المستردة فورياً أكبر من صفر (أي هناك منتجات ألغيت تلقائياً)
      if (totalRefundToUser > 0) {
        // قراءة الرصيد الحالي للزبون وتحويله لرقم
        const currentBuf = Number(userDoc.data().walletBalance || 0);
        // تحديث مستند الزبون في القاعدة بالرصيد الجديد (القديم + إجمالي المسترد الفوري)
        transaction.update(userRef, {
          walletBalance: currentBuf + totalRefundToUser
        });

        // إنشاء مستند جديد فريد لعملية مالية مسجلة بكوليكشن المعاملات الخاص بالزبون كـ Ledger محاسبي
        const userLogRef = db.collection("User").doc(userId).collection("Transactions").doc();
        // تدوين تفاصيل شحن المحفظة للزبون للشفافية المالية
        transaction.set(userLogRef, {
          id: userLogRef.id, // معرف العملية المالية
          amount: totalRefundToUser, // المبلغ المضاف
          type: "partial_refund", // نوع الحركة: استرداد جزئي
          title: "استرداد تلقائي لمنتجات معلقة", // عنوان الحركة المعروض بالتطبيق
          description: `تم استرداد مبلغ المنتجات الملغاة فورياً للطلب #${orderId.substring(0, 6)}. (شامل التوصيل المسترد: ${shippingFeeRefunded} LIS`,
          createdAt: admin.firestore.FieldValue.serverTimestamp() // توقيت السيرفر الرسمي للحركة الماليّة
        });

        // هـ. [الحركة العكسية للتجار]: المرور على كوليكشن المتاجر المطلوب الخصم منها بناءً على مبيعاتها المُلغاة فوريّاً
        for (const [storeId, amountToDeduct] of Object.entries(storesToUpdate)) {
          // جلب المرجع الخاص بالمتجر الحالي في الحلقة باستخدام الحقل الصحيح storeId
          const storeRef = db.collection("Stores").doc(storeId);
          // قراءة مستند المتجر بداخل الـ Transaction لقراءة الرصيد الراهن قبل الخصم منه
          const storeDoc = await transaction.get(storeRef);
          
          // إذا كان مستند المتجر مسجلاً وموجوداً بالفعل بالسيستم
          if (storeDoc.exists) {
            const storeData = storeDoc.data() || {};
            // قراءة رصيد محفظة المتجر الحالي وتحويله لرقم
            const currentPending = Number((storeData.wallet && storeData.wallet.pendingBalance) || 0);
            // تحديث مستند المتجر بخصم القيمة المالية المستردة للعميل من رصيده الراهن
            // حساب القيمة الجديدة بعد الخصم
            let newPending = currentPending - amountToDeduct;
            // حماية لمنع الرصيد المعلق من الهبوط تحت الصفر
            if (newPending < 0) newPending = 0;

            // [الأمان المطلق]: تحديث حقل pendingBalance فقط دون لمس أو جلب باقي الخريطة
            // باستخدام السلسلة النصية 'wallet.pendingBalance' يدرك الفايرستور أنك تريد تعديل هذا الفرع وتترك الباقي تماماً كما هو
            transaction.update(storeRef, {
              'wallet.pendingBalance': newPending
            });

            // إنشاء مستند عملية ماليّة بداخل كوليكشن المعاملات الفرعي للـ Store لتوثيق الخصم المحاسبي
            const storeLogRef = db.collection("Stores").doc(storeId).collection("Transactions").doc();
            // تدوين تفاصيل العملية السالبة بداخل محفظة المتجر للمراجعة الأسبوعية أو الشهرية
            transaction.set(storeLogRef, {
              id: storeLogRef.id, // معرف العملية الفريد للتاجر
              amount: -amountToDeduct, // وضع القيمة بإشارة سالبة لتوضيح أنها سحب أو خصم مالي
              type: "order_item_cancelled", // نوع الحركة: إلغاء عنصر من الطلب
              title: "خصم إلغاء فوري من زبون", // العنوان المعروض للتاجر بلوحته
              description: `سحب مالي لإلغاء تلقائي قبل التجهيز للطلب رقم #${orderId}.`,
              createdAt: admin.firestore.FieldValue.serverTimestamp() // وقت الخصم الفعلي من السيرفر
            });
          }
        }
      }

      // و. [تحديث مستند الطلب الرئيسي]: حساب القيمة المالية الإجمالية الجديدة المتبقية على الطلب
      const newTotalAmount = Number(orderData.totalAmount || 0) - totalRefundToUser;
      // تحديث مستند الطلب الأصلي بضخ المصفوفة الجديدة المحدثة بحالاتها (الملغاة والمعلقة معاً) والقيم المالية الجديدة
      transaction.update(orderRef, {
        items: items, // مصفوفة العناصر المحدثة بالحالات الجديدة (cancelled أو cancellation_requested أو return_requested)
        totalAmount: newTotalAmount < 0 ? 0 : newTotalAmount, // وضع إجمالي مالي جديد للطلب مع حمايته من النزول تحت الصفر
        // تحديث حالة الطلب الكلية: إذا ألغيت كل العناصر يصبح الطلب كله cancelled، وإلا يبقى بحالته السابقة
        Status: allItemsCancelled ? "cancelled" : (orderData.Status || "pending"),
        updatedAt: admin.firestore.FieldValue.serverTimestamp() // تسجيل توقيت آخر تعديل طرأ على الطلب
      });

      // إرجاع مصفوفة النتائج والمعطيات الحيوية المستخرجة من الـ Transaction لاستخدامها خارجاً في نظام الإشعارات
      return {
        success: true, // تأكيد نجاح العملية
        refundedAmount: totalRefundToUser, // ترحيل القيمة المستردة للزبون
        allItemsCancelled: allItemsCancelled, // ترحيل ما إذا كان الإلغاء كلياً للطلب أم لا
        automaticallyCancelledItems: automaticallyCancelledItems, // ترحيل قائمة الملغيات فوريّاً
        requestedForReviewItems: requestedForReviewItems, // ترحيل قائمة المنتجات المعلقة للمراجعة
        fcmToken: userDoc.data().fcmToken || null // جلب توكن الإشعارات (FCM Token) الخاص بالزبون المخزن بمستنده
      };
    });

    // 3. [نظام الإشعارات اللحظية الحية (FCM)]: التحقق من وجود توكن صالح للزبون لإرسال الـ Push Notification
    if (result.fcmToken) {
      // متغير نصي لبناء رسالة إشعار ذكية ودقيقة تناسب الإجراءات التي تمت بالسيرفر فعلياً
      let notificationBody = "";
      
      // الحالة الأولى: إذا حدث إلغاء فوري لبعض المنتجات وتم رفع طلب مراجعة للمسؤول للمنتجات الأخرى في نفس الوقت
      if (result.automaticallyCancelledItems.length > 0 && result.requestedForReviewItems.length > 0) {
        notificationBody = `تم إلغاء بعض المنتجات واسترداد ${result.refundedAmount} د.أ، وتم تحويل الباقي للمسؤول للمراجعة.`;
      } 
      // الحالة الثانية: إذا كانت كل المنتجات المطلوبة تم إلغاؤها تلقائياً بالكامل دون الحاجة للمسؤول
      else if (result.automaticallyCancelledItems.length > 0) {
        notificationBody = `تم إلغاء المنتجات المحددة وإعادة مبلغ ${result.refundedAmount} د.أ إلى محفظتك بنجاح.`;
      } 
      // الحالة الثالثة: إذا كانت كل المنتجات جُهزت أو شُحنت وتحولت بالكامل لطلبات مراجعة معلقة للإدارة
      else {
        notificationBody = `تم إرسال طلب إلغاء/إرجاع المنتجات للمسؤول للمراجعة وسيتم الرد عليك فور فحصها.`;
      }

      // صياغة الـ Payload الرسمي المتوافق مع بروتوكولات Google Cloud Messaging الحديثة لإرساله للهاتف
      const payload = {
        token: result.fcmToken, // توكن جهاز العميل المستهدف
        notification: {
          // عنوان الإشعار: يتغير ديناميكياً إذا كان الإلغاء شاملاً لكل الطلب أم مجرد أجزاء وعناصر منه
          title: result.allItemsCancelled ? "تم إلغاء الطلب بالكامل 🛑" : "تحديث حالة إلغاء منتجات 🛍️",
          body: notificationBody // نص الإشعار الذكي الذي تم صياغته في الأسطر السابقة
        },
        data: { 
          click_action: "FLUTTER_NOTIFICATION_CLICK", // توجيه فلوتر لفتح التطبيق عند النقر على الإشعار
          type: "partial_refund_update", // نوع الإشعار البرمجي لكي يستطيع كود فلوتر توجيهه لصفحة معينة
          orderId: orderId // تمرير معرف الطلب بداخل البيانات المخفية للإشعار
        }
      };
      
      // استدعاء موديول بروتوكول إرسال الإشعار الفعلي عبر السحابة وتجنب شل أو تعطيل كود السيرفر في حال فشله
      await admin.messaging().send(payload).catch(e => console.error("فشل إرسال إشعار FCM للمستخدم:", e));
    }

    // إرجاع الرد النهائي والناجح لكود فلوتر لإبلاغ الـ Controller بانتهاء العملية الإجمالية وتحديث الـ UI
    return { 
      status: "success", // تأكيد الحالة الناجحة
      refundedAmount: result.refundedAmount, // ترحيل المبلغ الإجمالي المعاد للمحفظة للزبون
      cancelledCount: result.automaticallyCancelledItems.length, // عدد العناصر التي ألغيت فورياً
      reviewCount: result.requestedForReviewItems.length // عدد العناصر التي تحولت لمراجعة الإدارة
    };

  } catch (error) {
    // طباعة تفاصيل الخطأ الكارثي أو البرمجي بداخل الـ Logs الخاصة بـ Firebase Console للمطور ومراجعتها
    console.error("خطأ كارثي حدث بداخل دالة cancelSpecificItems المحدثة:", error);
    
    // إذا كان الخطأ من الأخطاء التي قمنا بصياغتها يدوياً كـ HttpsError بداخل الكود أعلاه
    if (error instanceof HttpsError) {
      // نقوم بإعادة تمريره فوراً كما هو لكي يلتقطه الـ Controller في فلوتر ويعرضه للزبون في سناك بار
      throw error;
    }
    
    // إذا كان الخطأ غير متوقع (مثل سقوط سيرفر أو مشكلة باتصال قاعدة البيانات الداخلي)
    throw new HttpsError(
      "internal", // تصنيفه كخطأ خادم داخلي
      error.message || "حدث خطأ غير متوقع بداخل الخادم أثناء معالجة إلغاء السلة الجزئي." // إرسال نص عام لحماية الـ Stack trace
    );
  }
});*/



/*
exports.processAdminItemCancellation = onCall(async (request) => {
    // 1. التحقق من صلاحيات الأمان
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لتنفيذ هذه العملية.");
    }

    const { storeOrderId, productId, action, adminNotes } = request.data;

    // التحقق من المدخلات الأساسية
    if (!storeOrderId || !productId || !action) {
        throw new HttpsError("invalid-argument", "المعطيات ناقصة. يجب تزويد (storeOrderId, productId, action).");
    }

    if (!["approve", "reject"].includes(action)) {
        throw new HttpsError("invalid-argument", "العملية (action) يجب أن تكون إما 'approve' أو 'reject'.");
    }

    try {
        const storeOrderRef = admin.firestore().collection("StoreOrders").doc(storeOrderId);
        
        // استخدام Transaction لضمان ذرية وتناسق البيانات ومنع التداخل المالي
        const result = await admin.firestore().runTransaction(async (transaction) => {
            const storeOrderDoc = await transaction.get(storeOrderRef);

            if (!storeOrderDoc.exists) {
                throw new HttpsError("not-found", "لم يتم العثور على مستند الطلب الفرعي للمتجر.");
            }

            const storeOrderData = storeOrderDoc.data();
            const mainOrderId = storeOrderData.MainOrderId;
            const storeId = storeOrderData.StoreId;
            const userId = storeOrderData.UserId;

            // تحديد اسم مصفوفة العناصر (حروف كبيرة أم صغيرة) داخل الطلب الفرعي
            const subItemsKey =  "Items" ;
            let subItems = [...(storeOrderData[subItemsKey] || [])];

            const subItemIndex = subItems.findIndex(item => (item.productId === productId) || (item.id === productId));
            if (subItemIndex === -1) {
                throw new HttpsError("not-found", "المنتج المطلوب غير موجود ضمن هذا الطلب الفرعي.");
            }

            const targetItem = subItems[subItemIndex];
            const currentStatus = targetItem.itemStatus;

            // حصر الدالة في الحالتين المطلوبتين فقط من قبلك
            if (currentStatus !== "cancellation_requested" && currentStatus !== "return_requested") {
                return { success: false, message: `هذه الدالة تعالج فقط طلبات الإلغاء والإرجاع. الحالة الحالية للمنتج: ${currentStatus}` };
            }

            const storeRef = admin.firestore().collection("Stores").doc(storeId);
            const storeDoc = await transaction.get(storeRef);
            const commRate = storeDoc.exists ? (storeDoc.data().commissionRate || 2) : 2;

            let totalGrossToReturnToUser = 0;
            let totalNetToDeductFromStore = 0;
            let isCancellation = currentStatus === "cancellation_requested";

            // ==========================================
            // 📌 القسم الأول: معالجة حالة طلب الإلغاء (cancellation_requested)
            // ==========================================
            if (isCancellation) {
                if (action === "approve") {
                    targetItem.itemStatus = "canceled"; // تغيير الحالة إلى ملغي

                    // الحسبة المالية لإرجاع المستحقات (إذا لم يتم إرجاعها سابقاً)
                    if (!targetItem.refunded) {
                        totalGrossToReturnToUser = (parseFloat(targetItem.price) || 0) * (parseInt(targetItem.Quantity || targetItem.quantity) || 1);
                        totalNetToDeductFromStore = totalGrossToReturnToUser * (1 - (commRate / 100));
                        targetItem.refunded = true;
                    }
                } else if (action === "reject") {
                    targetItem.itemStatus = "accepted"; // في حالة الرفض يعود المنتج إلى "جاري التجهيز"
                }
            }
            // ==========================================
            // 📌 القسم الثاني: معالجة حالة طلب الإرجاع (return_requested)
            // ==========================================
            else { 
                if (action === "approve") {
                    targetItem.itemStatus = "returned"; // تحويل الحالة إلى مرجع من قبل الزبون

                    if (!targetItem.refunded) {
                        totalGrossToReturnToUser = (parseFloat(targetItem.price) || 0) * (parseInt(targetItem.Quantity || targetItem.quantity) || 1);
                        totalNetToDeductFromStore = totalGrossToReturnToUser * (1 - (commRate / 100));
                        targetItem.refunded = true;
                    }
                } else if (action === "reject") {
                    targetItem.itemStatus = "delivered"; // في حالة الرفض يعود لوضعه الطبيعي "تم التسليم" دون أي تغيير بالبيانات
                }
            }

            targetItem.adminCancelNotes = adminNotes || "";

            // 1. تحديث المصفوفة داخل مستند الطلب الفرعي للمتجر (StoreOrders)
            transaction.update(storeOrderRef, { [subItemsKey]: subItems });

            // 2. تحديث ومزامنة المنتج والملغ الكلي داخل الطلب الرئيسي للزبون (Orders)
            if (mainOrderId) {
                const mainOrderRef = admin.firestore().collection("Orders").doc(mainOrderId);
                const mainOrderDoc = await transaction.get(mainOrderRef);

                if (mainOrderDoc.exists) {
                    const mainOrderData = mainOrderDoc.data();
                    const mainItemsKey =  "Items" ;
                    let mainItems = [...(mainOrderData[mainItemsKey] || [])];

                    mainItems = mainItems.map(mItem => {
                        if (mItem.productId === productId) {
                            return { 
                                ...mItem, 
                                itemStatus: targetItem.itemStatus, 
                                refunded: targetItem.refunded || mItem.refunded || false,
                                adminCancelNotes: adminNotes || ""
                            };
                        }
                        return mItem;
                    });

                    const mainUpdatePayload = { [mainItemsKey]: mainItems };

                    // إذا تمت الموافقة، يتم زيادة حقل المبالغ المسترجعة في الطلب الرئيسي حسب نوع العملية
                    if (action === "approve" && totalGrossToReturnToUser > 0) {
                        if (isCancellation) {
                            mainUpdatePayload.CanceledAmount = admin.firestore.FieldValue.increment(totalGrossToReturnToUser);
                        } else {
                            mainUpdatePayload.ReturnedAmount = admin.firestore.FieldValue.increment(totalGrossToReturnToUser);
                        }
                    }

                    transaction.update(mainOrderRef, mainUpdatePayload);
                }
            }

            // 3. إجراء العمليات المالية وتسجيل الحركات (في حال وافق الأدمن وكان هناك مبالغ مسترجعة)
            if (action === "approve" && totalGrossToReturnToUser > 0) {
                const userRef = admin.firestore().collection("User").doc(userId);
                
                // أ. زيادة رصيد محفظة الزبون بالمبلغ الكامِل
                transaction.update(userRef, {
                    walletBalance: admin.firestore.FieldValue.increment(totalGrossToReturnToUser)
                });

                // ب. خصم المبلغ الصافي (بعد العموله) من محفظة/رصيد التاجر المعلق
                transaction.update(storeRef, {
                    "wallet.pendingBalance": admin.firestore.FieldValue.increment(-totalNetToDeductFromStore)
                });

                // ج. تسجيل العملية المالية في سجل حركات الزبون
                const userTransRef = userRef.collection("Transactions").doc();
                transaction.set(userTransRef, {
                    id: userTransRef.id,
                    amount: totalGrossToReturnToUser,
                    type: isCancellation ? "cancel_refund" : "return_refund",
                    status: "completed",
                    date: admin.firestore.FieldValue.serverTimestamp(),
                    description: isCancellation 
                        ? `مرتجع لإلغاء منتج: ${targetItem.Title || targetItem.name}`
                        : `مرتجع لإرجاع منتج: ${targetItem.Title || targetItem.name}`,
                    orderId: mainOrderId,
                    storeOrderId: storeOrderId,
                    productId: productId
                });

                // د. تسجيل العملية المالي في سجل حركات المتجر العام
                const storeTransRef = admin.firestore().collection("Transactions").doc();
                transaction.set(storeTransRef, {
                    storeId: storeId,
                    orderId: storeOrderId,
                    amount: -totalNetToDeductFromStore,
                    type: isCancellation ? "cancel_refund" : "return_refund",
                    status: "completed",
                    productId: productId,
                    productName: targetItem.Title || targetItem.name,
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }

            return {
                success: true,
                action,
                isCancellation,
                userId,
                storeId,
                productName: targetItem.Title || targetItem.name,
                amount: totalGrossToReturnToUser,
                message: "تمت معالجة العنصر بنجاح داخل الترانزاكشن."
            };
        });

        // 4. فحص هل أصبحت كل حركات المنتجات ملغية/مرفوضة لتحديث حالة الطلب الكلي والفرعي (خارج الترانزاكشن لسلامة الأداء الكلي)
        if (result.success && result.isCancellation && result.action === "approve") {
            const freshStoreOrderSnap = await storeOrderRef.get();
            const freshStoreOrderData = freshStoreOrderSnap.data();
            const itemsKey = freshStoreOrderData.Items !== undefined ? "Items" : "items";
            const currentSubItems = freshStoreOrderData[itemsKey] || [];

            // فحص هل كل العناصر في هذا الطلب الفرعي أصبحت canceled أو مسبقاً rejected
            const allItemsCanceledOrRejected = currentSubItems.every(item => ["canceled", "rejected"].includes(item.itemStatus));

            if (allItemsCanceledOrRejected) {
                // تحديث حالة الطلب الفرعي بالكامل ليصبح ملغي
                await storeOrderRef.update({ Status: "rejected" });

                // الآن نفحص الطلب الرئيسي الكلي المرتبط بكل المتاجر
                const mainOrderId = freshStoreOrderData.MainOrderId;
                if (mainOrderId) {
                    const allSubOrdersSnapshot = await admin.firestore()
                        .collection("StoreOrders")
                        .where("MainOrderId", "==", mainOrderId)
                        .get();

                    // إذا كانت كافة الطلبات الفرعية لجميع المتاجر المرتبطة بهذا الطلب حالتهم الآن "rejected"
                    const allStoresRejected = allSubOrdersSnapshot.docs.every(doc => doc.data().Status === "rejected");
                    
                    if (allStoresRejected) {
                        await admin.firestore().collection("Orders").doc(mainOrderId).update({ Status: "rejected" });
                    }
                }
            }
        }

        // 5. بناء وإرسال الإشعارات لكل جهة (الزبون والمتجر) بناءً على النتيجة
        if (result.success && result.userId) {
            const userRef = admin.firestore().collection("User").doc(result.userId);
            const userSnap = await userRef.get();
            const fcmToken = userSnap.data()?.fcmToken;

            const storeSnap = await admin.firestore().collection("Stores").doc(result.storeId).get();
            const storeFcmToken = storeSnap.data()?.fcmToken; // تأكد من وجود توكن للمتجر إذا كنت ترسل لهم fcm

            let uTitle = "", uBody = "", uType = "";
            let sTitle = "", sBody = "";

            if (result.isCancellation) {
                // إشعارات الإلغاء
                if (result.action === "approve") {
                    uTitle = "قبول طلب الإلغاء 🛍️";
                    uBody = `وافقت الإدارة على إلغاء [${result.productName}] وتم رد ${result.amount} شيكل لمحفظتك.`;
                    uType = "ITEM_CANCEL_APPROVED";

                    sTitle = "إلغاء منتج من طلب 🛑";
                    sBody = `قامت الإدارة بالموافقة على إلغاء منتج [${result.productName}] من الطلب الخاص بك بناء على رغبة الزبون.`;
                } else {
                    uTitle = "تحديث بخصوص طلب الإلغاء ⚠️";
                    uBody = `تم رفض طلب إلغاء منتج [${result.productName}] من قِبل الإدارة وسيتم استكمال تجهيزه وشحنه لك.`;
                    uType = "ITEM_CANCEL_REJECTED";
                }
            } else {
                // إشعارات الإرجاع
                if (result.action === "approve") {
                    uTitle = "قبول طلب الإرجاع 🔄";
                    uBody = `وافقت الإدارة على إرجاع منتج [${result.productName}] وتم إيداع ${result.amount} شيكل في محفظتك.`;
                    uType = "ITEM_RETURN_APPROVED";

                    sTitle = "مرتجع من زبون 🔄";
                    sBody = `تمت الموافقة من قِبل الإدارة على إرجاع منتج [${result.productName}] وتم تسوية الحساب المالي للمتجر.`;
                } else {
                    uTitle = "تحديث بخصوص طلب الإرجاع ⚠️";
                    uBody = `تم رفض طلب إرجاع منتج [${result.productName}] من قِبل الإدارة.`;
                    uType = "ITEM_RETURN_REJECTED";
                }
            }

            // أ. حفظ الإشعار للزبون في الفايرستور
            await userRef.collection("Notifications").add({
                title: uTitle, body: uBody, type: uType, mainOrderId: mainOrderId || "", createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // ب. إرسال FCM للزبون
            if (fcmToken) {
                await admin.messaging().send({
                    token: fcmToken, notification: { title: uTitle, body: uBody }, data: { orderId: mainOrderId || "", type: uType }
                }).catch(e => console.error("Customer FCM Error:", e));
            }

            // ج. إرسال FCM للمتجر في حالة الموافقة (Approve) لإعلامه بالتحديث والخصم المالي
            if (result.action === "approve" && storeFcmToken) {
                await admin.messaging().send({
                    token: storeFcmToken, notification: { title: sTitle, body: sBody }, data: { storeOrderId: storeOrderId, type: "STORE_FINANCIAL_UPDATE" }
                }).catch(e => console.error("Store FCM Error:", e));
            }
        }

        return { success: true, message: "تم إنهاء معالجة الطلب وتحديث الحسابات والإشعارات بنجاح." };

    } catch (error) {
        console.error("🔥 Error in processAdminItemCancellation:", error);
        if (error instanceof HttpsError) throw error;
        throw new HttpsError("internal", "حدث خطأ داخلي أثناء معالجة الطلب.");
    }
});*/





/*
exports.processAdminItemCancellation = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً لتنفيذ هذه العملية.");
    }

    const { storeOrderId, productId, action, adminNotes } = request.data;

    if (!storeOrderId || !productId || !action) {
        throw new HttpsError("invalid-argument", "المعطيات ناقصة. يجب تزويد (storeOrderId, productId, action).");
    }

    if (!["approve", "reject"].includes(action)) {
        throw new HttpsError("invalid-argument", "العملية (action) يجب أن تكون إما 'approve' أو 'reject'.");
    }

    try {
        const storeOrderRef = admin.firestore().collection("StoreOrders").doc(storeOrderId);
        
        const result = await admin.firestore().runTransaction(async (transaction) => {
            const storeOrderDoc = await transaction.get(storeOrderRef);

            if (!storeOrderDoc.exists) {
                throw new HttpsError("not-found", "لم يتم العثور على مستند الطلب الفرعي للمتجر.");
            }

            const storeOrderData = storeOrderDoc.data();
            const mainOrderId = storeOrderData.MainOrderId;
            const storeId = storeOrderData.StoreId;
            const userId = storeOrderData.UserId;

            const subItemsKey = storeOrderData.Items !== undefined ? "Items" : "items";
            let subItems = [...(storeOrderData[subItemsKey] || [])];

            const subItemIndex = subItems.findIndex(item => (item.productId === productId) || (item.id === productId));
            if (subItemIndex === -1) {
                throw new HttpsError("not-found", "المنتج المطلوب غير موجود ضمن هذا الطلب الفرعي.");
            }

            const targetItem = subItems[subItemIndex];
            const currentStatus = targetItem.itemStatus;

            // --- التحقق من الحالات المدعومة للمراجعة الإدارية ---
            const validStatuses = ["pending_admin_cancel", "cancellation_requested", "return_requested"];
            if (!validStatuses.includes(currentStatus)) {
                return { success: false, message: `هذا المنتج ليس في حالة معلقة تطلب تدخل الإدارة. حالته الحالية: ${currentStatus}` };
            }

            const storeRef = admin.firestore().collection("Stores").doc(storeId);
            const storeDoc = await transaction.get(storeRef);
            const commRate = storeDoc.exists ? (storeDoc.data().commissionRate || 2) : 2;

            let totalGrossToReturnToUser = 0;
            let totalNetToDeductFromStore = 0;
            let financialActionType = "cancel_refund"; // النوع الافتراضي للحركة المالية

            // --- أولاً: في حالة موافقة الأدمن (Approve) ---
            if (action === "approve") {
                if (currentStatus === "return_requested") {
                    targetItem.itemStatus = "returned"; // تحويل الحالة إلى مرجع بعد الاستلام
                    financialActionType = "return_refund";
                } else {
                    targetItem.itemStatus = "canceled"; // تحويل الحالة إلى ملغي قبل الشحن
                    financialActionType = "cancel_refund";
                }

                // الحسبة المالية لإرجاع المستحقات (شرط عدم الإرجاع المسبق)
                if (!targetItem.refunded) {
                    totalGrossToReturnToUser = (parseFloat(targetItem.price) || 0) * (parseInt(targetItem.Quantity || targetItem.quantity) || 1);
                    totalNetToDeductFromStore = totalGrossToReturnToUser * (1 - (commRate / 100));
                    targetItem.refunded = true; 
                }
            } 
            // --- ثانياً: في حالة رفض الأدمن (Reject) ---
            else if (action === "reject") {
                // إذا رفض الإرجاع يعود المستند لحالته الأصلية "delivered"
                if (currentStatus === "return_requested") {
                    targetItem.itemStatus = "delivered";
                } else {
                    // إذا رفض الإلغاء يعود لحالته الطبيعية قيد التجهيز أو القبول لكي يكمل المتجر عمله
                    targetItem.itemStatus = "accepted"; 
                }
            }

            targetItem.adminCancelNotes = adminNotes || "";

            // 1. تحديث الطلب الفرعي (StoreOrders)
            transaction.update(storeOrderRef, { [subItemsKey]: subItems });

            // 2. مزامنة وتحديث الطلب الرئيسي الكلي (Orders)
            if (mainOrderId) {
                const mainOrderRef = admin.firestore().collection("Orders").doc(mainOrderId);
                const mainOrderDoc = await transaction.get(mainOrderRef);

                if (mainOrderDoc.exists) {
                    const mainOrderData = mainOrderDoc.data();
                    const mainItemsKey = mainOrderData.Items !== undefined ? "Items" : "items";
                    let mainItems = [...(mainOrderData[mainItemsKey] || [])];

                    mainItems = mainItems.map(mItem => {
                        if ((mItem.productId === productId) || (mItem.id === productId)) {
                            return { 
                                ...mItem, 
                                itemStatus: targetItem.itemStatus, 
                                refunded: targetItem.refunded || mItem.refunded || false,
                                adminCancelNotes: adminNotes || ""
                            };
                        }
                        return mItem;
                    });

                    const mainUpdatePayload = { [mainItemsKey]: mainItems };

                    // تحديث حقول الإحصاء المالي الكلي في الطلب الرئيسي بناء على نوع العملية
                    if (action === "approve" && totalGrossToReturnToUser > 0) {
                        if (financialActionType === "return_refund") {
                            mainUpdatePayload.ReturnedAmount = admin.firestore.FieldValue.increment(totalGrossToReturnToUser);
                        } else {
                            mainUpdatePayload.CanceledAmount = admin.firestore.FieldValue.increment(totalGrossToReturnToUser);
                        }
                    }

                    transaction.update(mainOrderRef, mainUpdatePayload);
                }
            }

            // 3. إدارة التعديلات المالية والأرصدة بالفايرستور
            if (action === "approve" && totalGrossToReturnToUser > 0) {
                const userRef = admin.firestore().collection("User").doc(userId);
                
                // إضافة المبلغ بالكامل لمحفظة الزبون
                transaction.update(userRef, {
                    walletBalance: admin.firestore.FieldValue.increment(totalGrossToReturnToUser)
                });

                // خصم الصافي من الرصيد المعلق للمتجر (Pending Balance)
                transaction.update(storeRef, {
                    "wallet.pendingBalance": admin.firestore.FieldValue.increment(-totalNetToDeductFromStore)
                });

                // تسجيل الحركات المالية في كولكشن الترانزاكشنز للزبون وللمتجر
                const userTransRef = userRef.collection("Transactions").doc();
                transaction.set(userTransRef, {
                    id: userTransRef.id,
                    amount: totalGrossToReturnToUser,
                    type: financialActionType,
                    status: "completed",
                    date: admin.firestore.FieldValue.serverTimestamp(),
                    description: financialActionType === "return_refund" 
                        ? `مرتجع لإرجاع منتج مستلم: ${targetItem.Title || targetItem.name}`
                        : `مرتجع لإلغاء عنصر: ${targetItem.Title || targetItem.name}`,
                    orderId: mainOrderId,
                    storeOrderId: storeOrderId,
                    productId: productId
                });

                const storeTransRef = admin.firestore().collection("Transactions").doc();
                transaction.set(storeTransRef, {
                    storeId: storeId,
                    orderId: storeOrderId,
                    amount: -totalNetToDeductFromStore,
                    type: financialActionType,
                    status: "completed",
                    productId: productId,
                    productName: targetItem.Title || targetItem.name,
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }

            return {
                success: true,
                action,
                currentStatus,
                userId,
                productName: targetItem.Title || targetItem.name,
                amount: totalGrossToReturnToUser,
                message: action === "approve" 
                    ? (financialActionType === "return_refund" ? "تم قبول طلب الإرجاع بنجاح وضخ المبلغ للمحفظة." : "تم قبول طلب الإلغاء بنجاح وضخ المبلغ للمحفظة.")
                    : "تم رفض الطلب من قِبل الإدارة وإعادة المنتج لوضعه الطبيعي في الدورة التشغيلية."
            };
        });

        // 4. بناء وإرسال الإشعارات اللحظية FCM بناء على الحالة السابقة والقرار
        if (result.success && result.userId) {
            const userRef = admin.firestore().collection("User").doc(result.userId);
            const userSnap = await userRef.get();
            const fcmToken = userSnap.data()?.fcmToken;

            let notifTitle = "";
            let notifBody = "";
            let notifType = "";

            if (result.action === "approve") {
                if (result.currentStatus === "return_requested") {
                    notifTitle = "قبول طلب الإرجاع 🔄";
                    notifBody = `وافقت الإدارة على إرجاع منتج [${result.productName}]. وبناء عليه تم رد ${result.amount} شيكل لمحفظتك.`;
                    notifType = "ITEM_RETURN_APPROVED";
                } else {
                    notifTitle = "قبول طلب الإلغاء 🛍️";
                    notifBody = `وافقت الإدارة على إلغاء منتج [${result.productName}]. وبناء عليه تم رد ${result.amount} شيكل لمحفظتك.`;
                    notifType = "ITEM_CANCEL_APPROVED";
                }
            } else {
                if (result.currentStatus === "return_requested") {
                    notifTitle = "رفض طلب الإرجاع ⚠️";
                    notifBody = `نعتذر منك، تم رفض طلب إرجاع منتج [${result.productName}] من قِبل الإدارة.`;
                    notifType = "ITEM_RETURN_REJECTED";
                } else {
                    notifTitle = "رفض طلب الإلغاء ⚠️";
                    notifBody = `تم رفض طلب إلغاء منتج [${result.productName}] من قِبل الإدارة وسيتم استكمال شحنه لك.`;
                    notifType = "ITEM_CANCEL_REJECTED";
                }
            }

            await admin.firestore().collection("User").doc(result.userId).collection("Notifications").add({
                title: notifTitle,
                body: notifBody,
                type: notifType,
                mainOrderId: mainOrderId || "",
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            if (fcmToken) {
                await admin.messaging().send({
                    token: fcmToken,
                    notification: { title: notifTitle, body: notifBody },
                    data: { orderId: mainOrderId || "", type: notifType }
                }).catch(e => console.error("FCM Admin Resolution Error:", e));
            }
        }

        return { success: result.success, message: result.message };

    } catch (error) {
        console.error("🔥 Error in optimized processAdminItemCancellation:", error);
        if (error instanceof HttpsError) throw error;
        throw new HttpsError("internal", "حدث خطأ داخلي أثناء معالجة الطلب برمجياً.");
    }
});*/






