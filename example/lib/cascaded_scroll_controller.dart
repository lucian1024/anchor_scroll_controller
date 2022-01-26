
import 'dart:math';

import 'package:anchor_scroll_controller/anchor_scroll_wrapper.dart';
import 'package:flutter/material.dart';

class CascadesScrollControllerWidget extends StatefulWidget {
  const CascadesScrollControllerWidget(this.scrollController);
  final ScrollController scrollController;

  @override
  State<StatefulWidget> createState() {
    return _CascadesScrollControllerWidgetState();
  }
}

class _CascadesScrollControllerWidgetState extends State<CascadesScrollControllerWidget> {
  late final AnchorScrollViewWrapper _scrollViewWrapper;
  TabController? _tabController;
  final int length = 100;

  @override
  void initState() {
    super.initState();
  }

  void _onIndexChanged(index) {
  _tabController?.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("GeneralScrollView"),
        ),
        body: Column(
          children: [
            Expanded(
              child: AnchorScrollViewWrapper(
                controller: widget.scrollController,
                onIndexChanged: _onIndexChanged,
                child: Builder(
                  builder:(context) {
                    _scrollViewWrapper = AnchorScrollViewWrapper.of(context)!;
                    return ListView.builder(
                      itemCount: length,
                      itemBuilder: (context, index) => AnchorItemWrapper(
                        index: index,
                        scrollViewWrapper: _scrollViewWrapper,
                        child: Container(
                          height: 50.0 + Random().nextInt(50),
                          color: Colors.primaries[index % Colors.primaries.length],
                          alignment: Alignment.center,
                          child: Text(index.toString(),
                              style: const TextStyle(fontSize: 24, color: Colors.black)),
                        ),
                      )
                  );}
                ),
              ),
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
                          tabs: List.generate(length, (index) =>
                              Container(
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
                            _scrollViewWrapper.scrollToIndex(index: index);
                          }
                      );
                    }
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