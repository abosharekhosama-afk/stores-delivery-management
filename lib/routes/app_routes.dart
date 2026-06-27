import 'package:get/route_manager.dart';
import 'package:stors_admin_panel/bindings/AdminBinding.dart';
import 'package:stors_admin_panel/bindings/DriverBinding.dart';
import 'package:stors_admin_panel/common/widgets/layouts/templates/sitelayout.dart';
import 'package:stors_admin_panel/common/widgets/success_screen/success_screen.dart';
import 'package:stors_admin_panel/data/ChooseUser/screen/choose_user_type_screen.dart';
import 'package:stors_admin_panel/data/Driver/Notification/screen/driver_notifications_screen.dart';
import 'package:stors_admin_panel/data/Driver/screen/DriverProfile/driver_profile_screen.dart';
import 'package:stors_admin_panel/data/Driver/screen/FinalDelivery/final_delivery_screen.dart';
import 'package:stors_admin_panel/data/Driver/screen/common/navigation_menu.dart';
import 'package:stors_admin_panel/data/Driver/storeReady/ready_stores_screen.dart';
import 'package:stors_admin_panel/data/Driver/storeDetails/store_orders_details_screen.dart';
import 'package:stors_admin_panel/data/Driver/screen/login/driver_login_creen.dart';
import 'package:stors_admin_panel/data/Driver/screen/login/driver_signup_screen.dart';
import 'package:stors_admin_panel/data/stor/models/store_orders_model.dart';
import 'package:stors_admin_panel/data/stor/screens/MerchantPendingActions/merchant_pending_actions_screen.dart';
import 'package:stors_admin_panel/data/stor/screens/Notification/notification_screen.dart';
import 'package:stors_admin_panel/data/stor/screens/dashboard/dashboard.dart';
import 'package:stors_admin_panel/data/stor/screens/orders/Orders/order_detail_screen.dart';
import 'package:stors_admin_panel/data/stor/screens/orders/Orders/order_tap.dart';
import 'package:stors_admin_panel/data/stor/screens/products/all_products/product.dart';
import 'package:stors_admin_panel/data/stor/screens/products/edit_product/edit_product.dart';
import 'package:stors_admin_panel/data/stor/screens/products/product_details/product_detail_screen.dart';
import 'package:stors_admin_panel/data/stor/screens/wallet/wallet_screen.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/Financial/financialscreen.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/forget_password/forget_password.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/login/AccountStatusScreen.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/login/login.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/regestar/regestar.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/regestar/verify_email_screen.dart';
import 'package:stors_admin_panel/features/features_authintication/screens/reset_password/reset_password.dart';
import 'package:stors_admin_panel/features/media/screens/media.dart';
import 'package:stors_admin_panel/data/stor/screens/products/creat_product/product_addition_screen.dart';
import 'package:stors_admin_panel/features/personalizatuon/screens/profile/profile.dart';
import 'package:stors_admin_panel/features/personalizatuon/screens/store_profile_screen.dart';
import 'package:stors_admin_panel/routes/route_middleware.dart';
import 'package:stors_admin_panel/routes/routes.dart';
import 'package:stors_admin_panel/utils/constants/enums.dart';

