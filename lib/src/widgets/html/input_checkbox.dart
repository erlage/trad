import 'package:meta/meta.dart';
import 'package:rad/src/core/constants.dart';
import 'package:rad/src/core/types.dart';
import 'package:rad/src/widgets/abstract/input_tag.dart';
import 'package:rad/src/widgets/abstract/widget.dart';

class InputCheckBox extends InputTag {
  const InputCheckBox({
    String? id,
    String? name,
    String? value,
    bool? checked,
    bool? required,
    bool? disabled,
    OnInputChangeCallback? onChange,
    String? title,
    String? classAttribute,
    int? tabIndex,
    bool? draggable,
    bool? contenteditable,
    Map<String, String>? dataAttributes,
    bool? hidden,
    List<Widget>? children,
  }) : super(
          id: id,
          type: System.inputCheckbox,
          name: name,
          value: value,
          checked: checked,
          disabled: disabled,
          eventCallback: onChange,
          required: required,
          title: title,
          classAttribute: classAttribute,
          tabIndex: tabIndex,
          draggable: draggable,
          contenteditable: contenteditable,
          dataAttributes: dataAttributes,
          hidden: hidden,
          children: children,
        );

  @nonVirtual
  @override
  get concreteType => "$InputCheckBox";
}
