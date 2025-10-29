class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String assignedTo; // UID del usuario asignado
  final String createdBy; // UID del creador
  final bool isPersonal; // true = tarea personal, false = asignada por admin
  final String
      status; // 'pending', 'in_progress', 'completed', 'confirmed', 'rejected'
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? confirmedAt; // Fecha cuando admin confirma
  final String? confirmedBy; // UID del admin que confirma
  final bool isRead; // Si el usuario leyó la tarea
  final DateTime? readAt; // Fecha de lectura
  final String? rejectionReason; // Razón de rechazo si aplica

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.assignedTo,
    required this.createdBy,
    required this.isPersonal,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.confirmedAt,
    this.confirmedBy,
    this.isRead = false,
    this.readAt,
    this.rejectionReason,
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
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as dynamic)?.toDate(),
      confirmedAt: (data['confirmedAt'] as dynamic)?.toDate(),
      confirmedBy: data['confirmedBy'],
      isRead: data['isRead'] ?? false,
      readAt: (data['readAt'] as dynamic)?.toDate(),
      rejectionReason: data['rejectionReason'],
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
      'status': status,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'confirmedAt': confirmedAt,
      'confirmedBy': confirmedBy,
      'isRead': isRead,
      'readAt': readAt,
      'rejectionReason': rejectionReason,
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
    String? status,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? confirmedAt,
    String? confirmedBy,
    bool? isRead,
    DateTime? readAt,
    String? rejectionReason,
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
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isConfirmed => status == 'confirmed';
  bool get isRejected => status == 'rejected';
  bool get isOverdue =>
      DateTime.now().isAfter(dueDate) && !isCompleted && !isConfirmed;

  @override
  String toString() {
    return 'TaskModel(id: $id, title: $title, status: $status, dueDate: $dueDate)';
  }
}
