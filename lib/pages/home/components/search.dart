import 'dart:async';

import 'package:flibusta/blocs/home_grid/home_grid_bloc.dart';
import 'package:flibusta/model/advancedSearchParams.dart';
import 'package:flibusta/pages/home/advanced_search/advanced_search_bs.dart';
import 'package:flibusta/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BookSearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Поиск',
      icon: Icon(Icons.search),
      onPressed: () async {
        var previousBookSearches =
            await LocalStorage().getPreviousBookSearches();
        var homeGridBloc = BlocProvider.of<HomeGridBloc>(context);
        var currentSearchString = homeGridBloc.currentState.searchQuery ?? '';

        var searchQuery = await showSearch(
          context: context,
          delegate: _BookSearchDelegate(previousBookSearches),
          query: currentSearchString,
        );

        if (searchQuery == null) {
          return;
        }
        if (searchQuery is AdvancedSearchParams) {
          var advancedSearchParams = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return AdvancedSearchPage(
                  advancedSearchParams: AdvancedSearchParams(),
                );
              },
            ),
          );
          if (advancedSearchParams == null) {
            return;
          }
          homeGridBloc.advancedSearch(
              advancedSearchParams: advancedSearchParams);
          return;
        }
        if (searchQuery is String && searchQuery.trim() != '') {
          searchQuery = searchQuery.trim().toLowerCase();
          if (!previousBookSearches.contains(searchQuery)) {
            previousBookSearches.add(searchQuery);
            LocalStorage().setPreviousBookSearches(previousBookSearches);
          }
          homeGridBloc.globalSearch(searchQuery: searchQuery);
        }
      },
    );
  }
}

class _BookSearchDelegate extends SearchDelegate<dynamic> {
  final List<String> previousGridSearches;

  _BookSearchDelegate(this.previousGridSearches);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    Future.microtask(() => close(context, query));
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _SearchSuggestionBuilder(
      query: query,
      previousGridSearches: previousGridSearches,
      close: close,
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context);
    assert(theme != null);
    if (theme.brightness == Brightness.light) {
      return Theme.of(context).copyWith(
        primaryColor: Colors.white,
        primaryIconTheme: theme.primaryIconTheme.copyWith(color: Colors.grey),
        primaryColorBrightness: Brightness.light,
        primaryTextTheme: theme.textTheme,
      );
    } else {
      return Theme.of(context).copyWith(
        primaryColor: Color(0xFF333333),
        primaryColorBrightness: Brightness.dark,
        primaryTextTheme: theme.textTheme,
      );
    }
  }
}

class _SearchSuggestionBuilder extends StatefulWidget {
  final List<String> previousGridSearches;
  final String query;
  final void Function(BuildContext, dynamic) close;

  const _SearchSuggestionBuilder({
    Key key,
    @required this.previousGridSearches,
    @required this.query,
    @required this.close,
  }) : super(key: key);

  @override
  _SearchSuggestionBuilderState createState() =>
      _SearchSuggestionBuilderState();
}

class _SearchSuggestionBuilderState extends State<_SearchSuggestionBuilder> {
  var _previousGridSearchesController = StreamController<List<String>>();

  @override
  void initState() {
    super.initState();
    _previousGridSearchesController.add(widget.previousGridSearches);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: _previousGridSearchesController.stream,
      builder: (context, previousSearchesSnapshot) {
        var filteredSuggestions = widget.previousGridSearches
            ?.where((suggestion) =>
                suggestion.startsWith(widget.query.trim().toLowerCase()))
            ?.toList();

        return ListView.builder(
          itemCount: (filteredSuggestions?.length ?? 0) + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return Material(
                elevation: 4.0,
                color: Theme.of(context).backgroundColor,
                child: ListTile(
                  dense: true,
                  title: Center(
                    child: Text(
                      'Расширенный поиск',
                      style: Theme.of(context).textTheme.button,
                    ),
                  ),
                  onTap: () {
                    widget.close(context, AdvancedSearchParams());
                  },
                ),
              );
            }
            return ListTile(
              leading: Icon(Icons.history),
              title: Text(previousSearchesSnapshot.data.elementAt(index)),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  previousSearchesSnapshot.data
                      .remove(previousSearchesSnapshot.data.elementAt(index));
                  LocalStorage()
                      .setPreviousBookSearches(previousSearchesSnapshot.data);
                  _previousGridSearchesController
                      .add(previousSearchesSnapshot.data);
                },
              ),
              onTap: () {
                widget.close(
                    context, previousSearchesSnapshot.data.elementAt(index));
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _previousGridSearchesController.close();
    super.dispose();
  }
}