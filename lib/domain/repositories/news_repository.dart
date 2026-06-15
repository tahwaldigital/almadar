import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/article.dart';
import '../entities/category.dart';

abstract class NewsRepository {
  Future<Either<Failure, List<Article>>> getLatestNews({int page = 1, int perPage = 10});
  Future<Either<Failure, List<Article>>> getBreakingNews();
  Future<Either<Failure, List<Article>>> getTrendingNews({int page = 1});
  Future<Either<Failure, List<Article>>> getMostViewedNews();
  Future<Either<Failure, List<Article>>> getNewsByCategory(int categoryId, {int page = 1, int perPage = 10});
  Future<Either<Failure, List<Article>>> getRelatedPosts(int articleId, int categoryId);
  Future<Either<Failure, List<Article>>> searchNews(String query, {int page = 1});
  Future<Either<Failure, Article>> getArticleById(int id);
  Future<Either<Failure, List<Category>>> getCategories();
  Future<Either<Failure, List<Article>>> getSavedArticles();
  Future<Either<Failure, bool>> toggleSavedArticle(Article article);
  Future<Either<Failure, bool>> isArticleSaved(int articleId);
}
