import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  String? get currentUserId => _currentUser?.id;

  // Hash password with SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate unique 15-digit ID
  String _generateUserId() {
    final random = Random.secure();
    String id = '';
    for (int i = 0; i < AppConstants.userIdLength; i++) {
      id += random.nextInt(10).toString();
    }
    return id;
  }

  // Validate username
  String? validateUsername(String username) {
    if (username.isEmpty) return 'usernameRequired';
    if (username.length < AppConstants.minUsernameLen) return 'usernameTooShort';
    if (username.length > AppConstants.maxUsernameLen) return 'usernameTooLong';
    final regex = RegExp(AppConstants.usernamePattern);
    if (!regex.hasMatch(username)) return 'usernameInvalid';
    return null;
  }

  // Validate password
  String? validatePassword(String password) {
    if (password.isEmpty) return 'passwordRequired';
    if (password.length < AppConstants.minPasswordLen) return 'passwordTooShort';
    if (password.length > AppConstants.maxPasswordLen) return 'passwordTooLong';
    return null;
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    final query = await _firestore
        .collection(AppConstants.colUsers)
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  // Register new user
  Future<UserModel> register({
    required String name,
    required String username,
    required String password,
  }) async {
    // Check username availability
    final available = await isUsernameAvailable(username.toLowerCase());
    if (!available) throw Exception('usernameTaken');

    // Generate unique ID
    String userId = _generateUserId();
    // Ensure uniqueness
    while (true) {
      final existing = await _firestore
          .collection(AppConstants.colUsers)
          .where('id', isEqualTo: userId)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) break;
      userId = _generateUserId();
    }

    final passwordHash = _hashPassword(password);
    final now = DateTime.now();

    final user = UserModel(
      id: userId,
      username: username.toLowerCase(),
      name: name,
      passwordHash: passwordHash,
      createdAt: now,
      lastSeen: now,
      isOnline: true,
    );

    await _firestore
        .collection(AppConstants.colUsers)
        .doc(userId)
        .set(user.toMap());

    _currentUser = user;
    await _saveSession(user);
    return user;
  }

  // Login with username + password
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    final query = await _firestore
        .collection(AppConstants.colUsers)
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) throw Exception('accountNotFound');

    final user = UserModel.fromMap(query.docs.first.data());

    if (user.isBanned) throw Exception('accountBanned');

    final passwordHash = _hashPassword(password);
    if (user.passwordHash != passwordHash) throw Exception('wrongPassword');

    // Update online status
    await _firestore.collection(AppConstants.colUsers).doc(user.id).update({
      'isOnline': true,
      'lastSeen': Timestamp.fromDate(DateTime.now()),
    });

    _currentUser = user.copyWith(isOnline: true);
    await _saveSession(user);
    return _currentUser!;
  }

  // Initialize developer account
  Future<void> initDevAccount() async {
    final existing = await _firestore
        .collection(AppConstants.colUsers)
        .where('username', isEqualTo: AppConstants.devUsername.toLowerCase())
        .limit(1)
        .get();

    if (existing.docs.isEmpty) {
      final devUser = UserModel(
        id: AppConstants.devId,
        username: AppConstants.devUsername.toLowerCase(),
        name: AppConstants.devName,
        passwordHash: _hashPassword(AppConstants.devPasswordRaw),
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
        isAdmin: true,
      );
      await _firestore
          .collection(AppConstants.colUsers)
          .doc(AppConstants.devId)
          .set(devUser.toMap());
    }
  }

  // Save session
  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(AppConstants.prefCurrentUser, user.id);

    // Add to accounts list
    final accounts = prefs.getStringList(AppConstants.prefAccounts) ?? [];
    if (!accounts.contains(user.id)) {
      accounts.add(user.id);
      prefs.setStringList(AppConstants.prefAccounts, accounts);
    }
  }

  // Load saved session
  Future<UserModel?> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.prefCurrentUser);
      if (userId == null) return null;

      final doc = await _firestore
          .collection(AppConstants.colUsers)
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      _currentUser = UserModel.fromMap(doc.data()!);
      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    if (_currentUser != null) {
      await _firestore.collection(AppConstants.colUsers).doc(_currentUser!.id).update({
        'isOnline': false,
        'lastSeen': Timestamp.fromDate(DateTime.now()),
      });
    }
    final prefs = await SharedPreferences.getInstance();
    final accounts = prefs.getStringList(AppConstants.prefAccounts) ?? [];
    accounts.remove(_currentUser?.id);
    prefs.setStringList(AppConstants.prefAccounts, accounts);
    prefs.remove(AppConstants.prefCurrentUser);
    _currentUser = null;
  }

  // Switch account
  Future<UserModel?> switchAccount(String userId) async {
    if (_currentUser != null) {
      await _firestore.collection(AppConstants.colUsers).doc(_currentUser!.id).update({
        'isOnline': false,
        'lastSeen': Timestamp.fromDate(DateTime.now()),
      });
    }

    final prefs = await SharedPreferences.getInstance();
    prefs.setString(AppConstants.prefCurrentUser, userId);

    final doc = await _firestore.collection(AppConstants.colUsers).doc(userId).get();
    if (!doc.exists) return null;

    _currentUser = UserModel.fromMap(doc.data()!);
    await _firestore.collection(AppConstants.colUsers).doc(userId).update({
      'isOnline': true,
      'lastSeen': Timestamp.fromDate(DateTime.now()),
    });

    return _currentUser;
  }

  // Get saved accounts
  Future<List<UserModel>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = prefs.getStringList(AppConstants.prefAccounts) ?? [];
    final users = <UserModel>[];
    for (final id in accounts) {
      try {
        final doc = await _firestore.collection(AppConstants.colUsers).doc(id).get();
        if (doc.exists) {
          users.add(UserModel.fromMap(doc.data()!));
        }
      } catch (_) {}
    }
    return users;
  }

  // Update profile
  Future<void> updateProfile({
    String? name,
    String? username,
    String? photoUrl,
    String? bio,
    String? newPassword,
    Map<String, dynamic>? privacy,
    Map<String, dynamic>? settings,
  }) async {
    if (_currentUser == null) return;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (username != null) updates['username'] = username.toLowerCase();
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (bio != null) updates['bio'] = bio;
    if (newPassword != null) updates['passwordHash'] = _hashPassword(newPassword);
    if (privacy != null) updates['privacy'] = privacy;
    if (settings != null) updates['settings'] = settings;

    await _firestore.collection(AppConstants.colUsers).doc(_currentUser!.id).update(updates);

    final doc = await _firestore.collection(AppConstants.colUsers).doc(_currentUser!.id).get();
    _currentUser = UserModel.fromMap(doc.data()!);
  }

  // Update online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (_currentUser == null) return;
    await _firestore.collection(AppConstants.colUsers).doc(_currentUser!.id).update({
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore.collection(AppConstants.colUsers).doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  // Get user by username
  Future<UserModel?> getUserByUsername(String username) async {
    final query = await _firestore
        .collection(AppConstants.colUsers)
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return UserModel.fromMap(query.docs.first.data());
  }

  // Search users
  Future<List<UserModel>> searchUsers(String query) async {
    final results = <UserModel>[];
    final lowerQuery = query.toLowerCase().replaceFirst('@', '');

    // Search by username
    final usernameQuery = await _firestore
        .collection(AppConstants.colUsers)
        .where('username', isGreaterThanOrEqualTo: lowerQuery)
        .where('username', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
        .limit(10)
        .get();

    for (final doc in usernameQuery.docs) {
      final user = UserModel.fromMap(doc.data());
      if (user.id != _currentUser?.id) results.add(user);
    }

    // Search by name
    final nameQuery = await _firestore
        .collection(AppConstants.colUsers)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();

    for (final doc in nameQuery.docs) {
      final user = UserModel.fromMap(doc.data());
      if (user.id != _currentUser?.id && !results.any((u) => u.id == user.id)) {
        results.add(user);
      }
    }

    return results;
  }

  // Add/remove contact
  Future<void> toggleContact(String targetUserId, {String? nickname}) async {
    if (_currentUser == null) return;
    final contacts = List<String>.from(_currentUser!.contacts);
    final nicknames = Map<String, String>.from(_currentUser!.contactNicknames);

    if (contacts.contains(targetUserId)) {
      contacts.remove(targetUserId);
      nicknames.remove(targetUserId);
    } else {
      contacts.add(targetUserId);
      if (nickname != null) nicknames[targetUserId] = nickname;
    }

    await _firestore.collection(AppConstants.colUsers).doc(_currentUser!.id).update({
      'contacts': contacts,
      'contactNicknames': nicknames,
    });
    _currentUser = _currentUser!.copyWith(contacts: contacts, contactNicknames: nicknames);
  }

  // Block/unblock user
  Future<void> toggleBlock(String targetUserId) async {
    if (_currentUser == null) return;
    final blocked = List<String>.from(_currentUser!.blocked);
    if (blocked.contains(targetUserId)) {
      blocked.remove(targetUserId);
    } else {
      blocked.add(targetUserId);
    }
    await _firestore.collection(AppConstants.colUsers).doc(_currentUser!.id).update({
      'blocked': blocked,
    });
    _currentUser = _currentUser!.copyWith(blocked: blocked);
  }

  // Listen to current user changes
  Stream<UserModel> listenToCurrentUser() {
    if (_currentUser == null) throw Exception('No user logged in');
    return _firestore
        .collection(AppConstants.colUsers)
        .doc(_currentUser!.id)
        .snapshots()
        .map((doc) {
      if (!doc.exists) throw Exception('User not found');
      _currentUser = UserModel.fromMap(doc.data()!);
      return _currentUser!;
    });
  }

  // Delete account
  Future<void> deleteAccount() async {
    if (_currentUser == null) return;
    await _firestore.collection(AppConstants.colUsers).doc(_currentUser!.id).delete();
    await logout();
  }
}
