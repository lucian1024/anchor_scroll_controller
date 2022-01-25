import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'anchor_scroll_controller.dart';

/// The wrapper widget which helps to get the offset of the item
/// If the size of items are fixed, there is no need to wrap the widget to item
class AnchorItemWrapper extends StatefulWidget {
  AnchorItemWrapper({
    required this.controller,
    required this.index,
    required this.child,
    Key? key,
  }) : super(key: key ?? ValueKey(index));

  final AnchorScrollController controller;
  final int index;
  final Widget child;

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
    if (oldWidget.index != widget.index ||
        oldWidget.key != widget.key) {
      _removeItem(oldWidget.index);
      _addItem(widget.index);
    }
  }

  void _addItem(int index) {
    widget.controller.addItem(index, this);
  }

  void _removeItem(int index) {
    widget.controller.removeItem(index);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}