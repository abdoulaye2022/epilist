// lib/services/email_preference_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/email_preference.dart';
import '../config/app_config.dart';

class EmailPreferenceService {
  static const String baseUrl = AppConfig.baseUrl;

  /// Get authentication token from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Get user's email preferences
  static Future<EmailPreference?> getPreferences() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/email-preferences'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return EmailPreference.fromJson(jsonData['data']);
        }
      }

      return null;
    } catch (e) {
      print('Error getting email preferences: $e');
      return null;
    }
  }

  /// Update email preferences
  static Future<bool> updatePreferences(EmailPreference preferences) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/user/email-preferences'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(preferences.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['success'] == true;
      }

      return false;
    } catch (e) {
      print('Error updating email preferences: $e');
      return false;
    }
  }

  /// Reset preferences to default values
  static Future<bool> resetPreferences() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/user/email-preferences/reset'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['success'] == true;
      }

      return false;
    } catch (e) {
      print('Error resetting email preferences: $e');
      return false;
    }
  }

  /// Unsubscribe from all marketing emails
  static Future<bool> unsubscribeMarketing() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/user/email-preferences/unsubscribe-marketing'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['success'] == true;
      }

      return false;
    } catch (e) {
      print('Error unsubscribing from marketing: $e');
      return false;
    }
  }
}
