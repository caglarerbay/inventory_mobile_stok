import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/api_constants.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _username;
  String? _password;
  bool _isLoading = false;
  String? _errorMessage;

  final authService = AuthService();

  // _LoginScreenState sınıfı içinde, _submitForm() metodundan önce ekleyin:
  Future<void> _registerAndSendToken() async {
    // Firebase Messaging'den token'ı alıyoruz:
    String? token = await FirebaseMessaging.instance.getToken();
    print("Device Token: $token");

    if (token != null) {
      // SharedPreferences'ten username'i alıyoruz:
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString("username") ?? "";
      if (username.isEmpty) {
        print("Username bulunamadı, token gönderilemedi.");
        return;
      }
      // Backend URL'si: (Üretim ortamındaki URL'yi kullanın.)
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await authService.login(_username!, _password!);

      // data örneği:
      // { "detail": "Giriş başarılı.", "staff_flag": true/false, "token": "..." }
      final bool staffFlag = data['staff_flag'] ?? false;
      final String? token = data['token'];

      // SharedPreferences ile token'ı kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token ?? '');
      await prefs.setBool('staffFlag', staffFlag);
      await prefs.setString('username', _username!);
      await _registerAndSendToken();

      setState(() {
        _isLoading = false;
      });

      // "token" ve "staff_flag" değerlerini /home rotasına arguments olarak yolluyoruz
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: {"token": token, "staff_flag": staffFlag},
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Giriş Yap')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child:
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red),
                        ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Kullanıcı Adı'),
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Kullanıcı adı giriniz' : null,
                        onSaved: (value) => _username = value,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Şifre'),
                        obscureText: true,
                        validator:
                            (value) => value!.isEmpty ? 'Şifre giriniz' : null,
                        onSaved: (value) => _password = value,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: Text('Giriş Yap'),
                      ),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text('Kayıt Ol'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/forgot_password');
                        },
                        child: Text('Şifremi Unuttum'),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
