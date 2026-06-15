import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/article.dart';
import '../repositories/news_repository.dart';

class GetBreakingNews {
  final NewsRepository repository;
  GetBreakingNews(this.repository);

  Future<Either<Failure, List<Article>>> call() => repository.getBreakingNews();
}
