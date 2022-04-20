import 'package:meta/meta.dart';
import 'package:rad/src/core/common/constants.dart';
import 'package:rad/src/core/common/objects/build_context.dart';
import 'package:rad/src/core/services/services_registry.dart';
import 'package:rad/src/include/foundation/hash_codes.dart';
import 'package:rad/src/widgets/abstract/widget.dart';

/// A [Key] is an identifier for [Widget]s.
///
/// Most of the time, framework takes care of generating keys for you.
///
/// Keys must be unique amongst the [Widget]s with the same parent. By
/// contrast, [GlobalKey]s must be unique across entire document and [LocalKey]
/// must be unique in single app instance where it was created.
///
/// Key values are computed and computed value is used as value if ID attribute
/// of the element associated with the widget. This means computed value can be
/// used to find associated element in document.
///
///
/// For a [Key], getting computed value is not possible.
///
///
/// For a [LocalKey], you can get computed value using
/// [LocalKey.getComputedValue].
///
///
/// For a [GlobalKey], computed value is exactly same as provided value. Which
/// means you can access computed value using [Key.value] for [GlobalKey]s
///
@immutable
class Key {
  final String _value;

  /// Value of key that was used while creating key.
  ///
  String get value => _value;

  /// Whether value of key is using system reserved prefix.
  ///
  /// Reserved prefix is added to keys that are generated by the framework.
  ///
  bool get hasSystemPrefix => _value.startsWith(Constants.contextGenKeyPrefix);

  /// Simplest way to create a key.
  ///
  /// Keys must be unique amongst the [Widget]s with the same parent. By
  /// contrast, [GlobalKey]s must be unique across entire document.
  ///
  const Key(this._value);

  @override
  operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is Key && other.value == value;
  }

  @override
  get hashCode => hashValues(runtimeType, value);

  @override
  toString() => value;
}

/// A key that is unique within the app its created.
///
class LocalKey extends Key {
  /// Creates a local key.
  ///
  /// Constructing code must be responsible for providing a value that's unique
  /// within entire app.
  ///
  const LocalKey(String value) : super(value);

  /// Return computed value of local key.
  ///
  String getComputedValue(BuildContext context) {
    var keyGenService = ServicesRegistry.instance.getKeyGen(context);

    return keyGenService.getGlobalKeyUsingKey(this, context).value;
  }
}

/// A key that is unique within entire document(within multiple apps).
///
class GlobalKey extends Key {
  /// Creates a global key.
  ///
  /// Code that constructs key must be responsible for providing a value that's
  /// unique within entire document(i.e withing multiple app instances).
  ///
  const GlobalKey(String value) : super(value);
}
