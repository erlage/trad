import 'dart:html';

import 'package:meta/meta.dart';

import 'package:rad/src/core/common/constants.dart';
import 'package:rad/src/core/common/enums.dart';
import 'package:rad/src/core/common/objects/build_context.dart';
import 'package:rad/src/core/common/objects/render_object.dart';
import 'package:rad/src/core/common/types.dart';
import 'package:rad/src/core/services/scheduler/tasks/widgets_build_task.dart';
import 'package:rad/src/core/services/scheduler/tasks/widgets_update_task.dart';
import 'package:rad/src/core/services/services_registry.dart';
import 'package:rad/src/widgets/abstract/widget.dart';
import 'package:rad/src/widgets/inherited_widget.dart';
import 'package:rad/src/widgets/stateless_widget.dart';
import 'package:rad/src/widgets/utils/common_props.dart';
import 'package:rad/src/core/common/objects/key.dart';

/// A widget that has mutable state.
///
/// A stateful widget is a widget that describes dynamic user interface.
/// Stateful widgets are useful when the part of the user interface you are
/// describing can change dynamically, e.g. due to having an internal
/// state, or depending on some system state.
///
/// ## Performance consideration
///   Rad uses a extremely lightweight yet powerful mechanism to build and
///   update DOM. Below are some general tips along with high level
///   understanding of how things works under the hood:
///
/// * Push the state to the leaves. Having state at top level of application is
///   acceptable as well but it's worth noting that having less childs to update
///   means updates can be dispatched and processed faster.
///
///
/// * Use const constructors where possible.
///   A rebuild process involves cascading a update call to all child widgets.
///   Child widgets then *can* cascade update to their childs and so on. Every
///   widget will update its corresponding DOM only if its description has
///   changed. But when you use a const constructor, framework short circuit the
///   rebuild process at the point where it encounters a constant.
///
///
/// * In worst case, framework rebuild widgets from scratch. Complete rebuild
///   involves disposing off current childs and rebuilding new ones with new
///   state. Usually happens when child that framework is looking for is not
///   there anymore because of state change in parent. Rebuilds might be bad if
///   Rad has to render pixel multiple times a second. Luckly in Rad, building
///   and updating interface is a one-step process. Framework handles the
///   description of widgets and building process is carried out by the browser.
///   We can rely on browsers for building big parts of tree when needed.
///   After all that's what they do. By widget description, we mean 'data'
///   that's required to build a widget. This means even if you remove child
///   nodes/or part of DOM tree using browser inspector, calling setState() in a
///   parent widget will bring back everything back in DOM.
///
///
/// ## A Stateful widget example: 'click to toggle'
///
/// ```
/// class ClickToggle extends StatefulWidget {
///
///   @override
///   _ClickToggleState createState() => _ClickToggleState();
/// }
///
/// class _ClickToggleState extends State<ClickToggle> {
///   bool isClicked = false;
///
///   @override
///   Widget build(BuildContext context) {
///     return GestureDetector(
///       onTap: _handleTap,
///       child: Text(isClicked ? "on! click to turn off." : "click to turn on."),
///     );
///   }
///
///   _handleTap() {
///     setState(() {
///       isClicked = !isClicked;
///     });
///   }
/// }
/// ```
///
/// See also:
///
///  * [StatelessWidget], for widgets that always build the same way given a
///    particular configuration.
///
@immutable
abstract class StatefulWidget extends Widget {
  const StatefulWidget({Key? key}) : super(key: key);

  /// Creates the mutable state for this widget at a given location in the tree.
  ///
  @protected
  State createState();

  /*
  |--------------------------------------------------------------------------
  | widget internals
  |--------------------------------------------------------------------------
  */

  @nonVirtual
  @override
  get widgetType => "$StatefulWidget";

  @nonVirtual
  @override
  get correspondingTag => DomTag.division;

  @nonVirtual
  @override
  createConfiguration() => const WidgetConfiguration();

  @nonVirtual
  @override
  isConfigurationChanged(oldConfiguration) => true;

  @nonVirtual
  @override
  createRenderObject(context) => StatefulWidgetRenderObject(
        context: context,
        state: createState(),
      );
}

/*
|--------------------------------------------------------------------------
| render object
|--------------------------------------------------------------------------
*/

class StatefulWidgetRenderObject extends RenderObject {
  final State state;

  const StatefulWidgetRenderObject({
    required this.state,
    required BuildContext context,
  }) : super(context);

  @override
  render(element, configuration) {
    CommonProps.applyDataAttributes(element, {
      Constants.attrStateType: "${state.runtimeType}",
    });

    state
      ..frameworkBindContext(context)
      ..frameworkBindUpdateProcedure(updateProcedure)
      ..initState()
      ..didChangeDependencies();

    var schedulerService = ServicesRegistry.instance.getScheduler(context);

    schedulerService.addTask(
      WidgetsBuildTask(
        parentContext: context,
        widgets: [state.build(context)],
      ),
    );
  }

  @override
  afterWidgetRebind({
    required updateType,
    required covariant StatefulWidget newWidget,
    required covariant StatefulWidget oldWidget,
  }) {
    state
      ..frameworkRebindWidget(newWidget)
      ..didUpdateWidget(oldWidget);
  }

