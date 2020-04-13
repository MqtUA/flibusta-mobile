import 'dart:async';

import 'package:flibusta/blocs/proxy_list/proxy_list_bloc.dart';
import 'package:flibusta/constants.dart';
import 'package:flibusta/ds_controls/theme.dart';
import 'package:flibusta/ds_controls/ui/decor/staggers.dart';
import 'package:flibusta/pages/home/components/home_bottom_nav_bar.dart';
import 'package:flibusta/pages/home/views/proxy_settings/components/get_new_proxy_tile.dart';
import 'package:flibusta/pages/home/views/proxy_settings/components/proxy_radio_list_tile.dart';
import 'package:flutter/material.dart';

class ProxySettingsPage extends StatefulWidget {
  static const routeName = '/ProxySettings';

  final StreamController<int> selectedNavItemController;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const ProxySettingsPage({
    Key key,
    @required this.scaffoldKey,
    @required this.selectedNavItemController,
  }) : super(key: key);

  @override
  createState() => _ProxySettingsPageState();
}

class _ProxySettingsPageState extends State<ProxySettingsPage> {
  ProxyListBloc _proxyListBloc;

  @override
  void initState() {
    super.initState();
    _proxyListBloc = ProxyListBloc();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: widget.scaffoldKey,
      body: SafeArea(
        child: Scrollbar(
          child: ListView(
            physics: kBouncingAlwaysScrollableScrollPhysics,
            addSemanticIndexes: false,
            padding: EdgeInsets.fromLTRB(16, 16, 16, 42),
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Прокси',
                      style: Theme.of(context).textTheme.display1.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.body1.color,
                          ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh),
                      tooltip: 'Проверить прокси повторно',
                      onPressed: () {
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Использование прокси-сервера может помочь, если Флибуста заблокирована Вашим интернет-провайдером.',
                style: Theme.of(context).textTheme.body1,
              ),
              SizedBox(height: 8),
              Text(
                'Соединения:',
                style: Theme.of(context)
                    .textTheme
                    .subhead
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ListFadeInSlideStagger(
                index: 1,
                child: Card(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(kCardBorderRadius),
                    child: Material(
                      type: MaterialType.card,
                      borderRadius: BorderRadius.circular(kCardBorderRadius),
                      child: StreamBuilder(
                        stream: _proxyListBloc.actualProxyStream,
                        builder: (BuildContext context,
                            AsyncSnapshot<String> actualProxySnapshot) {
                          if (!actualProxySnapshot.hasData ||
                              !(actualProxySnapshot.data is String)) {
                            return Container();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              ProxyRadioListTile(
                                title: 'Без прокси',
                                value: '',
                                groupValue: actualProxySnapshot.data,
                                onChanged: _proxyListBloc.setActualProxy,
                                cancelToken: _proxyListBloc.cancelToken,
                              ),
                              Divider(),
                              ProxyRadioListTile(
                                title:
                                    'Прокси создателя приложения (не работает на мобильном интернете Yota)',
                                value:
                                    'flibustauser:ilovebooks@35.228.73.110:3128',
                                groupValue: actualProxySnapshot.data,
                                onChanged: _proxyListBloc.setActualProxy,
                                cancelToken: _proxyListBloc.cancelToken,
                              ),
                              Divider(),
                              StreamBuilder(
                                stream: _proxyListBloc.proxyListStream,
                                builder: (context,
                                    AsyncSnapshot<List<String>> snapshot) {
                                  if (snapshot.data == null ||
                                      snapshot.data.isEmpty) {
                                    return Container();
                                  }

                                  return Column(
                                    children: ListTile.divideTiles(
                                      context: context,
                                      tiles: [
                                        for (var proxyElement in snapshot.data)
                                          ProxyRadioListTile(
                                            title: proxyElement,
                                            value: proxyElement,
                                            groupValue:
                                                actualProxySnapshot.data,
                                            onChanged:
                                                _proxyListBloc.setActualProxy,
                                            onDelete: _proxyListBloc
                                                .removeFromProxyList,
                                            cancelToken:
                                                _proxyListBloc.cancelToken,
                                          ),
                                      ],
                                    ).toList()
                                      ..add(Divider()),
                                  );
                                },
                              ),
                              GetNewProxyTile(
                                callback: _proxyListBloc.addToProxyList,
                              ),
                              Divider(),
                              ListTile(
                                enabled: true,
                                leading: Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Icon(
                                    Icons.add,
                                    color: Theme.of(context).accentColor,
                                  ),
                                ),
                                title: Text('Добавить свой прокси'),
                                onTap: () async {
                                  var userProxy = await showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      final TextEditingController
                                          proxyHostController =
                                          TextEditingController();
                                      return SimpleDialog(
                                        title: Text('Добавить свой прокси'),
                                        children: <Widget>[
                                          TextField(
                                            controller: proxyHostController,
                                            autofocus: true,
                                            onEditingComplete: () {
                                              Navigator.pop(
                                                context,
                                                proxyHostController.text,
                                              );
                                            },
                                          )
                                        ],
                                      );
                                    },
                                  );
                                  if (userProxy != null &&
                                      userProxy.isNotEmpty) {
                                    _proxyListBloc.addToProxyList(userProxy);
                                    _proxyListBloc.setActualProxy(userProxy);
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 14.0),
            ],
          ),
        ),
      ),
      bottomNavigationBar: HomeBottomNavBar(
        key: Key('HomeBottomNavBar'),
        index: 2,
        selectedNavItemController: widget.selectedNavItemController,
      ),
    );
  }

  @override
  void dispose() {
    _proxyListBloc.dispose();
    super.dispose();
  }
}
