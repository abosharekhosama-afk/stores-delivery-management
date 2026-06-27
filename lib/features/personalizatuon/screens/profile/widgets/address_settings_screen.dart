import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stors_admin_panel/common/widgets/appbar/appbar.dart';
import 'package:stors_admin_panel/features/personalizatuon/controllers/address_controller_new.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:stors_admin_panel/utils/validators/validation.dart';

class AddressSettingsScreen extends StatelessWidget {
  const AddressSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddressControllerNew());

    return Scaffold(
      appBar: TAppBar(title: const Text('إعدادات العنوان'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              // 1. المحافظة
              DropdownSearch<String>(
                items: (filter, loadProps) =>
                    controller.palestineAddressData.keys.toList(),
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

              // 2. المنطقة
              Obx(
                () => DropdownSearch<String>(
                  items: (filter, loadProps) => controller.districtsList,
                  enabled: controller.selectedCity.isNotEmpty,
                  selectedItem: controller.selectedDistrict.value.isEmpty
                      ? null
                      : controller.selectedDistrict.value,
                  onChanged: (value) => controller.onDistrictChanged(value),
                  decoratorProps: const DropDownDecoratorProps(
                    decoration: InputDecoration(labelText: "المنطقة/الحي"),
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
                    decoration: InputDecoration(labelText: "الشارع"),
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

              TextFormField(
                controller: controller.addressDetails,
                decoration: const InputDecoration(
                  labelText: "تفاصيل العنوان",
                  prefixIcon: Icon(Iconsax.info_circle),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => controller.updateAddress(),
                  child: const Text("حفظ العنوان"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
