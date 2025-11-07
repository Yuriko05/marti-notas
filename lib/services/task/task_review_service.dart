import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/firestore_collections.dart';
import '../../models/task_status.dart';
import '../../utils/logger.dart';
import '../history_service.dart';

/// Gestiona el flujo de revisión de tareas (envío, aprobación y rechazo).
class TaskReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  const TaskReviewService._();

  /// Envía una tarea a revisión con comentarios y adjuntos opcionales.
  static Future<bool> submitTaskForReview({
    required String taskId,
    String? comment,
    List<String>? links,
    List<String>? attachments,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final taskRef =
          _firestore.collection(FirestoreCollections.tasks).doc(taskId);
      final prevSnap = await taskRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;

      await taskRef.update({
        'status': TaskStatus.pendingReview.value,
        'completionComment': comment,
        'links': links ?? [],
        'attachmentUrls': attachments ?? [],
        'submittedAt': FieldValue.serverTimestamp(),
      });

      final afterSnap = await taskRef.get();
      final afterData = afterSnap.exists ? afterSnap.data() : null;

      await HistoryService.recordEvent(
        taskId: taskId,
        action: 'submit_for_review',
        actorUid: user.uid,
        actorRole: null,
        payload: {
          'before': prevData,
          'after': afterData,
          'comment': comment,
          'links': links,
          'attachments': attachments,
        },
      );

      AppLogger.success('Tarea $taskId enviada para revisión por ${user.uid}',
          name: 'TaskReviewService');
      return true;
    } catch (e) {
      AppLogger.error('Error enviando tarea para revisión',
          error: e, name: 'TaskReviewService');
      return false;
    }
  }

  /// Aprueba una tarea en revisión por parte de un administrador.
  static Future<bool> approveTaskReview({
    required String taskId,
    String? reviewComment,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .get();
      if (!userDoc.exists || userDoc.data()?['role'] != 'admin') {
        AppLogger.warning('Solo administradores pueden aprobar tareas',
            name: 'TaskReviewService');
        return false;
      }

      final taskRef =
          _firestore.collection(FirestoreCollections.tasks).doc(taskId);
      final prevSnap = await taskRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;

      await taskRef.update({
        'status': TaskStatus.completed.value,
        'completedAt': FieldValue.serverTimestamp(),
        'confirmedAt': FieldValue.serverTimestamp(),
        'confirmedBy': user.uid,
        'reviewComment': reviewComment,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      final afterSnap = await taskRef.get();
      final afterData = afterSnap.exists ? afterSnap.data() : null;

      await HistoryService.recordEvent(
        taskId: taskId,
        action: 'approve_review',
        actorUid: user.uid,
        actorRole: userDoc.data()?['role'] as String?,
        payload: {
          'before': prevData,
          'after': afterData,
          'reviewComment': reviewComment,
        },
      );

      AppLogger.success('Tarea $taskId aprobada por admin',
          name: 'TaskReviewService');
      return true;
    } catch (e) {
      AppLogger.error('Error aprobando tarea',
          error: e, name: 'TaskReviewService');
      return false;
    }
  }

  /// Rechaza una tarea en revisión por parte de un administrador.
  static Future<bool> rejectTaskReview({
    required String taskId,
    required String reason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .get();
      if (!userDoc.exists || userDoc.data()?['role'] != 'admin') {
        AppLogger.warning('Solo administradores pueden rechazar tareas',
            name: 'TaskReviewService');
        return false;
      }

      final taskRef =
          _firestore.collection(FirestoreCollections.tasks).doc(taskId);
      final prevSnap = await taskRef.get();
      final prevData = prevSnap.exists ? prevSnap.data() : null;

      await taskRef.update({
        'status': TaskStatus.inProgress.value,
        'rejectionReason': reason,
        'reviewComment': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      final afterSnap = await taskRef.get();
      final afterData = afterSnap.exists ? afterSnap.data() : null;

      await HistoryService.recordEvent(
        taskId: taskId,
        action: 'reject_review',
        actorUid: user.uid,
        actorRole: userDoc.data()?['role'] as String?,
        payload: {'before': prevData, 'after': afterData, 'reason': reason},
      );

      AppLogger.success('Tarea $taskId rechazada en revisión por admin',
          name: 'TaskReviewService');
      return true;
    } catch (e) {
      AppLogger.error('Error rechazando tarea en revisión',
          error: e, name: 'TaskReviewService');
      return false;
    }
  }
}
