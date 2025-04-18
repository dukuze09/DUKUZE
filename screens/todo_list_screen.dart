import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../services/database_helper.dart';
import 'todo_form_screen.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({Key? key}) : super(key: key);

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  late Future<List<Todo>> _todosFuture;

  @override
  void initState() {
    super.initState();
    _refreshTodos();
  }

  void _refreshTodos() {
    setState(() {
      _todosFuture = DatabaseHelper.instance.getTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Todo>>(
        future: _todosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tasks found. Add one!'));
          } else {
            final todos = snapshot.data!;
            return ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Checkbox(
                      value: todo.isCompleted,
                      onChanged: (bool? value) async {
                        todo.isCompleted = value ?? false;
                        await DatabaseHelper.instance.updateTodo(todo);
                        _refreshTodos();
                      },
                    ),
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        decoration: todo.isCompleted 
                            ? TextDecoration.lineThrough 
                            : TextDecoration.none,
                        fontWeight: todo.isCompleted ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (todo.description?.isNotEmpty == true)
                          Text(todo.description!),
                        if (todo.dueDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDateTime(todo.dueDate!),
                                  style: TextStyle(
                                    color: _isOverdue(todo.dueDate!) && !todo.isCompleted
                                        ? Colors.red
                                        : Colors.grey,
                                    fontWeight: _isOverdue(todo.dueDate!) && !todo.isCompleted
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit button
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TodoFormScreen(todo: todo),
                              ),
                            );
                            if (result == true) {
                              _refreshTodos();
                            }
                          },
                        ),
                        // Delete button
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            // Show confirmation dialog
                            bool confirmDelete = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Task'),
                                content: Text('Are you sure you want to delete "${todo.title}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('CANCEL'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('DELETE'),
                                  ),
                                ],
                              ),
                            ) ?? false;

                            if (confirmDelete) {
                              await DatabaseHelper.instance.deleteTodo(todo.id!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Task deleted')),
                              );
                              _refreshTodos();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TodoFormScreen()),
          );
          if (result == true) {
            _refreshTodos();
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final DateFormat dateFormatter = DateFormat('MMM d, yyyy');
    final DateFormat timeFormatter = DateFormat('h:mm a');
    
    return '${dateFormatter.format(dateTime)} at ${timeFormatter.format(dateTime)}';
  }

  bool _isOverdue(DateTime dueDate) {
    final now = DateTime.now();
    return dueDate.isBefore(now);
  }
}