import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/data/stor/models/product_model.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';

class ImagesController extends GetxController {
  static ImagesController get instance => Get.find();

  RxString selectedProductImage = "".obs;

  List<String> getAllProductImages(ProductModel product) {
    // final storage = TfirebaseStorageService.instance;
    Set<String> images = {};
    images.add(product.thumbnail);

    selectedProductImage.value = product.thumbnail;

    if (product.images != null) {
      images.addAll(product.images!);
    }

    if (product.productVariation != null ||
        product.productVariation!.isNotEmpty) {
      images.addAll(product.productVariation!.map((e) => e.image));
    }

    return images.toList();
  }

  void showEnlargeImage(String image) {
    Get.to(
      fullscreenDialog: true,
      () => Dialog.fullscreen(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: TSizes.defaultSpace,
                horizontal: TSizes.defaultSpace,
              ),
              child: Image(image: AssetImage(image)),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 150,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  child: Text("Close"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
