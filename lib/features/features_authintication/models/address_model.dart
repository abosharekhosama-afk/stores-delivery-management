import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  String country;
  String city;
  String district;
  String street;
  String buildingNumber;
  String postalCode;
  String address;

  AddressModel({
    required this.country,
    required this.city,
    required this.district,
    required this.street,
    required this.buildingNumber,
    required this.postalCode,
    required this.address,
  });

  static String get getCountry => "country";
  static String get getCity => "city";
  static String get getDistrict => "district";
  static String get getStreet => "street";
  static String get getBuildingNumber => "buildingNumber";
  static String get getPostalCode => "postalCode";
  static String get getAddress => "address";

  String get fullAddress =>
      "$country, $city, $district, $street $buildingNumber, $postalCode";

  String get subAddress => "$city, $district, $street, $address";

  static AddressModel empty() => AddressModel(
    country: "",
    city: "",
    district: "",
    street: "",
    buildingNumber: "",
    postalCode: "",
    address: "",
  );

  Map<String, dynamic> toJson() {
    return {
      getCountry: country,
      getCity: city,
      getDistrict: district,
      getStreet: street,
      getBuildingNumber: buildingNumber,
      getPostalCode: postalCode,
      getAddress: address,
    };
  }

  AddressModel copyWith({
    String? country,
    String? city,
    String? district,
    String? street,
    String? buildingNumber,
    String? postalCode,
    String? address,
  }) {
    return AddressModel(
      country: country ?? this.country,
      city: city ?? this.city,
      district: district ?? this.district,
      street: street ?? this.street,
      buildingNumber: buildingNumber ?? this.buildingNumber,
      postalCode: postalCode ?? this.postalCode,
      address: address ?? this.address,
    );
  }

  factory AddressModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    if (document.data() != null) {
      final data = document.data()!;
      return AddressModel(
        country: data[getCountry] ?? "",
        city: data[getCity] ?? "",
        district: data[getDistrict] ?? "",
        street: data[getStreet] ?? "",
        address: data[getAddress] ?? "",
        buildingNumber: data[getBuildingNumber] ?? "",
        postalCode: data[getPostalCode] ?? "",
      );
    } else {
      return AddressModel.empty();
    }
  }

  factory AddressModel.fromMap(Map<String, dynamic> data) {
    return AddressModel(
      country: data[getCountry] ?? "",
      city: data[getCity] ?? "",
      district: data[getDistrict] ?? "",
      street: data[getStreet] ?? "",
      buildingNumber: data[getBuildingNumber] ?? "",
      postalCode: data[getPostalCode] ?? "",
      address: data[getAddress] ?? "",
    );
  }
}
