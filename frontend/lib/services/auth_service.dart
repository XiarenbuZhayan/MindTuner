import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 获取当前用户
  User? get currentUser => _auth.currentUser;

  // 用户状态流
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get baseUrl
  static String get baseUrl {
    const String serverIP = '192.168.0.102';

    if (Platform.isAndroid) return 'http://$serverIP:8080';
    if (Platform.isIOS) return 'http://$serverIP:8080';
    return 'http://localhost:8080';
  }

  // User registration - using backend API
  Future<Map<String, dynamic>> registerWithBackend({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final url = Uri.parse('${AuthService.baseUrl}/user/register');
    try {
      print('📝 用户注册: $url');

      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'display_name': displayName,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('📊 响应状态码: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {
          'success': true,
          'uid': data['uid'],
          'email': data['email'],
          'display_name': data['display_name'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(res.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['detail'] ?? '注册失败',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'error': '请求超时，请检查网络连接',
      };
    } catch (e) {
      print('❌ 注册异常: $e');
      return {
        'success': false,
        'error': '网络错误: $e',
      };
    }
  }

  // 用户登录 - 使用后端API
  Future<Map<String, dynamic>> loginWithBackend({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${AuthService.baseUrl}/user/login');
    try {
      print('🔐 用户登录: $url');

      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('📊 响应状态码: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;

        // 后端登录成功，直接返回结果
        // 不再调用 Firebase Auth 登录，避免 reCAPTCHA 问题
        print('✅ 后端登录成功，跳过 Firebase Auth 登录');

        return {
          'success': true,
          'uid': data['uid'],
          'email': data['email'],
          'display_name': data['display_name'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(res.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['detail'] ?? '登录失败',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'error': '请求超时，请检查网络连接',
      };
    } catch (e) {
      print('❌ 登录异常: $e');
      return {
        'success': false,
        'error': '网络错误: $e',
      };
    }
  }

  // 获取用户信息 - 使用后端API
  Future<Map<String, dynamic>> getUserInfoFromBackend(String uid) async {
    final url = Uri.parse('${AuthService.baseUrl}/user/user/$uid');
    try {
      print('👤 获取用户信息: $url');

      final res = await http.get(url).timeout(const Duration(seconds: 30));

      print('📊 响应状态码: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {
          'success': true,
          'user_info': data,
        };
      } else {
        final errorData = jsonDecode(res.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['detail'] ?? '获取用户信息失败',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'error': '请求超时，请检查网络连接',
      };
    } catch (e) {
      print('❌ 获取用户信息异常: $e');
      return {
        'success': false,
        'error': '网络错误: $e',
      };
    }
  }

  // 删除用户 - 使用后端API
  Future<Map<String, dynamic>> deleteUserFromBackend(String uid) async {
    final url = Uri.parse('${AuthService.baseUrl}/user/user/$uid');
    try {
      print('🗑️ 删除用户: $url');

      final res = await http.delete(url).timeout(const Duration(seconds: 30));

      print('📊 响应状态码: ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(res.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['detail'] ?? '删除用户失败',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'error': '请求超时，请检查网络连接',
      };
    } catch (e) {
      print('❌ 删除用户异常: $e');
      return {
        'success': false,
        'error': '网络错误: $e',
      };
    }
  }

  // 用户注册 - 使用Firebase Auth（备用方案）
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // 创建用户
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // 更新显示名称
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }

        // 创建用户模型
        UserModel userModel = UserModel(
          uid: user.uid,
          email: user.email!,
          displayName: displayName ?? user.displayName,
          photoURL: user.photoURL,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        // 保存到Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toJson());

        return userModel;
      }
      return null;
    } catch (e) {
      debugPrint('Error registering user: $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (e is FirebaseAuthException) {
        debugPrint('Firebase Auth Error Code: ${e.code}');
        debugPrint('Firebase Auth Error Message: ${e.message}');
      }
      rethrow;
    }
  }

  // 用户登录 - 使用Firebase Auth（备用方案）
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // 更新最后登录时间
        await _firestore.collection('users').doc(user.uid).update({
          'lastLoginAt': DateTime.now().toIso8601String(),
        });

        // 获取用户数据
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists) {
          return UserModel.fromJson(doc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error signing in user: $e');
      rethrow;
    }
  }

  // 用户登出
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // 重置密码
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }

  // 更新用户资料
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);

        // 更新Firestore
        Map<String, dynamic> updates = {};
        if (displayName != null) updates['displayName'] = displayName;
        if (photoURL != null) updates['photoURL'] = photoURL;

        if (updates.isNotEmpty) {
          await _firestore.collection('users').doc(user.uid).update(updates);
        }
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  // 获取用户数据
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // 测试后端连接
  Future<Map<String, dynamic>> testBackendConnection() async {
    final url = Uri.parse('${AuthService.baseUrl}/');
    try {
      print('🔍 测试后端连接: $url');
      final res = await http.get(url).timeout(const Duration(seconds: 10));

      return {
        'success': res.statusCode == 200,
        'statusCode': res.statusCode,
        'response': res.body,
        'url': url.toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'url': url.toString(),
      };
    }
  }

  // 检查用户是否已登录
  bool get isLoggedIn => _auth.currentUser != null;

  // 获取当前用户ID
  String? get currentUserId => _auth.currentUser?.uid;

  // 获取当前用户邮箱
  String? get currentUserEmail => _auth.currentUser?.email;

  // 获取当前用户显示名称
  String? get currentUserDisplayName => _auth.currentUser?.displayName;
}
