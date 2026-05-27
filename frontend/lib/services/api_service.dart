import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/v1';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Returns true if an auth token is already stored (used by SplashScreen).
  static Future<bool> loadToken() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<Map<String, dynamic>> login({required String email, required String password}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(res.body);
      final token = data['token'] ?? data['data']?['token'];
      if (data['success'] == true && token != null) {
        await setToken(token);
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> googleLogin({
    required String idToken,
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'email': email,
          'name': name,
          'photoUrl': photoUrl,
        }),
      );
      final data = jsonDecode(res.body);
      final token = data['token'] ?? data['data']?['token'];
      if (data['success'] == true && token != null) {
        await setToken(token);
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final token = await _getToken();
      final res = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          if (phone != null && phone.isNotEmpty) 'mobile': phone,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> listAtms() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/atms'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        return {'success': true, 'data': {'atms': decoded}};
      }
      return decoded;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getComplaints() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/complaints'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        return {'success': true, 'data': decoded};
      }
      return decoded;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> submitComplaint({
    required String atmId,
    required String complaintType,
    required String description,
    List<Uint8List>? imagesBytes,
    List<String>? imagesNames,
  }) async {
    try {
      final token = await _getToken();
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/complaints'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['atm_id'] = atmId;
      request.fields['complaint_type'] = complaintType;
      request.fields['description'] = description;

      if (imagesBytes != null && imagesNames != null) {
        for (int i = 0; i < imagesBytes.length; i++) {
          request.files.add(http.MultipartFile.fromBytes(
            'photo',
            imagesBytes[i],
            filename: imagesNames[i],
          ));
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateComplaint({
    required String complaintId,
    String? description,
    List<Uint8List>? imagesBytes,
    List<String>? imagesNames,
  }) async {
    try {
      final token = await _getToken();
      var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/complaints/$complaintId'));
      request.headers['Authorization'] = 'Bearer $token';
      
      if (description != null) {
        request.fields['description'] = description;
      }

      if (imagesBytes != null && imagesNames != null) {
        for (int i = 0; i < imagesBytes.length; i++) {
          request.files.add(http.MultipartFile.fromBytes(
            'photo',
            imagesBytes[i],
            filename: imagesNames[i],
          ));
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteComplaint(String complaintId) async {
    try {
      final token = await _getToken();
      final res = await http.delete(
        Uri.parse('$baseUrl/complaints/$complaintId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? mobile,
  }) async {
    try {
      final token = await _getToken();
      final res = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          if (mobile != null) 'mobile': mobile,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await _getToken();
      final res = await http.put(
        Uri.parse('$baseUrl/user/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> markNotificationsAsRead() async {
    try {
      final token = await _getToken();
      final res = await http.put(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getNotifications() async {
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        return {'success': true, 'data': decoded};
      }
      return decoded;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static String getBankLogo(String name) {
    name = name.toLowerCase();
    if (name.contains('axis')) return 'logos/axis_logo.png';
    if (name.contains('icici')) return 'logos/icici_logo.png';
    if (name.contains('hdfc')) return 'logos/hdfc_logo.png';
    if (name.contains('kotak')) return 'logos/kotak_logo.png';
    if (name.contains('baroda')) return 'logos/bob_logo.png';
    if (name.contains('sbi') || name.contains('state bank')) return 'logos/sbi_logo.png';
    
    if (name.contains('hdfc')) return 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/HDFC_Bank_Logo.svg/512px-HDFC_Bank_Logo.svg.png';
    if (name.contains('icici')) return 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/ICICI_Bank_Logo.svg/512px-ICICI_Bank_Logo.svg.png';
    if (name.contains('canara')) return 'https://upload.wikimedia.org/wikipedia/en/thumb/6/69/Canara_Bank_Logo.svg/512px-Canara_Bank_Logo.svg.png';
    if (name.contains('pnb') || name.contains('punjab')) return 'https://upload.wikimedia.org/wikipedia/en/thumb/2/2b/Punjab_National_Bank_logo.svg/512px-Punjab_National_Bank_logo.svg.png';
    return 'https://cdn-icons-png.flaticon.com/512/2830/2830284.png';
  }
}
