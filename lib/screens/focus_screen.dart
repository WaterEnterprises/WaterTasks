import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';
import '../services/background_notification_service.dart';
import '../widgets/glass_card.dart';

class FocusScreen extends StatefulWidget {
  final bool fromNotification;
  const FocusScreen({super.key, this.fromNotification = false});

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

    // Check immediately if check-in is already due when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.fromNotification) {
        _triggerCheckInDue();
      } else {
        final remaining = context.read<TaskProvider>().computeSecondsRemaining();
        if (remaining <= 0 && !_checkInDue) {
          _triggerCheckInDue();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _blinkController.dispose();
    _tickTimer?.cancel();
    NotificationService().stopSiren();
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
      }
    });
  }

  void _triggerCheckInDue() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _checkInDue = true;
    _blinkController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    HapticFeedback.heavyImpact();
    final provider = context.read<TaskProvider>();
    NotificationService().startSiren(toneType: provider.toneType);
    final task = provider.activeTask;
    if (task != null) {
      BackgroundNotificationService().startBuzzing(task.title);
    }
  }

  void _resetCheckIn() {
    _checkInDue = false;
    _blinkController.stop();
    _blinkController.reset();
    _pulseController.stop();
    _pulseController.reset();
    NotificationService().stopSiren();
    BackgroundNotificationService().stopBuzzing();
  }

  void _handleCheckIn() {
    _resetCheckIn();
    context.read<TaskProvider>().checkIn();
    _startTickTimer();
    _recalculateCheckIn();
  }

  Future<void> _stopSession() async {
    _tickTimer?.cancel();
    NotificationService().stopSiren();
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
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                task.title,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
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
              const SizedBox(height: 8),
              Text(
                'What is your progress?',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: progressController,
                decoration: const InputDecoration(
                  hintText: 'Describe what you\'ve done...',
                ),
                maxLines: 3,
                autofocus: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, 'continue'),
                  child: const Text('Continue working'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    _isDialogOpen = false;

    if (result == 'continue') {
      _handleCheckIn();
    }
  }

  Future<bool> _confirmStopSession() async {
    final provider = context.read<TaskProvider>();
    final elapsed = provider.activeSession?.durationSeconds ?? 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'End Session?',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'You\'ve been focusing for ${_formatDuration(elapsed)}.',
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('End Session'),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    final color = taskList != null
        ? Color(taskList.color)
        : const Color(0xFF00E5FF);
    final colors = Theme.of(context).colorScheme;

    if (!provider.hasActiveSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handlePopRequest();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(task?.title ?? 'Focus'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _handlePopRequest,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      task?.title ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    if (task?.description != null &&
                        task!.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          task.description!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (ctx, _) {
                  return Transform.scale(
                    scale: _checkInDue ? _scaleAnimation.value : 1.0,
                    child: GlassContainer(
                      width: 220,
                      height: 220,
                      borderRadius: BorderRadius.circular(110),
                      opacity: _checkInDue ? 0.15 : 0.06,
                      blurSigma: 12,
                      borderColor: _checkInDue
                          ? accentBlue.withValues(alpha: 0.8)
                          : color.withValues(alpha: 0.3),
                      borderWidth: _checkInDue ? 3 : 2,
                      boxShadow: _checkInDue
                          ? [
                              BoxShadow(
                                color: accentBlue.withValues(alpha: 0.35),
                                blurRadius: 30,
                                spreadRadius: 6,
                              ),
                            ]
                          : null,
                      child: Center(
                        child: Text(
                          _formatDuration(
                              _checkInDue ? 0 : _secondsRemaining),
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w200,
                            fontFamily: 'monospace',
                            color: _checkInDue
                                ? accentBlue
                                : colors.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Check-in $_checkInCount',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.outline,
                    ),
              ),
              const Spacer(flex: 2),
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
                                _checkInDue ? accentBlue : color,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _checkInDue ? _onCheckInTap : null,
                          icon: Icon(
                            _checkInDue
                                ? Icons.notifications_active_rounded
                                : Icons.touch_app_rounded,
                          ),
                          label: Text(
                            _checkInDue ? "I'M WORKING ON THIS" : 'Working on this',
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
              TextButton.icon(
                onPressed: _handlePopRequest,
                icon: Icon(Icons.stop_circle_outlined,
                    color: Colors.red.shade300),
                label: Text(
                  'End Session',
                  style: TextStyle(color: Colors.red.shade300, fontSize: 16),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

const Color accentBlue = Color(0xFF00E5FF);
