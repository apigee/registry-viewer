import 'package:flutter/material.dart';

typedef Widget ItemBuilder<T>(BuildContext context, T entry, int index);
typedef Future<List<T>> PageFuture<T>(int? pageIndex);
typedef Widget ErrorBuilder(BuildContext context, Object? error);
typedef Widget NoItemsFoundBuilder(BuildContext context);
typedef Widget RetryBuilder(BuildContext context, RetryCallback retryCallback);
typedef void RetryCallback();
typedef Widget PagewiseBuilder<T>(PagewiseState<T> state);

/// An abstract base class for widgets that fetch their content one page at a
/// time.
///
/// The widget fetches the page when we scroll down to it, and then keeps it in
/// memory
///
/// You can build your own Pagewise widgets by extending this class and
/// returning your builder in the [builder] function which provides you with the
/// Pagewise state. Look [PagewiseListView] and [PagewiseGridView] for examples.
///
/// See also:
///
///  * [PagewiseGridView], a [Pagewise] implementation of [GridView](https://docs.flutter.io/flutter/widgets/GridView-class.html)
///  * [PagewiseListView], a [Pagewise] implementation of [ListView](https://docs.flutter.io/flutter/widgets/ListView-class.html)
abstract class Pagewise<T> extends StatefulWidget {
  /// The number  of entries per page
  final int? pageSize;

  /// Called whenever a new page (or batch) is to be fetched
  ///
  /// It is provided with the page index, and expected to return a [Future](https://api.dartlang.org/stable/1.24.3/dart-async/Future-class.html) that
  /// resolves to a list of entries. Please make sure to return only [pageSize]
  /// or less entries (in the case of the last page) for each page.
  final PageFuture<T>? pageFuture;

  /// Called with an error object if an error occurs when loading the page
  ///
  /// It is expected to return a widget to display in place of the page that
  /// failed to load. For example:
  /// ```dart
  /// (BuildContext context, Object error) {
  ///   return Text('Failed to load page: $error');
  /// }
  /// ```
  /// If not specified, a [Text] containing the error will be displayed
  final ErrorBuilder? errorBuilder;

  /// Called when no items are found
  ///
  /// It is expected to return a widget that gives the user the idea that no
  /// items exist in the list
  /// For example:
  ///  ```dart
  ///  (BuildContext context) {
  ///    return Text('No Items Found!');
  ///  }
  ///  ```
  final NoItemsFoundBuilder? noItemsFoundBuilder;

  /// Called to build each entry in the view.
  ///
  /// It is called for each of the entries fetched by [pageFuture] and provided
  /// with the [BuildContext](https://docs.flutter.io/flutter/widgets/BuildContext-class.html) and the entry. It is expected to return the widget
  /// that we want to display for each entry
  ///
  /// For example, the [pageFuture] might return a list that looks like:
  /// ```dart
  ///[
  ///  {
  ///    'name': 'product1',
  ///    'price': 10
  ///  },
  ///  {
  ///    'name': 'product2',
  ///    'price': 15
  ///  },
  ///]
  /// ```
  /// Then itemBuilder will be called twice, once for each entry. We can for
  /// example do:
  /// ```dart
  /// (BuildContext context, dynamic entry) {
  ///   return Text(entry['name'] + ' - ' + entry['price']);
  /// }
  /// ```
  final ItemBuilder<T> itemBuilder;

  /// The actual builder that builds the Pagewise widget. It is called and
  /// provided the PagewiseState. This function is important only for classes
  /// extending Pagewise. See [PagewiseListView] and [PagewiseGridView] for
  /// examples.
  final PagewiseBuilder<T> builder;

  /// The controller that controls the loading of pages.
  ///
  /// You don't have to provide this parameter unless you want to control or
  /// listen to the data that Pagewise fetches. Review the documentation of
  /// [PagewiseLoadController] for more details
  final PagewiseLoadController<T>? pageLoadController;

  /// Creates a pagewise widget.
  ///
  /// This is an abstract class, this constructor should only be called from
  /// constructors of widgets that extend this class
  const Pagewise(
      {this.pageSize,
      this.pageFuture,
      Key? key,
      this.pageLoadController,
      this.noItemsFoundBuilder,
      required this.itemBuilder,
      this.errorBuilder,
      required this.builder})
      : assert((pageLoadController == null &&
                pageSize != null &&
                pageFuture != null) ||
            (pageLoadController != null &&
                pageSize == null &&
                pageFuture == null)),
        super(key: key);

  @override
  PagewiseState<T> createState() => PagewiseState<T>();
}

class PagewiseState<T> extends State<Pagewise<T?>> {
  PagewiseLoadController<T?>? _controller;

  PagewiseLoadController<T?>? get _effectiveController =>
      widget.pageLoadController ?? this._controller;

  late VoidCallback _controllerListener;

  @override
  void initState() {
    super.initState();

    if (widget.pageLoadController == null) {
      this._controller = PagewiseLoadController<T?>(
          pageFuture: widget.pageFuture, pageSize: widget.pageSize);
    }

    this._effectiveController!.init();

    this._controllerListener = () {
      setState(() {});
    };

    this._effectiveController!.addListener(this._controllerListener);
  }

