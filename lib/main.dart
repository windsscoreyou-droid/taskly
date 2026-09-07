import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mobmajamwnxqtrwrsihj.supabase.co',
    anonKey: 'sb_publishable_MPCFZfn-qNieoL1kBNeFrg_fjJlSWEE',
  );

  runApp(const TasklyApp());
}

class TasklyApp extends StatelessWidget {
  const TasklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// ============================================================
// 認証状態を監視
// ============================================================

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? authSubscription;

  Session? session;

  @override
  void initState() {
    super.initState();

    session = Supabase.instance.client.auth.currentSession;

    authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        if (!mounted) return;

        setState(() {
          session = data.session;
        });
      },
    );
  }

  @override
  void dispose() {
    authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (session == null) {
      return const AuthPage();
    }

    return const HomePage();
  }
}

// ============================================================
// ログイン画面
// ============================================================

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      showMessage('メールアドレスを入力してください');
      return;
    }

    if (password.isEmpty) {
      showMessage('パスワードを入力してください');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ========================================================
      // メールアドレス＋パスワードでログイン
      //
      // Magic Link / OTP は使用しません。
      // そのためログイン時にメールは送信されません。
      // ========================================================

      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      showMessage('ログインしました');
    } on AuthException catch (e) {
      if (!mounted) return;

      String message = e.message;

      if (e.message.toLowerCase().contains('invalid login')) {
        message = 'メールアドレスまたはパスワードが違います';
      }

      showMessage(
        'ログインに失敗しました\n$message',
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'エラーが発生しました\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 80,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Taskly',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'ログイン',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    '登録済みのメールアドレスと\n'
                    'パスワードでログインしてください。',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // ==================================================
                  // メールアドレス
                  // ==================================================

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'メールアドレス',
                      hintText: 'example@gmail.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // パスワード
                  // ==================================================

                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!isLoading) {
                        submit();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'パスワード',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // ログインボタン
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: isLoading ? null : submit,
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(),
                            )
                          : const Text(
                              'ログイン',
                              style: TextStyle(
                                fontSize: 17,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'ログイン時にメールは送信されません。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'このアプリでは新規アカウント登録はできません。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ホーム
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> tasks = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      final user =
          Supabase.instance.client.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });

          showMessage(
            'ログインユーザーが取得できません',
          );
        }

        return;
      }

      final data = await Supabase.instance.client
          .from('tasks')
          .select(
            'id, title, user_id, completed, due_date, start_date, end_date, status',
          )
          .eq('user_id', user.id);

      if (!mounted) return;

      setState(() {
        tasks.clear();

        tasks.addAll(
          List<Map<String, dynamic>>.from(data),
        );

        isLoading = false;
      });
    } on PostgrestException catch (e) {
      print('タスク読み込みエラー');
      print('message: ${e.message}');
      print('code: ${e.code}');
      print('details: ${e.details}');
      print('hint: ${e.hint}');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(
        'タスクの読み込みに失敗しました\n'
        'code: ${e.code}\n'
        '${e.message}',
      );
    } catch (e) {
      print('タスク読み込みエラー: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(
        'タスクの読み込みに失敗しました: $e',
      );
    }
  }

  String formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String getPeriodText(
    String? startDate,
    String? endDate,
  ) {
    DateTime? start;
    DateTime? end;

    if (startDate != null) {
      start = DateTime.tryParse(startDate);
    }

    if (endDate != null) {
      end = DateTime.tryParse(endDate);
    }

    if (start == null && end == null) {
      return '期間なし';
    }

    if (start == null && end != null) {
      return '${end.month}/${end.day}';
    }

    if (start != null && end == null) {
      return '${start.month}/${start.day}〜';
    }

    if (start != null && end != null) {
      if (start.year == end.year &&
          start.month == end.month &&
          start.day == end.day) {
        return '${start.month}/${start.day}';
      }

      return '${start.month}/${start.day}〜'
          '${end.month}/${end.day}';
    }

    return '期間なし';
  }

  Future<void> addTask() async {
    final result =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) {
        return const AddTaskDialog();
      },
    );

    if (!mounted || result == null) {
      return;
    }

    final name =
        result['title'] as String;

    final startDate =
        result['start_date'] as DateTime?;

    final endDate =
        result['end_date'] as DateTime?;

    final status =
        result['status'] as String? ?? 'todo';

    if (name.isEmpty) {
      return;
    }

    if (startDate != null &&
        endDate != null &&
        endDate.isBefore(startDate)) {
      showMessage(
        '終了日は開始日以降にしてください',
      );
      return;
    }

    try {
      final user =
          Supabase.instance.client.auth.currentUser;

      if (user == null) {
        showMessage('ログインしてください');
        return;
      }

      await Supabase.instance.client
          .from('tasks')
          .insert({
        'title': name,
        'user_id': user.id,
        'start_date': startDate == null
            ? null
            : formatDate(startDate),
        'end_date': endDate == null
            ? null
            : formatDate(endDate),
        'status': status,
        'completed': status == 'done',
      });

      await loadTasks();

      if (mounted) {
        showMessage('タスクを追加しました');
      }
    } on PostgrestException catch (e) {
      print('Supabase登録エラー');
      print('message: ${e.message}');
      print('code: ${e.code}');
      print('details: ${e.details}');
      print('hint: ${e.hint}');

      if (mounted) {
        showMessage(
          'タスクの保存に失敗しました\n'
          'code: ${e.code}\n'
          '${e.message}',
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(
          'タスクの保存に失敗しました: $e',
        );
      }
    }
  }

  Future<void> deleteTask(String id) async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      showMessage('ログインしてください');
      return;
    }

    try {
      await Supabase.instance.client
          .from('tasks')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);

      await loadTasks();
    } on PostgrestException catch (e) {
      showMessage(
        'タスクの削除に失敗しました\n'
        'code: ${e.code}\n'
        '${e.message}',
      );
    } catch (e) {
      showMessage(
        'タスクの削除に失敗しました: $e',
      );
    }
  }

  Future<void> editTask(
    String id,
    String currentTitle,
    String? currentStartDate,
    String? currentEndDate,
    String currentStatus,
  ) async {
    final result =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) {
        return _EditTaskDialog(
          taskId: id,
          currentTitle: currentTitle,
          currentStartDate: currentStartDate,
          currentEndDate: currentEndDate,
          currentStatus: currentStatus,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    if (result['deleted'] == true) {
      await loadTasks();

      if (mounted) {
        showMessage('タスクを削除しました');
      }

      return;
    }

    final startDate =
        result['start_date'] as DateTime?;

    final endDate =
        result['end_date'] as DateTime?;

    final status =
        result['status'] as String? ?? 'todo';

    if (startDate != null &&
        endDate != null &&
        endDate.isBefore(startDate)) {
      showMessage(
        '終了日は開始日以降にしてください',
      );
      return;
    }

    try {
      final user =
          Supabase.instance.client.auth.currentUser;

      if (user == null) {
        showMessage('ログインしてください');
        return;
      }

      await Supabase.instance.client
          .from('tasks')
          .update({
        'title': result['title'],
        'start_date': startDate == null
            ? null
            : formatDate(startDate),
        'end_date': endDate == null
            ? null
            : formatDate(endDate),
        'status': status,
        'completed': status == 'done',
      })
          .eq('id', id)
          .eq('user_id', user.id);

      await loadTasks();

      if (mounted) {
        showMessage('タスクを更新しました');
      }
    } on PostgrestException catch (e) {
      print('タスク編集エラー');
      print('message: ${e.message}');
      print('code: ${e.code}');
      print('details: ${e.details}');
      print('hint: ${e.hint}');

      if (mounted) {
        showMessage(
          'タスクの編集に失敗しました\n'
          'code: ${e.code}\n'
          '${e.message}',
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(
          'タスクの編集に失敗しました: $e',
        );
      }
    }
  }

  Future<void> changeStatus(
    String id,
    String status,
  ) async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      showMessage('ログインしてください');
      return;
    }

    try {
      final completed = status == 'done';

      await Supabase.instance.client
          .from('tasks')
          .update({
        'status': status,
        'completed': completed,
      })
          .eq('id', id)
          .eq('user_id', user.id);

      await loadTasks();
    } on PostgrestException catch (e) {
      showMessage(
        'ステータス変更に失敗しました\n'
        'code: ${e.code}\n'
        '${e.message}',
      );
    } catch (e) {
      showMessage(
        'ステータスの変更に失敗しました: $e',
      );
    }
  }

  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } on AuthException catch (e) {
      if (mounted) {
        showMessage(
          'ログアウトに失敗しました\n${e.message}',
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(
          'ログアウトに失敗しました\n$e',
        );
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget buildTaskSection({
    required String title,
    required IconData icon,
    required String status,
  }) {
    final sectionTasks = tasks
        .where(
          (task) => task['status'] == status,
        )
        .toList();

    if (sectionTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 4,
            top: 8,
            bottom: 8,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...sectionTasks.map((task) {
          final taskId =
              task['id'].toString();

          final taskTitle =
              task['title']?.toString() ?? '';

          final completed =
              task['completed'] == true;

          final startDate =
              task['start_date']?.toString();

          final endDate =
              task['end_date']?.toString();

          final currentStatus =
              task['status']?.toString() ??
                  'todo';

          return Card(
            child: ListTile(
              leading: Checkbox(
                value: completed,
                onChanged: (value) async {
                  if (value == null) {
                    return;
                  }

                  await changeStatus(
                    taskId,
                    value ? 'done' : 'todo',
                  );
                },
              ),
              title: Text(
                taskTitle,
                style: TextStyle(
                  decoration: completed
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              subtitle:
                  startDate == null &&
                          endDate == null
                      ? null
                      : Text(
                          '期間：'
                          '${getPeriodText(startDate, endDate)}',
                        ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.swap_vert,
                    ),
                    tooltip: 'ステータス変更',
                    onSelected: (value) {
                      changeStatus(
                        taskId,
                        value,
                      );
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: 'todo',
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .radio_button_unchecked,
                              ),
                              SizedBox(width: 8),
                              Text('未着手'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'doing',
                          child: Row(
                            children: [
                              Icon(
                                Icons.timelapse,
                              ),
                              SizedBox(width: 8),
                              Text('進行中'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'done',
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .check_circle_outline,
                              ),
                              SizedBox(width: 8),
                              Text('完了'),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                    ),
                    onPressed: () {
                      editTask(
                        taskId,
                        taskTitle,
                        startDate,
                        endDate,
                        currentStatus,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                    onPressed: () {
                      deleteTask(taskId);
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final email =
        Supabase.instance.client.auth.currentUser
                ?.email ??
            '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taskly'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const CalendarPage(),
                ),
              );

              if (mounted) {
                await loadTasks();
              }
            },
            icon: const Icon(
              Icons.calendar_month,
            ),
            tooltip: 'カレンダー',
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(
              Icons.logout,
            ),
            tooltip: 'ログアウト',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              '今日のタスク',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ログイン中：$email',
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : tasks.isEmpty
                      ? const Center(
                          child: Text(
                            'タスクはまだありません',
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        )
                      : ListView(
                          children: [
                            buildTaskSection(
                              title: '未着手',
                              icon: Icons
                                  .radio_button_unchecked,
                              status: 'todo',
                            ),
                            buildTaskSection(
                              title: '進行中',
                              icon:
                                  Icons.timelapse,
                              status: 'doing',
                            ),
                            buildTaskSection(
                              title: '完了',
                              icon: Icons
                                  .check_circle_outline,
                              status: 'done',
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          FloatingActionButton(
        onPressed: addTask,
        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }
}

// ============================================================
// タスク追加
// ============================================================

class AddTaskDialog extends StatefulWidget {
  final DateTime? initialDate;

  const AddTaskDialog({
    super.key,
    this.initialDate,
  });

  @override
  State<AddTaskDialog> createState() =>
      _AddTaskDialogState();
}

class _AddTaskDialogState
    extends State<AddTaskDialog> {
  final TextEditingController controller =
      TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  String selectedStatus = 'todo';

  @override
  void initState() {
    super.initState();

    if (widget.initialDate != null) {
      startDate = widget.initialDate;
      endDate = widget.initialDate;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> selectDateRange() async {
    final initialStart =
        startDate ?? DateTime.now();

    final initialEnd =
        endDate ?? initialStart;

    final picked =
        await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: initialStart,
        end: initialEnd.isBefore(initialStart)
            ? initialStart
            : initialEnd,
      ),
      helpText: '期間を選択',
      cancelText: 'キャンセル',
      confirmText: '決定',
      saveText: '決定',
      fieldStartHintText: '開始日',
      fieldEndHintText: '終了日',
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  String dateText(DateTime? date) {
    if (date == null) {
      return '未設定';
    }

    return '${date.year}/${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'タスクを追加',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'タスク名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                labelText: '状態',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'todo',
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .radio_button_unchecked,
                      ),
                      SizedBox(width: 8),
                      Text('未着手'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'doing',
                  child: Row(
                    children: [
                      Icon(
                        Icons.timelapse,
                      ),
                      SizedBox(width: 8),
                      Text('進行中'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'done',
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .check_circle_outline,
                      ),
                      SizedBox(width: 8),
                      Text('完了'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedStatus = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.play_arrow,
                ),
                const SizedBox(width: 8),
                const Text('開始日'),
                const Spacer(),
                Text(
                  dateText(startDate),
                ),
                TextButton(
                  onPressed: selectDateRange,
                  child:
                      const Text('期間を選択'),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(
                  Icons.stop,
                ),
                const SizedBox(width: 8),
                const Text('終了日'),
                const Spacer(),
                Text(
                  dateText(endDate),
                ),
                TextButton(
                  onPressed: selectDateRange,
                  child:
                      const Text('期間を選択'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'キャンセル',
          ),
        ),
        FilledButton(
          onPressed: () {
            final name =
                controller.text.trim();

            if (name.isEmpty) {
              return;
            }

            if (startDate != null &&
                endDate != null &&
                endDate!.isBefore(startDate!)) {
              return;
            }

            Navigator.of(context).pop({
              'title': name,
              'start_date': startDate,
              'end_date': endDate,
              'status': selectedStatus,
            });
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

// ============================================================
// タスク編集
// ============================================================

class _EditTaskDialog extends StatefulWidget {
  final String taskId;
  final String currentTitle;
  final String? currentStartDate;
  final String? currentEndDate;
  final String currentStatus;

  const _EditTaskDialog({
    required this.taskId,
    required this.currentTitle,
    required this.currentStartDate,
    required this.currentEndDate,
    required this.currentStatus,
  });

  @override
  State<_EditTaskDialog> createState() =>
      _EditTaskDialogState();
}

class _EditTaskDialogState
    extends State<_EditTaskDialog> {
  late final TextEditingController controller;

  DateTime? startDate;
  DateTime? endDate;

  String selectedStatus = 'todo';

  @override
  void initState() {
    super.initState();

    controller =
        TextEditingController(
      text: widget.currentTitle,
    );

    startDate =
        widget.currentStartDate == null
            ? null
            : DateTime.tryParse(
                widget.currentStartDate!,
              );

    endDate =
        widget.currentEndDate == null
            ? null
            : DateTime.tryParse(
                widget.currentEndDate!,
              );

    selectedStatus =
        widget.currentStatus;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> selectDateRange() async {
    final initialStart =
        startDate ?? DateTime.now();

    final initialEnd =
        endDate ?? initialStart;

    final picked =
        await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: initialStart,
        end: initialEnd.isBefore(initialStart)
            ? initialStart
            : initialEnd,
      ),
      helpText: '期間を選択',
      cancelText: 'キャンセル',
      confirmText: '決定',
      saveText: '決定',
      fieldStartHintText: '開始日',
      fieldEndHintText: '終了日',
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  String dateText(DateTime? date) {
    if (date == null) {
      return '未設定';
    }

    return '${date.year}/${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'タスクを編集',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: false,
              decoration: const InputDecoration(
                labelText: 'タスク名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                labelText: '状態',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'todo',
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .radio_button_unchecked,
                      ),
                      SizedBox(width: 8),
                      Text('未着手'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'doing',
                  child: Row(
                    children: [
                      Icon(
                        Icons.timelapse,
                      ),
                      SizedBox(width: 8),
                      Text('進行中'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'done',
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .check_circle_outline,
                      ),
                      SizedBox(width: 8),
                      Text('完了'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedStatus = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.play_arrow,
                ),
                const SizedBox(width: 8),
                const Text('開始日'),
                const Spacer(),
                Text(
                  dateText(startDate),
                ),
                TextButton(
                  onPressed: selectDateRange,
                  child:
                      const Text('期間を選択'),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(
                  Icons.stop,
                ),
                const SizedBox(width: 8),
                const Text('終了日'),
                const Spacer(),
                Text(
                  dateText(endDate),
                ),
                TextButton(
                  onPressed: selectDateRange,
                  child:
                      const Text('期間を選択'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () async {
            final confirmed =
                await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text(
                    'タスクを削除',
                  ),
                  content: const Text(
                    'このタスクを削除しますか？',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pop(false);
                      },
                      child:
                          const Text('キャンセル'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pop(true);
                      },
                      child: const Text('削除'),
                    ),
                  ],
                );
              },
            );

            if (confirmed != true) {
              return;
            }

            try {
              final user =
                  Supabase.instance.client.auth.currentUser;

              if (user == null) {
                return;
              }

              await Supabase.instance.client
                  .from('tasks')
                  .delete()
                  .eq('id', widget.taskId)
                  .eq('user_id', user.id);

              if (!mounted) return;

              Navigator.of(context).pop({
                'deleted': true,
              });
            } on PostgrestException catch (e) {
              if (!mounted) return;

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                SnackBar(
                  content: Text(
                    '削除に失敗しました\n'
                    'code: ${e.code}\n'
                    '${e.message}',
                  ),
                ),
              );
            } catch (e) {
              if (!mounted) return;

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                SnackBar(
                  content: Text(
                    '削除に失敗しました: $e',
                  ),
                ),
              );
            }
          },
          child: const Text(
            '削除',
            style: TextStyle(
              color: Colors.red,
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            final title =
                controller.text.trim();

            if (title.isEmpty) {
              return;
            }

            if (startDate != null &&
                endDate != null &&
                endDate!.isBefore(startDate!)) {
              return;
            }

            Navigator.of(context).pop({
              'title': title,
              'start_date': startDate,
              'end_date': endDate,
              'status': selectedStatus,
            });
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}

// ============================================================
// カレンダー
// ============================================================

class CalendarPage extends StatefulWidget {
  const CalendarPage({
    super.key,
  });

  @override
  State<CalendarPage> createState() =>
      _CalendarPageState();
}

class _CalendarPageState
    extends State<CalendarPage> {
  DateTime currentMonth = DateTime.now();

  List<Map<String, dynamic>> tasks = [];

  bool isLoading = true;

  static const double weekHeight = 105;
  static const double dayHeaderHeight = 22;
  static const double barHeight = 18;
  static const double barGap = 2;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(
      value.toString(),
    );
  }

  DateTime dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  bool isSameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  bool isToday(DateTime date) {
    return isSameDay(
      date,
      DateTime.now(),
    );
  }

  bool isJapaneseHoliday(DateTime date) {
    final year = date.year;
    final month = date.month;
    final day = date.day;

    final fixedHolidays = <String>{
      '$year-1-1',
      '$year-2-11',
      '$year-2-23',
      '$year-4-29',
      '$year-5-3',
      '$year-5-4',
      '$year-5-5',
      '$year-8-11',
      '$year-11-3',
      '$year-11-23',
    };

    if (fixedHolidays.contains(
      '$year-$month-$day',
    )) {
      return true;
    }

    if (month == 3) {
      final vernalDay =
          _vernalEquinoxDay(year);

      if (day == vernalDay) {
        return true;
      }
    }

    if (month == 9) {
      final autumnalDay =
          _autumnalEquinoxDay(year);

      if (day == autumnalDay) {
        return true;
      }
    }

    if (month == 1 &&
        date.weekday == DateTime.monday &&
        day >= 8 &&
        day <= 14) {
      return true;
    }

    if (month == 7 &&
        date.weekday == DateTime.monday &&
        day >= 15 &&
        day <= 21) {
      return true;
    }

    if (month == 9 &&
        date.weekday == DateTime.monday &&
        day >= 15 &&
        day <= 21) {
      return true;
    }

    if (month == 10 &&
        date.weekday == DateTime.monday &&
        day >= 8 &&
        day <= 14) {
      return true;
    }

    if (date.weekday == DateTime.monday) {
      final previousDay =
          date.subtract(
        const Duration(days: 1),
      );

      if (isJapaneseHolidayWithoutSubstitute(
        previousDay,
      )) {
        return true;
      }
    }

    final previousDay =
        date.subtract(
      const Duration(days: 1),
    );

    final nextDay =
        date.add(
      const Duration(days: 1),
    );

    if (isJapaneseHolidayWithoutSubstitute(
          previousDay,
        ) &&
        isJapaneseHolidayWithoutSubstitute(
          nextDay,
        )) {
      return true;
    }

    return false;
  }

  bool isJapaneseHolidayWithoutSubstitute(
    DateTime date,
  ) {
    final year = date.year;
    final month = date.month;
    final day = date.day;

    final fixedHolidays = <String>{
      '$year-1-1',
      '$year-2-11',
      '$year-2-23',
      '$year-4-29',
      '$year-5-3',
      '$year-5-4',
      '$year-5-5',
      '$year-8-11',
      '$year-11-3',
      '$year-11-23',
    };

    if (fixedHolidays.contains(
      '$year-$month-$day',
    )) {
      return true;
    }

    if (month == 3 &&
        day == _vernalEquinoxDay(year)) {
      return true;
    }

    if (month == 9 &&
        day == _autumnalEquinoxDay(year)) {
      return true;
    }

    if (month == 1 &&
        date.weekday == DateTime.monday &&
        day >= 8 &&
        day <= 14) {
      return true;
    }

    if (month == 7 &&
        date.weekday == DateTime.monday &&
        day >= 15 &&
        day <= 21) {
      return true;
    }

    if (month == 9 &&
        date.weekday == DateTime.monday &&
        day >= 15 &&
        day <= 21) {
      return true;
    }

    if (month == 10 &&
        date.weekday == DateTime.monday &&
        day >= 8 &&
        day <= 14) {
      return true;
    }

    return false;
  }

  int _vernalEquinoxDay(int year) {
    return (20.8431 +
            0.242194 * (year - 1980) -
            ((year - 1980) / 4).floor())
        .floor();
  }

  int _autumnalEquinoxDay(int year) {
    return (23.2488 +
            0.242194 * (year - 1980) -
            ((year - 1980) / 4).floor())
        .floor();
  }

  Future<void> loadTasks() async {
    try {
      final user =
          Supabase.instance.client.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }

        return;
      }

      final data =
          await Supabase.instance.client
              .from('tasks')
              .select(
                'id, title, user_id, completed, due_date, start_date, end_date, status',
              )
              .eq(
                'user_id',
                user.id,
              );

      if (!mounted) return;

      setState(() {
        tasks =
            List<Map<String, dynamic>>.from(data);

        isLoading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(
        'カレンダーの読み込みに失敗しました\n'
        'code: ${e.code}\n'
        '${e.message}',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(
        'カレンダーの読み込みに失敗しました: $e',
      );
    }
  }

  Map<String, dynamic>? getTaskPeriod(
    Map<String, dynamic> task,
  ) {
    DateTime? start =
        parseDate(task['start_date']);

    DateTime? end =
        parseDate(task['end_date']);

    if (start == null &&
        end == null &&
        task['due_date'] != null) {
      final oldDate =
          parseDate(task['due_date']);

      start = oldDate;
      end = oldDate;
    }

    if (start == null) {
      return null;
    }

    end ??= start;

    start = dateOnly(start);
    end = dateOnly(end);

    if (end.isBefore(start)) {
      return null;
    }

    return {
      'start': start,
      'end': end,
    };
  }

  List<Map<String, dynamic>> getTasksForDate(
    DateTime date,
  ) {
    final target = dateOnly(date);

    return tasks.where((task) {
      final period =
          getTaskPeriod(task);

      if (period == null) {
        return false;
      }

      final start =
          period['start'] as DateTime;

      final end =
          period['end'] as DateTime;

      return !target.isBefore(start) &&
          !target.isAfter(end);
    }).toList();
  }

  Future<void> addCalendarTask(
    DateTime date,
  ) async {
    final result =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) {
        return AddTaskDialog(
          initialDate: date,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    final title =
        result['title']?.toString().trim() ?? '';

    if (title.isEmpty) {
      return;
    }

    final startDate =
        result['start_date'] as DateTime? ??
            date;

    final endDate =
        result['end_date'] as DateTime? ??
            startDate;

    final status =
        result['status'] as String? ??
            'todo';

    if (endDate.isBefore(startDate)) {
      showMessage(
        '終了日は開始日以降にしてください',
      );
      return;
    }

    try {
      final user =
          Supabase.instance.client.auth.currentUser;

      if (user == null) {
        showMessage('ログインしてください');
        return;
      }

      await Supabase.instance.client
          .from('tasks')
          .insert({
        'title': title,
        'user_id': user.id,
        'start_date':
            formatDate(startDate),
        'end_date':
            formatDate(endDate),
        'status': status,
        'completed': status == 'done',
      });

      await loadTasks();

      if (mounted) {
        showMessage('タスクを登録しました');
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;

      showMessage(
        'タスクの登録に失敗しました\n'
        'code: ${e.code}\n'
        '${e.message}',
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'タスクの登録に失敗しました: $e',
      );
    }
  }

  Future<void> editCalendarTask(
    Map<String, dynamic> task,
  ) async {
    final result =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) {
        return _EditTaskDialog(
          taskId: task['id'].toString(),
          currentTitle:
              task['title']?.toString() ?? '',
          currentStartDate:
              task['start_date']?.toString(),
          currentEndDate:
              task['end_date']?.toString(),
          currentStatus:
              task['status']?.toString() ??
                  'todo',
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    if (result['deleted'] == true) {
      await loadTasks();

      if (mounted) {
        showMessage('タスクを削除しました');
      }

      return;
    }

    final startDate =
        result['start_date'] as DateTime?;

    final endDate =
        result['end_date'] as DateTime?;

    final status =
        result['status'] as String? ??
            'todo';

    if (startDate != null &&
        endDate != null &&
        endDate.isBefore(startDate)) {
      showMessage(
        '終了日は開始日以降にしてください',
      );
      return;
    }

    try {
      final user =
          Supabase.instance.client.auth.currentUser;

      if (user == null) {
        showMessage('ログインしてください');
        return;
      }

      await Supabase.instance.client
          .from('tasks')
          .update({
        'title': result['title'],
        'start_date': startDate == null
            ? null
            : formatDate(startDate),
        'end_date': endDate == null
            ? null
            : formatDate(endDate),
        'status': status,
        'completed': status == 'done',
      })
          .eq(
            'id',
            task['id'],
          )
          .eq(
            'user_id',
            user.id,
          );

      await loadTasks();

      if (mounted) {
        showMessage(
          'タスクを更新しました',
        );
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;

      showMessage(
        'タスクの更新に失敗しました\n'
        'code: ${e.code}\n'
        '${e.message}',
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'タスクの更新に失敗しました: $e',
      );
    }
  }

  Future<void> toggleCalendarTask(
    Map<String, dynamic> task,
  ) async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      showMessage('ログインしてください');
      return;
    }

    final completed =
        task['completed'] == true;

    try {
      await Supabase.instance.client
          .from('tasks')
          .update({
        'completed': !completed,
        'status':
            !completed ? 'done' : 'todo',
      })
          .eq(
            'id',
            task['id'],
          )
          .eq(
            'user_id',
            user.id,
          );

      await loadTasks();
    } on PostgrestException catch (e) {
      if (!mounted) return;

      showMessage(
        'タスクの変更に失敗しました\n'
        'code: ${e.code}\n'
        '${e.message}',
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'タスクの変更に失敗しました: $e',
      );
    }
  }

  Future<void> deleteCalendarTask(
    Map<String, dynamic> task,
  ) async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      showMessage('ログインしてください');
      return;
    }

    try {
      await Supabase.instance.client
          .from('tasks')
          .delete()
          .eq(
            'id',
            task['id'],
          )
          .eq(
            'user_id',
            user.id,
          );

      await loadTasks();

      if (mounted) {
        showMessage(
          'タスクを削除しました',
        );
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;

      showMessage(
        'タスクの削除に失敗しました\n'
        'code: ${e.code}\n'
        '${e.message}',
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'タスクの削除に失敗しました: $e',
      );
    }
  }

  void previousMonth() {
    setState(() {
      currentMonth = DateTime(
        currentMonth.year,
        currentMonth.month - 1,
        1,
      );
    });
  }

  void nextMonth() {
    setState(() {
      currentMonth = DateTime(
        currentMonth.year,
        currentMonth.month + 1,
        1,
      );
    });
  }

  void showDayTasks(DateTime date) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final dayTasks =
            getTasksForDate(date);

        return AlertDialog(
          title: Text(
            '${date.year}年'
            '${date.month}月'
            '${date.day}日',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                ...dayTasks.map((task) {
                  final completed =
                      task['completed'] == true;

                  final start =
                      parseDate(
                    task['start_date'],
                  );

                  final end =
                      parseDate(
                    task['end_date'],
                  );

                  String periodText = '';

                  if (start != null &&
                      end != null) {
                    periodText =
                        '${start.month}/${start.day}'
                        '〜'
                        '${end.month}/${end.day}';
                  }

                  return ListTile(
                    leading: Checkbox(
                      value: completed,
                      onChanged: (_) async {
                        Navigator.of(
                          dialogContext,
                        ).pop();

                        await toggleCalendarTask(
                          task,
                        );
                      },
                    ),
                    title: Text(
                      task['title']
                              ?.toString() ??
                          '',
                      style: TextStyle(
                        decoration: completed
                            ? TextDecoration
                                .lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle:
                        periodText.isEmpty
                            ? null
                            : Text(
                                '期間：$periodText',
                              ),
                    trailing: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                          ),
                          onPressed: () async {
                            Navigator.of(
                              dialogContext,
                            ).pop();

                            await editCalendarTask(
                              task,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                          ),
                          onPressed: () async {
                            Navigator.of(
                              dialogContext,
                            ).pop();

                            await deleteCalendarTask(
                              task,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
                if (dayTasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'この日のタスクはありません',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                Navigator.of(
                  dialogContext,
                ).pop();

                await addCalendarTask(
                  date,
                );
              },
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                'タスク追加',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                '閉じる',
              ),
            ),
          ],
        );
      },
    );
  }

  List<DateTime> createCalendarDays() {
    final firstDay = DateTime(
      currentMonth.year,
      currentMonth.month,
      1,
    );

    final lastDay = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    );

    final startOffset =
        firstDay.weekday - 1;

    final calendarStart =
        firstDay.subtract(
      Duration(days: startOffset),
    );

    final endOffset =
        7 - lastDay.weekday;

    final calendarEnd =
        lastDay.add(
      Duration(days: endOffset),
    );

    final List<DateTime> days = [];

    DateTime cursor = calendarStart;

    while (!cursor.isAfter(calendarEnd)) {
      days.add(cursor);

      cursor = cursor.add(
        const Duration(days: 1),
      );
    }

    return days;
  }

  List<List<DateTime>> createWeeks() {
    final days =
        createCalendarDays();

    final List<List<DateTime>> weeks = [];

    for (
      int i = 0;
      i < days.length;
      i += 7
    ) {
      weeks.add(
        days.sublist(
          i,
          i + 7,
        ),
      );
    }

    return weeks;
  }

  List<Map<String, dynamic>> getTasksForWeek(
    List<DateTime> week,
  ) {
    final weekStart =
        dateOnly(week.first);

    final weekEnd =
        dateOnly(week.last);

    final result =
        <Map<String, dynamic>>[];

    for (final task in tasks) {
      final period =
          getTaskPeriod(task);

      if (period == null) {
        continue;
      }

      final start =
          period['start'] as DateTime;

      final end =
          period['end'] as DateTime;

      if (!end.isBefore(weekStart) &&
          !start.isAfter(weekEnd)) {
        result.add(task);
      }
    }

    result.sort((a, b) {
      final aPeriod =
          getTaskPeriod(a);

      final bPeriod =
          getTaskPeriod(b);

      if (aPeriod == null ||
          bPeriod == null) {
        return 0;
      }

      final aStart =
          aPeriod['start'] as DateTime;

      final bStart =
          bPeriod['start'] as DateTime;

      final result =
          aStart.compareTo(bStart);

      if (result != 0) {
        return result;
      }

      final aEnd =
          aPeriod['end'] as DateTime;

      final bEnd =
          bPeriod['end'] as DateTime;

      return aEnd.compareTo(bEnd);
    });

    return result;
  }

  Widget buildWeek(
    List<DateTime> week,
  ) {
    return SizedBox(
      height: weekHeight,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.maxWidth;

          final cellWidth =
              width / 7.0;

          final weekStart =
              dateOnly(week.first);

          final weekEnd =
              dateOnly(week.last);

          final weekTasks =
              getTasksForWeek(week);

          final Map<String, int> taskLane =
              {};

          final List<
              List<Map<String, dynamic>>> lanes =
              [];

          for (final task in weekTasks) {
            final period =
                getTaskPeriod(task);

            if (period == null) {
              continue;
            }

            final start =
                period['start'] as DateTime;

            final end =
                period['end'] as DateTime;

            final visibleStart =
                start.isBefore(weekStart)
                    ? weekStart
                    : start;

            final visibleEnd =
                end.isAfter(weekEnd)
                    ? weekEnd
                    : end;

            final startIndex =
                visibleStart
                    .difference(weekStart)
                    .inDays
                    .clamp(0, 6);

            final endIndex =
                visibleEnd
                    .difference(weekStart)
                    .inDays
                    .clamp(0, 6);

            int selectedLane = -1;

            for (
              int laneIndex = 0;
              laneIndex < lanes.length;
              laneIndex++
            ) {
              bool overlap = false;

              for (final other
                  in lanes[laneIndex]) {
                final otherPeriod =
                    getTaskPeriod(other);

                if (otherPeriod == null) {
                  continue;
                }

                final otherStart =
                    otherPeriod['start']
                        as DateTime;

                final otherEnd =
                    otherPeriod['end']
                        as DateTime;

                final otherVisibleStart =
                    otherStart.isBefore(
                            weekStart)
                        ? weekStart
                        : otherStart;

                final otherVisibleEnd =
                    otherEnd.isAfter(weekEnd)
                        ? weekEnd
                        : otherEnd;

                final otherStartIndex =
                    otherVisibleStart
                        .difference(
                          weekStart,
                        )
                        .inDays
                        .clamp(0, 6);

                final otherEndIndex =
                    otherVisibleEnd
                        .difference(
                          weekStart,
                        )
                        .inDays
                        .clamp(0, 6);

                if (startIndex <=
                        otherEndIndex &&
                    endIndex >=
                        otherStartIndex) {
                  overlap = true;
                  break;
                }
              }

              if (!overlap) {
                selectedLane = laneIndex;
                break;
              }
            }

            if (selectedLane == -1) {
              selectedLane = lanes.length;
              lanes.add([]);
            }

            lanes[selectedLane].add(task);

            taskLane[
                task['id'].toString()] =
                selectedLane;
          }

          const maxVisibleLanes = 3;

          return ClipRRect(
            borderRadius:
                BorderRadius.circular(6),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
                borderRadius:
                    BorderRadius.circular(6),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: Row(
                      children:
                          List.generate(
                        7,
                        (index) {
                          final date =
                              week[index];

                          final today =
                              isToday(date);

                          final currentMonthDay =
                              date.month ==
                                  currentMonth.month;

                          final holiday =
                              isJapaneseHoliday(
                            date,
                          );

                          Color dateColor;

                          if (!currentMonthDay) {
                            dateColor =
                                Colors.grey;
                          } else if (holiday ||
                              date.weekday ==
                                  DateTime.sunday) {
                            dateColor =
                                Colors.red;
                          } else if (date.weekday ==
                              DateTime.saturday) {
                            dateColor =
                                Colors.blue;
                          } else if (today) {
                            dateColor =
                                Colors.blue;
                          } else {
                            dateColor =
                                Colors.black;
                          }

                          return Expanded(
                            child:
                                GestureDetector(
                              onTap: () {
                                showDayTasks(
                                  date,
                                );
                              },
                              child:
                                  Container(
                                decoration:
                                    BoxDecoration(
                                  color: today
                                      ? Colors
                                          .blue
                                          .withValues(
                                          alpha: 0.06,
                                        )
                                      : null,
                                  border: Border(
                                    right: index == 6
                                        ? BorderSide
                                            .none
                                        : BorderSide(
                                            color: Colors
                                                .grey
                                                .shade200,
                                          ),
                                  ),
                                ),
                                padding:
                                    const EdgeInsets
                                        .only(
                                  top: 3,
                                  left: 4,
                                ),
                                child: Align(
                                  alignment:
                                      Alignment
                                          .topLeft,
                                  child: Text(
                                    '${date.day}',
                                    style:
                                        TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color:
                                          dateColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  ...weekTasks.map(
                    (task) {
                      final lane =
                          taskLane[
                              task['id']
                                  .toString()];

                      if (lane == null ||
                          lane >=
                              maxVisibleLanes) {
                        return const SizedBox();
                      }

                      final period =
                          getTaskPeriod(task);

                      if (period == null) {
                        return const SizedBox();
                      }

                      final start =
                          period['start']
                              as DateTime;

                      final end =
                          period['end']
                              as DateTime;

                      final visibleStart =
                          start.isBefore(
                                  weekStart)
                              ? weekStart
                              : start;

                      final visibleEnd =
                          end.isAfter(weekEnd)
                              ? weekEnd
                              : end;

                      int startIndex =
                          visibleStart
                              .difference(
                                weekStart,
                              )
                              .inDays;

                      int endIndex =
                          visibleEnd
                              .difference(
                                weekStart,
                              )
                              .inDays;

                      startIndex =
                          startIndex.clamp(0, 6);

                      endIndex =
                          endIndex.clamp(0, 6);

                      if (endIndex <
                          startIndex) {
                        return const SizedBox();
                      }

                      final title =
                          task['title']
                                  ?.toString() ??
                              '';

                      final status =
                          task['status']
                                  ?.toString() ??
                              'todo';

                      final barColor =
                          status == 'doing'
                              ? Colors.blue.shade200
                              : status == 'done'
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade300;

                      final textColor =
                          status == 'done'
                              ? Colors.white
                              : Colors.black87;

                      final rawLeft =
                          startIndex *
                              cellWidth;

                      final rawWidth =
                          (endIndex -
                                  startIndex +
                                  1) *
                              cellWidth;

                      final safeLeft =
                          rawLeft.clamp(
                        0.0,
                        width,
                      );

                      final maxWidth =
                          width -
                              safeLeft -
                              4;

                      final safeWidth =
                          (rawWidth - 4).clamp(
                        1.0,
                        maxWidth < 1.0
                            ? 1.0
                            : maxWidth,
                      );

                      final top =
                          dayHeaderHeight +
                              lane *
                                  (barHeight +
                                      barGap);

                      return Positioned(
                        left: safeLeft + 2,
                        top: top,
                        width: safeWidth,
                        height: barHeight,
                        child:
                            GestureDetector(
                          onTap: () async {
                            await editCalendarTask(
                              task,
                            );
                          },
                          child: Container(
                            clipBehavior:
                                Clip.hardEdge,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 5,
                            ),
                            decoration:
                                BoxDecoration(
                              color: barColor,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                4,
                              ),
                            ),
                            alignment:
                                Alignment.centerLeft,
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style:
                                  TextStyle(
                                fontSize: 10,
                                color:
                                    textColor,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (weekTasks.where(
                    (task) {
                      final lane =
                          taskLane[
                              task['id']
                                  .toString()];

                      return lane != null &&
                          lane >=
                              maxVisibleLanes;
                    },
                  ).isNotEmpty)
                    Positioned(
                      left: 4,
                      top: dayHeaderHeight +
                          maxVisibleLanes *
                              (barHeight +
                                  barGap),
                      child: Builder(
                        builder: (context) {
                          final hiddenCount =
                              weekTasks.where(
                            (task) {
                              final lane =
                                  taskLane[
                                      task['id']
                                          .toString()];

                              return lane != null &&
                                  lane >=
                                      maxVisibleLanes;
                            },
                          ).length;

                          return Text(
                            '+${hiddenCount}件',
                            style:
                                const TextStyle(
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weeks = createWeeks();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'カレンダー',
        ),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      IconButton(
                        onPressed:
                            previousMonth,
                        icon: const Icon(
                          Icons.chevron_left,
                        ),
                      ),
                      Text(
                        '${currentMonth.year}年'
                        '${currentMonth.month}月',
                        style:
                            const TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed:
                            nextMonth,
                        icon: const Icon(
                          Icons.chevron_right,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: const [
                      Expanded(
                        child: _WeekdayCell(
                          text: '月',
                        ),
                      ),
                      Expanded(
                        child: _WeekdayCell(
                          text: '火',
                        ),
                      ),
                      Expanded(
                        child: _WeekdayCell(
                          text: '水',
                        ),
                      ),
                      Expanded(
                        child: _WeekdayCell(
                          text: '木',
                        ),
                      ),
                      Expanded(
                        child: _WeekdayCell(
                          text: '金',
                        ),
                      ),
                      Expanded(
                        child: _WeekdayCell(
                          text: '土',
                        ),
                      ),
                      Expanded(
                        child: _WeekdayCell(
                          text: '日',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Expanded(
                  child:
                      SingleChildScrollView(
                    child: Column(
                      children: weeks
                          .map(
                            (week) =>
                                buildWeek(
                              week,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton:
          FloatingActionButton(
        onPressed: () {
          addCalendarTask(
            DateTime.now(),
          );
        },
        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }
}

// ============================================================
// 曜日
// ============================================================

class _WeekdayCell extends StatelessWidget {
  final String text;

  const _WeekdayCell({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor = Colors.black;

    if (text == '土') {
      textColor = Colors.blue;
    } else if (text == '日') {
      textColor = Colors.red;
    }

    return SizedBox(
      height: 24,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
