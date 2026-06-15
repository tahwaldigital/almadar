import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/article_model.dart';
import '../../models/category_model.dart';

abstract class NewsLocalDataSource {
  Future<List<ArticleModel>> getCachedArticles(String cacheKey);
  Future<void> cacheArticles(String cacheKey, List<ArticleModel> articles);
  Future<List<ArticleModel>> getSavedArticles();
  Future<bool> toggleSavedArticle(ArticleModel article);
  Future<bool> isArticleSaved(int articleId);
  Future<void> clearSavedArticles();
  Future<List<CategoryModel>> getCachedCategories();
  Future<void> cacheCategories(List<CategoryModel> categories);
  Future<List<String>> getSearchHistory();
  Future<void> saveSearchQuery(String query);
  Future<void> removeSearchQuery(String query);
  Future<void> clearSearchHistory();
}

class NewsLocalDataSourceImpl implements NewsLocalDataSource {
  final SharedPreferences _prefs;

  NewsLocalDataSourceImpl(this._prefs);

  Box<dynamic> get _savedBox => Hive.box(ApiConstants.savedPostsBox);
  Box<dynamic> get _cacheBox => Hive.box(ApiConstants.cachedPostsBox);

  @override
  Future<List<ArticleModel>> getCachedArticles(String cacheKey) async {
    try {
      final cached = _cacheBox.get(cacheKey);
      if (cached == null) return [];
      final List<dynamic> jsonList = jsonDecode(cached as String) as List<dynamic>;
      return jsonList
          .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> cacheArticles(String cacheKey, List<ArticleModel> articles) async {
    try {
      final jsonList = articles.map((a) => a.toJson()).toList();
      await _cacheBox.put(cacheKey, jsonEncode(jsonList));
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<ArticleModel>> getSavedArticles() async {
    try {
      final keys = _savedBox.keys.toList();
      return keys
          .map((k) {
            final json = jsonDecode(_savedBox.get(k) as String) as Map<String, dynamic>;
            return ArticleModel.fromJson(json);
          })
          .toList();
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<bool> toggleSavedArticle(ArticleModel article) async {
    try {
      final key = 'article_${article.id}';
      if (_savedBox.containsKey(key)) {
        await _savedBox.delete(key);
        return false;
      } else {
        await _savedBox.put(key, jsonEncode(article.toJson()));
        return true;
      }
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<bool> isArticleSaved(int articleId) async {
    return _savedBox.containsKey('article_$articleId');
  }

  @override
  Future<void> clearSavedArticles() async {
    await _savedBox.clear();
  }

  @override
  Future<List<CategoryModel>> getCachedCategories() async {
    try {
      final cached = _prefs.getString(ApiConstants.categoriesBox);
      if (cached == null) return [];
      final List<dynamic> jsonList = jsonDecode(cached) as List<dynamic>;
      return jsonList
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> cacheCategories(List<CategoryModel> categories) async {
    final jsonList = categories.map((c) => c.toJson()).toList();
    await _prefs.setString(ApiConstants.categoriesBox, jsonEncode(jsonList));
  }

  @override
  Future<List<String>> getSearchHistory() async {
    return _prefs.getStringList(ApiConstants.searchHistoryKey) ?? [];
  }

  @override
  Future<void> saveSearchQuery(String query) async {
    final history = await getSearchHistory();
    history.remove(query);
    history.insert(0, query);
    final limited = history.take(10).toList();
    await _prefs.setStringList(ApiConstants.searchHistoryKey, limited);
  }

  @override
  Future<void> removeSearchQuery(String query) async {
    final history = await getSearchHistory();
    history.remove(query);
    await _prefs.setStringList(ApiConstants.searchHistoryKey, history);
  }

  @override
  Future<void> clearSearchHistory() async {
    await _prefs.remove(ApiConstants.searchHistoryKey);
  }
}
