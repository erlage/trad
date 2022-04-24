import 'package:rad/src/core/common/objects/build_context.dart';
import 'package:rad/src/core/services/debug/debug.dart';
import 'package:rad/src/core/services/keygen/key_gen.dart';
import 'package:rad/src/core/services/router/router.dart';
import 'package:rad/src/core/services/services.dart';
import 'package:rad/src/core/services/walker/walker.dart';
import 'package:rad/src/core/services/scheduler/scheduler.dart';

/// Services Registry.
///
class ServicesRegistry {
  ServicesRegistry._();
  static ServicesRegistry? _instance;
  static ServicesRegistry get instance => _instance ??= ServicesRegistry._();

  final _services = <String, Services>{};

  void registerServices(BuildContext context, Services services) {
    if (_services.containsKey(context.appTargetId)) {
      throw "Services are already registered with the context.";
    }

    _services[context.appTargetId] = services;
  }

  void unRegisterServices(BuildContext context) {
    _services.remove(context.appTargetId);
  }

  Services getServices(BuildContext context) {
    var services = _services[context.appTargetId];

    if (null == services) {
      throw "Services are not registered yet.";
    }

    return services;
  }

  // helpers

  Debug getDebug(BuildContext context) => getServices(context).debug;
  KeyGen getKeyGen(BuildContext context) => getServices(context).keyGen;
  Router getRouter(BuildContext context) => getServices(context).router;
  Walker getWalker(BuildContext context) => getServices(context).walker;

  Scheduler getScheduler(BuildContext context) {
    return getServices(context).scheduler;
  }
}
