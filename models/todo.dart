class Todo {
  final int? id;
  String title;
  String? description;
  bool isCompleted;
  DateTime? dueDate;

  Todo({
    this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.dueDate,
  });

  // Convert a Todo into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'dueDate': dueDate?.millisecondsSinceEpoch,
    };
  }

  // Create a Todo from a Map
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      isCompleted: map['isCompleted'] == 1,
      dueDate: map['dueDate'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['dueDate']) 
        : null,
    );
  }

  // Clone method for creating copies when updating
  Todo copy({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}