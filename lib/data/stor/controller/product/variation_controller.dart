import 'package:get/get.dart';
import 'package:stors_admin_panel/data/stor/controller/product/images_controller.dart';
import 'package:stors_admin_panel/data/stor/models/product_model.dart';
import 'package:stors_admin_panel/data/stor/models/product_variation_model.dart';

class VariationController extends GetxController {
  static VariationController get instance => Get.find();

  RxMap selectedAttributes = {}.obs;
  RxString variationStockStats = "".obs;
  Rx<ProductVariationModel> selectedVariation =
      ProductVariationModel.empty().obs;

  void onAttributeSelected(
    ProductModel product,
    attributeName,
    attributeValue,
  ) {
    final selectedAttributs = Map<String, dynamic>.from(selectedAttributes);
    selectedAttributs[attributeName] = attributeValue;
    selectedAttributes[attributeName] = attributeValue;

    final selectedVariation = product.productVariation!.firstWhere(
      (element) =>
          _isSamaAttributeValues(element.attributeValues, selectedAttributs),
      orElse: () => ProductVariationModel.empty(),
    );

    if (selectedVariation.image.isNotEmpty) {
      ImagesController.instance.selectedProductImage.value =
          selectedVariation.image;
    }

    /* if (selectedVariation.image.isNotEmpty) {
      final cartController = CartController.instance;
      cartController.productQuantityInCart.value = cartController
          .getVariationQuantityInCart(product.id, selectedVariation.id);
    }*/

    this.selectedVariation.value = selectedVariation;

    getProductVariationsStockStutus();
  }

  bool _isSamaAttributeValues(
    Map<String, dynamic> variationAttributes,
    Map<String, dynamic> selectedAttribues,
  ) {
    if (variationAttributes.length != selectedAttribues.length) return false;

    for (final key in variationAttributes.keys) {
      if (variationAttributes[key] != selectedAttribues[key]) return false;
    }

    return true;
  }

  Set<String?> getAttributesAvailableInVariation(
    List<ProductVariationModel> variation,
    String attributeName,
  ) {
    final availebleVariationAttributeValues = variation
        .where(
          (element) =>
              element.attributeValues[attributeName] != null &&
              element.attributeValues[attributeName]!.isNotEmpty &&
              element.stock > 0,
        )
        .map((variation) => variation.attributeValues[attributeName])
        .toSet();

    return availebleVariationAttributeValues;
  }

  void getProductVariationsStockStutus() {
    variationStockStats.value = selectedVariation.value.stock > 0
        ? "In Stock"
        : "Out of Stock";
  }

  void resetSelectedAttributes() {
    selectedAttributes.clear();
    variationStockStats.value = "";
    selectedVariation.value = ProductVariationModel.empty();
  }

  String getVariationPrice() {
    return (selectedVariation.value.salePrice > 0
            ? selectedVariation.value.salePrice
            : selectedVariation.value.price)
        .toString();
  }
}
