import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

//cihaz ve kurum bilgi importları

import 'package:inventory_mobile/services/api_constants.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/transfer_usage_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/admin_add_product_screen.dart';
import 'screens/admin_update_stock_screen.dart';
import 'screens/admin_user_stocks_screen.dart';
import 'screens/my_stock_screen.dart';
import 'screens/admin_settings_screen.dart';
import 'screens/admin_min_limit_screen.dart';
import 'screens/push_notification_screen.dart';
import 'screens/notification_history_screen.dart';
import 'screens/external_list_screen.dart';
import 'screens/critical_stock_screen.dart';

//cihaz vekurum bilgisi dart importları

import 'screens/manage_screen.dart';

//kurum bilgise devam importları

import 'screens/institutions_list_screen.dart';
import 'screens/institution_detail_screen.dart';
import 'screens/institution_edit_screen.dart';
import 'screens/institution_note_edit_screen.dart';
import 'screens/institution_create_screen.dart';

// Model tipi route’ta cast etmek için
import 'models/institution_note.dart';
//cihaz görüntüleme listesi için import
import 'package:inventory_mobile/screens/devices_list_screen.dart';
//cihaz ekleme sayfası için import
import 'package:inventory_mobile/screens/device_create_screen.dart';
//cihaz detay sayfası için import
import 'package:inventory_mobile/screens/device_detail_screen.dart';
//bakım sayfası için import
import 'package:inventory_mobile/screens/maintenance_list_screen.dart';
//arıza sayfası için import
import 'package:inventory_mobile/screens/fault_list_screen.dart';
//bakım sayfası yeni bakım ekleme sayfası için import
import 'package:inventory_mobile/screens/maintenance_create_screen.dart';
//arıza sayfası yeni arıza ekleme sayfası için import
import 'package:inventory_mobile/screens/fault_create_screen.dart';
//cihaz kurulum sayfası için import
import 'package:inventory_mobile/screens/installation_create_screen.dart';
//kurulum geçmişi sayfası için import
import 'package:inventory_mobile/screens/installation_history_screen.dart';
//arıza ekranları için importlar
import 'package:inventory_mobile/models/fault_record.dart';
import 'screens/fault_form_screen.dart';

///

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase initialize işlemi
  runApp(TokenRegister(child: MyApp()));
}

Future<bool> checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  return token != null && token.isNotEmpty;
}

/// Bu widget, uygulama başlatıldığında cihazın tokenını alır, backend'e gönderir
/// ve gelen foreground mesajları yerel bildirim olarak gösterir.
class TokenRegister extends StatefulWidget {
  final Widget child;
  const TokenRegister({required this.child});

  @override
  _TokenRegisterState createState() => _TokenRegisterState();
}

