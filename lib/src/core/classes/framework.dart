import 'dart:html';

import '/src/core/enums.dart';
import '/src/core/constants.dart';
import '/src/core/classes/utils.dart';
import '/src/core/structures/build_context.dart';
import '/src/core/structures/render_object.dart';
import '/src/core/structures/widget_object.dart';

class Framework {
  static var _isInit = false;
  static var _monotonicId = 0;

  static final _registeredWidgetObjects = <String, WidgetObject>{};

  static init() {
    if (_isInit) {
      throw "Framework aleady initialized.";
    }

    _isInit = true;
  }

  static generateId() {
    _monotonicId++;
    return _monotonicId.toString() + "_" + Utils.random();
  }

  static WidgetObject? getWidgetObject(String widgetId) {
    return _registeredWidgetObjects[widgetId];
  }

  static WidgetObject? findAncestorOfType<WidgetType>(BuildContext context) {
    if (Constants.inBuildPhase == context.key) {
      throw "Part of context are not ready for usage. This means that context is under construction and cannot be used.  Contexts contruction completes after render object for a widget is built.";
    }

    var domNode = document.getElementById(context.key)?.closest("[data-wtype='" + WidgetType.toString() + "'");

    if (null == domNode) {
      return null;
    }

    var widgetObject = getWidgetObject(domNode.id);

    if (null == widgetObject) {
      throw "Trying to look up a disposed widget";
    }

    return widgetObject;
  }

  static buildWidget({
    append = false,
    required RenderObject renderObject,
  }) {
    if (!_isInit) {
      throw "Framework not initialized. If you're building your own AppWidget implementation, make sure to call Framework.init()";
    }

    if (_tryRebuildingWidgetHavingId(renderObject.context.key)) {
      return;
    }

    var htmlElement = document.createElement(mapDomTag(tag: renderObject.context.widgetDomTag)) as HtmlElement;

    htmlElement.id = renderObject.context.key;
    htmlElement.dataset["wtype"] = renderObject.context.widgetType;

    var widgetObject = WidgetObject(
      renderObject: renderObject,
      htmlElement: htmlElement,
    );

    _registerWidgetObject(widgetObject);

    // dispose inner contents if not appending

    if (!append) {
      // if root div

      if (Constants.bigBang == renderObject.context.parentKey) {
        var rootElement = document.getElementById(renderObject.context.parentKey);

        if (null == rootElement) {
          throw "Unable to find target to mount app. Make sure your DOM has element with id #${renderObject.context.parentKey}";
        }

        rootElement.innerHtml = "";
      } else {
        // else it's in widget tree

        disposeWidget(getWidgetObject(renderObject.context.parentKey), preserveTarget: true);
      }
    }

    // lifecycle hook

    widgetObject.renderObject.beforeMount();

    // mount

    widgetObject.mount();

    // lifecycle hook

    widgetObject.renderObject.afterMount();

    // lifecycle hook, paint childs contents

    widgetObject.renderObject.render(widgetObject);
  }

  static _tryRebuildingWidgetHavingId(String widgetId) {
    var widgetObject = getWidgetObject(widgetId);

    if (null == widgetObject) {
      // widget doesn't exists

      return false;
    }

    /**
     * we'are directly disposing all child nodes and then rebuilding
     * whole subtree after this widget. this is the easiest way to
     * ensure that all required childs are updated.
     *
     * more performant way would be to:
     *
     * - decouple interface and data part of a widget by creating
     *   a implicit state element(object) for each widet. this way
     *   rebuild process will be:
     *
     *    1. pass parent's element to immediate childs only
     *    2. childs will merge parent's element with their elements
     *    3. child then compare if they have to rebuild themselves
     *    4. if yes: child pass element to its childs and so on
     *       if no: child will ignore and won't cascade rebuilds
     *
     * for now goal is to make this thing work. moreover, browsers are
     * not so bad at building webpages. after all that's what they do
     */

    disposeWidget(widgetObject, preserveTarget: true);

    widgetObject.renderObject.render(widgetObject);

    return true;
  }

  static disposeWidget(WidgetObject? widgetObject, {bool preserveTarget = false}) {
    if (null == widgetObject) {
      return;
    }

    if (widgetObject.htmlElement.hasChildNodes()) {
      for (var childHtmlElement in widgetObject.htmlElement.childNodes) {
        childHtmlElement as HtmlElement;

        disposeWidget(getWidgetObject(childHtmlElement.id));
      }
    }

    if (preserveTarget) return;

    if (widgetObject.htmlElement == document.body || null == widgetObject.htmlElement.dataset["wtype"]) {
      return;
    }

    // lifecycle hook, about to remove dom node

    widgetObject.renderObject.beforeUnMount();

    // unregister both render and dom node

    _unRegisterWidgetObject(widgetObject);

    // remove dom node

    widgetObject.htmlElement.remove();
  }

  static void _registerWidgetObject(WidgetObject widgetObject) {
    _registeredWidgetObjects[widgetObject.context.key] = widgetObject;
  }

  static void _unRegisterWidgetObject(WidgetObject widgetObject) {
    _registeredWidgetObjects.remove(widgetObject.context.key);
  }
}
