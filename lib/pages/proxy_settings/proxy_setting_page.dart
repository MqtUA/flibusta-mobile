import 'package:flibusta/pages/proxy_settings/free_proxy_tiles/free_proxy_tiles.dart';
import 'package:flibusta/services/http_client_service.dart';
import 'package:flibusta/services/local_store_service.dart';
import 'package:flutter/material.dart';

class ProxySettings extends StatefulWidget {
  static const routeName = "/ProxySettings";
  @override
  createState() => ProxySettingsState();
}

class ProxySettingsState extends State<ProxySettings> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ProxyHttpClient _httpClient = ProxyHttpClient();

  String _flibustaHostAddress;
  String _customProxy;
  bool _cachedGetUseFreeProxy;

  @override
  void initState() {
    super.initState();

    _customProxy = "";
    LocalStore().getUseFreeProxy().then((value) {
      setState(() {
        _cachedGetUseFreeProxy = value;
      });
    });
    LocalStore().getActualCustomProxy().then((value) {
      setState(() {
        _customProxy = value;
      });
    });
    _flibustaHostAddress = _httpClient.getFlibustaHostAddress();
    LocalStore().getFlibustaHostAddress().then((value) {
      setState(() {
        _flibustaHostAddress = value;
      });
    });
  }

  void changeGetUseFreeProxy(bool value) {
    if (_cachedGetUseFreeProxy != value) {
      setState(() {
        _cachedGetUseFreeProxy = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: false,
        title: Text("Настройки Proxy"),
      ),
      body: ListView(
        children: <Widget> [
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  child: Text("Используемый сайт Флибусты:", style: TextStyle(color: Theme.of(context).accentColor, fontSize: 18, fontWeight: FontWeight.w600),),
                ),
                RadioListTile(
                  title: Text("Оригинальный (flibusta.is)"),
                  groupValue: _flibustaHostAddress,
                  value: "flibusta.is",
                  onChanged: ((hostAddress) {
                    setState(() {
                      _flibustaHostAddress = hostAddress;
                      LocalStore().setFlibustaHostAddress(_flibustaHostAddress);
                      ProxyHttpClient().setFlibustaHostAddress(_flibustaHostAddress);
                    });
                  }),
                ),
                Divider(height: 1,),
                RadioListTile(
                  title: Text("В облаке гугл (flibusta.appspot.com)"),
                  subtitle: Text("Некоторые функции приложения могут не работать"),
                  groupValue: _flibustaHostAddress,
                  value: "flibusta.appspot.com",
                  onChanged: ((hostAddress) {
                    setState(() {
                      _flibustaHostAddress = hostAddress;
                      LocalStore().setFlibustaHostAddress(_flibustaHostAddress);
                      ProxyHttpClient().setFlibustaHostAddress(_flibustaHostAddress);
                    });
                  }),
                ),
                // Divider(height: 1,),
                // RadioListTile(
                //   title: Text("Tor версия (flibustahezeous3.onion)"),
                //   groupValue: _flibustaHostAddress,
                //   value: "flibustahezeous3.onion",
                //   onChanged: ((hostAddress) {
                //     setState(() {
                //       _flibustaHostAddress = hostAddress;
                //       LocalStore().setFlibustaHostAddress(_flibustaHostAddress);
                //       ProxyHttpClient().setFlibustaHostAddress(_flibustaHostAddress);
                //     });
                //   }),
                // ),
              ],
            ),
          ),
          Container(
            color: Colors.transparent, 
            height: 20.0,
          ),
          FreeProxyTiles(getUseFreeProxyChangeCallBack: (value) {
            changeGetUseFreeProxy(value);
          }),
          Container(
            color: Colors.transparent, 
            height: 20.0,
          ),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  child: Text("Подключения:", style: TextStyle(color: Theme.of(context).accentColor, fontSize: 18, fontWeight: FontWeight.w600),),
                ),
                RadioListTile(
                  title: Text("Без прокси"),
                  subtitle: _cachedGetUseFreeProxy ?? true ? Container() : FutureBuilder(future: ProxyHttpClient().connectionCheck(""),
                    builder: (context, snapshot) {
                      var subtitleText = "";
                      var subtitleColor;
                      if (snapshot.data != null && snapshot.connectionState != ConnectionState.waiting) {
                        if (snapshot.data >= 0) {
                          subtitleText = "доступно (пинг: " + snapshot.data.toString() + "мс)";
                          subtitleColor = Colors.green;
                        } else {
                          subtitleText = "недоступно";
                          subtitleColor = Colors.red;
                        }
                      } else {
                        subtitleText = "проверка...";
                        subtitleColor = Colors.grey[400];
                      }
                      return Text(subtitleText, style: TextStyle(color: subtitleColor));
                    }
                  ),
                  groupValue: _customProxy,
                  value: "",
                  onChanged: _cachedGetUseFreeProxy ?? true ? null : ((proxy) {
                    setState(() {
                      _customProxy = proxy;
                      LocalStore().setActualCustomProxy(_customProxy);
                      ProxyHttpClient().setProxy(_customProxy);
                    });
                  }),
                ),
                Divider(height: 1,),
                FutureBuilder(
                  future: LocalStore().getUserProxies(),
                  builder: (context, snapshot) {
                    if (snapshot.data != null && snapshot.data.length > 0) {
                      return Column(
                        children:
                          List<Widget>.generate(
                            snapshot.data.length,
                            (int index) =>
                            RadioListTile(
                              groupValue: _customProxy,
                              value: snapshot.data[index],
                              title: Text(snapshot.data[index]),
                              subtitle: _cachedGetUseFreeProxy ?? true ? Container() : FutureBuilder(future: ProxyHttpClient().connectionCheck(snapshot.data[index]),
                                builder: (context, snapshot) {
                                  var subtitleText = "";
                                  var subtitleColor;
                                  if (snapshot.data != null && snapshot.connectionState != ConnectionState.waiting) {
                                    if (snapshot.data >= 0) {
                                      subtitleText = "доступно (пинг: " + snapshot.data.toString() + "мс)";
                                      subtitleColor = Colors.green;
                                    } else {
                                      subtitleText = "недоступно";
                                      subtitleColor = Colors.red;
                                    }
                                  } else {
                                    subtitleText = "проверка...";
                                    subtitleColor = Colors.grey[400];
                                  }
                                  return Text(subtitleText, style: TextStyle(color: subtitleColor));
                                }
                              ),
                              onChanged: _cachedGetUseFreeProxy ?? true ? null : (proxy) {
                                setState(() {
                                  _customProxy = proxy;
                                  LocalStore().setActualCustomProxy(_customProxy);
                                  ProxyHttpClient().setProxy(_customProxy);
                                });
                              },
                              secondary: IconButton(
                                icon: Icon(Icons.close, color: Theme.of(context).accentColor),
                                onPressed: () async {
                                  await LocalStore().deleteUserProxy(snapshot.data[index]);  
                                  setState(() {});
                                },
                              ),
                            ),
                        ),
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor,),
                ListTile(
                  enabled: _cachedGetUseFreeProxy ?? true ? false : true,
                  leading: Icon(Icons.add, color: Theme.of(context).accentColor,),
                  title: Text("Добавить прокси"),
                  onTap: _cachedGetUseFreeProxy ?? true ? null : () async {
                    var userProxy = await showDialog<String>(
                      context: context,
                      builder: (BuildContext context) {
                        final TextEditingController proxyHostController = TextEditingController();
                        return SimpleDialog(
                          title: Text("Добавить прокси"),
                          children: <Widget>[
                            TextField(
                              controller: proxyHostController,
                              autofocus: true,
                              onEditingComplete: () {
                                Navigator.pop(context, proxyHostController.text);
                              },
                            )
                          ],
                        );
                      }
                    );
                    if (userProxy != null && userProxy.isNotEmpty) {
                      setState(() {
                        _customProxy = userProxy;
                        LocalStore().setActualCustomProxy(_customProxy);
                        ProxyHttpClient().setProxy(_customProxy);
                      });
                      LocalStore().addUserProxy(userProxy);
                    }
                  },
                ),
              ],
            ),
          ),
        ]
      ),
    );
  }
}