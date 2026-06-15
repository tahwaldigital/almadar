import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/article.dart';
import '../repositories/news_repository.dart';

class SearchNews {
  final NewsRepository repository;
  SearchNews(this.repository);

  Future<Either<Failure, List<Article>>> call(String query, {int page = 1}) =>
      repository.searchNews(query, page: page);
}
