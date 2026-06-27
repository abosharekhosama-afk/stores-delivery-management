import 'package:stors_admin_panel/data/stor/models/brand_model.dart';
import 'package:stors_admin_panel/data/stor/models/product_attribute_model.dart';
import 'package:stors_admin_panel/data/stor/models/product_model.dart';
import 'package:stors_admin_panel/data/stor/models/product_variation_model.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';
import 'package:stors_admin_panel/utils/constants/image_strings.dart';

const Map<String, Map<String, List<String>>> palestineAddressData = {
  "شمال غزة": {
    "جباليا": [
      "مخيم جباليا",
      "منطقة الفالوجا",
      "شارع الهوجا",
      "تل الزعتر",
      "عزبة عبد ربه",
    ],
    "بيت لاهيا": [
      "مشروع بيت لاهيا",
      "منطقة السلاطين",
      "شارع المنشية",
      "عزبة فدعة",
      "قرية أم النصر",
    ],
    "بيت حانون": [
      "شارع خليل الوزير",
      "منطقة المصريين",
      "شارع القسام",
      "منطقة البورصة",
    ],
  },
  "مدينة غزة": {
    "الرمال": [
      "الرمال الجنوبي",
      "الرمال الشمالي",
      "شارع عمر المختار",
      "شارع الوحدة",
      "شارع النصر",
    ],
    "الشيخ رضوان": [
      "الشارع الأول",
      "شارع الجلاء",
      "منطقة جسر الشيخ رضوان",
      "بئر النعجة",
    ],
    "النصر": [
      "شارع النصر العام",
      "منطقة المستشفيات",
      "المخابرات",
      "شارع العيون",
    ],
    "الزيتون": ["شارع صلاح الدين", "شارع كشكو", "منطقة عسقولة", "دوار دولة"],
    "الشجاعية": ["شارع بغداد", "حي التركمان", "حي الجديدة", "شارع المنصورة"],
    "تل الهوا": ["شارع جامعة الدول العربية", "منطقة برشلونة", "دوار الدحدوح"],
    "الصبرة": ["شارع المغربي", "منطقة الثكنة", "حي الدحدوح"],
  },
  "الوسطى": {
    "دير البلح": [
      "شارع الرشيد",
      "حي البشارة",
      "منطقة البركة",
      "مخيم دير البلح",
      "شارع السلام",
    ],
    "النصيرات": [
      "مخيم 1",
      "مخيم 2",
      "سوق النصيرات",
      "شارع العشرين",
      "منطقة الحساينة",
    ],
    "البريج": ["مدخل البريج", "بلوك 1", "بلوك 12", "شارع صلاح الدين (البريج)"],
    "المغازي": ["مخيم المغازي", "منطقة الزعفران", "شارع السكة"],
  },
  "خانيونس": {
    "وسط البلد": [
      "شارع جلال",
      "شارع البحر",
      "منطقة القلعة",
      "حي الأمل",
      "مخيم خانيونس",
    ],
    "بني سهيلا": ["دوار بني سهيلا", "حي الرميضة", "شارع العودة"],
    "عبسان": ["عبسان الكبيرة", "عبسان الصغيرة", "منطقة الفراحين"],
    "القرارة": ["شارع صلاح الدين (القرارة)", "منطقة المعري", "حي الأسطر"],
    "الفخاري": ["منطقة المستشفى الأوروبي", "عزبة العمور"],
  },
  "رفح": {
    "وسط البلد": [
      "شارع البحر (رفح)",
      "ميدان العودة",
      "حي الشابورة",
      "مخيم يبنا",
    ],
    "تل السلطان": ["شارع الرشيد (رفح)", "الحي السعودي", "منطقة الإسكان"],
    "خربة العدس": ["شارع جورني", "منطقة موراج", "حي النصر (رفح)"],
    "حي الجنينة": ["شارع المضخة", "منطقة التنور"],
  },
};

class TestPro {
  static List<ProductModel> testProducts = [
    // 1. منتج بسيط (Simple Product) - هاتف ذكي
    ProductModel(
      id: '001',
      storId: 'store_01',
      title: 'iPhone 15 Pro',
      stock: 15,
      price: 999.0,
      salePrice: 899.0,
      thumbnail: TImages.productImage18, // فارغ بناءً على طلبك
      productType: 'ProductType.single',
      productVisibility: ProductVisibility.published,
      sku: 'IPH15-PRO-BLU',
      date: DateTime.now(),
      isFeatured: true,
      categoryId: 'cat_electronics',
      description: 'أحدث هاتف من شركة آبل مع معالج A17 Pro الكتروني.',
      brande: BrandModel(
        id: 'b1',
        name: 'Apple',
        image: '',
        isFeatured: true,
        productsCount: 50,
      ),
      images: ['', '', ''],
    ),

    // 2. منتج بمتغيرات (Variable Product) - قميص رياضي
    ProductModel(
      id: '002',
      storId: 'store_01',
      title: 'T-Shirt Adidas Training',
      stock: 100,
      price: 45.0,
      salePrice: 35.0,
      thumbnail: TImages.productImage10,
      productType: 'ProductType.variable',
      productVisibility: ProductVisibility.published,
      sku: 'ADI-TSHIRT-01',
      date: DateTime.now(),
      isFeatured: false,
      categoryId: 'cat_clothing',
      description: 'قميص رياضي مريح مناسب للتمارين اليومية.',
      brande: BrandModel(
        id: 'b2',
        name: 'Adidas',
        image: '',
        isFeatured: true,
        productsCount: 120,
      ),

      // تعريف الخصائص (Attributes)
      productAttribute: [
        ProductAttributeModel(name: 'Color', values: ['Black', 'Blue']),
        ProductAttributeModel(name: 'Size', values: ['M', 'L', 'XL']),
      ],

      // تعريف المتغيرات (Variations)
      productVariation: [
        ProductVariationModel(
          id: 'v1',
          sku: 'ADI-BLK-M',
          image: TImages.productImage13,
          price: 45.0,
          salePrice: 35.0,
          stock: 10,
          attributeValues: {'Color': 'Black', 'Size': 'M'},
        ),
        ProductVariationModel(
          id: 'v2',
          sku: 'ADI-BLU-L',
          image: TImages.productImage22,
          price: 50.0,
          salePrice: 40.0,
          stock: 5,
          attributeValues: {'Color': 'Blue', 'Size': 'L'},
        ),
      ],
    ),

    // 3. منتج بسيط آخر - سماعات لاسلكية
    ProductModel(
      id: '003',
      storId: 'store_02',
      title: 'Sony WH-1000XM5',
      stock: 8,
      price: 350.0,
      salePrice: 320.0,
      thumbnail: TImages.productImage20,
      productType: 'ProductType.single',
      productVisibility: ProductVisibility.published,
      sku: 'SONY-WH1000',
      date: DateTime.now(),
      isFeatured: true,
      categoryId: 'cat_audio',
      description: 'سماعات عازلة للضوضاء بجودة صوت استثنائية.',
      brande: BrandModel(
        id: 'b3',
        name: 'Sony',
        image: '',
        isFeatured: false,
        productsCount: 30,
      ),
    ),
  ];
}
