import 'dart:html';

import 'package:rad/src/core/classes/router.dart';
import 'package:rad/src/core/types.dart';
import 'package:rad/src/core/classes/utils.dart';
import 'package:rad/src/core/constants.dart';
import 'package:rad/src/core/objects/widget_object.dart';
import 'package:rad/src/core/structures/widget.dart';
import 'package:rad/src/core/objects/update_object.dart';
import 'package:rad/src/core/structures/build_context.dart';

class Framework {
  static var _isInit = false;
  static var _debugMode = false;

  static final _registeredWidgetObjects = <String, WidgetObject>{};

  static init({
    required bool debugMode,
    required String routingPath,
  }) {
    if (_isInit) {
      throw "Framework aleady initialized.";
    }

    _debugMode = debugMode;

    Router.init(
      debugMode: debugMode,
      routingPath: routingPath,
    );

    _isInit = true;
  }

  static void addGlobalStyles(String styles, [String? logEntry]) {
    var styleSheet = document.createElement("style");

    styleSheet.innerText = styles;

    if (null != document.head) {
      document.head!.insertBefore(styleSheet, null);
    } else if (null != document.body) {
      document.head!.insertBefore(styleSheet, null);
    } else {
      throw "For Rad to work, your page must have either a head tag or a body."
          "Creating a body(or head) in your page will fix this problem.";
    }

    if (_debugMode) {
      if (null != logEntry) {
        print("Styles injected: $logEntry");
      }
    }
  }

  static WidgetObject? findAncestorOfType<WidgetType>(BuildContext context) {
    if (System.keyNotSet == context.key) {
      throw "Part of build context is not ready. This means that context is under construction.";
    }

    var domNode = document
        .getElementById(context.key)
        ?.closest("[data-wtype='$WidgetType']");

    if (null == domNode) {
      return null;
    }

    return _getWidgetObject(domNode.id);
  }

  static buildChildren({
    // widgets to build
    required List<Widget> widgets,
    required BuildContext parentContext,
    ElementCallback? elementCallback,
    //
    // -- flags --
    //
    flagCleanParentContents = true,
    //
  }) {
    if (!_isInit) {
      throw "Framework not initialized. If you're building your own AppWidget implementation, make sure to call Framework.init()";
    }

    for (var widget in widgets) {
      // generate key if not set
      var widgetKey = System.keyNotSet == widget.initialKey
          ? Utils.generateWidgetKey()
          : widget.initialKey;

      var buildContext = BuildContext(
        key: widgetKey,
        parent: parentContext,
        widgetType: widget.type,
        widgetDomTag: widget.tag,
        widgetClassName: widget.runtimeType.toString(),
      );
      widget.onContextCreate(buildContext);

      var renderObject = widget.createRenderObject(buildContext);
      widget.onRenderObjectCreate(renderObject);

      if (_debugMode) {
        print("Build widget: ${widget.type} #${buildContext.key}");
      }

      var widgetObject = WidgetObject(
        widget: widget,
        renderObject: renderObject,
      );

      widgetObject.createElement();

      if (null != elementCallback) {
        elementCallback(widgetObject.element);
      }

      _registerWidgetObject(widgetObject);

      // dispose inner contents if flag is on

      if (flagCleanParentContents) {
        //
        // if it's not a root widget
        if (System.typeBigBang != widgetObject.context.parent.widgetType) {
          _disposeWidget(
            preserveTarget: true,
            widgetObject: _getWidgetObject(widgetObject.context.parent.key),
          );

          // else it's a root widget, simple clean the contents
        } else {
          var element = document.getElementById(
            renderObject.context.parent.key,
          );

          if (null == element) {
            throw "Unable to find target to mount app. Make sure your DOM has element with id #${renderObject.context.parent}";
          }

          element.innerHtml = "";
        }
      }

      widgetObject.renderObject.beforeMount();

      widgetObject.mount();

      widgetObject.renderObject.afterMount();

      widgetObject.build();

      // unset flag
      // because remaining childs must not remove newly added childs
      flagCleanParentContents = false;
    }
  }

