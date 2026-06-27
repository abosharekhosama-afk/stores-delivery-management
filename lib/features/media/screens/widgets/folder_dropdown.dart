import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/features/media/controller/media_controller.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';

class FolderDropdown extends StatelessWidget {
  const FolderDropdown({super.key, this.onChanged});
  final void Function(MediaCategory?)? onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = MediaController.instance;
    return Obx(
      () => SizedBox(
        width: 140,
        child: DropdownButtonFormField(
          isExpanded: false,
          value: controller.selectPath.value,
          items: MediaCategory.values
              .map(
                (category) => DropdownMenuItem(
                  value: category,
                  child: Text(category.name.capitalize.toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
