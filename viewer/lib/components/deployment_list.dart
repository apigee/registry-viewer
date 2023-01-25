// Copyright 2020 Google LLC. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:flutter_pagewise/flutter_pagewise.dart';
import 'package:registry/registry.dart';
import '../components/custom_search_box.dart';
import '../components/filter.dart';
import '../models/selection.dart';
import '../models/string.dart';
import '../models/deployment.dart';
import '../service/service.dart';

typedef DeploymentSelectionHandler = Function(
    BuildContext context, ApiDeployment deployment);

// DeploymentListCard is a card that displays a list of deployments.
class DeploymentListCard extends StatefulWidget {
  @override
  _DeploymentListCardState createState() => _DeploymentListCardState();
}

class _DeploymentListCardState extends State<DeploymentListCard> {
  DeploymentService? deploymentService;
  PagewiseLoadController<ApiDeployment>? pageLoadController;

  _DeploymentListCardState() {
    deploymentService = DeploymentService();
    pageLoadController = PagewiseLoadController<ApiDeployment>(
        pageSize: pageSize,
        pageFuture: ((pageIndex) => deploymentService!
            .getDeploymentsPage(pageIndex!)
            .then((value) => value!)));
  }

  @override
  Widget build(BuildContext context) {
    return ObservableStringProvider(
      observable: ObservableString(),
      child: Card(
        child: Column(
          children: [
            filterBar(context, DeploymentSearchBox(),
                refresh: () => pageLoadController!.reset()),
            Expanded(
              child: DeploymentListView(
                null,
                deploymentService,
                pageLoadController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// DeploymentListView is a scrollable ListView of deployments.
class DeploymentListView extends StatefulWidget {
  final DeploymentSelectionHandler? selectionHandler;
  final DeploymentService? deploymentService;
  final PagewiseLoadController<ApiDeployment>? pageLoadController;

  DeploymentListView(
    this.selectionHandler,
    this.deploymentService,
    this.pageLoadController,
  );

  @override
  _DeploymentListViewState createState() => _DeploymentListViewState();
}

class _DeploymentListViewState extends State<DeploymentListView> {
  String? apiName;
  int selectedIndex = -1;
  Selection? selection;
  ObservableString? filter;
  final ScrollController scrollController = ScrollController();

  void selectionListener() {
    setState(() {});
  }

  void filterListener() {
    setState(() {
      ObservableString? filter = ObservableStringProvider.of(context);
      if (filter != null) {
        widget.deploymentService!.filter = filter.value;
        widget.pageLoadController!.reset();
        selectedIndex = -1;
      }
      SelectionProvider.of(context)?.updateDeploymentName("");
    });
  }

  @override
  void didChangeDependencies() {
    selection = SelectionProvider.of(context);
    selection!.apiName.addListener(selectionListener);
    filter = ObservableStringProvider.of(context);
    filter!.addListener(filterListener);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    selection!.apiName.removeListener(selectionListener);
    filter!.removeListener(filterListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.deploymentService!.context = context;
    if (widget.deploymentService!.apiName !=
        SelectionProvider.of(context)!.apiName.value) {
      widget.deploymentService!.apiName =
          SelectionProvider.of(context)!.apiName.value;
      widget.pageLoadController!.reset();
      selectedIndex = -1;
    }
    return Scrollbar(
      controller: scrollController,
      child: PagewiseListView<ApiDeployment>(
        itemBuilder: this._itemBuilder,
        pageLoadController: widget.pageLoadController,
        controller: scrollController,
      ),
    );
  }

  Widget _itemBuilder(context, ApiDeployment deployment, index) {
    if (index == 0) {
      Future.delayed(const Duration(), () {
        Selection? selection = SelectionProvider.of(context);
        if ((selection != null) && (selection.deploymentName.value == "")) {
          selection.updateDeploymentName(deployment.name);
          setState(() {
            selectedIndex = 0;
          });
        }
      });
    }

    return ListTile(
      title: Text(deployment.nameForDisplay()),
      selected: index == selectedIndex,
      dense: false,
      onTap: () async {
        setState(() {
          selectedIndex = index;
        });
        Selection? selection = SelectionProvider.of(context);
        selection?.updateDeploymentName(deployment.name);
        widget.selectionHandler?.call(context, deployment);
      },
      trailing: IconButton(
        color: Colors.black,
        icon: Icon(Icons.open_in_new),
        tooltip: "open",
        onPressed: () {
          Navigator.pushNamed(
            context,
            deployment.routeNameForDetail(),
          );
        },
      ),
    );
  }
}

// DeploymentSearchBox provides a search box for deployments.
class DeploymentSearchBox extends CustomSearchBox {
  DeploymentSearchBox()
      : super("Filter Deployments", "deployment_id.contains('TEXT')");
}
