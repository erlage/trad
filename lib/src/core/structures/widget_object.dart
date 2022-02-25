import 'dart:html';

import '/src/core/structures/build_context.dart';
import '/src/core/structures/render_object.dart';

class WidgetObject {
  late BuildContext context;

  RenderObject renderObject;
  HtmlElement htmlElement;

  WidgetObject({
    required this.renderObject,
    required this.htmlElement,
  }) {
    context = renderObject.context;
  }

  mount() {
    // we can't use node.parent here cus root widget's parent can be null

    var parentElement = document.getElementById(renderObject.context.parentId);

    if (null == parentElement) {
      throw "Unable to find parent widget of element #${context.id}. Either disposed or something went wrong;";
    }

    parentElement.append(htmlElement);
  }
}
