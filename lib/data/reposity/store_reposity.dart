import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:get/get_core/get_core.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stors_admin_panel/utils/exceptions/firebase_auth_exceptions.dart';
import 'package:stors_admin_panel/utils/exceptions/firebase_exceptions.dart';
import 'package:stors_admin_panel/utils/exceptions/format_exceptions.dart';
import 'package:stors_admin_panel/utils/exceptions/platform_exceptions.dart';
import 'package:stors_admin_panel/features/features_authintication/models/user_stor_model.dart';

class StoreRepository extends GetxController {
  static StoreRepository get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveStoreRecord(StoreModel store) async {
    try {
      await _db
          .collection(StoreModel.getStoreCollectionName)
          .doc(store.storeId)
          .set(store.toJson());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "somthing went wrong, pleas try agin";
    }
  }

  Future<StoreModel> fetchStoreDetails(String storeId) async {
    try {
      final documentSnapshot = await _db
          .collection(StoreModel.getStoreCollectionName)
          .doc(storeId)
          .get();
      if (documentSnapshot.exists) {
        return StoreModel.fromSnapshot(documentSnapshot);
      } else {
        return StoreModel.empty();
      }
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "somthing went wrong, pleas try agin";
    }
  }

  Future<void> updateStoreDetails(StoreModel updatedStore) async {
    try {
      await _db
          .collection(StoreModel.getStoreCollectionName)
          .doc(updatedStore.storeId)
          .update(updatedStore.toJson());
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  Future<void> updateSingleField(
    String storeId,
    Map<String, dynamic> json,
  ) async {
    try {
      await _db
          .collection(StoreModel.getStoreCollectionName)
          .doc(storeId)
          .update(json);
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  Future<void> removeStoreRecord(String storeId) async {
    try {
      await _db
          .collection(StoreModel.getStoreCollectionName)
          .doc(storeId)
          .delete();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  Future<String> uploadImage(String path, XFile image) async {
    try {
      final ref = FirebaseStorage.instance.ref(path).child(image.name);
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  /// جلب بيانات متجر معين
  Future<StoreModel> getStoreById(String storeId) async {
    try {
      final snapshot = await _db
          .collection(StoreModel.getStoreCollectionName)
          .doc(storeId)
          .get();
      if (snapshot.exists) {
        return StoreModel.fromSnapshot(snapshot);
      }
      return StoreModel.empty();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  /// تحديث حقول معينة في المتجر
  Future<void> updateStoreFields(
    String storeId,
    Map<String, dynamic> json,
  ) async {
    try {
      await _db
          .collection(StoreModel.getStoreCollectionName)
          .doc(storeId)
          .update(json);
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw "حدث خطأ غير متوقع. الرجاء المحاولة مجدداً";
    }
  }

  // جلب كافة البيانات من Firebase
  Future<List<Map<String, dynamic>>> fetchAllShippingData() async {
    try {
      final snapshot = await _db.collection('ShippingRates').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } on FirebaseException catch (e) {
      throw 'حدث خطأ في قاعدة البيانات: ${e.message}';
    } catch (e) {
      throw 'عذراً، حدث خطأ غير متوقع أثناء جلب البيانات.';
    }
  }
}
