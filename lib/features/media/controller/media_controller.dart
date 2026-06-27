import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/reposity/media/media_reposity.dart';
import 'package:stors_admin_panel/features/media/models/image_model.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/image_strings.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:stors_admin_panel/utils/constants/text_strings.dart';
import 'package:stors_admin_panel/utils/popups/dialogs.dart';
import 'package:stors_admin_panel/utils/popups/full_screen_loader.dart';
import 'package:stors_admin_panel/utils/popups/loaders.dart';

class MediaController extends GetxController {
  static MediaController get instance => Get.find();

  late DropzoneViewController dropzoneViewController;
  final RxBool showImageUploaderSection = false.obs;
  final RxBool loading = false.obs;
  final int initialLoadCount = 20;
  final int loadMoreCount = 25;

  final Rx<MediaCategory> selectPath = MediaCategory.folders.obs;
  final RxList<ImageModel> selectedImagesToUpload = <ImageModel>[].obs;

  Future<List<ImageModel>?> get sel async {
    await selectedLocalImages();
    return selectedImagesToUpload.isEmpty
        ? null
        : selectedImagesToUpload.toList();
  }

  Future<List<ImageModel>?> selFro() async {
    await selectedLocalImages();
    return selectedImagesToUpload.isEmpty
        ? null
        : selectedImagesToUpload.toList();
  }

  final RxList<ImageModel> alImages = <ImageModel>[].obs;
  final RxList<ImageModel> alBannerImages = <ImageModel>[].obs;
  final RxList<ImageModel> alProductImages = <ImageModel>[].obs;
  final RxList<ImageModel> alBrandImages = <ImageModel>[].obs;
  final RxList<ImageModel> alCategoryImages = <ImageModel>[].obs;
  final RxList<ImageModel> alUserImages = <ImageModel>[].obs;
  final RxList<ImageModel> alStoreImages = <ImageModel>[].obs;

  final MediaReposity mediaReposity = MediaReposity();

  Future<void> selectedLocalImages() async {
    final files = await dropzoneViewController.pickFiles(
      multiple: true,
      mime: ["image/jpeg"],
    );
    /*if (files.isNotEmpty) {
      for (var file in files) {
        if (file is html.File) {
          final bytes = await dropzoneViewController.getFileData(file);

          final image = ImageModel(
            url: "",
            folder: "",
            fileName: file.name,
            file: file,
            localImageToDisplay: Uint8List.fromList(bytes),
          );
          selectedImagesToUpload.add(image);
        }
      }
    }*/
  }

  void uploadImagesConfirmation() {
    if (selectPath.value == MediaCategory.folders) {
      TLoaders.warningSnackBar(
        title: "قم باختيار مجلد",
        message: "الرجاء اختيار مجلد للصورة لرفع",
      );
      return;
    }

    TDialogs.defaultDialog(
      context: Get.context!,
      title: "رفع صور",
      confirmText: "رفع",
      onConfirm: () {},
      content:
          "هل انت متاكد انك تريد رفع جميع هذه الصور في مجلد ${selectPath.value.name.toUpperCase()}",
    );
  }

  Future<void> uploadImages() async {
    try {
      Get.back();
      uploadImagesLoader();
      MediaCategory selectPathCategory = selectPath.value;
      RxList<ImageModel> targetList;

      switch (selectPathCategory) {
        case MediaCategory.banners:
          targetList = alBannerImages;
          break;
        case MediaCategory.brands:
          targetList = alBrandImages;
          break;
        case MediaCategory.products:
          targetList = alProductImages;
          break;
        case MediaCategory.users:
          targetList = alUserImages;
          break;
        //case MediaCategory.sore:
        //targetList = alStoreImages;
        // break;
        default:
          return;
      }

      for (int i = selectedImagesToUpload.length - 1; i >= 0; i--) {
        var selectedImage = selectedImagesToUpload[i];
        final image = selectedImage.file!;

        final ImageModel uploadedImage = await mediaReposity
            .uploadImageFileInStorage(
              file: image,
              path: getSelctedPath(),
              imageName: selectedImage.fileName,
            );

        uploadedImage.mediaCategory = selectPathCategory.name;
        final id = await mediaReposity.uploadImageFileInDatabase(uploadedImage);
        uploadedImage.id = id;
        selectedImagesToUpload.removeAt(i);
        targetList.add(uploadedImage);
      }
      TFullScreenLoader.stopLoading();
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.warningSnackBar(
        title: "خطا في رفع الصور",
        message: "حدث خطا في عملية رفع الصور",
      );
    }
  }

