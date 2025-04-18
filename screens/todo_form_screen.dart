import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../services/database_helper.dart';

class TodoFormScreen extends StatefulWidget {
  final Todo? todo;

  const TodoFormScreen({Key? key, this.todo}) : super(key: key);

  @override
  _TodoFormScreenState createState() => _TodoFormScreenState();
}

class _TodoFormScreenState extends State<TodoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  String? _description;
  late bool _isCompleted;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;

  @override
  void initState() {
    super.initState();
    _title = widget.todo?.title ?? '';
    _description = widget.todo?.description;
    _isCompleted = widget.todo?.isCompleted ?? false;
    
    if (widget.todo?.dueDate != null) {
      _dueDate = DateTime(
        widget.todo!.dueDate!.year,
        widget.todo!.dueDate!.month,
        widget.todo!.dueDate!.day,
      );
      _dueTime = TimeOfDay(
        hour: widget.todo!.dueDate!.hour,
        minute: widget.todo!.dueDate!.minute,
      );
    }
  }

  // Function to pick date
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        // If there's no time set yet, default to current time
        if (_dueTime == null) {
          _dueTime = TimeOfDay.now();
        }
      });
    }
  }

  // Function to pick time
  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _dueTime = picked;
      });
    }
  }

  // Function to clear date and time
  void _clearDateTime() {
    setState(() {
      _dueDate = null;
      _dueTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.todo == null ? 'Add Task' : 'Edit Task'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  initialValue: _title,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _title = value!;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _description,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  onSaved: (value) {
                    _description = value;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Due Date & Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Date Picker
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: Text(_dueDate == null 
                          ? 'Select Due Date' 
                          : 'Due Date: ${_formatDate(_dueDate!)}'),
                        trailing: _dueDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearDateTime,
                            )
                          : null,
                        onTap: () => _pickDate(context),
                      ),
                      // Time Picker
                      if (_dueDate != null)
                        ListTile(
                          leading: const Icon(Icons.access_time),
                          title: Text(_dueTime == null 
                            ? 'Select Due Time' 
                            : 'Due Time: ${_dueTime!.format(context)}'),
                          onTap: () => _pickTime(context),
                        ),
                    ],
                  ),
                ),
                if (widget.todo != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: CheckboxListTile(
                      title: const Text('Mark as Completed'),
                      value: _isCompleted,
                      onChanged: (bool? value) {
                        setState(() {
                          _isCompleted = value ?? false;
                        });
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _saveTask,
                  child: Text(
                    widget.todo == null ? 'Add Task' : 'Update Task',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Format date to display
  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('MMM d, yyyy');
    return formatter.format(date);
  }

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Combine date and time if both are selected
      DateTime? combinedDateTime;
      if (_dueDate != null) {
        if (_dueTime != null) {
          combinedDateTime = DateTime(
            _dueDate!.year,
            _dueDate!.month,
            _dueDate!.day,
            _dueTime!.hour,
            _dueTime!.minute,
          );
        } else {
          combinedDateTime = DateTime(
            _dueDate!.year,
            _dueDate!.month,
            _dueDate!.day,
            0, 0, // Default to midnight if no time specified
          );
        }
      }

      if (widget.todo == null) {
        // Create new todo
        final newTodo = Todo(
          title: _title,
          description: _description,
          isCompleted: false,
          dueDate: combinedDateTime,
        );

        await DatabaseHelper.instance.insertTodo(newTodo);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task added successfully')),
          );
        }
      } else {
        // Update existing todo
        final updatedTodo = Todo(
          id: widget.todo!.id,
          title: _title,
          description: _description,
          isCompleted: _isCompleted,
          dueDate: combinedDateTime,
        );

        await DatabaseHelper.instance.updateTodo(updatedTodo);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task updated successfully')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }
}