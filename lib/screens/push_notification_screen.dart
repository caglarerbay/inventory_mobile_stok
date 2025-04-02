import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PushNotificationScreen extends StatefulWidget {
  @override
  _PushNotificationScreenState createState() => _PushNotificationScreenState();
}

class _PushNotificationScreenState extends State<PushNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _title;
  String? _message;
  bool _isSending = false;
  String? _resultMessage;

  Future<void> _sendPushNotification() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSending = true;
      _resultMessage = null;
    });

    // SharedPreferences'ten token’ı alıyoruz:
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    // Sunucunuzdaki bildirim endpoint'ini kullanın.
    final url = Uri.parse(
      "http://nukstoktakip.eu-north-1.elasticbeanstalk.com/api/send_push_notification/",
    );

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          // Oturum bilgilerini Authorization header'ıyla gönderiyoruz.
          "Authorization": "Token $token",
        },
        body: jsonEncode({"title": _title, "message": _message}),
      );

      setState(() {
        _isSending = false;
        if (response.statusCode == 200) {
          _resultMessage = "Bildirim gönderildi.";
        } else {
          _resultMessage =
              "Hata: ${response.statusCode} - ${response.body.toString()}";
        }
      });
    } catch (e) {
      setState(() {
        _isSending = false;
        _resultMessage = "Hata oluştu: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Push Bildirim Gönder")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _isSending
                ? Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      if (_resultMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _resultMessage!,
                            style: TextStyle(
                              color:
                                  _resultMessage!.startsWith("Hata")
                                      ? Colors.red
                                      : Colors.green,
                            ),
                          ),
                        ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Başlık'),
                        validator:
                            (value) => value!.isEmpty ? 'Başlık giriniz' : null,
                        onSaved: (value) => _title = value,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Mesaj'),
                        validator:
                            (value) => value!.isEmpty ? 'Mesaj giriniz' : null,
                        onSaved: (value) => _message = value,
                        maxLines: 3,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _sendPushNotification,
                        child: Text("Gönder"),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
