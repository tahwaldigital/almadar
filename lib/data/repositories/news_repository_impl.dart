import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/article.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/news_repository.dart';
import '../datasources/local/news_local_datasource.dart';
import '../datasources/remote/news_remote_datasource.dart';
import '../models/article_model.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsRemoteDataSource _remote;
  final NewsLocalDataSource _local;

  NewsRepositoryImpl(this._remote, this._local);

  @override
  Future<Either<Failure, List<Article>>> getLatestNews({int page = 1, int perPage = 10}) async {
    try {
      final cacheKey = 'latest_p${page}_pp$perPage';
      final remote = await _remote.getLatestNews(page: page, perPage: perPage);
      await _local.cacheArticles(cacheKey, remote);
      return Right(remote);
    } on NetworkException {
      final cached = await _local.getCachedArticles('latest_p${page}_pp$perPage');
      if (cached.isNotEmpty) return Right(cached);
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Article>>> getBreakingNews() async {
    try {
      const cacheKey = 'breaking';
      final remote = await _remote.getBreakingNews();
      await _local.cacheArticles(cacheKey, remote);
      return Right(remote);
    } on NetworkException {
      final cached = await _local.getCachedArticles('breaking');
      if (cached.isNotEmpty) return Right(cached);
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Article>>> getTrendingNews({int page = 1}) async {
    try {
      final remote = await _remote.getTrendingNews(page: page);
      return Right(remote);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Article>>> getMostViewedNews() async {
    try {
      final remote = await _remote.getMostViewedNews();
      return Right(remote);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Article>>> getNewsByCategory(int categoryId, {int page = 1, int perPage = 10}) async {
    try {
      final cacheKey = 'cat_${categoryId}_p$page';
      final remote = await _remote.getNewsByCategory(categoryId, page: page, perPage: perPage);
      if (page == 1) await _local.cacheArticles(cacheKey, remote);
      return Right(remote);
    } on NetworkException {
      final cached = await _local.getCachedArticles('cat_${categoryId}_p1');
      if (cached.isNotEmpty) return Right(cached);
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Article>>> getRelatedPosts(int articleId, int categoryId) async {
    try {
      final remote = await _remote.getRelatedPosts(articleId, categoryId);
      return Right(remote);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Article>>> searchNews(String query, {int page = 1}) async {
    try {
      await _local.saveSearchQuery(query);
      final remote = await _remote.searchNews(query, page: page);
      return Right(remote);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Article>> getArticleById(int id) async {
    try {
      final remote = await _remote.getArticleById(id);
      // خزّن المقال الكامل للقراءة دون اتصال لاحقاً.
      await _local.cacheArticles('article_$id', [remote]);
      return Right(remote);
    } on NetworkException {
      final cached = await _local.getCachedArticles('article_$id');
      if (cached.isNotEmpty) return Right(cached.first);
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      final remote = await _remote.getCategories();
      await _local.cacheCategories(remote);
      return Right(remote);
    } on NetworkException {
      final cached = await _local.getCachedCategories();
      if (cached.isNotEmpty) return Right(cached);
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Article>>> getSavedArticles() async {
    try {
      final saved = await _local.getSavedArticles();
      return Right(saved);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> toggleSavedArticle(Article article) async {
    try {
      final isSaved = await _local.toggleSavedArticle(article as ArticleModel);
      return Right(isSaved);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isArticleSaved(int articleId) async {
    try {
      final result = await _local.isArticleSaved(articleId);
      return Right(result);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
