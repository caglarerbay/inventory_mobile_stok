import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationHistoryScreen extends StatefulWidget {
  @override
  _NotificationHistoryScreenState createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  List notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(
      'token',
    ); // Token SharedPreferences'tan çekiliyor
    final url = Uri.parse(
      "http://nukstoktakip.eu-north-1.elasticbeanstalk.com/api/notification_history/",
    );
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Token $token",
      },
    );
    if (response.statusCode == 200) {
      // Burada response.body yerine response.bodyBytes kullanıyoruz:
      final body = utf8.decode(response.bodyBytes);
      final data = jsonDecode(body);
      setState(() {
        notifications = data["notifications"];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      // Hata durumunda uygun bir mesaj gösterebilirsin.
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
                      // Bildirim detay ekranına yönlendir
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
      body: Padding(
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
