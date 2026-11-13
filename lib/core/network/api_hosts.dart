import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';

/// Decides which domain the app talks to, so a build is never tied to one host.
///
/// Where the list of domains comes from, strongest first:
/// 1. Remote Config key [remoteKey]. It is served by Google, so it stays
///    reachable even when a site domain is blocked, and the operator can move
///    the app to a new domain from the Firebase console without an app update.
/// 2. The last list received, cached on the device (offline / Firebase down).
/// 3. [_builtInHosts], shipped with this build.
///
/// Endpoint constants are written against [ApiConstants.siteUrl]; DioClient
/// swaps that origin for the live one and, when a domain is unreachable,
/// moves down the list and remembers whichever domain answered.
class ApiHosts {
  ApiHosts._();

  static final ApiHosts instance = ApiHosts._();

  /// Remote Config parameter: domains separated by commas or new lines,
  /// primary first (e.g. `ar.almadr-news.com, www.almadr-news.com`).
  static const String remoteKey = 'api_hosts';

  static const List<String> _builtInHosts = [
    'https://ar.almadr-news.com',
    'https://www.almadr-news.com',
  ];

  static const String _hostsPrefKey = 'api_hosts_list';
  static const String _activePrefKey = 'api_hosts_active';

  // Explicit fetches are throttled by Firebase anyway; realtime updates
  // (onConfigUpdated) deliver changes instantly while the app is open.
  static const Duration _minFetchInterval = Duration(minutes: 15);
  static const Duration _fetchTimeout = Duration(seconds: 10);

  List<String> _hosts = _builtInHosts;
  String _active = _builtInHosts.first;
  SharedPreferences? _prefs;
  FirebaseRemoteConfig? _remote;
  Future<bool>? _refreshing;

  /// The domain requests currently go to, e.g. `https://ar.almadr-news.com`.
  String get active => _active;

  /// Absolute URL on the live domain for a site path such as `/wp-content/...`.
  String url(String path) => '$_active$path';

  /// Restores the last known choice and subscribes to Remote Config.
  /// Never waits on the network, so app startup is not delayed.
  Future<void> init(SharedPreferences prefs, {required bool firebaseReady}) async {
    _prefs = prefs;
    final cached = parse((prefs.getStringList(_hostsPrefKey) ?? const []).join(','));
    if (cached.isNotEmpty) _hosts = cached;
    final savedActive = prefs.getString(_activePrefKey);
    _active = savedActive != null && _hosts.contains(savedActive)
        ? savedActive
        : _hosts.first;

    if (!firebaseReady) return;
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: _fetchTimeout,
        minimumFetchInterval: _minFetchInterval,
      ));
      await rc.setDefaults(const {remoteKey: ''});
      _remote = rc;
      _applyRemote();
      unawaited(refresh());
      rc.onConfigUpdated.listen(
        (update) async {
          if (!update.updatedKeys.contains(remoteKey)) return;
          try {
            await rc.activate();
            _applyRemote();
          } catch (e) {
            debugPrint('[hosts] activate failed: $e');
          }
        },
        onError: (Object e) => debugPrint('[hosts] realtime updates: $e'),
      );
    } catch (e) {
      // Remote Config is an improvement, not a requirement: cached/built-in
      // domains keep working without it.
      debugPrint('[hosts] Remote Config unavailable: $e');
    }
  }

  /// Fetches the latest list from Remote Config; true when the list changed.
  /// Concurrent callers share a single fetch.
  Future<bool> refresh() async {
    final rc = _remote;
    if (rc == null) return false;
    final pending = _refreshing;
    if (pending != null) return pending;
    final future = _fetch(rc);
    _refreshing = future;
    try {
      return await future;
    } finally {
      if (identical(_refreshing, future)) _refreshing = null;
    }
  }

  Future<bool> _fetch(FirebaseRemoteConfig rc) async {
    try {
      await rc.fetchAndActivate().timeout(_fetchTimeout);
      return _applyRemote();
    } catch (e) {
      debugPrint('[hosts] fetch failed: $e');
      return false;
    }
  }

  /// Applies the activated Remote Config value; true when the list changed.
  bool _applyRemote() {
    final rc = _remote;
    if (rc == null) return false;
    final list = parse(rc.getString(remoteKey));
    // Empty means "not configured": keep what we have rather than lose it.
    if (list.isEmpty || listEquals(list, _hosts)) return false;
    _hosts = list;
    // A new list is the operator's explicit choice, so start from its primary
    // even if an older domain happened to work last time.
    _active = list.first;
    unawaited(_persist());
    debugPrint('[hosts] new domains: $list');
    return true;
  }

  /// Whether [url] targets the API and may be moved to another domain.
  bool owns(String url) => _originOf(url, [ApiConstants.siteUrl]) != null;

  /// [url] on every known domain, the live one first. URLs that are not
  /// ours are returned unchanged.
  List<String> candidatesFor(String url) {
    const template = ApiConstants.siteUrl;
    if (!owns(url)) return [url];
    final rest = url.substring(template.length);
    return [_active, ..._hosts.where((h) => h != _active)]
        .map((h) => '$h$rest')
        .toList(growable: false);
  }

  /// Remembers the domain that just answered so later requests go there first.
  void markWorking(String url) {
    final origin = _originOf(url, _hosts);
    if (origin == null || origin == _active) return;
    _active = origin;
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setStringList(_hostsPrefKey, _hosts);
      await prefs.setString(_activePrefKey, _active);
    } catch (e) {
      debugPrint('[hosts] could not save: $e');
    }
  }

  /// Returns the origin in [origins] that [url] starts with, matching on a
  /// full host boundary (so `a.com` never matches `a.com.evil.net`).
  static String? _originOf(String url, Iterable<String> origins) {
    for (final o in origins) {
      if (url == o || url.startsWith('$o/') || url.startsWith('$o?')) return o;
    }
    return null;
  }

  /// Turns the operator's text into clean `https://host` origins, in order and
  /// without duplicates. Accepts commas, spaces, new lines or a JSON array, and
  /// bare hosts or full URLs. Plain http is rejected so traffic stays encrypted.
  @visibleForTesting
  static List<String> parse(String raw) {
    final out = <String>[];
    for (final token in raw.split(RegExp(r'[\s,;\[\]"]+'))) {
      if (token.isEmpty) continue;
      final uri = Uri.tryParse(token.contains('://') ? token : 'https://$token');
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          !uri.host.contains('.') ||
          uri.userInfo.isNotEmpty) {
        continue;
      }
      final origin =
          uri.hasPort ? 'https://${uri.host}:${uri.port}' : 'https://${uri.host}';
      if (!out.contains(origin)) out.add(origin);
    }
    return out;
  }
}
