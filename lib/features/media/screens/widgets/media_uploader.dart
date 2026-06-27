import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/common/widgets/containers/rounded_container.dart';
import 'package:stors_admin_panel/common/widgets/images/t_rounded_image.dart';
import 'package:stors_admin_panel/features/media/controller/media_controller.dart';
import 'package:stors_admin_panel/features/media/screens/widgets/folder_dropdown.dart';
import 'package:stors_admin_panel/utils/constants/colors.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/image_strings.dart';
import 'package:stors_admin_panel/utils/constants/sizes.dart';
import 'package:stors_admin_panel/utils/device/device_utility.dart';

class MediaUploader extends StatelessWidget {
  const MediaUploader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = MediaController.instance;

    return Obx(
      () => controller.showImageUploaderSection.value
          ? Column(
              children: [
                TRoundedContainer(
                  height: 250,
                  showBorder: true,
                  borderColor: TColors.borderPrimary,
                  backgroundColor: TColors.primaryBackground,
                  padding: EdgeInsets.all(TSizes.defaultSpace),
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            DropzoneView(
                              mime: ["image/jpeg"],
                              cursor: CursorType.Default,
                              operation: DragOperation.copy,
                              onLoaded: () => debugPrint("zone loaded"),
                              onLeave: () => debugPrint("zone onLeave"),
                              onError: (ev) => debugPrint("zone onError: $ev"),
                              onHover: () => debugPrint("zone onHover"),
                              onCreated: (contrl) =>
                                  controller.dropzoneViewController = contrl,

                              onDropInvalid: (value) =>
                                  debugPrint("zone onDropInvalid: $value"),
                              onDropMultiple: (ev) async {
                                debugPrint("zone onDropMultiple: $ev");
                              },
                              /*onDrop: (file) async {
                                if (file is html.File) {
                                  final bytes = await controller
                                      .dropzoneViewController
                                      .getFileData(file);

                                  final image = ImageModel(
                                    url: "",
                                    folder: "",
                                    fileName: file.name,
                                    file: file,
                                    localImageToDisplay: Uint8List.fromList(
                                      bytes,
                                    ),
                                  );
                                  controller.selectedImagesToUpload.add(image);
                                } else if (file is String) {
                                  debugPrint("zone drop: $file");
                                } else {
                                  debugPrint("zone unk type: ${file.runtimeType}");
                                }
                              },*/
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  TImages.defaultMultiImageIcon,
                                  width: 50,
                                  height: 50,
                                ),
                                const SizedBox(height: TSizes.spaceBtwItems),
                                const Text("اسحب و افلت الصور هنا"),
                                const SizedBox(height: TSizes.spaceBtwItems),
                                OutlinedButton(
                                  onPressed: () {},
                                  child: const Text("اختر صور"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                if (controller.selectedImagesToUpload.isNotEmpty)
                  TRoundedContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [
                            Row(
                              children: [
                                Text(
                                  "اختر مجلد",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(width: TSizes.spaceBtwItems),
                                FolderDropdown(
                                  onChanged: (MediaCategory? newValue) {
                                    if (newValue != null) {
                                      controller.selectPath.value = newValue;
                                    }
                                  },
                                ),
                              ],
                            ),

                            Row(
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      controller.selectedImagesToUpload.clear(),
                                  child: const Text("ازالة الجميع"),
                                ),
                                const SizedBox(height: TSizes.spaceBtwItems),
                                TDeviceUtils.isMobileScreen(context)
                                    ? const SizedBox.shrink()
                                    : SizedBox(
                                        width: TSizes.buttonWidth,
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              controller.uploadImages(),
                                          child: const Text("رفع"),
                                        ),
                                      ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(width: TSizes.spaceBtwSections),

                        Wrap(
                          alignment: WrapAlignment.start,
                          spacing: TSizes.spaceBtwItems / 2,
                          runSpacing: TSizes.spaceBtwItems / 2,
                          children: controller.selectedImagesToUpload
                              .where(
                                (image) => image.localImageToDisplay != null,
                              )
                              .map(
                                (element) => TRoundedImage(
                                  imageType: ImageType.memory,
                                  memoryImage: element.localImageToDisplay,
                                  width: 90,
                                  height: 90,
                                  padding: TSizes.sm,
                                  backgroundColor: TColors.primaryBackground,
                                ),
                              )
                              .toList(),
                          /*[
                            ListView.builder(
                              itemCount: 11,
                              itemBuilder: (context, index) {
                                return TRoundedImage(
                                  imageType: ImageType.asset,
                                  image: TImages.adidasLogo,
                                  width: 90,
                                  height: 90,
                                  padding: TSizes.sm,
                                  backgroundColor: TColors.primaryBackground,
                                );
                              },
                            ),
                          ],*/
                        ),
                        const SizedBox(height: TSizes.spaceBtwSections),
                        TDeviceUtils.isMobileScreen(context)
                            ? SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  child: const Text("رفع"),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