  void uploadImagesLoader() {
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text("رفع الصور"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                TImages.uploadingImageIllustration,
                height: 300,
                width: 300,
              ),
              SizedBox(height: TSizes.spaceBtwItems),
              Text("تم رفع الصور"),
            ],
          ),
        ),
      ),
    );
  }

  String getSelctedPath() {
    String path = "";
    switch (selectPath.value) {
      case MediaCategory.banners:
        path = TTexts.bannersStoragePath;
        break;
      case MediaCategory.brands:
        path = TTexts.brandsStoragePath;
        break;
      case MediaCategory.categories:
        path = TTexts.categoriesStoragePath;
        break;
      case MediaCategory.products:
        path = TTexts.productsStoragePath;
        break;
      case MediaCategory.users:
        path = TTexts.usersStoragePath;
        break;
      //case MediaCategory.sore:
      //path = TTexts.storsStoragePath;
      // break;
      default:
        path = "Others";
    }
    return path;
  }

  void getMediaImages() async {
    try {
      loading.value = true;
      RxList<ImageModel> tragetList = <ImageModel>[].obs;

      if (selectPath.value == MediaCategory.banners &&
          alBannerImages.isNotEmpty) {
        tragetList = alBannerImages;
      } else if (selectPath.value == MediaCategory.brands &&
          alBrandImages.isNotEmpty) {
        tragetList = alBrandImages;
      } else if (selectPath.value == MediaCategory.products &&
          alProductImages.isNotEmpty) {
        tragetList = alProductImages;
      } else if (selectPath.value == MediaCategory.categories &&
          alCategoryImages.isNotEmpty) {
        tragetList = alCategoryImages;
      }

      final images = await mediaReposity.fetchImagesFromDatabase(
        selectPath.value,
        initialLoadCount,
      );
      tragetList.assignAll(images);

      loading.value = false;
    } catch (e) {
      loading.value = false;
      TLoaders.errorSnackBar(
        title: "خطا",
        message: "حدث خطا في عملية جلب الصور",
      );
    }
  }

  void loadMoreMediaImages() async {
    try {
      loading.value = true;
      RxList<ImageModel> tragetList = <ImageModel>[].obs;

      if (selectPath.value == MediaCategory.banners &&
          alBannerImages.isNotEmpty) {
        tragetList = alBannerImages;
      } else if (selectPath.value == MediaCategory.brands &&
          alBrandImages.isNotEmpty) {
        tragetList = alBrandImages;
      } else if (selectPath.value == MediaCategory.products &&
          alProductImages.isNotEmpty) {
        tragetList = alProductImages;
      } else if (selectPath.value == MediaCategory.categories &&
          alCategoryImages.isNotEmpty) {
        tragetList = alCategoryImages;
      }

      final images = await mediaReposity.loadMoreImagesFromDatabase(
        selectPath.value,
        initialLoadCount,
        tragetList.last.createdAt ?? DateTime.now(),
      );
      tragetList.assignAll(images);

      loading.value = false;
    } catch (e) {
      loading.value = false;
      TLoaders.errorSnackBar(
        title: "خطا",
        message: "حدث خطا في عملية جلب الصور",
      );
    }
  }
}