  @override
  void dispose() {
    super.dispose();
    this._effectiveController!.removeListener(this._controllerListener);
  }

  @override
  void didUpdateWidget(Pagewise oldWidget) {
    super.didUpdateWidget(oldWidget as Pagewise<T>);
    if (widget.pageLoadController == null &&
        oldWidget.pageLoadController != null) {
      oldWidget.pageLoadController!.removeListener(this._controllerListener);
      this._controller = PagewiseLoadController<T>(
          pageFuture: oldWidget.pageLoadController!.pageFuture,
          pageSize: oldWidget.pageLoadController!.pageSize);
      this._effectiveController!.addListener(this._controllerListener);
      this._effectiveController!.init();
    } else if (widget.pageLoadController != null &&
        oldWidget.pageLoadController == null) {
      this._controller!.removeListener(this._controllerListener);
      this._controller = null;
      this._effectiveController!.addListener(this._controllerListener);
      this._effectiveController!.init();
    } else if (widget.pageLoadController != null &&
        (widget.pageLoadController != oldWidget.pageLoadController)) {
      oldWidget.pageLoadController!.removeListener(this._controllerListener);
      this._effectiveController!.addListener(this._controllerListener);
      this._effectiveController!.init();
    }
  }

  int get _itemCount => this._effectiveController!.loadedItems!.length + 1;

  @override
  Widget build(BuildContext context) {
    return widget.builder(this);
  }

  Widget? _itemBuilder(BuildContext context, int index) {
    // The total number of widgets, is the number of loaded items
    // plus 1 for the loader
    final total = this._effectiveController!.loadedItems!.length + 1;

    if (index >= total) {
      return null;
    }
    if (index == total - 1) {
      if (this._effectiveController!.noItemsFound) {
        return this._getNoItemsFoundWidget();
      }

      if (this._effectiveController!.error != null) {
        return this._getErrorWidget(this._effectiveController!.error);
      }

      if (this._effectiveController!.hasMoreItems!) {
        this._effectiveController!.fetchNewPage();
        return this._getLoadingWidget();
      } else {
        return Container();
      }
    } else {
      if (index >= this._effectiveController!.loadedItems!.length) {
        // this means that the function is asking for an element from the
        // appended items, so we return an empty container
        return Container();
      }
      // Otherwise, we return the actual item
      return widget.itemBuilder(
          context, this._effectiveController!.loadedItems![index], index);
    }
  }

  Widget _getLoadingWidget() {
    return this._getStandardContainer(child: CircularProgressIndicator());
  }

  Widget _getNoItemsFoundWidget() {
    return this._getStandardContainer(
        child: widget.noItemsFoundBuilder != null
            ? widget.noItemsFoundBuilder!(context)
            : Container());
  }

  Widget _getErrorWidget(Object? error) {
    return this._getStandardContainer(
        child: widget.errorBuilder != null
            ? widget.errorBuilder!(context, this._effectiveController!.error)
            : Text('Error: $error',
                style: TextStyle(
                    color: Theme.of(context).disabledColor,
                    fontStyle: FontStyle.italic)));
  }

  Widget _getStandardContainer({Widget? child}) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Align(
          alignment: Alignment.topCenter,
          child: child,
        ));
  }
}

/// The controller responsible for managing page loading in Pagewise
///
/// You don't have to provide a controller yourself when creating a Pagewise
/// widget. The widget will create one for you. However you might wish to create
/// one yourself in order to achieve some effects.
///
/// Notice though that if you provide a controller yourself, you should provide
/// the [pageFuture] and [pageSize] parameters to the *controller* instead of
/// the widget.
///
/// A possible use case of the controller is to force a reset of the loaded
/// pages using a [RefreshIndicator](https://docs.flutter.io/flutter/material/RefreshIndicator-class.html).
/// you could achieve that as follows:
///
/// ```dart
/// final _pageLoadController = PagewiseLoadController(
///   pageSize: 6,
///   pageFuture: BackendService.getPage
/// );
///
/// @override
/// Widget build(BuildContext context) {
///   return RefreshIndicator(
///     onRefresh: () async {
///       await this._pageLoadController.reset();
///     },
///     child: PagewiseListView(
///         itemBuilder: this._itemBuilder,
///         pageLoadController: this._pageLoadController,
///     ),
///   );
/// }
/// ```
///
/// Another use case for creating the controller yourself is if you want to
/// listen to the state of Pagewise and act accordingly.
/// For example, you might want to show a specific widget when the list is empty
/// In that case, you could do:
/// ```dart
/// final _pageLoadController = PagewiseLoadController(
///   pageSize: 6,
///   pageFuture: BackendService.getPage
/// );
///
/// bool _empty = false;
///
/// @override
/// void initState() {
///   super.initState();
///
///   this._pageLoadController.addListener(() {
///     if (this._pageLoadController.noItemsFound) {
///       setState(() {
///         this._empty = this._pageLoadController.noItemsFound;
///       });
///     }
///   });
/// }
/// ```
///
/// And then in your `build` function you do:
/// ```dart
/// if (this._empty) {
///   return Text('NO ITEMS FOUND');
/// }
/// ```
class PagewiseLoadController<T> extends ChangeNotifier {
  List<T>? _loadedItems;
  int? _numberOfLoadedPages;
  bool? _hasMoreItems;
  Object? _error;
  late bool _isFetching;

