import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';
import 'helpers.dart';
import 'session_store.dart';

class AppController extends ChangeNotifier {
  final ApiClient api;
  final SessionStore store;
  AppController({ApiClient? apiClient, SessionStore? sessionStore})
      : api = apiClient ?? ApiClient(),
        store = sessionStore ?? SessionStore();

  bool booting = true;
  bool busy = false;
  String? error;
  String? token;
  Map<String, dynamic>? payload;
  Timer? _gpsTimer;
  bool tracking = false;

  bool get signedIn => token != null && payload != null;
  Map<String, dynamic> get work => Map<String, dynamic>.from(payload?['work'] ?? const {});
  Map<String, dynamic> get profile => Map<String, dynamic>.from(work['profile'] ?? const {});
  List<Map<String, dynamic>> get villages => mapList(work['villages']);
  List<Map<String, dynamic>> get bills => mapList(work['bills']);
  List<Map<String, dynamic>> get packages => mapList(work['packages']);
  List<Map<String, dynamic>> get complaints => mapList(work['complaints']);
  List<Map<String, dynamic>> get requests => mapList(work['requests']);
  List<Map<String, dynamic>> get collectionHistory => mapList(work['collection_history']);
  List<Map<String, dynamic>> get expenseRequests => mapList(work['expense_requests']);
  List<Map<String, dynamic>> get assignedAssets => mapList(work['assigned_assets']);
  Map<String, dynamic> get summary => Map<String, dynamic>.from(work['summary'] ?? const {});
  String get name => '${payload?['name'] ?? profile['name'] ?? 'Staff'}';
  String get photoUrl => '${payload?['photo_url'] ?? ''}';
  bool get sharing => (payload?['sharing'] ?? 0).toString() == '1';

  Future<void> initialize() async {
    try {
      token = await store.read();
      if (token != null && token!.isNotEmpty) {
        payload = await api.post({'action': 'snapshot', 'session_token': token});
      } else {
        token = null;
      }
    } catch (_) {
      token = null;
      payload = null;
      await store.clear();
    } finally {
      booting = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final data = await api.post({
        'action': 'login',
        'username': username.trim(),
        'password': password,
      });
      final issued = '${data['session_token'] ?? ''}';
      if (issued.isEmpty) throw ApiException('Server did not issue an app session.');
      token = issued;
      payload = data;
      await store.write(issued);
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (token == null) return;
    try {
      payload = await api.post({'action': 'snapshot', 'session_token': token});
      error = null;
    } on ApiException catch (e) {
      error = e.message;
      if ((e.status ?? 0) == 400 && e.message.toLowerCase().contains('sign in')) {
        await logout(localOnly: true);
      }
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> action(String action, [Map<String, dynamic> extra = const {}]) async {
    if (token == null) throw ApiException('Please sign in again.');
    final data = await api.post({'action': action, 'session_token': token, ...extra});
    if (data['work'] != null) payload = data;
    notifyListeners();
    return data;
  }

  Future<void> logout({bool localOnly = false}) async {
    _gpsTimer?.cancel();
    _gpsTimer = null;
    tracking = false;
    if (!localOnly && token != null) {
      try {
        await api.post({'action': 'logout', 'session_token': token});
      } catch (_) {}
    }
    token = null;
    payload = null;
    await store.clear();
    notifyListeners();
  }

  Future<void> startDuty() async {
    error = null;
    notifyListeners();
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw ApiException('Location permission is required to start duty.');
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw ApiException('Turn on phone location/GPS and retry.');
    }
    await action('start');
    tracking = true;
    await _sendLocation();
    _gpsTimer?.cancel();
    _gpsTimer = Timer.periodic(const Duration(seconds: 30), (_) => _sendLocation());
    notifyListeners();
  }

  Future<void> stopDuty() async {
    _gpsTimer?.cancel();
    _gpsTimer = null;
    tracking = false;
    await action('stop');
    notifyListeners();
  }

  Future<void> _sendLocation() async {
    if (!tracking || token == null) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      await action('location', {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'accuracy': pos.accuracy,
      });
    } catch (e) {
      error = e is ApiException ? e.message : 'Unable to update duty location.';
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> submitRequest(Map<String, dynamic> data) async {
    return action('submit_request', {'request_key': requestKey(), ...data});
  }

  Future<Map<String, dynamic>> submitExpense(Map<String, dynamic> data) async {
    return action('expense_submit', data);
  }

  Future<void> updateProfilePhoto(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > 8 * 1024 * 1024) throw ApiException('Choose an image smaller than 8 MB.');
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw ApiException('Unable to read this image.');
    final square = img.copyResizeCropSquare(decoded, size: 360);
    final jpg = Uint8List.fromList(img.encodeJpg(square, quality: 86));
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(jpg)}';
    await action('profile_photo', {'image': dataUrl});
  }

  Future<void> removeProfilePhoto() => action('remove_photo');

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }
}
