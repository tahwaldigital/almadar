import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/article.dart';
import '../repositories/news_repository.dart';

class GetRelatedPosts {
  final NewsRepository repository;
  GetRelatedPosts(this.repository);

  Future<Either<Failure, List<Article>>> call(int articleId, int categoryId) =>
      repository.getRelatedPosts(articleId, categoryId);
}
