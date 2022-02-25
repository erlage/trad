import '/src/core/structures/widget.dart';
import '/src/widgets/main/app_widget.dart';

class CastorApp extends AppWidget {
  CastorApp({
    required Widget child,
    required String targetId,
  }) : super(
          child: child,
          targetId: targetId,
          widgetType: (CastorApp).toString(),
        );
}
