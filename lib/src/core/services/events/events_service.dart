import 'dart:async';
import 'dart:html';

import 'package:rad/src/core/common/enums.dart';
import 'package:rad/src/core/common/functions.dart';
import 'package:rad/src/core/common/objects/app_options.dart';
import 'package:rad/src/core/common/objects/build_context.dart';
import 'package:rad/src/core/common/objects/widget_object.dart';
import 'package:rad/src/core/common/types.dart';
import 'package:rad/src/core/services/abstract.dart';
import 'package:rad/src/core/services/events/emitted_event.dart';

/// Events service.
///
class EventsService extends Service {
  final EventsOptions options;

  final _eventSubscriptions = <StreamSubscription<Event>>[];

  EventsService(BuildContext context, this.options) : super(context);

  @override
  startService() {
    var rootElement = document.getElementById(rootContext.appTargetId);

    if (null != rootElement) {
      _eventSubscriptions.addAll([
        Element.clickEvent.forElement(rootElement).capture(_handle),
        Element.inputEvent.forElement(rootElement).capture(_handle),
        Element.changeEvent.forElement(rootElement).capture(_handle),
        Element.submitEvent.forElement(rootElement).capture(_handle),
        Element.keyUpEvent.forElement(rootElement).capture(_handle),
        Element.keyDownEvent.forElement(rootElement).capture(_handle),
        Element.keyPressEvent.forElement(rootElement).capture(_handle),
      ]);
    }
  }

  @override
  stopService() {
    while (_eventSubscriptions.isNotEmpty) {
      _eventSubscriptions.removeLast().cancel();
    }
  }

  void _handle(Event event) {
    var target = event.target;

    var emittedEvent = EmittedEvent.fromNativeEvent(event);

    if (null != target && target is Element) {
      var closestWidgetObject = _getClosestTargetWidgetObject(target);

      if (null != closestWidgetObject) {
        _dispatch(emittedEvent, closestWidgetObject);
      }
    }
  }

  WidgetObject? _getClosestTargetWidgetObject(Element element) {
    var widgetObject = services.walker.getWidgetObjectUsingElement(element);

    if (null != widgetObject) {
      return widgetObject;
    }

    var parent = element.parent;

    if (null != parent) {
      return _getClosestTargetWidgetObject(parent);
    }

    return null;
  }

  void _dispatch(EmittedEvent event, WidgetObject widgetObject) {
    var eventType = fnMapEventTypeToDomEventType(event.type);

    if (null == eventType) {
      return;
    }

    var listeners = _collectListeners(
      widgetObject: widgetObject,
      eventType: eventType,
    );

    _dispatchEventToListeners(
      listeners: listeners,
      eventType: eventType,
      event: event,
    );
  }

  List<EventCallback> _collectListeners({
    required WidgetObject widgetObject,
    required DomEventType eventType,
  }) {
    var capturingCallbacks = <EventCallback>[];
    var bubblingCallbacks = <EventCallback>[];

    var current = widgetObject;
    while (true) {
      var curCapListeners = current.widget.widgetCaptureEventListeners;
      var curBubListeners = current.widget.widgetEventListeners;

      var curCapListener = curCapListeners[eventType];
      var curBubListener = curBubListeners[eventType];

      if (null != curCapListener) {
        capturingCallbacks.add(curCapListener);
      }

      if (null != curBubListener) {
        bubblingCallbacks.add(curBubListener);
      }

      var parentNode = current.renderNode.parent;
      if (null == parentNode || current.context.isRoot) {
        break;
      }

      var parentObject = services.walker.getWidgetObject(parentNode.context);
      if (null == parentObject) {
        break;
      }

      current = parentObject;
    }

    var callbacks = capturingCallbacks.reversed.toList();

    callbacks.addAll(bubblingCallbacks);

    return callbacks;
  }

  void _dispatchEventToListeners({
    required List<EventCallback> listeners,
    required DomEventType eventType,
    required EmittedEvent event,
  }) {
    // assume event is not absorbed yet
    var isEventAbsorbable = false;

    switch (eventType) {

      // we should stop forwarding these events
      // if a valid listener callback got called
      case DomEventType.change:
      case DomEventType.input:
      case DomEventType.submit:
      case DomEventType.keyUp:
      case DomEventType.keyDown:
      case DomEventType.keyPress:
        isEventAbsorbable = true;

        break;

      // we should forward these events to next elements
      // even if a valid listener callback got called
      case DomEventType.click:
        isEventAbsorbable = false;

        break;
    }

    for (final listener in listeners) {
      if (isEventAbsorbable) {
        event.stopImmediatePropagation();
      }

      listener(event);

      if (event.isPropagationStopped) {
        break;
      }
    }
  }
}
