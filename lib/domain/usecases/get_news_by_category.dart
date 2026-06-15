import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/article.dart';
import '../repositories/news_repository.dart';

class GetNewsByCategory {
  final NewsRepository repository;
  GetNewsByCategory(this.repository);

  Future<Either<Failure, List<Article>>> call(int categoryId, {int page = 1, int perPage = 10}) =>
      repository.getNewsByCategory(categoryId, page: page, perPage: perPage);
}
