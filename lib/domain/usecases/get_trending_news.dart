import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/article.dart';
import '../repositories/news_repository.dart';

class GetTrendingNews {
  final NewsRepository repository;
  GetTrendingNews(this.repository);

  Future<Either<Failure, List<Article>>> call({int page = 1}) =>
      repository.getTrendingNews(page: page);
}
