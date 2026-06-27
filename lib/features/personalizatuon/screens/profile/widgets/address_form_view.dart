import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/features/personalizatuon/controllers/profile_controller.dart';
import 'package:stors_admin_panel/utils/constants/address_data.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:stors_admin_panel/utils/validators/validation.dart';

class AddressFormWidget extends StatelessWidget {
  const AddressFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProfileController.instance; // استخدام الكنترولر الموحد

    return Column(
      children: [
        // 1. المحافظة
        DropdownSearch<String>(
          items: (filter, loadProps) => palestineAddressData.keys.toList(),
          decoratorProps: const DropDownDecoratorProps(
            decoration: InputDecoration(
              labelText: "المحافظة",
              prefixIcon: Icon(Iconsax.location),
            ),
          ),
          onChanged: (value) => controller.onCityChanged(value),
          selectedItem: controller.selectedCity.value.isEmpty
              ? null
              : controller.selectedCity.value,
        ),

        const SizedBox(height: TSizes.spaceBtwInputFields),

        // 2. المنطقة (تحتاج Obx لأن القائمة تتغير)
        Obx(
          () => DropdownSearch<String>(
            items: (filter, loadProps) => controller.districtsList,
            enabled: controller.selectedCity.isNotEmpty,
            selectedItem: controller.selectedDistrict.value.isEmpty
                ? null
                : controller.selectedDistrict.value,
            onChanged: (value) => controller.onDistrictChanged(value),
            decoratorProps: DropDownDecoratorProps(
              decoration: InputDecoration(
                labelText: "المنطقة/الحي",
                hintText: controller.selectedCity.isEmpty
                    ? "اختر المحافظة أولاً"
                    : "اختر المنطقة",
              ),
            ),
          ),
        ),

        const SizedBox(height: TSizes.spaceBtwInputFields),

        // 3. الشارع
        Obx(
          () => DropdownSearch<String>(
            items: (filter, loadProps) => controller.streetsList,
            enabled: controller.selectedDistrict.isNotEmpty,
            selectedItem: controller.selectedStreet.value.isEmpty
                ? null
                : controller.selectedStreet.value,
            onChanged: (value) => controller.onStreetChanged(value),
            decoratorProps: const DropDownDecoratorProps(
              decoration: InputDecoration(labelText: "الشارع/الحي الفرعي"),
            ),
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwInputFields),
        Obx(
          () => DropdownSearch<String>(
            items: (filter, loadProps) => controller.landmarksList,
            enabled: controller.selectedDistrict.isNotEmpty,
            selectedItem: controller.selectedMarks.value.isEmpty
                ? null
                : controller.selectedMarks.value,
            onChanged: (value) => controller.onMarksChanged(value),
            decoratorProps: const DropDownDecoratorProps(
              decoration: InputDecoration(labelText: "اقرب معلم"),
            ),
          ),
        ),

        const SizedBox(height: TSizes.spaceBtwInputFields),

        // 4. رقم المبنى
        TextFormField(
          controller: controller.buildingNumber,
          decoration: const InputDecoration(
            labelText: "رقم المبنى",
            prefixIcon: Icon(Iconsax.building),
          ),
          validator: (value) =>
              TValidator.validateEmptyText("رقم المبنى", value),
        ),

        const SizedBox(height: TSizes.spaceBtwInputFields),

        // 5. الرمز البريدي
        TextFormField(
          controller: controller.postalCode,
          decoration: const InputDecoration(
            labelText: "الرمز البريدي",
            prefixIcon: Icon(Iconsax.code),
          ),
        ),

        const SizedBox(height: TSizes.spaceBtwInputFields),

        // 6. العنوان التفصيلي
        TextFormField(
          controller: controller.addressDetails,
          decoration: const InputDecoration(
            labelText: "العنوان التفصيلي",
            prefixIcon: Icon(Iconsax.info_circle),
          ),
        ),
      ],
    );
  }
}
