class StoreFinancialModel {
  double commissionRate; // نسبة عمولة التطبيق (مثلاً 0.10 تعني 10%)
  double totalSales; // إجمالي المبيعات (الكل)
  double totalRejected; // إجمالي الطلبات المرفوضة
  double totalAccepted; // إجمالي المبيعات المقبولة
  double totalWithdrawn; // إجمالي المبالغ التي تم سحبها بالفعل

  StoreFinancialModel({
    this.commissionRate = 0.0,
    this.totalSales = 0.0,
    this.totalRejected = 0.0,
    this.totalAccepted = 0.0,
    this.totalWithdrawn = 0.0,
  });

  // حساب الرصيد القابل للسحب (المقبول - المسحوب - عمولة التطبيق)
  double get withdrawableBalance {
    double netSales = totalAccepted - (totalAccepted * commissionRate);
    return netSales - totalWithdrawn;
  }
}




/*
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * وظيفة الدالة: عند إنشاء طلب فرعي للمتجر، يتم حساب ربح التاجر الصافي
 * وحجزه في "الرصيد المعلق" مع تسجيل حركة مالية وإرسال إشعار.
 */
exports.onStoreOrderCreated = onDocumentCreated("StoreOrders/{storeOrderId}", async (event) => {
    const orderData = event.data.data();
    const storeId = (orderData.StoreId || "").trim();
    
    // حساب المجموع الكلي يدوياً من المصفوفة لضمان الدقة العالية
    const items = orderData.Items || [];
    let totalOrderAmount = 0;
    items.forEach(item => {
        totalOrderAmount += (parseFloat(item.price) || 0) * (parseInt(item.Quantity) || 1);
    });

    if (!storeId) return console.error("❌ StoreId missing.");

    try {
        const storeRef = admin.firestore().collection("Stores").doc(storeId);
        const storeDoc = await storeRef.get();
        if (!storeDoc.exists) return;

        // جلب نسبة العمولة من بيانات المتجر (الافتراضي 2% كما ذكرت)
        const commissionRate = storeDoc.data().commissionRate || 2; 
        const netProfit = totalOrderAmount * (1 - (commissionRate / 100));

        // 1. تحديث محفظة المتجر (زيادة الرصيد المعلق)
        await storeRef.update({
            "wallet.pendingBalance": admin.firestore.FieldValue.increment(netProfit)
        });

        // 2. تسجيل المعاملة في كولكشن مستقل للتدقيق
        await admin.firestore().collection("Transactions").add({
            storeId,
            orderId: event.params.storeOrderId,
            mainOrderId: orderData.MainOrderId || "",
            amount: netProfit,
            type: "order_revenue",
            status: "pending",
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // 3. إرسال الإشعار الاحترافي
        const fcmToken = storeDoc.data().fcmToken;
        if (fcmToken) {
            const message = {
                token: fcmToken,
                notification: {
                    title: "طلب جديد وارد! 🛍️",
                    body: `وصلك طلب جديد. ربحك الصافي: ${netProfit.toFixed(2)} شيكل`,
                },
                android: { 
                    notification: { 
                        channelId: "orders_channel", 
                        imageUrl: orderData.Items[0].Image || "",
                        color: "#00BFA6"
                    } 
                },
                data: { orderId: event.params.storeOrderId, type: "vendor_order" }
            };
            await admin.messaging().send(message);
        }
    } catch (error) {
        console.error("🔥 Error in onStoreOrderCreated:", error);
    }
});

/**
 * وظيفة الدالة: مراقبة تحديثات الطلب.
 * 1. إذا رُفض منتج: يُخصم ثمنه الصافي من رصيد التاجر المعلق.
 * 2. إذا اكتمل الطلب (Delivered): يُنقل المال من "المعلق" إلى "المتاح للسحب".
 */
exports.onStoreOrderUpdated = onDocumentUpdated("StoreOrders/{storeOrderId}", async (event) => {
    const newData = event.data.after.data();
    const previousData = event.data.before.data();
    const storeId = newData.StoreId;
    const mainOrderId = newData.MainOrderId;
    
    const newItems = newData.Items || [];
    const oldItems = previousData.Items || [];

    try {
        const storeRef = admin.firestore().collection("Stores").doc(storeId);
        const storeDoc = await storeRef.get();
        const commRate = storeDoc.exists ? (storeDoc.data().commissionRate || 2) : 2;

        // جلب بيانات الزبون مرة واحدة فقط
        const userDoc = await admin.firestore().collection("Users").doc(userId).get();
        const userFcmToken = userDoc.exists ? userDoc.data().fcmToken : null;

        // --- أولاً: معالجة المنتجات المرفوضة (Refund Logic) ---
        let totalNetRefund = 0;
        let itemsUpdated = false;
        for (const item of newItems) {
            const oldItem = oldItems.find(o => o.productId === item.productId);
            // التدقيق في حالة المنتج (rejected)
            const isRejected = item.itemStatus === "rejected";
            const wasNotRejected = !oldItem || oldItem.itemStatus !== "rejected";
            // الشرط الذهبي: الحالة هي مرفوض + لم يكن مرفوضاً سابقاً + لم يتم رد مبلغه مسبقاً
             const alreadyRefunded = item.refunded === true; // فحص العلامة

            if (isRejected && wasNotRejected && !alreadyRefunded) {
                const itemGross = (parseFloat(item.price) || 0) * (parseInt(item.Quantity) || 1);
                const itemNet = itemGross * (1 - (commRate / 100)); 
                totalNetRefund += itemNet;

                // وضع علامة على المنتج بأنه تم رد مبلغه لعدم تكرار العملية
                 item.refunded = true; 
                 itemsUpdated = true;        
                // تسجيل حركة المرتجع
                   await admin.firestore().collection("Transactions").add({
                        storeId,
                        orderId: event.params.storeOrderId,
                        amount: -itemNet,
                        type: "refund",
                        status: "completed",
                        productId: item.productId, // إضافة الـ ID للتدقيق
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                      });

                
                if (userDoc.exists) {
                    const fcmToken = userDoc.data().fcmToken;
                    const productName = item.Title || "منتج من طلبك"; // الحقل اسمه Title حسب بياناتك
                    const itemImage = item.Image || ""; // الحقل اسمه Image حسب بياناتك

                    if (fcmToken) {
                        const message = {
                            token: fcmToken,
                            notification: {
                                title: "تحديث بخصوص طلبك ⚠️",
                                body: `نعتذر منك، المنتج (${productName}) غير متوفر حالياً. سيتم إرجاع المبلغ لحسابك.`,
                            },
                            android: {
                                notification: {
                                    imageUrl: itemImage,
                                    color: "#f44336",
                                    sound: "default"
                                }
                            },
                            data: {
                                click_action: "FLUTTER_NOTIFICATION_CLICK",
                                orderId: mainOrderId,
                                type: "ITEM_REJECTED"
                            }
                        };
                        await admin.messaging().send(message);
                    }

                    await admin.firestore().collection("Users").doc(userId).collection("Notifications").add({
                        title: "تم رفض منتج ❌",
                        body: `المنتج (${productName}) مرفوض من قبل المتجر. المبلغ في طريق العودة إليك.`,
                        image: itemImage,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        isRead: false,
                        type: "REJECTION",
                        mainOrderId: mainOrderId
                    });
                }
                  



            }
        }

        // إذا تم تحديث مبالغ، نحدث المحفظة ونضيف علامة الـ refunded للمنتجات في الـ StoreOrder
                if (totalNetRefund > 0) {
                      await storeRef.update({
                      "wallet.pendingBalance": admin.firestore.FieldValue.increment(-totalNetRefund)
                  });
    // تحديث مستند الـ StoreOrder نفسه لإضافة علامة refunded: true للمنتج
                      await event.data.after.ref.update({ Items: newItems });
                }
        

        // --- ثانياً: تحرير الأموال عند التوصيل (Release Funds) ---
        if (newData.Status === "OrderStatus.delivered" && previousData.Status !== "OrderStatus.delivered") {
            // حساب الصافي النهائي لما لم يتم رفضه
            let finalOrderTotal = 0;
            newItems.forEach(item => {
                if (item.itemStatus !== "rejected") {
                    finalOrderTotal += (parseFloat(item.price) || 0) * (parseInt(item.Quantity) || 1);
                }
            });

            const finalNetProfit = finalOrderTotal * (1 - (commRate / 100));

            await storeRef.update({
                "wallet.pendingBalance": admin.firestore.FieldValue.increment(-finalNetProfit),
                "wallet.availableBalance": admin.firestore.FieldValue.increment(finalNetProfit),
                "wallet.totalEarnings": admin.firestore.FieldValue.increment(finalNetProfit)
            });
            console.log(`✅ Funds released for store ${storeId}: ${finalNetProfit}`);
        }

        // --- ثالثاً: مزامنة الحالة مع الطلب الرئيسي الزبون ---
        // --- ثالثاً: مزامنة الحالة وحساب المبالغ المرفوضة في طلب الزبون الرئيسي ---
if (mainOrderId) {
    const mainOrderRef = admin.firestore().collection("Orders").doc(mainOrderId);
    const mainOrderDoc = await mainOrderRef.get();
    
    if (mainOrderDoc.exists) {
        let mainItems = mainOrderDoc.data().Items || [];
        let currentRejectedAmount = mainOrderDoc.data().RejectedAmount || 0;
        let hasChanges = false;
        let additionalRefund = 0;

        mainItems = mainItems.map(mItem => {
            const updated = newItems.find(ni => ni.productId === mItem.productId);
            // إذا تغيرت الحالة إلى مرفوض ولم تكن مرفوضة سابقاً في طلب الزبون
            if (updated && updated.itemStatus !== mItem.itemStatus) {
                hasChanges = true;
                
                if (updated.itemStatus === "rejected" && mItem.itemStatus !== "rejected") {
                    const itemPrice = (parseFloat(mItem.price) || 0) * (parseInt(mItem.Quantity) || 1);
                    additionalRefund += itemPrice;
                }
                
                return { ...mItem, itemStatus: updated.itemStatus };
            }
            return mItem;
        });

        if (hasChanges) {
            const updatePayload = { Items: mainItems };
            // تحديث مبلغ المرتجعات الكلي للزبون
            if (additionalRefund > 0) {
                updatePayload.RejectedAmount = admin.firestore.FieldValue.increment(additionalRefund);
            }
            await mainOrderRef.update(updatePayload);
            console.log(`✅ Synced main order ${mainOrderId} and updated RejectedAmount by ${additionalRefund}`);
        }
    }
}

    } catch (error) {
        console.error("🔥 Error in onStoreOrderUpdated:", error);
    }
});

// دالة مساعدة لتخزين الإشعار في قاعدة البيانات
async function saveNotification(userId, title, body, type, relatedId) {
    await admin.firestore().collection("Notifications").add({
        userId: userId,
        title: title,
        body: body,
        type: type, // 'order_update' أو 'vendor_order'
        relatedId: relatedId, // orderId
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}

*/

//------------------------------------------------








/*


const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");

const admin = require("firebase-admin");

// تهيئة التطبيق لمرة واحدة فقط
if (admin.apps.length === 0) {
    admin.initializeApp();
}

exports.onStoreOrderCreated = onDocumentCreated("StoreOrders/{StoreId}", async (event) => {
    const orderData = event.data.data();
    const storeId = (orderData['StoreId']).trim();
    const totalAmount = orderData.TotalAmount || 0;

    if (!storeId) {
        console.error("❌ Error: StoreId missing.");
        return;
    }

    try {
        const storeRef = admin.firestore().collection("Stores").doc(storeId);
        const storeDoc = await storeRef.get();
        
        if (!storeDoc.exists) return;

        // حساب العمولة (نفترض 10% أو القيمة المخزنة في المتجر)
        const commissionRate = storeDoc.data().commissionRate || 2;
        const netProfit = totalAmount - (totalAmount * (commissionRate / 100));

        // تحديث محفظة المتجر: زيادة الرصيد المعلق
        await storeRef.update({
            "wallet.pendingBalance": admin.firestore.FieldValue.increment(netProfit)
        });

        // تسجيل العملية في سجل المعاملات
        await admin.firestore().collection("Transactions").add({
            storeId,
            orderId: event.params.storeOrderId,
            amount: netProfit,
            type: "order_revenue",
            status: "pending",
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        const fcmToken = storeDoc.data().fcmToken;
        const notificationData = {
            title: "طلب جديد وارد! 🛍️",
            body: `وصلك طلب جديد بقيمة ${orderData.TotalAmount || 0} شيكل`,
            imageUrl: orderData.Thumbnail || "", // إضافة صورة المنتج للاشعار لتبدو احترافية
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            orderId: event.params.storeOrderId,
            isRead: false,
            type: "NEW_ORDER"
        };

        // --- الخطوة الأولى: أرشفة الإشعار في Firestore ليعرض في التطبيق ---
        await storeRef.collection("Notifications").add(notificationData);

        // --- الخطوة الثانية: إرسال الإشعار عبر FCM مع ميزات احترافية ---
        if (fcmToken) {
            const message = {
                token: fcmToken,
                notification: {
                    title: notificationData.title,
                    body: notificationData.body,
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "orders_channel", // مهم جداً للأندرويد الحديث
                        icon: "stock_ticker_update",
                        color: "#00BFA6", // لون المتجر (مينت جرين مثلاً)
                        // تجعل الإشعار ثابتاً (Ongoing) لا يمسح بسهولة إلا بالنقر
                        sticky: true, 
                        visibility: "public",
                        sound: "default",
                        // صورة كبيرة داخل الإشعار (احترافية)
                        imageUrl: notificationData.imageUrl 
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            contentAvailable: true,
                            badge: 1,
                            sound: "default"
                        },
                    },
                },
                data: {
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    orderId: notificationData.orderId,
                    type: "vendor_order"
                }
            };

            await admin.messaging().send(message);
            console.log("✅ Notification sent & archived for store:", storeId);
        }
    } catch (error) {
        console.error("🔥 Error:", error);
    }
});


exports.onStoreOrderUpdated = onDocumentUpdated("StoreOrders/{StoreId}", async (event) => {
    const newData = event.data.after.data();
    const previousData = event.data.before.data();

    const newItems = newData.Items || [];
    const oldItems = previousData.Items || [];
    const mainOrderId = newData.MainOrderId || newData.MainOrderId; // حسب بياناتك الحقل اسمه Id
    const userId = newData.UserId;

    // --- 1. المزامنة العامة والحسابات المالية ---
    if (mainOrderId) {
        try {
            const mainOrderRef = admin.firestore().collection("Orders").doc(mainOrderId);
            const mainOrderDoc = await mainOrderRef.get();

            if (mainOrderDoc.exists) {
                let mainOrderItems = mainOrderDoc.data().Items || [];
                let totalRefundToAdd = 0;
                let isChanged = false;

                // تحديث مصفوفة المنتجات في الطلب الرئيسي
                mainOrderItems = mainOrderItems.map(mItem => {
                    // البحث عن المنتج المطابق باستخدام productId (حسب بياناتك الحرف الأول صغير)
                    const updatedItem = newItems.find(newItem => newItem.productId === mItem.productId);
                    
                    if (updatedItem && updatedItem.itemStatus !== mItem.itemStatus) {
                        isChanged = true;
                        
                        // منطق مالي: إذا تغيرت الحالة إلى Rejected لأول مرة
                        const wasAlreadyRejected = oldItems.find(o => o.productId === mItem.productId && o.itemStatus === "Rejected");
                        
                        if (updatedItem.itemStatus === "rejected" && !wasAlreadyRejected) {
                            const price = parseFloat(updatedItem.price || 0); // السعر price حرف صغير
                            const quantity = parseInt(updatedItem.Quantity || 1); // الكمية Quantity حرف كبير
                            totalRefundToAdd += (price * quantity);
                        }

                        return { ...mItem, itemStatus: updatedItem.itemStatus };
                    }
                    return mItem;
                });

                if (isChanged) {
                    const updateData = {
                        Items: mainOrderItems,
                        lastStatusUpdate: admin.firestore.FieldValue.serverTimestamp()
                    };

                    if (totalRefundToAdd > 0) {
                        updateData.RejectedAmount = admin.firestore.FieldValue.increment(totalRefundToAdd);
                        console.log(`💰 تم إضافة مبلغ مسترد: ${totalRefundToAdd}`);
                    }

                    await mainOrderRef.update(updateData);
                    console.log(`✅ تم مزامنة الطلب الرئيسي: ${mainOrderId}`);
                }
            }
        } catch (error) {
            console.error("🔥 Error syncing items or finance:", error);
        }
    }

    // --- 2. إرسال الإشعارات والأرشفة (عند الرفض فقط) ---
    for (const item of newItems) {
        const oldItem = oldItems.find(old => old.productId === item.productId);

        if (item.itemStatus === "rejected" && (!oldItem || oldItem.itemStatus !== "rejected")) {
            try {
                const userDoc = await admin.firestore().collection("Users").doc(userId).get();
                
                if (userDoc.exists) {
                    const fcmToken = userDoc.data().fcmToken;
                    const productName = item.Title || "منتج من طلبك"; // الحقل اسمه Title حسب بياناتك
                    const itemImage = item.Image || ""; // الحقل اسمه Image حسب بياناتك

                    if (fcmToken) {
                        const message = {
                            token: fcmToken,
                            notification: {
                                title: "تحديث بخصوص طلبك ⚠️",
                                body: `نعتذر منك، المنتج (${productName}) غير متوفر حالياً. سيتم إرجاع المبلغ لحسابك.`,
                            },
                            android: {
                                notification: {
                                    imageUrl: itemImage,
                                    color: "#f44336",
                                    sound: "default"
                                }
                            },
                            data: {
                                click_action: "FLUTTER_NOTIFICATION_CLICK",
                                orderId: mainOrderId,
                                type: "ITEM_REJECTED"
                            }
                        };
                        await admin.messaging().send(message);
                    }

                    await admin.firestore().collection("Users").doc(userId).collection("Notifications").add({
                        title: "تم رفض منتج ❌",
                        body: `المنتج (${productName}) مرفوض من قبل المتجر. المبلغ في طريق العودة إليك.`,
                        image: itemImage,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        isRead: false,
                        type: "REJECTION",
                        mainOrderId: mainOrderId
                    });
                }
            } catch (error) {
                console.error("🔥 Error in Notification Process:", error);
            }
        }
    }
});

*/



///////////////////////////////////////////


/*
exports.onStoreOrderUpdated = onDocumentUpdated("StoreOrders/{storeOrderId}", async (event) => {
    const newData = event.data.after.data();
    const previousData = event.data.before.data();
    const storeId = newData.StoreId;
    const userId = newData.UserId; // تم الإصلاح هنا
    const mainOrderId = newData.MainOrderId;
    const newItems = [...(newData.Items || [])]; // نسخة للتعديل
    const oldItems = previousData.Items || [];
    const statusBefore = previousData.Status;
    const statusAfter = newData.Status;

    try {
        const storeRef = admin.firestore().collection("Stores").doc(storeId);
        const storeDoc = await storeRef.get();
        const commRate = storeDoc.exists ? (storeDoc.data().commissionRate || 2) : 2;
        const statsUpdate = {};
        const globalRef = getGlobalRef();
        const userRef = admin.firestore().collection('User').doc(userId);
        const transactionRef = admin.firestore().collection('User').doc(userId).collection('Transactions').doc();

        // --- 1. إحصائيات القبول والرفض (بناءً على حالة الطلب الكلية) ---
       // تحديث إحصائيات القبول والرفض (للمتجر وللمنصة)
        if (statusAfter === "accepted" && statusBefore !== "accepted") {
            await storeRef.update({ acceptedOrders: admin.firestore.FieldValue.increment(1) });
            await globalRef.update({ acceptedOrders: admin.firestore.FieldValue.increment(1) });
        } else if (statusAfter === "rejected" && statusBefore !== "rejected") {
            await storeRef.update({ rejectedOrders: admin.firestore.FieldValue.increment(1) });
            await globalRef.update({ rejectedOrders: admin.firestore.FieldValue.increment(1) });
        }

        
        // تنفيذ تحديث الإحصائيات إذا وجد تغيير
        if (Object.keys(statsUpdate).length > 0) {
            await storeRef.update(statsUpdate);
        }



        // جلب بيانات الزبون (مرة واحدة خارج الحلقة للكفاءة)
        const userDoc = await admin.firestore().collection("User").doc(userId).get();
        const userFcmToken = userDoc.exists ? userDoc.data().fcmToken : null;

        let totalNetRefund = 0;
        let totalGrossRefundForUser = 0; // للزبون (المبلغ الكامل الذي دفعه)
        const rejectedItemsToProcess = [];
        // --- أولاً: معالجة الرفض ---
        for (const item of newItems) {
            const oldItem = oldItems.find(o => o.productId === item.productId);
            if (item.itemStatus === "rejected" && (!oldItem || oldItem.itemStatus !== "rejected") && !item.refunded) {
                const storeDoc = await storeRef.get();
                const commRate = storeDoc.exists ? (storeDoc.data().commissionRate || 2) : 2;
                
                const itemGross = (parseFloat(item.price) || 0) * (parseInt(item.Quantity) || 1);
                const itemNet = itemGross * (1 - (commRate / 100));
                
                rejectedItemsToProcess.push({ item, itemGross, itemNet });
                totalNetToDeductFromStore += itemNet;
                totalGrossToReturnToUser += itemGross;
                item.refunded = true; // وسم المنتج لمنع التكرار
            }
        }

        if (rejectedItemsToProcess.length > 0) {
            // تنفيذ العملية المالية في ترانزاكشن واحد فقط
            await admin.firestore().runTransaction(async (transaction) => {
                // تحديث رصيد الزبون
                transaction.update(userRef, {
                    walletBalance: admin.firestore.FieldValue.increment(totalGrossToReturnToUser)
                });
                // تحديث محفظة المتجر
                transaction.update(storeRef, {
                    "wallet.pendingBalance": admin.firestore.FieldValue.increment(-totalNetToDeductFromStore)
                });

                // تسجيل العمليات في السجلات
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
                    amount: -entry.itemNet, // القيمة بالسالب لأنها خصم من رصيد المتجر
                    type: "refund",
                    status: "completed",
                    productId: entry.item.productId,
                    productName: entry.item.Title, // إضافة اسم المنتج مفيدة جداً للمتجر
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                     });
                }

                logNotificationWithTransaction(transaction, "User", userId, {
                    title: "تم استرداد مبلغ ",
                    body: `تم إرجاع ${totalGrossToReturnToUser} شيكل لمحفظتك عن منتجات مرفوضة.`,
                    type: "REJECTION",
                    mainOrderId
                });
            });

            // تحديث الطلب بـ الـ Items الجديدة (التي تحتوي على refunded: true)
            await event.data.after.ref.update({ Items: newItems });

            // إرسال FCM (خارج الترانزاكشن)
            const userDoc = await userRef.get();
            const fcmToken = userDoc.data()?.fcmToken;
            if (fcmToken) {
                await admin.messaging().send({
                    token: fcmToken,
                    notification: { title: "تحديث بخصوص طلبك ⚠️", body: `تم إرجاع مبلغ لمنتجات غير متوفرة.` },
                    data: { orderId: mainOrderId, type: "ITEM_REJECTED" }
                }).catch(e => console.error("FCM Error:", e));
            }
        }






        

        // --- ثالثاً: مزامنة الطلب الرئيسي (الزبون) ---
        if (mainOrderId) {
            const mainOrderRef = admin.firestore().collection("Orders").doc(mainOrderId);
            const mainOrderDoc = await mainOrderRef.get();
            if (mainOrderDoc.exists) {
                let mainItems = mainOrderDoc.data().Items || [];
                let mainStatus = mainOrderDoc.data().Status || "pending";
                let additionalRefund = 0;
                let hasChanges = false;

                mainItems = mainItems.map(mItem => {
                    const updated = newItems.find(ni => ni.productId === mItem.productId);
                    if (updated && updated.itemStatus !== mItem.itemStatus) {
                        hasChanges = true;
                        if (updated.itemStatus === "rejected" && mItem.itemStatus !== "rejected") {
                            additionalRefund += (parseFloat(mItem.price) || 0) * (parseInt(mItem.Quantity) || 1);
                        }
                        return { ...mItem, itemStatus: updated.itemStatus };
                    }
                    return mItem;
                });

                if (hasChanges) {
                    const updatePayload = { Items: mainItems };
                    if (additionalRefund > 0) {
                        updatePayload.RejectedAmount = admin.firestore.FieldValue.increment(additionalRefund);
                    }
                    await mainOrderRef.update(updatePayload);
                }

                // 2. التحقق من حالة "شُحن" (المنطق المطلوب)
                if (newData.Status === "shipped" && previousData.Status !== "shipped") {
                    
                    // جلب جميع الطلبات الفرعية لهذا الطلب الرئيسي
                    const allSubOrders = await admin.firestore()
                        .collection("StoreOrders")
                        .where("MainOrderId", "==", mainOrderId)
                        .get();

                    // فحص: هل كل الطلبات الفرعية أصبحت (shipped أو delivered أو rejected)؟
                    const allShipped = allSubOrders.docs.every(doc => {
                        const status = doc.data().Status;
                        return status === "shipped" || status === "rejected";
                    });
                    if (allShipped) {
                        await mainOrderRef.update({ Status: "shipped" });
                        
                        // إشعار الزبون أن طلبه بالكامل خرج للتوصيل
                        if (userFcmToken) {
                            await admin.messaging().send({
                                token: userFcmToken,
                                notification: { 
                                    title: "طلبك في الطريق! 🚚", 
                                    body: "جميع المتاجر سلمت أغراضك للمندوب وهي الآن في طريقها إليك." 
                                },
                                data: { orderId: mainOrderId, type: "ORDER_SHIPPED" }
                            });
                        }
                     await logNotification("User", userId, { title, body, type: "ORDER_SHIPPED", mainOrderId });

                    }
                }
                

    

            }
        }


        // --- رابعاً: إشعار المناديب (جاهز للاستلام) ---
    if (newData.Status === "readyForPickup" && previousData.Status !== "readyForPickup") {
    
    // 1. جلب بيانات المتجر لمعرفة موقعه (اختياري لتخصيص الإشعار)
    const storeSnapshot = await admin.firestore().collection("Stores").doc(storeId).get();
    const storeName = storeSnapshot.exists ? storeSnapshot.data().storName : "متجر";
    const storeArea = storeSnapshot.exists ? storeSnapshot.data().area : "";

    // 2. جلب جميع المناديب النشطين والمتاحين للعمل
    const driversSnapshot = await admin.firestore()
        .collection("DeliveryDrivers")
        .where("isActive", "==", true)
        .get();

    if (!driversSnapshot.empty) {
        const notificationTitle = "طلب جديد جاهز للاستلام 📦";
        const notificationBody = `المتجر: ${storeName} في منطقة ${storeArea} لديه طلب جاهز للتجميع.`;

        // مصفوفة لتخزين وعود (Promises) العمليات لضمان الكفاءة
        const driverPromises = [];

        driversSnapshot.docs.forEach(doc => {
            const driverId = doc.id;
            const driverData = doc.data();
            const driverToken = driverData.fcmToken;

            // أ. حفظ الإشعار في كولكشن المندوب الفرعي (باستخدام الدالة المساعدة لديك)
            driverPromises.push(
                logNotification("DeliveryDrivers", driverId, {
                    title: notificationTitle,
                    body: notificationBody,
                    type: "NEW_ORDER_AVAILABLE",
                    orderId: event.params.storeOrderId,
                    storeId: storeId,
                })
            );

            // ب. إرسال FCM إذا كان التوكن موجوداً
            if (driverToken) {
                driverPromises.push(
                    admin.messaging().send({
                        token: driverToken,
                        notification: { 
                            title: notificationTitle, 
                            body: notificationBody 
                        },
                        data: { 
                            orderId: event.params.storeOrderId, 
                            type: "NEW_ORDER_AVAILABLE",
                            storeId: storeId
                        }
                    }).catch(err => console.error(`Error sending to driver ${driverId}:`, err))
                );
            }
        });

        // تنفيذ جميع العمليات بالتوازي
        await Promise.all(driverPromises);
    }
}

    } catch (error) {
        console.error("🔥 Error in onStoreOrderUpdated:", error);
    }
});

*/


    /* 
    // تسجيل حركة المرتجع مالياً
                await admin.firestore().collection("Transactions").add({
                    storeId, orderId: event.params.storeOrderId, amount: -itemNet,
                    type: "refund", status: "completed", productId: item.productId,
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });

                // 1. تسجيل عملية مالية في سجل المستخدم (Transactions Sub-collection)
                const transactionRef = userRef.collection('Transactions').doc();
                await transactionRef.set({
                    id: transactionRef.id,
                    amount: itemGross,
                    type: "refund",
                    status: "pending", // بما أنه تم تأكيد الرفض هنا
                    date: admin.firestore.FieldValue.serverTimestamp(),
                    description: `استرجاع مبلغ منتج: ${item.Title || 'منتج'} (مرفوض)`,
                    orderId: mainOrderId,
                    storeOrderId: event.params.storeOrderId,
                    productId: item.productId
                });

                await logNotification("User", userId, { 
                    title: "تم رفض منتج ❌", body: noteBody, 
                    image: item.Image || "", type: "REJECTION", mainOrderId 
                });

                if (userFcmToken) {
                    await admin.messaging().send({
                        token: userFcmToken,
                        notification: { title: noteTitle, body: noteBody },
                        data: { orderId: mainOrderId, type: "ITEM_REJECTED" }
                    });
                }
    */


                /*



                // --- بدء العملية المالية الآمنة ---
             await admin.firestore().runTransaction(async (transaction) => {
            // 1. جلب المستندات داخل الترانزاكشن لضمان أحدث بيانات
            const userSnap = await transaction.get(userRef);
            const storeSnap = await transaction.get(storeRef);

            if (!userSnap.exists) throw "User does not exist!";

            // 2. حساب الأرصدة الجديدة
            const currentWalletBalance = userSnap.data().walletBalance || 0;
            const currentStorePending = storeSnap.data().wallet?.pendingBalance || 0;

            // 3. تنفيذ التحديثات (الذرية)
            // أ. زيادة رصيد الزبون
            transaction.update(userRef, {
                walletBalance: currentWalletBalance + itemGross
            });

            // ب. خصم من أرباح المتجر المعلقة
            transaction.update(storeRef, {
                "wallet.pendingBalance": currentStorePending - itemNet
            });

            // ج. تسجيل عملية الاسترداد في سجل الزبون
            const userTransRef = userRef.collection('Transactions').doc();
            transaction.set(userTransRef, {
                id: userTransRef.id,
                amount: itemGross,
                type: 'refund',
                status: 'completed',
                date: admin.firestore.FieldValue.serverTimestamp(),
                description: `مرتجع منتج: ${item.Title}`,
                orderId: mainOrderId,
                storeOrderId: event.params.storeOrderId,
                productId: item.productId
            });

            // د. تسجيل العملية في السجل العام (اختياري حسب نظامك)
            const globalTransRef = admin.firestore().collection("Transactions").doc();
            transaction.set(globalTransRef, {
                storeId,
                orderId: event.params.storeOrderId,
                amount: -itemNet,
                type: "refund",
                status: "completed",
                productId: item.productId,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // 2. استخدام الدالة الجديدة لتسجيل الإشعار داخل نفس الترانزاكشن
             logNotificationWithTransaction(transaction, "User", userId, { 
                title: "تم رفض منتج ❌", 
                body: `المنتج (${item.Title}) غير متوفر. تم إرجاع ${itemGross} شيكل لمحفظتك.`,
                type: "REJECTION", 
                mainOrderId ,
                image: item.Image || ""
            });
             });



                
                

                // إشعار الزبون (تخزين في الكولكشن الفرعي للزبون + FCM)
                const noteTitle = "تحديث بخصوص طلبك ⚠️";
                const noteBody = `المنتج (${item.Title || 'منتج'}) غير متوفر. سيتم إرجاع المبلغ لحسابك.`;
                

                
                 // 3. الآن بعد نجاح الترانزاكشن تماماً، أرسل الإشعار للموبايل (خارج الترانزاكشن)
            if (userFcmToken) {
               try {
               await admin.messaging().send({
                token: userFcmToken,
                notification: { title: noteTitle, body: noteBody },
                data: { orderId: mainOrderId, type: "ITEM_REJECTED" }
                });
                } catch (fcmError) {
                console.error("FCM failed but data is saved:", fcmError);
              // حتى لو فشل إرسال الإشعار للموبايل، المال بأمان والسجل محفوظ
                 }
            }
                */



            /*
            for (const item of newItems) {
            const oldItem = oldItems.find(o => o.productId === item.productId);
            if (item.itemStatus === "rejected" && (!oldItem || oldItem.itemStatus !== "rejected") && !item.refunded) {
                
                const itemGross = (parseFloat(item.price) || 0) * (parseInt(item.Quantity) || 1);
                const itemNet = itemGross * (1 - (commRate / 100)); 
                rejectedItemsToProcess.push({ item, itemGross });
                totalNetRefund += itemNet;
                totalGrossRefundForUser += itemGross;
                item.refunded = true; 


             
            }
        }

        if (totalNetRefund > 0) {

            // أ. تحديث رصيد الزبون (إضافة المبلغ كاملاً)
            await userRef.update({
                walletBalance: admin.firestore.FieldValue.increment(totalGrossRefundForUser)
            });
            // ب. تحديث محفظة المتجر (خصم المبلغ الصافي من الأرباح المعلقة)
            await storeRef.update({ "wallet.pendingBalance": admin.firestore.FieldValue.increment(-totalNetRefund) });
            
            // ج. تحديث مستند الطلب الفرعي لوسم المنتجات كـ Refunded لمنع التكرار
            await event.data.after.ref.update({ Items: newItems });
        }


        // 2. إذا وجد منتجات مرفوضة، نفذ العملية المالية في ترانزاكشن واحد "ذري"
        if (rejectedItemsToProcess.length > 0) {
            await admin.firestore().runTransaction(async (transaction) => {
                const userSnap = await transaction.get(userRef);
                const storeSnap = await transaction.get(storeRef);
                
                const storeData = storeSnap.data();
                const commRate = storeData?.commissionRate || 2;

                let batchGross = 0;
                let batchNet = 0;

                for (const entry of rejectedItemsToProcess) {
                    const itemNet = entry.itemGross * (1 - (commRate / 100));
                    batchGross += entry.itemGross;
                    batchNet += itemNet;

                    // سجل المعاملة الفردي داخل الترانزاكشن
                    const userTransRef = userRef.collection('Transactions').doc();
                    transaction.set(userTransRef, {
                        amount: entry.itemGross,
                        type: 'refund',
                        status: 'completed',
                        date: admin.firestore.FieldValue.serverTimestamp(),
                        description: `مرتجع: ${entry.item.Title}`,
                        orderId: mainOrderId,
                        productId: entry.item.productId
                    });
                }

                // تحديث الأرصدة الإجمالي
                transaction.update(userRef, {
                    walletBalance: admin.firestore.FieldValue.increment(batchGross)
                });
                transaction.update(storeRef, {
                    "wallet.pendingBalance": admin.firestore.FieldValue.increment(-batchNet)
                });

                // تسجيل الإشعار الإجمالي (أو فردي حسب رغبتك)
                logNotificationWithTransaction(transaction, "User", userId, {
                    title: "تحديث المرتجعات",
                    body: `تم إرجاع مبلغ ${batchGross} شيكل لمحفظتك عن منتجات مرفوضة.`,
                    type: "REJECTION",
                    mainOrderId
                });
            });

            // 3. تحديث مستند الطلب لمرة واحدة فقط لوسم refunded: true
            await event.data.after.ref.update({ Items: newItems });
        }

            */















