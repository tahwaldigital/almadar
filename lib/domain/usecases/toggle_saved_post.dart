import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/article.dart';
import '../repositories/news_repository.dart';

class ToggleSavedPost {
  final NewsRepository repository;
  ToggleSavedPost(this.repository);

  Future<Either<Failure, bool>> call(Article article) =>
      repository.toggleSavedArticle(article);
}