  static updateChildren({
    // widgets to build
    required List<Widget> widgets,
    required BuildContext parentContext,
    ElementCallback? elementCallback,
    //
    // -- flags for special nodes --
    //
    flagHideObsoluteChildren = false,
    flagDisposeObsoluteChildren = true,
    //
    // -- flags for widgets that aren't found in tree --
    //
    flagAddIfNotFound = false,
    //
    // -- hard flags, can cause subtree rebuilds --
    //
    flagTolerateMissingChildren = false,
    flagTolerateChildrenCountMisMatch = false,
    //
  }) {
    if (!_isInit) {
      throw "Framework not initialized. If you're building your own AppWidget implementation, make sure to call Framework.init()";
    }

    void dispatchCompleteRebuild() {
      buildChildren(
        widgets: widgets,
        parentContext: parentContext,
        elementCallback: elementCallback,
      );
    }

    /*
    |--------------------------------------------------------------------------
    | get parent
    |--------------------------------------------------------------------------
    */

    var parentElement = document.getElementById(parentContext.key);

    if (null == parentElement) {
      return dispatchCompleteRebuild();
    }

    /*
    |--------------------------------------------------------------------------
    | ensure children count match if flag is on
    |--------------------------------------------------------------------------
    */

    if (!flagTolerateChildrenCountMisMatch) {
      if (parentElement.children.length != widgets.length) {
        return dispatchCompleteRebuild();
      }
    }

    /*
    |--------------------------------------------------------------------------
    | list of updates  {Node index}: existing {WidgetObject}
    |--------------------------------------------------------------------------
    */

    var updates = <String, UpdateObject>{};

    /*
    |--------------------------------------------------------------------------
    | prepare updates
    |
    | nested loops? can be improved. yes.
    | 
    | given the fact how this works, we can keep track of previously matched
    | nodes and search just in the remaining nodes... 
    | 
    | updates.containsKey(childElement.id) is true most of the time and cases
    | when its not, we usually hit the child we looking for.
    |
    | for now, we don't have any problem here, plus most widgets have only one
    | child. 
    | but if required, this loop can be improved.
    |--------------------------------------------------------------------------
    */

    widgetLoop:
    for (var widget in widgets) {
      for (var childElement in parentElement.children) {
        // if not already selected
        if (!updates.containsKey(childElement.id)) {
          //
          // if there's child that has same type
          if (childElement.dataset.isNotEmpty &&
              widget.runtimeType.toString() ==
                  childElement.dataset[System.attrClass]) {
            //
            // add to updates list
            updates[childElement.id] = UpdateObject(widget, childElement.id);

            continue widgetLoop;
          }
        }
      }

      // child is missing

      if (!flagTolerateChildrenCountMisMatch) {
        return dispatchCompleteRebuild();
      }

      // if flag is on for missing childs

      if (flagAddIfNotFound) {
        updates["_${Utils.generateMonotonicId()}"] = UpdateObject(widget, null);
      }
    }

    /*
    |--------------------------------------------------------------------------
    | publish widget updates
    |--------------------------------------------------------------------------
    */

    updates.forEach((elementId, updateObject) {
      if (null != updateObject.existingElementId) {
        var existingWidgetObject = _getWidgetObject(elementId);

        // if found
        if (null != existingWidgetObject) {
          // get updated render object
          var renderObject = updateObject.widget.createRenderObject(
            existingWidgetObject.context,
          );

          //
          // if there's element callback
          //
          if (null != elementCallback) {
            elementCallback(existingWidgetObject.element);
          }
          //
          // publish update
          return existingWidgetObject.renderObject.update(
            existingWidgetObject,
            renderObject,
          );
        } else {
          if (!flagTolerateChildrenCountMisMatch) {
            return dispatchCompleteRebuild();
          }
        }
      } else {
        if (flagAddIfNotFound) {
          buildChildren(
            widgets: [updateObject.widget],
            parentContext: parentContext,
            elementCallback: elementCallback,
          );
        }
      }
    });

    /*
    |--------------------------------------------------------------------------
    | deal with obsolute nodes
    |--------------------------------------------------------------------------
    */

    for (var childElement in parentElement.children) {
      if (!updates.containsKey(childElement.id)) {
        if (flagDisposeObsoluteChildren) {
          _disposeWidget(
            widgetObject: _getWidgetObject(childElement.id),
            preserveTarget: false,
          );
        } else if (flagHideObsoluteChildren) {
          _hideElement(childElement);
        }
      }
    }
  }

  // internals

  static _disposeWidget({
    WidgetObject? widgetObject,
    bool preserveTarget = false,
  }) {
    if (null == widgetObject) {
      return;
    }

    if (widgetObject.element.hasChildNodes()) {
      for (var childElement in widgetObject.element.children) {
        _disposeWidget(widgetObject: _getWidgetObject(childElement.id));
      }
    }

    if (preserveTarget) return;

    // if a body tag

    if (widgetObject.element == document.body) {
      return;
    }

    // if is not a framework's tag

    if (null == widgetObject.element.dataset[System.attrType]) {
      return;
    }

    // lifecycle hook, about to remove dom node

    widgetObject.renderObject.beforeUnMount();

    // unregister both render and dom node

    _unRegisterWidgetObject(widgetObject);

    // remove dom node

    widgetObject.element.remove();
  }

  static _hideElement(Element element) {
    element.classes.add('rad-hidden');
  }

  static WidgetObject? _getWidgetObject(String widgetKey) {
    return _registeredWidgetObjects[widgetKey];
  }

  static void _registerWidgetObject(WidgetObject widgetObject) {
    _registeredWidgetObjects[widgetObject.context.key] = widgetObject;
  }

  static void _unRegisterWidgetObject(WidgetObject widgetObject) {
    _registeredWidgetObjects.remove(widgetObject.context.key);
  }
}