  @override
  update({
    required element,
    required updateType,
    required oldConfiguration,
    required newConfiguration,
  }) {
    if (UpdateType.dependencyChanged == updateType) {
      state.didChangeDependencies();
    }

    updateProcedure(updateType);
  }

  void updateProcedure(UpdateType updateType) {
    var schedulerService = ServicesRegistry.instance.getScheduler(context);

    schedulerService.addTask(
      WidgetsUpdateTask(
        parentContext: context,
        updateType: updateType,
        widgets: [state.build(context)],
      ),
    );
  }

  @override
  beforeUnMount() => state.frameworkDispose();
}

/*
|--------------------------------------------------------------------------
| state
|--------------------------------------------------------------------------
*/

/// The logic and internal state for a [StatefulWidget].
///
/// [State] has three main lifecycle hooks and one state function
/// [setState].
///
/// Framework calls lifecycle hooks on particular events,
///
/// 1. [State.initState] - is called when framework decides to inflate the
/// widget.
/// It's called exactly once during lifetime of this widget.
///
///
/// 2. [State.build] - is called when framework wants to build interface for
/// widget.
/// Whatever interface(widgets) this method return will be built. Note that,
/// Framework can call this method multiple times to stay up-to-date with
/// widget's interface description.
///
///
/// 3. [State.dispose] - is called when framework is about to dispose widget and
/// its state.
///
/// Apart from three main hooks, [State] has two additional hooks that
/// implementations can override when needed. These are,
///
/// [State.didUpdateWidget] - Called whenever the widget configuration changes.
///
/// [State.didChangeDependencies]- Called when a dependency of this [State]
/// object changes.
///
/// Apart from lifecycle hooks, there is a [State.setState] function which a widget
/// can use to tell framework to rebuild widget's interface because some
/// internal state of this widget has changed.
///
/// It's responsibility of concrete implementation of [StatefulWidget]
/// to tell framework when to rebuild the interface using [State.setState]
///
abstract class State<T extends StatefulWidget> {
  /*
  |--------------------------------------------------------------------------
  | useful getters
  |--------------------------------------------------------------------------
  */

  T? _widget;
  T get widget => _widget!;

  BuildContext? _context;
  BuildContext get context => _context!;

  /*
  |--------------------------------------------------------------------------
  | lifecycle hooks
  |--------------------------------------------------------------------------
  */

  /// Called when this widget is inserted into the tree.
  ///
  @protected
  void initState() {}

  /// Describes the part of the user interface represented by this widget.
  ///
  @protected
  Widget build(BuildContext context);

  @protected
  void dispose() {}

  /// Called whenever the widget configuration changes.
  ///
  /// The framework always calls [build] after calling [didUpdateWidget], which
  /// means any calls to [setState] in [didUpdateWidget] are redundant.
  ///
  @protected
  void didUpdateWidget(T oldWidget) {}

  /// Called when a dependency of this [State] object changes.
  ///
  /// For example, if the previous call to [build] referenced an
  /// [InheritedWidget] that later changed, the framework would call this
  /// method to notify this object about the change. This method is also
  /// called immediately after [initState].
  ///
  /// The framework always calls [build] after calling [didChangeDependencies],
  /// which means any calls to [setState] in [didChangeDependencies] are
  /// redundant.
  ///
  @protected
  void didChangeDependencies() {}

  /*
  |--------------------------------------------------------------------------
  | methods
  |--------------------------------------------------------------------------
  */

  /// Notify the framework that the internal state of this widget has changed.
  ///
  @nonVirtual
  @protected
  void setState(Callback? callable) {
    if (_isRebuilding) {
      return;
    }

    _isRebuilding = true;

    if (null != callable) {
      callable();
    }

    _updateProcedure!(UpdateType.setState);

    _isRebuilding = false;
  }

  /*
  |--------------------------------------------------------------------------
  | for internal use
  |--------------------------------------------------------------------------
  */

  var _isRebuilding = false;

  Function(UpdateType type)? _updateProcedure;

  /// Whether widget of current state object is rebuilding.
  ///
  /// Widget might be under rebuild even if this hook returns false. Goal of
  /// this hook is to prevent common overflow(calling setState within same
  /// setState). Which means this hook return true only if setState is called
  /// within the same setState.
  ///
  bool get isRebuilding => _isRebuilding;

  @nonVirtual
  @protected
  void frameworkBindUpdateProcedure(
    Function(UpdateType type) updateProcedure,
  ) {
    if (null != _updateProcedure) {
      throw Exception(Constants.coreError);
    }

    _updateProcedure = updateProcedure;
  }

  @nonVirtual
  @protected
  void frameworkBindContext(BuildContext context) {
    if (null != _context) {
      throw Exception(Constants.coreError);
    }

    _context = context;
  }

  @nonVirtual
  @protected
  void frameworkBindWidget(Widget widget) {
    if (null != _widget) {
      throw Exception(Constants.coreError);
    }

    _widget = widget as T;
  }

  @nonVirtual
  @protected
  void frameworkRebindWidget(Widget newWidget) {
    _widget = newWidget as T;
  }

  @nonVirtual
  @protected
  void frameworkDispose() {
    dispose();
  }
}
