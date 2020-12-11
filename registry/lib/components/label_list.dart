// Copyright 2020 Google LLC. All Rights Reserved.
//
// Licensed under the Apache License, Label 2.0 (the "License");
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
import 'package:registry/generated/google/cloud/apigee/registry/v1alpha1/registry_models.pb.dart';
import '../service/service.dart';
import '../models/label.dart';
import '../models/string.dart';
import '../models/selection.dart';
import 'custom_search_box.dart';
import 'filter.dart';
import 'label_add.dart';
import 'label_delete.dart';

const int pageSize = 50;

typedef ObservableStringFn = ObservableString Function(BuildContext context);

typedef LabelSelectionHandler = Function(BuildContext context, Label label);

PagewiseLoadController<Label> pageLoadController; // hack

// LabelListCard is a card that displays a list of labels.
class LabelListCard extends StatefulWidget {
  final ObservableStringFn getObservableResourceName;
  LabelListCard(this.getObservableResourceName);

  @override
  _LabelListCardState createState() => _LabelListCardState();
}

class _LabelListCardState extends State<LabelListCard> {
  ObservableString subjectNameManager;
  String subjectName;

  String projectName() {
    return subjectName.split("/").sublist(0, 2).join("/");
  }

  void listener() {
    pageLoadController?.reset();
    setState(() {
      subjectName = subjectNameManager.value;
      if (subjectName == null) {
        subjectName = "";
      }
    });
  }

  @override
  void didChangeDependencies() {
    subjectNameManager = widget.getObservableResourceName(context);
    subjectNameManager.addListener(listener);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    print("rebuilding");
    Function add = () {
      final selection = SelectionProvider.of(context);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SelectionProvider(
              selection: selection,
              child: AlertDialog(
                content: AddLabelForm(subjectName),
              ),
            );
          });
    };

    return ObservableStringProvider(
      observable: ObservableString(),
      child: Card(
        child: Column(
          children: [
            filterBar(context, LabelSearchBox(),
                type: "label",
                add: add,
                refresh: () => pageLoadController.reset()),
            Expanded(
              child: LabelListView(widget.getObservableResourceName, null),
            ),
          ],
        ),
      ),
    );
  }
}

// LabelListView is a scrollable ListView of labels.
class LabelListView extends StatefulWidget {
  final ObservableStringFn getObservableResourceName;
  final LabelSelectionHandler selectionHandler;
  LabelListView(this.getObservableResourceName, this.selectionHandler);
  @override
  _LabelListViewState createState() => _LabelListViewState();
}

class _LabelListViewState extends State<LabelListView> {
  String parentName;
  //PagewiseLoadController<Label> pageLoadController;
  LabelService labelService;
  int selectedIndex = -1;

  _LabelListViewState() {
    labelService = LabelService();
    pageLoadController = PagewiseLoadController<Label>(
        pageSize: pageSize,
        pageFuture: (pageIndex) => labelService.getLabelsPage(pageIndex));
  }

  @override
  void didChangeDependencies() {
    ObservableStringProvider.of(context).addListener(() => setState(() {
          ObservableString filter = ObservableStringProvider.of(context);
          if (filter != null) {
            labelService.filter = filter.value;
            pageLoadController.reset();
            selectedIndex = -1;
          }
        }));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    labelService.context = context;
    String subjectName = widget.getObservableResourceName(context).value;
    if (labelService.parentName != subjectName) {
      labelService.parentName = subjectName;
      pageLoadController.reset();
      selectedIndex = -1;
    }
    return Scrollbar(
      child: PagewiseListView<Label>(
        itemBuilder: this._itemBuilder,
        pageLoadController: pageLoadController,
      ),
    );
  }

  Widget _itemBuilder(context, Label label, index) {
    return ListTile(
      title: Text(label.nameForDisplay()),
      selected: index == selectedIndex,
      trailing: IconButton(
        color: Colors.black,
        icon: Icon(Icons.delete),
        tooltip: "delete",
        onPressed: () {
          final selection = SelectionProvider.of(context);
          selection.updateLabelName(label.name);
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return SelectionProvider(
                  selection: selection,
                  child: AlertDialog(
                    content: DeleteLabelForm(),
                  ),
                );
              });
        },
      ),
      dense: false,
      onTap: () async {
        setState(() {
          selectedIndex = index;
        });
      },
    );
  }
}

// LabelSearchBox provides a search box for labels.
class LabelSearchBox extends CustomSearchBox {
  LabelSearchBox() : super("Filter Labels", "label_id.contains('TEXT')");
}
