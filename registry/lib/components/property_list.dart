// Copyright 2020 Google LLC. All Rights Reserved.
//
// Licensed under the Apache License, Property 2.0 (the "License");
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
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_pagewise/flutter_pagewise.dart';
import 'package:registry/generated/google/cloud/apigee/registry/v1alpha1/registry_models.pb.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/custom_search_box.dart';
import '../components/filter.dart';
import '../components/property_add.dart';
import '../components/property_delete.dart';
import '../models/property.dart';
import '../models/string.dart';
import '../models/selection.dart';
import '../service/service.dart';

typedef ObservableStringFn = ObservableString Function(BuildContext context);

typedef PropertySelectionHandler = Function(
    BuildContext context, Property property);

// PropertyListCard is a card that displays a list of properties.
class PropertyListCard extends StatefulWidget {
  final ObservableStringFn getObservableResourceName;
  PropertyListCard(this.getObservableResourceName);

  @override
  _PropertyListCardState createState() => _PropertyListCardState();
}

class _PropertyListCardState extends State<PropertyListCard> {
  ObservableString observableSubjectName;
  String subjectName;
  PropertyService propertyService;
  PagewiseLoadController<Property> pageLoadController;

  _PropertyListCardState() {
    propertyService = PropertyService();
    pageLoadController = PagewiseLoadController<Property>(
        pageSize: pageSize,
        pageFuture: (pageIndex) =>
            propertyService.getPropertiesPage(pageIndex));
  }

  void selectionListener() {
    pageLoadController?.reset();
    setState(() {
      subjectName = observableSubjectName.value;
      if (subjectName == null) {
        subjectName = "";
      }
    });
  }

  @override
  void didChangeDependencies() {
    observableSubjectName = widget.getObservableResourceName(context);
    observableSubjectName.addListener(selectionListener);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    observableSubjectName.removeListener(selectionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Function add = () {
      final selection = SelectionProvider.of(context);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return SelectionProvider(
              selection: selection,
              child: AlertDialog(
                content: AddPropertyForm(subjectName),
              ),
            );
          });
    };
    return ObservableStringProvider(
      observable: ObservableString(),
      child: Card(
        child: Column(
          children: [
            filterBar(context, PropertySearchBox(),
                type: "properties",
                add: add,
                refresh: () => pageLoadController.reset()),
            Expanded(
              child: PropertyListView(
                widget.getObservableResourceName,
                null,
                propertyService,
                pageLoadController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// PropertyListView is a scrollable ListView of properties.
class PropertyListView extends StatefulWidget {
  final ObservableStringFn getObservableResourceName;
  final PropertySelectionHandler selectionHandler;
  final PropertyService propertyService;
  final PagewiseLoadController<Property> pageLoadController;
  PropertyListView(
    this.getObservableResourceName,
    this.selectionHandler,
    this.propertyService,
    this.pageLoadController,
  );
  @override
  _PropertyListViewState createState() => _PropertyListViewState();
}

class _PropertyListViewState extends State<PropertyListView> {
  String parentName;
  int selectedIndex = -1;

  void filterListener() {
    setState(() {
      ObservableString filter = ObservableStringProvider.of(context);
      if (filter != null) {
        widget.propertyService.filter = filter.value;
        widget.pageLoadController.reset();
        selectedIndex = -1;
      }
    });
  }

  @override
  void didChangeDependencies() {
    ObservableStringProvider.of(context).addListener(filterListener);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    ObservableStringProvider.of(context).removeListener(filterListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.propertyService.context = context;
    String subjectName = widget.getObservableResourceName(context).value;
    if (widget.propertyService.parentName != subjectName) {
      widget.propertyService.parentName = subjectName;
      widget.pageLoadController.reset();
      selectedIndex = -1;
    }
    return Scrollbar(
      child: PagewiseListView<Property>(
        itemBuilder: this._itemBuilder,
        pageLoadController: widget.pageLoadController,
      ),
    );
  }

  Widget widgetForPropertyValue(Property property) {
    if (property.hasStringValue()) {
      final value = property.stringValue;
      return Linkify(
        onOpen: (link) async {
          if (await canLaunch(link.url)) {
            await launch(link.url);
          } else {
            throw 'Could not launch $link';
          }
        },
        text: value,
        textAlign: TextAlign.left,
        style: Theme.of(context).textTheme.bodyText1,
        linkStyle:
            Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.blue),
      );
    }
    if (property.hasMessageValue()) {
      return Text(
        property.messageValue.typeUrl,
        textAlign: TextAlign.left,
      );
    }
    return Text("");
  }

  Widget _itemBuilder(context, Property property, index) {
    String propertyInfoLink;
    switch (property.messageValue.typeUrl) {
      case "gnostic.metrics.Vocabulary":
        propertyInfoLink =
            "https://github.com/google/gnostic/blob/master/metrics/vocabulary.proto#L27";
        break;
      case "gnostic.metrics.Complexity":
        propertyInfoLink =
            "https://github.com/google/gnostic/blob/master/metrics/complexity.proto#L23";
        break;
    }
    bool canDelete = property.hasStringValue();
    return ListTile(
      title: Text(property.nameForDisplay()),
      subtitle: widgetForPropertyValue(property),
      selected: index == selectedIndex,
      dense: false,
      onTap: () async {
        setState(() {
          selectedIndex = index;
        });
        Selection selection = SelectionProvider.of(context);
        selection?.updatePropertyName(property.name);
        widget.selectionHandler?.call(context, property);
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (propertyInfoLink != null)
            IconButton(
                color: Colors.black,
                icon: Icon(Icons.info),
                tooltip: "info",
                onPressed: () async {
                  if (await canLaunch(propertyInfoLink)) {
                    await launch(propertyInfoLink);
                  } else {
                    throw 'Could not launch $propertyInfoLink';
                  }
                }),
          if (canDelete)
            IconButton(
              color: Colors.black,
              icon: Icon(Icons.delete),
              tooltip: "delete",
              onPressed: () {
                final selection = SelectionProvider.of(context);
                selection.updatePropertyName(property.name);
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return SelectionProvider(
                        selection: selection,
                        child: AlertDialog(
                          content: DeletePropertyForm(),
                        ),
                      );
                    });
              },
            ),
        ],
      ),
    );
  }
}

// PropertySearchBox provides a search box for properties.
class PropertySearchBox extends CustomSearchBox {
  PropertySearchBox()
      : super(
          "Filter Properties",
          "property_id.contains('TEXT')",
        );
}