  /// Called whenever a new page (or batch) is to be fetched
  ///
  /// It is provided with the page index, and expected to return a [Future](https://api.dartlang.org/stable/1.24.3/dart-async/Future-class.html) that
  /// resolves to a list of entries. Please make sure to return only [pageSize]
  /// or less entries (in the case of the last page) for each page.
  final PageFuture<T>? pageFuture;

  /// The number  of entries per page
  final int? pageSize;

  /// Creates a PagewiseLoadController.
  ///
  /// You must provide both the [pageFuture] and the [pageSize]
  PagewiseLoadController({required this.pageFuture, required this.pageSize});

  /// The list of items that have already been loaded
  List<T>? get loadedItems => this._loadedItems;

  /// The number of pages that have already been loaded
  int? get numberOfLoadedPages => this._numberOfLoadedPages;

  /// Whether there are still more items to load
  bool? get hasMoreItems => this._hasMoreItems;

  /// The latest error that has been faced when trying to load a page
  Object? get error => this._error;

  /// set to true if no data was found
  bool get noItemsFound =>
      this._loadedItems!.length == 0 && this.hasMoreItems == false;

  /// Called to initialize the controller. Same as [reset]
  void init() {
    this.reset();
  }

  /// Resets all the information of the controller
  void reset() {
    this._loadedItems = [];
    this._numberOfLoadedPages = 0;
    this._hasMoreItems = true;
    this._error = null;
    this._isFetching = false;
    notifyListeners();
  }

  /// Fetches a new page by calling [pageFuture]
  Future<void> fetchNewPage() async {
    if (!this._isFetching) {
      this._isFetching = true;

      List<T> page;
      try {
        page = await this.pageFuture!(this._numberOfLoadedPages);
        if (this._numberOfLoadedPages != null) {
          this._numberOfLoadedPages = this._numberOfLoadedPages! + 1;
        }
      } catch (error) {
        this._error = error;
        this._isFetching = false;
        notifyListeners();
        return;
      }

      // Get length accounting for possible null Future return. We'l treat a null Future as an empty return
      final int length = page.length;

      if (length > this.pageSize!) {
        this._isFetching = false;
        throw ('Page length ($length) is greater than the maximum size (${this.pageSize})');
      }

      if (length == 0) {
        this._hasMoreItems = false;
      } else {
        this._loadedItems!.addAll(page);
      }
      this._isFetching = false;
      notifyListeners();
    }
  }

  /// Attempts to retry in case an error occurred
  void retry() {
    this._error = null;
    notifyListeners();
  }
}

class PagewiseListView<T> extends Pagewise<T> {
  /// Creates a Pagewise ListView.
  ///
  /// All the properties are either those documented for normal [ListViews](https://docs.flutter.io/flutter/widgets/ListView-class.html),
  /// or those inherited from [Pagewise]
  PagewiseListView(
      {Key? key,
      EdgeInsetsGeometry? padding,
      bool? primary,
      bool addSemanticIndexes = true,
      int? semanticChildCount,
      bool shrinkWrap = false,
      ScrollController? controller,
      PagewiseLoadController<T>? pageLoadController,
      double? itemExtent,
      bool addAutomaticKeepAlives = true,
      Axis scrollDirection = Axis.vertical,
      bool addRepaintBoundaries = true,
      double? cacheExtent,
      ScrollPhysics? physics,
      bool reverse = false,
      int? pageSize,
      PageFuture<T>? pageFuture,
      RetryBuilder? retryBuilder,
      NoItemsFoundBuilder? noItemsFoundBuilder,
      required ItemBuilder<T> itemBuilder,
      ErrorBuilder? errorBuilder})
      : super(
            pageSize: pageSize,
            pageFuture: pageFuture,
            pageLoadController: pageLoadController,
            key: key,
            itemBuilder: itemBuilder,
            errorBuilder: errorBuilder,
            noItemsFoundBuilder: noItemsFoundBuilder,
            builder: (PagewiseState<T> state) {
              return ListView.builder(
                  itemExtent: itemExtent,
                  addAutomaticKeepAlives: addAutomaticKeepAlives,
                  scrollDirection: scrollDirection,
                  addRepaintBoundaries: addRepaintBoundaries,
                  cacheExtent: cacheExtent,
                  physics: physics,
                  reverse: reverse,
                  padding: padding,
                  addSemanticIndexes: addSemanticIndexes,
                  semanticChildCount: semanticChildCount,
                  shrinkWrap: shrinkWrap,
                  primary: primary,
                  controller: controller,
                  itemCount: state._itemCount,
                  itemBuilder:
                      state._itemBuilder as Widget Function(BuildContext, int));
            });
}
