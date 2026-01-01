import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 1. Connection Settings
  // Android Emulator uses 10.0.2.2 to talk to your computer
  static const String baseUrl = "http://127.0.0.1:5000";

  // 2. Check Connection Function
  static Future<String> checkBackend() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        return "Connected! Server says: ${json.decode(response.body)['message']}";
      } else {
        return "Server Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: Cannot find server. Is python app.py running?";
    }
  }

  // 3. Sign Up Function (THIS IS NEW)
  static Future<Map<String, dynamic>> signup(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/signup"), 
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "username": username,
          "email": email,
          "password": password,
        }),
      );

      // Return the JSON answer from Python
      return json.decode(response.body);
    } catch (e) {
      return {"error": "Connection Failed: $e"};
    }
  }
  // ... existing signup code ...

  // Add this NEW Login function
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": email,
          "password": password,
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      return {"error": "Connection Failed: $e"};
    }
  }
}