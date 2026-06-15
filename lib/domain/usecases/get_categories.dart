import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/category.dart';
import '../repositories/news_repository.dart';

class GetCategories {
  final NewsRepository repository;
  GetCategories(this.repository);

  Future<Either<Failure, List<Category>>> call() => repository.getCategories();
}
