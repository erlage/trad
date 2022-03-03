import 'package:rad/src/core/constants.dart';
import 'package:rad/src/core/classes/framework.dart';
import 'package:rad/src/core/enums.dart';
import 'package:rad/src/core/objects/render_object.dart';
import 'package:rad/src/core/structures/build_context.dart';
import 'package:rad/src/core/structures/widget.dart';
import 'package:rad/src/widgets/layout/overlay/overlay_entry.dart';
import 'package:rad/src/widgets/layout/overlay/overlay_state.dart';

/// A stack of entries that can be managed independently.
///
/// Overlays let independent child widgets "float" visual elements on top of
/// other widgets by inserting them into the overlay's stack. The overlay lets
/// each of these widgets manage their participation in the overlay using
/// [OverlayEntry] objects.
///
/// The [Overlay] widget uses a custom stack implementation, which is very
/// similar to the [Stack] widget but it provides more low-level controls.
///
/// See also:
///
///  * [OverlayEntry], the class that is used for describing the overlay entries.
///  * [OverlayState], which is used to insert the entries into the overlay.
///  * [Stack], which allows directly displaying a stack of widgets.
///
class Overlay extends Widget {
  final String? key;

  final String? styles;

  final List<OverlayEntry> initialEntries;

  const Overlay({
    this.key,
    this.styles,
    required this.initialEntries,
  });

  @override
  DomTag get tag => DomTag.div;

  @override
  String get type => (Overlay).toString();

  @override
  String get initialKey => key ?? System.keyNotSet;

  @override
  createRenderObject(context) => OverlayRenderObject(context);

  @override
  onRenderObjectCreate(renderObject) {
    renderObject as OverlayRenderObject;

    renderObject.state = OverlayState();
  }

  /// The state from the closest instance of this class that encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// OverlayState overlay = Overlay.of(context);
  /// ```
  static OverlayState of(BuildContext context) {
    var widgetObject = Framework.findAncestorOfType<Overlay>(context);

    if (null == widgetObject) {
      throw "Overlay.of(context) called with the context that doesn't contains Overylay";
    }

    return (widgetObject.renderObject as OverlayRenderObject).state;
  }
}

class OverlayRenderObject extends RenderObject {
  late final OverlayState state;

  OverlayRenderObject(BuildContext context) : super(context);

  @override
  render(widgetObject) => state.render(widgetObject);
}
