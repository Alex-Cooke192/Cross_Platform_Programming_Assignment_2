import '../daos/task_dao.dart';

class TaskRepository {
  TaskRepository(this._taskDao);

  final TaskDao _taskDao;
}