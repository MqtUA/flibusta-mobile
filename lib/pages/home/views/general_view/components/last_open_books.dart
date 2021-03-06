import 'package:flibusta/constants.dart';
import 'package:flibusta/ds_controls/theme.dart';
import 'package:flibusta/ds_controls/ui/decor/shimmers.dart';
import 'package:flibusta/model/bookCard.dart';
import 'package:flibusta/pages/book/book_page.dart';
import 'package:flibusta/services/local_storage.dart';
import 'package:flutter/material.dart';

class LastOpenBooksCard extends StatefulWidget {
  const LastOpenBooksCard({
    Key key,
  });

  @override
  _LastOpenBooksCardState createState() => _LastOpenBooksCardState();
}

class _LastOpenBooksCardState extends State<LastOpenBooksCard> {
  List<BookCard> lastOpenBooks;

  @override
  void initState() {
    super.initState();

    LocalStorage().getLastOpenBooks().then((lastOpenBooks) {
      if (!mounted) return;
      setState(() {
        this.lastOpenBooks = lastOpenBooks;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6.0),
          child: Text(
            'Последние открытые книги',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kCardBorderRadius),
            child: Material(
              type: MaterialType.card,
              borderRadius: BorderRadius.circular(kCardBorderRadius),
              child: Builder(
                builder: (context) {
                  if (lastOpenBooks == null) {
                    return ShimmerListTile();
                  }
                  if (lastOpenBooks.length == 0) {
                    return Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'Здесь будут последние три книги, которые вы открывали.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    addSemanticIndexes: false,
                    physics: NeverScrollableScrollPhysics(),
                    separatorBuilder: (context, index) {
                      return Divider(indent: 16);
                    },
                    itemCount: lastOpenBooks.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          lastOpenBooks[index].tileTitle ?? '',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                        ),
                        subtitle: Text(
                          lastOpenBooks[index].tileSubtitle ?? '',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                        ),
                        trailing: kIconArrowForward,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            BookPage.routeName,
                            arguments: lastOpenBooks[index].id,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
