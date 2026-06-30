import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _checkInDue = false;
  bool _isDialogOpen = false;
  int _secondsRemaining = 0;
  int _checkInCount = 0;
  Timer? _tickTimer;
  late AnimationController _pulseController;
  late AnimationController _blinkController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final provider = context.read<TaskProvider>();
    _secondsRemaining = provider.computeSecondsRemaining();
    _checkInCount = provider.activeSession?.checkInCount ?? 0;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _startTickTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _blinkController.dispose();
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recalculateCheckIn();
    }
  }

  void _startTickTimer() {
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _recalculateCheckIn();
    });
  }

  void _recalculateCheckIn() {
    final provider = context.read<TaskProvider>();
    if (!provider.hasActiveSession) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final remaining = provider.computeSecondsRemaining();
    final count = provider.activeSession?.checkInCount ?? 0;

    setState(() {
      _secondsRemaining = remaining;
      _checkInCount = count;
      if (remaining <= 0 && !_checkInDue && !_isDialogOpen) {
        _triggerCheckInDue();
      } else if (remaining > 0 && _checkInDue) {
        _resetCheckIn();
      }
    });
  }

  void _triggerCheckInDue() {
    _checkInDue = true;
    _blinkController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    HapticFeedback.heavyImpact();
    NotificationService().playCheckInSound();
  }

  void _resetCheckIn() {
    _checkInDue = false;
    _blinkController.stop();
    _blinkController.reset();
    _pulseController.stop();
    _pulseController.reset();
  }

  void _handleCheckIn() {
    context.read<TaskProvider>().checkIn();
    _recalculateCheckIn();
  }

  Future<void> _stopSession() async {
    _tickTimer?.cancel();
    await context.read<TaskProvider>().stopTask();
  }

  Future<void> _onCheckInTap() async {
    if (!_checkInDue || _isDialogOpen) return;

    _isDialogOpen = true;
    final provider = context.read<TaskProvider>();
    final task = provider.activeTask;
    if (task == null) return;

    final progressController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(task.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null && task.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    task.description!,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              Text(
                'What is your progress?',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: progressController,
                decoration: const InputDecoration(
                  hintText: 'Describe what you\'ve done...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'continue'),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'done'),
            child: const Text('Mark as Done'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, 'stop'),
            child: const Text('Stop Session'),
          ),
        ],
      ),
    );

    _isDialogOpen = false;

    if (result == null || result == 'continue') {
      _handleCheckIn();
      return;
    }

    if (result == 'done') {
      if (task.id != null) {
        await provider.toggleTaskComplete(task);
      }
      await _stopSession();
      if (mounted) Navigator.pop(context);
      return;
    }

    if (result == 'stop') {
      await _stopSession();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<bool> _confirmStopSession() async {
    final provider = context.read<TaskProvider>();
    final elapsed = provider.activeSession?.durationSeconds ?? 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Session?'),
        content: Text(
          'You\'ve been focusing for ${_formatDuration(elapsed)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _handlePopRequest() async {
    final confirmed = await _confirmStopSession();
    if (confirmed && mounted) {
      await _stopSession();
      if (mounted) Navigator.pop(context);
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final task = provider.activeTask;
    final taskList = provider.activeTaskList;
    final color = taskList != null ? Color(taskList.color) : const Color(0xFF2196F3);

    if (!provider.hasActiveSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }

    return PopScope(
      canPop: false,
      // ignore: deprecated_member_use
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handlePopRequest();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(task?.title ?? 'Focus'),
          centerTitle: true,
          backgroundColor: color.withValues(alpha: 0.15),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _handlePopRequest,
          ),
          actions: [
            TextButton(
              onPressed: _handlePopRequest,
              child: const Text('End'),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.25),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Task info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        task?.title ?? '',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      if (task?.description != null &&
                          task!.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            task.description!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Timer circle
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (ctx, _) {
                    return Transform.scale(
                      scale: _checkInDue ? _scaleAnimation.value : 1.0,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(
                              alpha: _checkInDue ? 0.2 : 0.08),
                          border: Border.all(
                            color: _checkInDue
                                ? Colors.yellowAccent.withValues(alpha: 0.8)
                                : color.withValues(alpha: 0.3),
                            width: _checkInDue ? 3 : 2,
                          ),
                          boxShadow: _checkInDue
                              ? [
                                  BoxShadow(
                                    color: Colors.yellowAccent
                                        .withValues(alpha: 0.3),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            _formatDuration(
                                _checkInDue ? 0 : _secondsRemaining),
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w200,
                              fontFamily: 'monospace',
                              color: _checkInDue
                                  ? Colors.yellowAccent
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Check-in count
                Text(
                  'Check-in $_checkInCount',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),

                const Spacer(flex: 2),

                // Check-in button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: AnimatedBuilder(
                    animation:
                        Listenable.merge([_pulseController, _blinkController]),
                    builder: (ctx, _) {
                      final opacity =
                          _checkInDue ? _opacityAnimation.value : 0.4;
                      return Opacity(
                        opacity: opacity,
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  _checkInDue ? Colors.amber : color,
                            ),
                            onPressed: _checkInDue ? _onCheckInTap : null,
                            icon: Icon(
                              _checkInDue
                                  ? Icons.notifications_active_rounded
                                  : Icons.touch_app_rounded,
                            ),
                            label: Text(
                              _checkInDue ? 'CHECK IN NOW' : 'Check In',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // End session
                TextButton.icon(
                  onPressed: _handlePopRequest,
                  icon: Icon(Icons.stop_circle_outlined,
                      color: Colors.red.shade300),
                  label: Text(
                    'End Session',
                    style: TextStyle(
                        color: Colors.red.shade300, fontSize: 16),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
