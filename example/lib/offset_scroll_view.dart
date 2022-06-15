import 'dart:math';

import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/material.dart';

class OffsetScrollViewWidget extends StatefulWidget {
  const OffsetScrollViewWidget();

  @override
  State<StatefulWidget> createState() {
    return _OffsetScrollViewWidgetState();
  }
}

const double HEADER_HEIGHT = 100.0;

class _OffsetScrollViewWidgetState extends State<OffsetScrollViewWidget> {
  late final AnchorScrollController _scrollController;
  TabController? _tabController;
  final int length = 100;

  @override
  void initState() {
    super.initState();

    _scrollController = AnchorScrollController(
      anchorOffset: HEADER_HEIGHT,
      onIndexChanged: (index, userScroll) {
        if (userScroll) {
          _tabController?.animateTo(index);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("OffsetScrollViewWidget"),
        ),
        body: Stack(
          children: [
            ListView.builder(
                controller: _scrollController,
                itemCount: length,
                itemBuilder: (context, index) => AnchorItemWrapper(
                      index: index,
                      controller: _scrollController,
                      child: Container(
                        height: 50.0 + Random().nextInt(50),
                        color:
                            Colors.primaries[index % Colors.primaries.length],
                        alignment: Alignment.center,
                        child: Text(index.toString(),
                            style: const TextStyle(
                                fontSize: 24, color: Colors.black)),
                      ),
                    )),
            Container(
              color: Colors.white,
              height: HEADER_HEIGHT,
              alignment: Alignment.centerLeft,
              child: Container(
                height: 30,
                child: DefaultTabController(
                  length: length,
                  child: Builder(builder: (context) {
                    _tabController = DefaultTabController.of(context);
                    return TabBar(
                        isScrollable: true,
                        tabs: List.generate(
                            length,
                            (index) => Container(
                                  width: 50,
                                  alignment: Alignment.center,
                                  child: Text(
                                    index.toString(),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                    ),
                                  ),
                                )),
                        labelPadding: EdgeInsets.symmetric(horizontal: 5),
                        indicatorSize: TabBarIndicatorSize.label,
                        indicator: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        onTap: (index) {
                          _scrollController.scrollToIndex(index: index);
                        });
                  }),
                ),
              ),
            ),
          ],
        ));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
