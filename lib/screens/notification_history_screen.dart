// lib/screens/notification_history_screen.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventory_mobile/services/api_constants.dart';

class NotificationHistoryScreen extends StatefulWidget {
  @override
  _NotificationHistoryScreenState createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  List notifications = [];
  bool isLoading = true;
  bool isStaff = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    fetchNotifications();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isStaff = prefs.getBool('staffFlag') ?? false;
    });
  }

  Future<void> fetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final url = Uri.parse('${ApiConstants.baseUrl}/api/notification_history/');

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Token $token",
      },
    );

    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes);
      final data = json.decode(body);
      setState(() {
        notifications = data["notifications"];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteNotification(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";
    final notif = notifications[index];
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/api/notification_history/${notif["id"]}/',
    );

    final response = await http.delete(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Token $token",
      },
    );

    if (response.statusCode == 204) {
      setState(() {
        notifications.removeAt(index);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bildirim silindi.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silme hatası: ${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bildirim Geçmişi")),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return ListTile(
                    title: Text(notification["title"]),
                    subtitle: Text(notification["sent_at"]),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => NotificationDetailScreen(
                                notification: notification,
                              ),
                        ),
                      );
                    },
                    onLongPress:
                        isStaff ? () => _deleteNotification(index) : null,
                    trailing:
                        isStaff
                            ? IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteNotification(index),
                            )
                            : null,
                  );
                },
              ),
    );
  }
}

class NotificationDetailScreen extends StatelessWidget {
  final Map notification;

  NotificationDetailScreen({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bildirim Detayı")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification["title"],
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text("Gönderilme Zamanı: ${notification["sent_at"]}"),
            Divider(),
            SizedBox(height: 10),
            Text(notification["message"]),
          ],
        ),
      ),
    );
  }
}
