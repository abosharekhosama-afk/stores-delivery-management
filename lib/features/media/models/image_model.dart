import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:stors_admin_panel/utils/formatters/formatter.dart';
import 'package:universal_html/html.dart';

class ImageModel {
  String id;
  final String url;
  final String folder;
  final int? sizeBytes;
  String mediaCategory;
  final String? fullpath;
  final DateTime? createdAt;
  final DateTime? updateAt;
  final String? contentType;
  final File? file;
  final String fileName;
  RxBool isSelected = false.obs;
  final Uint8List? localImageToDisplay;

  ImageModel({
    required this.url,
    required this.folder,
    required this.fileName,
    this.id = "",
    this.sizeBytes,
    this.fullpath,
    this.createdAt,
    this.updateAt,
    this.contentType,
    this.file,
    this.localImageToDisplay,
    this.mediaCategory = "",
  });

  static ImageModel empty() => ImageModel(folder: "", fileName: "", url: "");

  String get createdAtFormatted => TFormatter.formatDate(createdAt);
  String get updatedAtFormatted => TFormatter.formatDate(updateAt);

  Map<String, dynamic> toJson() {
    return {
      "url": url,
      "folder": folder,
      "sizeBytes": sizeBytes,
      "fileName": fileName,
      "fullpath": fullpath,
      "createdAt": createdAt?.toUtc(),
      "mediaCategory": mediaCategory,
    };
  }

  factory ImageModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    if (document.data() != null) {
      final data = document.data()!;

      return ImageModel(
        id: document.id,
        sizeBytes: data["sizeBytes"],
        fullpath: data["fullpath"],
        createdAt: data.containsKey("createdAt")
            ? data["createdAt"]?.toDate()
            : null,
        updateAt: data.containsKey("updateAt")
            ? data["updateAt"]?.toDate()
            : null,
        contentType: data["contentType"] ?? "",
        url: data["url"] ?? "",
        folder: data["folder"] ?? "",
        fileName: data["fileName"] ?? "",
        mediaCategory: data["mediaCategory"] ?? "",
      );
    } else {
      return ImageModel.empty();
    }
  }

  factory ImageModel.fromFirbaseMetadata(
    FullMetadata metadata,
    String folder,
    String fileName,
    String downlodUrl,
  ) {
    return ImageModel(
      url: downlodUrl,
      folder: folder,
      fileName: fileName,
      fullpath: metadata.fullPath,
      sizeBytes: metadata.size,
      updateAt: metadata.updated,
      createdAt: metadata.timeCreated,
      contentType: metadata.contentType,
    );
  }
}
