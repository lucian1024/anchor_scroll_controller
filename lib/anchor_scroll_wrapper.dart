import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'anchor_scroll_controller.dart';

/// The wrapper widget which helps to get the offset of the item
/// If the size of items are fixed, there is no need to wrap the widget to item
class AnchorItemWrapper extends StatefulWidget {
  AnchorItemWrapper({
    required this.index,
    required this.child,
    this.controller,
    this.scrollViewWrapper,
    Key? key,
  })  : assert(controller != null || scrollViewWrapper != null,
            "must has AnchorScrollController or AnchorScrollViewWrapper"),
        super(key: key ?? ValueKey(index));

  final AnchorScrollController? controller;
  final int index;
  final Widget child;
  final AnchorScrollViewWrapper? scrollViewWrapper;

  @override
  AnchorItemWrapperState createState() => AnchorItemWrapperState();
}

class AnchorItemWrapperState extends State<AnchorItemWrapper> {
  @override
  void initState() {
    super.initState();
    _addItem(widget.index);
  }

  @override
  void dispose() {
    _removeItem(widget.index);
    super.dispose();
  }

  @override
  void didUpdateWidget(AnchorItemWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index || oldWidget.key != widget.key) {
      _removeItem(oldWidget.index);
      _addItem(widget.index);
    }
  }

  void _addItem(int index) {
    if (widget.controller != null) {
      widget.controller!.addItem(index, this);
    } else if (widget.scrollViewWrapper != null) {
      widget.scrollViewWrapper!.addItem(index, this);
    }
  }

  void _removeItem(int index) {
    if (widget.controller != null) {
      widget.controller!.removeItem(index);
    } else if (widget.scrollViewWrapper != null) {
      widget.scrollViewWrapper!.removeItem(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// ignore: must_be_immutable
class AnchorScrollViewWrapper extends InheritedWidget
    with AnchorScrollControllerMixin {
  AnchorScrollViewWrapper({
    required this.controller,
    required Widget child,
    this.fixedItemSize,
    this.onIndexChanged,
    Key? key,
  }) : super(key: key, child: child);

  final ScrollController controller;

  final double? fixedItemSize;

  final ValueChanged<int>? onIndexChanged;

  static AnchorScrollViewWrapper? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AnchorScrollViewWrapper>();
  }

  @override
  bool updateShouldNotify(AnchorScrollViewWrapper oldWidget) =>
      controller != oldWidget.controller;

  @override
  InheritedElement createElement() {
    controller.addListener(() {
      notifyIndexChanged(controller);
    });
    return super.createElement();
  }

  Future<void> scrollToIndex(
      {required int index,
      double scrollSpeed = 2,
      Curve curve = Curves.linear}) async {
    scrollToIndexWithScrollController(
        controller: controller,
        index: index,
        scrollSpeed: scrollSpeed,
        curve: curve);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ScrollController>(
        'controller', controller,
        ifNull: 'no controller', showName: false));
  }
}
