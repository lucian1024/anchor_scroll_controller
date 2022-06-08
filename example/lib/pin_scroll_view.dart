
import 'dart:math';

import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

class PinScrollViewWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _PinScrollViewWidgetState();
  }
}

class _PinScrollViewWidgetState extends State<PinScrollViewWidget> {
  late final AnchorScrollController _scrollController;
  TabController? _tabController;
  final int length = 25;

  @override
  void initState() {
    super.initState();
    _scrollController = AnchorScrollController(
      onIndexChanged: (index, userScroll) {
        if (userScroll) {
          _tabController?.animateTo(index);
        }
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("PinScrollView"),
        ),
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: List.generate(length, (index) {
                  return SliverStickyHeader(
                    header: AnchorItemWrapper(
                      controller: _scrollController,
                      index: index,
                      child: Builder(
                        builder: (context) {
                          return Container(
                            height: 50,
                            padding: EdgeInsets.only(left: 5),
                            color: Colors.black,
                            alignment: Alignment.centerLeft,
                            child: Text("#$index",
                                style: const TextStyle(fontSize: 24, color: Colors.white)),
                         );
                        }
                      ),
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          return Container(
                            height: 50.0 + Random().nextInt(50),
                            color: Colors.primaries[i % Colors.primaries.length],
                            alignment: Alignment.center,
                            child: Text(i.toString(),
                                style: const TextStyle(
                                    fontSize: 24, color: Colors.black)),
                          );
                        },
                        childCount: Random().nextInt(5) + 1,
                      ),
                    ),
                  );
                }),
              )
            ),
            Container(
              color: Colors.white,
              height: 40,
              alignment: Alignment.centerLeft,
              child: Container(
                height: 30,
                child: DefaultTabController(
                  length: length,
                  child: Builder(
                    builder: (context) {
                      _tabController = DefaultTabController.of(context);
                      return TabBar(
                          isScrollable: true,
                          tabs: List.generate(length, (index) => Container(
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
                            _scrollController.scrollToIndex(index: index,);
                          }
                      );
                    },
                  ),
                ),
              ),
            )
          ],
        )
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}