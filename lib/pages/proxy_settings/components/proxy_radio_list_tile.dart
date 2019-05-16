import 'package:dio/dio.dart';
import 'package:flibusta/services/http_client_service.dart';
import 'package:flutter/material.dart';

class ProxyRadioListTile extends StatelessWidget {
  final String _title;
  final String _value;
  final String _groupValue;
  final void Function(String) _onChanged;
  final void Function(String) _onDelete;
  final CancelToken _cancelToken;

  ProxyRadioListTile({
    Key key,
    @required String title,
    @required String value,
    @required String groupValue,
    @required void Function(String) onChanged,
    void Function(String) onDelete,
    CancelToken cancelToken,
  })  : _title = title,
        _value = value,
        _groupValue = groupValue,
        _onChanged = onChanged,
        _onDelete = onDelete,
        _cancelToken = cancelToken,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return RadioListTile(
      title: Text(_title),
      subtitle: FutureBuilder(
        future: ProxyHttpClient().connectionCheck(_value, cancelToken: _cancelToken),
        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
          var subtitleText = "";
          var subtitleColor;
          if (snapshot.data != null &&
              snapshot.connectionState != ConnectionState.waiting) {
            if (snapshot.data >= 0) {
              subtitleText = "доступно (пинг: ${snapshot.data.toString()}мс)";
              subtitleColor = Colors.green;
            } else {
              subtitleText = "ошибка";
              subtitleColor = Colors.red;
            }
          } else {
            subtitleText = "проверка...";
            subtitleColor = Colors.grey[400];
          }
          return Text(subtitleText, style: TextStyle(color: subtitleColor));
        },
      ),
      groupValue: _groupValue,
      value: _value,
      onChanged: _onChanged,
      secondary: _onDelete != null
          ? IconButton(
              icon: Icon(Icons.delete),
              tooltip: 'Удалить прокси',
              onPressed: () => _onDelete(_value),
            )
          : null,
    );
  }
}
