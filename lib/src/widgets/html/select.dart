import 'package:meta/meta.dart';

import 'package:rad/src/core/common/constants.dart';
import 'package:rad/src/core/common/enums.dart';
import 'package:rad/src/core/common/objects/build_context.dart';
import 'package:rad/src/core/common/objects/key.dart';
import 'package:rad/src/core/common/types.dart';
import 'package:rad/src/widgets/abstract/html_widget_base.dart';
import 'package:rad/src/widgets/abstract/widget.dart';

/// The Select widget (HTML's `select` tag).
///
/// This HTML dom node represents a control that provides a menu of options.
///
class Select extends HTMLWidgetBase {
  /// Associated Name.
  /// Used if Select is part of a form.
  ///
  final String? name;

  /// This Boolean attribute indicates that multiple options
  /// can be selected in the list.
  ///
  final bool? multiple;

  /// Whether Select is disabled.
  ///
  final bool? disabled;

  /// On change event listener.
  ///
  final EventCallback? onChange;

  const Select({
    this.name,
    this.multiple,
    this.disabled,
    this.onChange,
    Key? key,
    String? id,
    bool? hidden,
    bool? draggable,
    bool? contenteditable,
    int? tabIndex,
    String? title,
    String? style,
    String? classAttribute,
    Map<String, String>? dataAttributes,
    String? onClickAttribute,
    String? innerText,
    Widget? child,
    List<Widget>? children,
    EventCallback? onClick,
  }) : super(
          key: key,
          id: id,
          title: title,
          tabIndex: tabIndex,
          draggable: draggable,
          contenteditable: contenteditable,
          hidden: hidden,
          style: style,
          classAttribute: classAttribute,
          dataAttributes: dataAttributes,
          onClickAttribute: onClickAttribute,
          innerText: innerText,
          child: child,
          children: children,
          onClick: onClick,
        );

  @nonVirtual
  @override
  String get widgetType => 'Select';

  @override
  DomTag get correspondingTag => DomTag.select;

  @override
  Map<DomEventType, EventCallback?> get widgetEventListeners => {
        DomEventType.click: onClick,
        DomEventType.change: onChange,
      };

  @override
  createConfiguration() {
    return _SelectConfiguration(
      name: name,
      multiple: multiple,
      disabled: disabled,
      globalConfiguration:
          super.createConfiguration() as HTMLWidgetBaseConfiguration,
    );
  }

  @override
  isConfigurationChanged(covariant _SelectConfiguration oldConfiguration) {
    return name != oldConfiguration.name ||
        multiple != oldConfiguration.multiple ||
        disabled != oldConfiguration.disabled ||
        super.isConfigurationChanged(oldConfiguration.globalConfiguration);
  }

  @override
  createRenderObject(context) => _SelectRenderObject(context);
}

/*
|--------------------------------------------------------------------------
| configuration
|--------------------------------------------------------------------------
*/

class _SelectConfiguration extends WidgetConfiguration {
  final HTMLWidgetBaseConfiguration globalConfiguration;

  final String? name;

  final bool? multiple;
  final bool? disabled;

  const _SelectConfiguration({
    this.name,
    this.multiple,
    this.disabled,
    required this.globalConfiguration,
  });
}

/*
|--------------------------------------------------------------------------
| render object
|--------------------------------------------------------------------------
*/

class _SelectRenderObject extends MarkUpGlobalRenderObject {
  const _SelectRenderObject(BuildContext context) : super(context);

  @override
  render({
    required covariant _SelectConfiguration configuration,
  }) {
    var domNodeDescription = super.render(
      configuration: configuration.globalConfiguration,
    );

    domNodeDescription?.attributes.addAll(
      _prepareAttributes(
        props: configuration,
        oldProps: null,
      ),
    );

    return domNodeDescription;
  }

  @override
  update({
    required updateType,
    required covariant _SelectConfiguration oldConfiguration,
    required covariant _SelectConfiguration newConfiguration,
  }) {
    var domNodeDescription = super.update(
      updateType: updateType,
      oldConfiguration: oldConfiguration.globalConfiguration,
      newConfiguration: newConfiguration.globalConfiguration,
    );

    domNodeDescription?.attributes.addAll(
      _prepareAttributes(
        props: newConfiguration,
        oldProps: oldConfiguration,
      ),
    );

    return domNodeDescription;
  }
}

/*
|--------------------------------------------------------------------------
| props
|--------------------------------------------------------------------------
*/

Map<String, String?> _prepareAttributes({
  required _SelectConfiguration props,
  required _SelectConfiguration? oldProps,
}) {
  var attributes = <String, String?>{};

  if (null != props.name) {
    attributes[Attributes.name] = props.name;
  } else {
    if (null != oldProps?.name) {
      attributes[Attributes.name] = null;
    }
  }

  if (null != props.multiple && props.multiple!) {
    attributes[Attributes.multiple] = '${props.multiple}';
  } else {
    if (null != oldProps?.multiple) {
      attributes[Attributes.multiple] = null;
    }
  }

  if (null != props.disabled && props.disabled!) {
    attributes[Attributes.disabled] = '${props.disabled}';
  } else {
    if (null != oldProps?.disabled) {
      attributes[Attributes.disabled] = null;
    }
  }

  return attributes;
}