class _TokenRegisterState extends State<TokenRegister> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    // Local notifications plugin'ini initialize ediyoruz.
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        navigatorKey.currentState?.pushNamed('/notification_history');
      },
    );

    _registerAndSendToken();

    // Gelen FCM mesajlarını dinliyoruz.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print(
        "Mesaj alındı: ${message.notification?.title} - ${message.notification?.body}",
      );
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        const AndroidNotificationDetails
        androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'high_importance_channel', // AndroidManifest'de tanımlı kanal id'si
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
        const NotificationDetails platformChannelSpecifics =
            NotificationDetails(android: androidPlatformChannelSpecifics);
        await flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          platformChannelSpecifics,
          payload: 'Default_Sound',
        );
      }
    });
  }

  Future<void> _registerAndSendToken() async {
    String? token = await _messaging.getToken();
    print("Device Token: $token");
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString("username") ?? "";
      if (username.isEmpty) {
        print("Username bulunamadı, token gönderilemedi.");
        return;
      }
      final url = Uri.parse('${ApiConstants.baseUrl}/api/save_device_token/');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"device_token": token, "username": username}),
      );
      print("Token gönderildi, status: ${response.statusCode}");
      print("Sunucu cevabı: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Global navigator key ekleniyor
      title: 'Stok Takip',
      home: FutureBuilder<bool>(
        future: checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData && snapshot.data == true) {
            return HomeScreen();
          } else {
            return LoginScreen();
          }
        },
      ),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/forgot_password': (context) => ForgotPasswordScreen(),
        '/home': (context) => HomeScreen(),
        '/transfer_usage': (context) => TransferUsageScreen(),
        '/admin_panel': (context) => AdminPanelScreen(),
        '/admin_add_product': (context) => AdminAddProductScreen(),
        '/admin_update_stock': (context) => AdminUpdateStockScreen(),
        '/admin_user_stocks': (context) => AdminUserStocksScreen(),
        '/my_stock_screen': (context) => MyStockScreen(),
        '/admin_settings': (context) => AdminSettingsScreen(),
        '/admin_min_limit': (context) => AdminMinLimitScreen(),
        '/push_notification': (context) => PushNotificationScreen(),
        '/notification_history': (context) => NotificationHistoryScreen(),
        '/external_products': (context) => ExternalListScreen(),
        '/critical_stock': (_) => CriticalStockScreen(),

        '/manage': (ctx) => ManageScreen(),
        // kurum bilgisi ve cihaz bilgisi ekranı
        // *** Kurumlar modülü için yeni route’lar: ***
        // Kurumlar Listeleme
        '/institutions': (ctx) => InstitutionsListScreen(),

        // Kurum Detay
        '/institutions/detail': (ctx) {
          final id = ModalRoute.of(ctx)!.settings.arguments as int;
          return InstitutionDetailScreen(institutionId: id);
        },

        // Kurum Düzenleme
        '/institutions/edit': (ctx) {
          final id = ModalRoute.of(ctx)!.settings.arguments as int;
          return InstitutionEditScreen(institutionId: id);
        },

        // Kurum Notu Ekle / Düzenle
        '/institution-notes/edit': (ctx) {
          final args =
              ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
          return InstitutionNoteEditScreen(
            institutionId: args['institutionId'] as int,
            note: args['note'] as InstitutionNote?,
          );
        },

        // ********************************************************

        //yeni kurum ekleme rotası
        '/institutions/create': (ctx) => InstitutionCreateScreen(),
        //cihaz liteleme
        '/devices/list': (context) => DevicesListScreen(),
        //cihaz ekleme sayfası
        '/devices/create': (context) => DeviceCreateScreen(),
        //cihaz detay sayfası
        '/devices/detail': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as int;
          return DeviceDetailScreen(deviceId: id);
        },
        //bakım route
        '/devices/maintenance/list': (ctx) {
          final deviceId = ModalRoute.of(ctx)!.settings.arguments as int;
          return MaintenanceListScreen(deviceId: deviceId);
        },

        //arıza route (değiştirildi)
        '/devices/fault/list':
            (c) => FaultListScreen(
              deviceId: ModalRoute.of(c)!.settings.arguments as int,
            ),

        //yeni bakım ekleme sayfası
        '/devices/maintenance/create': (ctx) {
          final deviceId = ModalRoute.of(ctx)!.settings.arguments as int;
          return MaintenanceCreateScreen(deviceId: deviceId);
        },

        //yeni arıza ekleme sayfası
        '/devices/fault/create': (ctx) {
          final deviceId = ModalRoute.of(ctx)!.settings.arguments as int;
          return FaultCreateScreen(deviceId: deviceId);
        },

        //cihaz kurulum sayfası route
        '/devices/installation/create': (ctx) {
          final deviceId = ModalRoute.of(ctx)!.settings.arguments as int;
          return InstallationCreateScreen(deviceId: deviceId);
        },

        //kurulum geçmişi sayfası route
        '/devices/installation/history': (ctx) {
          final deviceId = ModalRoute.of(ctx)!.settings.arguments as int;
          return InstallationHistoryScreen(deviceId: deviceId);
        },

        //arıza güncelleme formu
        '/devices/fault/form': (c) {
          final arg = ModalRoute.of(c)!.settings.arguments;
          if (arg is FaultRecord) {
            return FaultFormScreen(deviceId: arg.deviceId, fault: arg);
          } else {
            return FaultFormScreen(deviceId: arg as int, fault: null);
          }
        },
      },
    );
  }
}
