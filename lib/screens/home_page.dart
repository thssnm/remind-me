import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:remind_me/services/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController myController = TextEditingController();
  List<PendingNotificationRequest> pendingNotifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingNotifications();
  }

  Future<void> _loadPendingNotifications() async {
    final notifications =
        await NotificationService().showPendingNotifications();
    setState(() {
      pendingNotifications = notifications.cast<PendingNotificationRequest>();
      // Sortiere nach Zeit (aus payload)
      pendingNotifications.sort((a, b) {
        final timeA = a.payload ?? '99:99';
        final timeB = b.payload ?? '99:99';
        return timeA.compareTo(timeB);
      });
      isLoading = false;
    });
  }

  Future<void> _setReminder() async {
    if (myController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reminder text'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    var time = await showTimePicker(
      confirmText: "Set Reminder",
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.grey.shade500,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      await NotificationService().scheduleNotification(
        title: "Remind Me",
        body: myController.text,
        hour: time.hour,
        minute: time.minute,
      );

      FocusScope.of(context).unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder set for ${time.format(context)}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        myController.clear();
      });

      await _loadPendingNotifications();
    }
  }

  Future<void> _deleteReminder(int id) async {
    await FlutterLocalNotificationsPlugin().cancel(id);
    await _loadPendingNotifications();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder deleted'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _deleteAllReminders() async {
    await NotificationService().cancelNotifications();
    await _loadPendingNotifications();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All reminders deleted'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Remind Me',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
        ),
        actions: [
          if (pendingNotifications.isNotEmpty)
            IconButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1F2937),
                    title: const Text(
                      'Delete all reminders?',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'This will delete all pending reminders.',
                      style: TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Delete All',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _deleteAllReminders();
                }
              },
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
            ),
        ],
      ),
      body: Column(
        children: [
          // Input area
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                TextField(
                  controller: myController,
                  cursorColor: Colors.white,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                    hintText: 'What do you want to be reminded of?',
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF374151)),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelText: 'Reminder',
                  ),
                  onEditingComplete: _setReminder,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _setReminder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF374151),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Set Reminder',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(
            color: Color(0xFF374151),
            thickness: 1,
          ),

          // Pending notifications list
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6B7280),
                    ),
                  )
                : pendingNotifications.isEmpty
                    ? const Center(
                        child: Text(
                          'No pending reminders',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: pendingNotifications.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final notification = pendingNotifications[index];
                          return Dismissible(
                            key: Key(notification.id.toString()),
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) =>
                                _deleteReminder(notification.id),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F2937),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF374151),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.alarm,
                                    color: Color(0xFF9CA3AF),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notification.body ?? 'No description',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notification.payload ?? '--:--',
                                          style: const TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _deleteReminder(notification.id),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
