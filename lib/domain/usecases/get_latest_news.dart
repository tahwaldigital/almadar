import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/article.dart';
import '../repositories/news_repository.dart';

class GetLatestNews {
  final NewsRepository repository;
  GetLatestNews(this.repository);

  Future<Either<Failure, List<Article>>> call({int page = 1, int perPage = 10}) =>
      repository.getLatestNews(page: page, perPage: perPage);
}
