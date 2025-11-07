import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marti_notas/models/comment.dart';
import 'package:marti_notas/models/task_model.dart';
import 'package:marti_notas/models/task_status.dart';

void main() {
  group('TaskModel serialization', () {
    test('toFirestore serializes enums and comments correctly', () {
      final task = TaskModel(
        id: 'task-1',
        title: 'Actualizar reporte',
        description: 'Revisar y subir evidencia',
        dueDate: DateTime(2025, 1, 10, 9),
        assignedTo: 'user-1',
        createdBy: 'admin-1',
        isPersonal: false,
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        createdAt: DateTime(2025, 1, 5, 8),
        comments: [
          Comment(
            authorId: 'admin-1',
            message: 'Por favor, añade capturas',
            createdAt: DateTime(2025, 1, 6, 14),
          ),
        ],
      );

      final data = task.toFirestore();

      expect(data['status'], equals(TaskStatus.inProgress.value));
      expect(data['priority'], equals(TaskPriority.high.value));
      final comments = data['comments'] as List<dynamic>;
      expect(comments, hasLength(1));
      final rawComment = comments.first as Map<String, dynamic>;
      expect(rawComment['authorId'], equals('admin-1'));
      expect(rawComment['message'], equals('Por favor, añade capturas'));
    });

    test('fromFirestore restores enum values and comments', () {
      final snapshot = {
        'title': 'Revisión final',
        'description': 'Confirma checklist',
        'dueDate': Timestamp.fromDate(DateTime(2025, 1, 15)),
        'assignedTo': 'user-2',
        'createdBy': 'admin-1',
        'isPersonal': false,
        'status': 'completed',
        'priority': 'low',
        'createdAt': Timestamp.fromDate(DateTime(2025, 1, 10)),
        'comments': [
          {
            'authorId': 'user-2',
            'message': 'Listo para revisión',
            'createdAt': Timestamp.fromDate(DateTime(2025, 1, 14, 18)),
          }
        ],
      };

      final model = TaskModel.fromFirestore(snapshot, 'task-2');

      expect(model.status, equals(TaskStatus.completed));
      expect(model.priority, equals(TaskPriority.low));
      expect(model.comments, hasLength(1));
      expect(model.comments.first.message, equals('Listo para revisión'));
    });
  });
}
