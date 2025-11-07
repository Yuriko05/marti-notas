import 'comment.dart';
import 'task_status.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String assignedTo; // UID del usuario asignado
  final String createdBy; // UID del creador
  final bool isPersonal; // true = tarea personal, false = asignada por admin
  final TaskStatus status; // Estado normalizado de la tarea
  final TaskPriority priority; // Prioridad de la tarea
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? confirmedAt; // Fecha cuando admin confirma
  final String? confirmedBy; // UID del admin que confirma
  final bool isRead; // Si el usuario leyó la tarea
  final DateTime? readAt; // Fecha de lectura
  final String? readBy; // UID del usuario que leyó la tarea
  final String? rejectionReason; // Razón de rechazo si aplica
  
  // Nuevos campos para evidencias
  final List<String> attachmentUrls; // URLs de archivos adjuntos (imágenes, docs)
  final List<String> links; // Enlaces externos
  final String? completionComment; // Comentario del usuario al completar
  final DateTime? submittedAt; // Fecha cuando se envía para revisión
  final String? reviewComment; // Comentario del admin al revisar
  
  // Archivos/enlaces iniciales (adjuntados por admin al crear tarea)
  final List<String> initialAttachments; // URLs de archivos iniciales del admin
  final List<String> initialLinks; // Enlaces iniciales del admin
  final String? initialInstructions; // Instrucciones adicionales del admin
  final List<Comment> comments; // Conversación interna asociada a la tarea

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.assignedTo,
    required this.createdBy,
    required this.isPersonal,
  required this.status,
  this.priority = TaskPriority.medium,
    required this.createdAt,
    this.completedAt,
    this.confirmedAt,
    this.confirmedBy,
    this.isRead = false,
    this.readAt,
    this.readBy,
    this.rejectionReason,
    this.attachmentUrls = const [],
    this.links = const [],
    this.completionComment,
    this.submittedAt,
    this.reviewComment,
    this.initialAttachments = const [],
    this.initialLinks = const [],
    this.initialInstructions,
    this.comments = const [],
  });

  factory TaskModel.fromFirestore(Map<String, dynamic> data, String id) {
    return TaskModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: (data['dueDate'] as dynamic)?.toDate() ?? DateTime.now(),
      assignedTo: data['assignedTo'] ?? '',
      createdBy: data['createdBy'] ?? '',
      isPersonal: data['isPersonal'] ?? false,
  status: taskStatusFromString(data['status'] as String?),
  priority: taskPriorityFromString(data['priority'] as String?),
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as dynamic)?.toDate(),
      confirmedAt: (data['confirmedAt'] as dynamic)?.toDate(),
      confirmedBy: data['confirmedBy'],
      isRead: data['isRead'] ?? false,
      readAt: (data['readAt'] as dynamic)?.toDate(),
      readBy: data['readBy'],
      rejectionReason: data['rejectionReason'],
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      links: List<String>.from(data['links'] ?? []),
      completionComment: data['completionComment'],
      submittedAt: (data['submittedAt'] as dynamic)?.toDate(),
      reviewComment: data['reviewComment'],
      initialAttachments: List<String>.from(data['initialAttachments'] ?? []),
      initialLinks: List<String>.from(data['initialLinks'] ?? []),
      initialInstructions: data['initialInstructions'],
      comments: (data['comments'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(Comment.fromMap)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'isPersonal': isPersonal,
  'status': status.value,
  'priority': priority.value,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'confirmedAt': confirmedAt,
      'confirmedBy': confirmedBy,
      'isRead': isRead,
      'readAt': readAt,
      'readBy': readBy,
      'rejectionReason': rejectionReason,
      'attachmentUrls': attachmentUrls,
      'links': links,
      'completionComment': completionComment,
      'submittedAt': submittedAt,
      'reviewComment': reviewComment,
      'initialAttachments': initialAttachments,
      'initialLinks': initialLinks,
      'initialInstructions': initialInstructions,
      'comments': comments.map((comment) => comment.toMap()).toList(),
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? assignedTo,
    String? createdBy,
    bool? isPersonal,
  TaskStatus? status,
  TaskPriority? priority,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? confirmedAt,
    String? confirmedBy,
    bool? isRead,
    DateTime? readAt,
    String? readBy,
    String? rejectionReason,
    List<String>? attachmentUrls,
    List<String>? links,
    String? completionComment,
    DateTime? submittedAt,
    String? reviewComment,
    List<String>? initialAttachments,
    List<String>? initialLinks,
    String? initialInstructions,
    List<Comment>? comments,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      isPersonal: isPersonal ?? this.isPersonal,
  status: status ?? this.status,
  priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      readBy: readBy ?? this.readBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      links: links ?? this.links,
      completionComment: completionComment ?? this.completionComment,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewComment: reviewComment ?? this.reviewComment,
      initialAttachments: initialAttachments ?? this.initialAttachments,
      initialLinks: initialLinks ?? this.initialLinks,
      initialInstructions: initialInstructions ?? this.initialInstructions,
      comments: comments ?? this.comments,
    );
  }

  bool get isCompleted => status == TaskStatus.completed;
  bool get isPending => status == TaskStatus.pending;
  bool get isInProgress => status == TaskStatus.inProgress;
  bool get isPendingReview => status == TaskStatus.pendingReview;
  bool get isConfirmed => status == TaskStatus.confirmed;
  bool get isRejected => status == TaskStatus.rejected;
  bool get isOverdue =>
    DateTime.now().isAfter(dueDate) && !isCompleted && !isConfirmed;

  @override
  String toString() {
    return 'TaskModel(id: $id, title: $title, status: ${status.value}, dueDate: $dueDate)';
  }
}
