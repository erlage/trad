import 'dart:async';

import 'package:rad/src/core/common/enums.dart';
import 'package:rad/src/core/common/types.dart';
import 'package:rad/src/core/services/scheduler/abstract.dart';
import 'package:rad/src/core/services/scheduler/tasks/stimulate_listener_task.dart';

/// A Task scheduler.
///
/// Running tasks is the sole responsbility of task listener. Scheduler service
/// is a mere mediator between objects that want to add tasks and the objects
/// that are capable of running those tasks.
///
class Scheduler {
  final _tasks = <SchedulerTask>[];

  /// Stream that listener(e.g Framework) can listen to for getting tasks.
  ///
  StreamController<SchedulerTask>? _tasksStream;

  /// Stream that scheduler will listen to for listening to outer events
  /// , and act accordingly.
  ///
  StreamController<SchedulerEvent>? _eventStream;

  /// Start scheduler service.
  ///
  /// This process involves setting up listeners and task streams.
  ///
  void startService(SchedulerTaskCallback listener) {
    _tasksStream = StreamController<SchedulerTask>();
    _eventStream = StreamController<SchedulerEvent>();

    _tasksStream!.stream.listen(listener);
    _eventStream!.stream.listen(_eventListener);
  }

  /// Stop scheduler service.
  ///
  void stopService() {
    _tasksStream!.close();
    _eventStream!.close();
  }

  /// Add a event to task scheduler.
  ///
  void addEvent(SchedulerEvent event) {
    _eventStream!.sink.add(event);
  }

  /// Schedule a task for processing.
  ///
  void addTask(SchedulerTask task) {
    _tasks.add(task);

    _tasksStream!.sink.add(StimulateListenerTask());
  }

  void _eventListener(SchedulerEvent event) {
    switch (event.eventType) {
      case SchedulerEventType.sendNextTask:
        if (_tasks.isNotEmpty) {
          _tasksStream!.sink.add(_tasks.removeAt(0));
        }

        break;
    }
  }
}