class AppRoutes {
  static final List<GetPage> pages = [
    GetPage(name: TRoutes.login, page: () => const LoginScreen()),
    GetPage(name: TRoutes.register, page: () => const Regestar()),
    GetPage(name: TRoutes.forgetPassword, page: () => const ForgetPassword()),
    GetPage(name: TRoutes.resetPassword, page: () => const ResetPassword()),
    GetPage(name: TRoutes.verifyEmail, page: () => const VerifyEmailScreen()),
    GetPage(
      name: TRoutes.accountStatus,
      page: () => const AccountStatusScreen(),
    ),
    GetPage(
      name: TRoutes.successScreen,
      page: () => SuccessScreen(image: "", title: "", subTitle: ""),
    ),
    GetPage(
      name: TRoutes.dashboard,
      page: () => const Dashboard(),
      middlewares: [RouteMiddleware()],
    ),
    GetPage(
      name: TRoutes.firstScreen,
      page: () => const TSitelayout(),
      binding: AdminBinding(),
      middlewares: [RouteMiddleware()],
    ),
    GetPage(
      name: TRoutes.media,
      page: () => const MediaScreen(),
      middlewares: [RouteMiddleware()],
    ),
    GetPage(
      name: TRoutes.products,
      page: () => const AllProduct(),
      middlewares: [RouteMiddleware()],
    ),
    GetPage(
      name: TRoutes.editProduct,
      page: () => const EditProduct(),
      middlewares: [RouteMiddleware()],
    ),
    GetPage(
      name: TRoutes.createProduct,
      page: () => const ProductAdditionScreen(),
      middlewares: [RouteMiddleware()],
    ),
    GetPage(
      name: TRoutes.profile,
      page: () => const Profile(),
      middlewares: [RouteMiddleware()],
    ),
    GetPage(
      name: TRoutes.financial,
      page: () => const FinancialScreen(),
      middlewares: [RouteMiddleware()],
    ),
    /*GetPage(
      name: TRoutes.orders,
      page: () => const VendorOrderManagement(),
      middlewares: [RouteMiddleware()],
    ),
    GetPage(
      name: TRoutes.ordersItemsList,
      page: () => const OrderItemsList(statusTab: ''),
      middlewares: [RouteMiddleware()],
    ),*/
    GetPage(
      name: TRoutes.ordersTap,
      page: () => const OrderTap(),
      middlewares: [RouteMiddleware()],
    ),
    GetPage(
      name: TRoutes.productDetails,
      page: () => ProductDetailScreen(),
      middlewares: [RouteMiddleware()],
    ),
    GetPage(
      name: TRoutes.storeProfileScreen,
      page: () => StoreProfileScreen(),
      middlewares: [RouteMiddleware()],
    ),
    GetPage(
      name: TRoutes.wallet,
      page: () => WalletScreen(),
      middlewares: [RouteMiddleware()],
    ),
    GetPage(
      name: TRoutes.notifications,
      page: () => NotificationScreen(),
      middlewares: [RouteMiddleware()],
    ),
    GetPage(
      name: TRoutes.ordersItemsDetail,
      page: () => OrderDetailScreen(
        order: StoreOrdersModel(
          storeOrderId: "",
          mainOrderId: '',
          storeId: '',
          orderDate: DateTime.now(),
          pickupDate: DateTime.now(),
          items: const [],
          status: OrderStatus.pending,
          userAddress: null,
          userId: '',
          pickupCode: "",
        ),
      ),
      middlewares: [RouteMiddleware()],
    ),
    GetPage(
      name: TRoutes.merchantPendingActions,
      page: () => const MerchantPendingActionsScreen(),
      middlewares: [RouteMiddleware()],
    ),

    GetPage(
      name: TRoutes.chooseUserType,
      page: () => const ChooseUserTypeScreen(),
    ),

    // شاشة دخول المندوب
    GetPage(name: TRoutes.driverLogin, page: () => DriverLoginScreen()),
    GetPage(name: TRoutes.driverLogin, page: () => DriverSignupScreen()),
    GetPage(name: TRoutes.storeOrdersDetails, page: () => DriverSignupScreen()),
    GetPage(name: TRoutes.readyStores, page: () => ReadyStoresScreen()),
    GetPage(
      name: TRoutes.navigationMenu,
      page: () => NavigationMenu(),
      binding: DriverBinding(),
    ),
    GetPage(name: TRoutes.finalDelivery, page: () => FinalDeliveryScreen()),
    GetPage(
      name: TRoutes.storeOrdersDetails,
      page: () => StoreOrdersDetailsScreen(storeId: '', storeName: ''),
    ),
    GetPage(
      name: TRoutes.driverNotifications,
      page: () => NotificationsScreen(),
    ),
    GetPage(name: TRoutes.driverProfile, page: () => DriverProfileScreen()),
  ];
}
