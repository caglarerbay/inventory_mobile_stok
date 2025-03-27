import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _username;
  String? _email;
  // Daily access code alanı kaldırıldı.
  String? _password;
  String? _password2;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submitForm() async {
    // Form doğrulaması
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse('http://127.0.0.1:8000/api/register/');
    // Uygun base URL'yi kullanmayı unutmayın.
    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': _username,
          'email': _email,
          // 'access_code' alanı kaldırıldı.
          'password': _password,
          'password2': _password2,
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          _isLoading = false;
        });
        Navigator.pop(context);
      } else {
        setState(() {
          _isLoading = false;
          final decoded = json.decode(utf8.decode(response.bodyBytes));
          _errorMessage = decoded['detail'] ?? 'Bilinmeyen hata.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sunucuya erişilemedi. Hata: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kayıt Ol')),
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
                        decoration: InputDecoration(labelText: 'Email'),
                        validator:
                            (value) => value!.isEmpty ? 'Email giriniz' : null,
                        onSaved: (value) => _email = value,
                      ),
                      // Daily code alanı kaldırıldı.
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Şifre'),
                        obscureText: true,
                        validator:
                            (value) => value!.isEmpty ? 'Şifre giriniz' : null,
                        onSaved: (value) => _password = value,
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Şifre (Tekrar)',
                        ),
                        obscureText: true,
                        onSaved: (value) => _password2 = value,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: Text('Kayıt Ol'),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
