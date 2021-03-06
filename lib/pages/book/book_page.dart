import 'dart:io';

import 'package:flibusta/blocs/tor_proxy/tor_proxy_bloc.dart';
import 'package:flibusta/constants.dart';
import 'package:flibusta/ds_controls/theme.dart';
import 'package:flibusta/ds_controls/ui/app_bar.dart';
import 'package:flibusta/ds_controls/ui/buttons/outline_button.dart';
import 'package:flibusta/ds_controls/ui/show_modal_bottom_sheet.dart';
import 'package:flibusta/model/bookInfo.dart';
import 'package:flibusta/model/extension_methods/dio_error_extension.dart';
import 'package:flibusta/pages/author/author_page.dart';
import 'package:flibusta/pages/book/components/book_app_bar.dart';
import 'package:flibusta/pages/sequence/sequence_page.dart';
import 'package:flibusta/services/local_storage.dart';
import 'package:flibusta/services/transport/book_service.dart';
import 'package:flibusta/utils/dialog_utils.dart';
import 'package:flibusta/utils/file_utils.dart';
import 'package:flutter/material.dart';
import 'package:flibusta/components/loading_indicator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rxdart/rxdart.dart';

class BookPage extends StatefulWidget {
  static const routeName = '/BookPage';

  final int bookId;

  const BookPage({Key key, this.bookId}) : super(key: key);
  @override
  BookPageState createState() => BookPageState();
}

class BookPageState extends State<BookPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  BehaviorSubject<double> _downloadProgressController;

  BookInfo _bookInfo;
  Image _coverImage;

  DsError _getBookInfoError;
  DsError _getBookCoverImageError;

  @override
  void initState() {
    super.initState();

    _downloadProgressController = BehaviorSubject<double>();

    BookService.getBookInfo(widget.bookId).then((bookInfo) {
      if (!mounted) return;
      setState(() {
        _bookInfo = bookInfo;
      });
      LocalStorage().getDownloadedBooks().then((downloadedBooks) {
        var downloadedBook = downloadedBooks?.firstWhere(
          (book) => book.id == _bookInfo.id,
          orElse: () => null,
        );
        if (downloadedBook != null) {
          if (!mounted) return;
          setState(() {
            _bookInfo.localPath = downloadedBook.localPath;
          });
        }
      });
      if (bookInfo.coverImgSrc == null) {
        setState(() {
          _getBookCoverImageError = DsError(userMessage: 'Нет обложки');
        });
        return;
      }
      BookService.getBookCoverImage(bookInfo.coverImgSrc).then((coverImgBytes) {
        if (!mounted) return;
        setState(() {
          _coverImage = Image.memory(
            coverImgBytes,
            fit: BoxFit.cover,
          );
        });
      }, onError: (dsError) {
        if (!mounted) return;
        setState(() {
          _getBookCoverImageError = dsError;
        });
      });
    }, onError: (dsError) {
      if (!mounted) return;
      setState(() {
        _getBookInfoError = dsError;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_getBookInfoError != null) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: DsAppBar(),
        body: Center(
          child: Text(
            _getBookInfoError.toString(),
            style: Theme.of(context).textTheme.headline5,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_bookInfo == null) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: DsAppBar(),
        body: LoadingIndicator(),
      );
    }
    return Scaffold(
      key: _scaffoldKey,
      body: Builder(
        builder: (context) {
          Widget appBarBackground;
          if (_getBookCoverImageError != null) {
            appBarBackground = SafeArea(
              child: Center(
                child: Text(
                  _getBookCoverImageError.toString(),
                  style: Theme.of(context).textTheme.headline5,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (_coverImage == null) {
            appBarBackground = LoadingIndicator();
          } else {
            appBarBackground = _coverImage;
          }

          return CustomScrollView(
            physics: kBouncingAlwaysScrollableScrollPhysics,
            slivers: [
              BookAppBar(
                coverImg: appBarBackground,
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  if (!(TorProxyBloc().state is InTorProxyState)) ...[
                    Material(
                      type: MaterialType.card,
                      borderRadius: BorderRadius.zero,
                      color: Colors.red.withOpacity(0.6),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          FontAwesomeIcons.copyright,
                          color: Colors.white,
                        ),
                        title: Text(
                          'У меня есть права на это произведение и я хочу убрать её из библиотеки.',
                          style: TextStyle(color: Colors.white),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                        onTap: () {
                          DialogUtils.simpleAlert(
                            context,
                            'Права на произведение',
                            content: Text(
                              'Напишите администратору сайта на почту lib.contact.email@gmail.com',
                            ),
                          );
                        },
                      ),
                    ),
                    Divider(),
                  ],
                  ListTile(
                    title: Text(_bookInfo.title ?? ''),
                    subtitle: Text('Название произведения'),
                    trailing: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FutureBuilder<bool>(
                          future: LocalStorage().isFavoriteBook(_bookInfo.id),
                          builder: (context, isFavoriteBookSnapshot) {
                            return IconButton(
                              tooltip: isFavoriteBookSnapshot.data == true
                                  ? 'Убрать из избранного'
                                  : 'Добавить в избранное',
                              icon: Icon(
                                isFavoriteBookSnapshot.data == true
                                    ? FontAwesomeIcons.solidHeart
                                    : FontAwesomeIcons.heart,
                                color: isFavoriteBookSnapshot.data == true
                                    ? Colors.red
                                    : null,
                              ),
                              onPressed: () async {
                                if (isFavoriteBookSnapshot.data == true) {
                                  await LocalStorage()
                                      .deleteFavoriteBook(_bookInfo.id);
                                } else {
                                  await LocalStorage()
                                      .addFavoriteBook(_bookInfo);
                                }
                                setState(() {});
                              },
                            );
                          },
                        ),
                        FutureBuilder<bool>(
                          future: LocalStorage().isPostponeBook(_bookInfo.id),
                          builder: (context, isPostponeSnapshot) {
                            return IconButton(
                              tooltip: isPostponeSnapshot.data == true
                                  ? 'Убрать из отложенного'
                                  : 'Отложить на потом',
                              icon: Icon(
                                FontAwesomeIcons.clock,
                                color: isPostponeSnapshot.data == true
                                    ? kSecondaryColor(context)
                                    : null,
                              ),
                              onPressed: () async {
                                if (isPostponeSnapshot.data == true) {
                                  await LocalStorage()
                                      .deletePostponeBook(_bookInfo.id);
                                } else {
                                  await LocalStorage()
                                      .addPostponeBook(_bookInfo);
                                }
                                setState(() {});
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Divider(indent: 16),
                  ListTile(
                    title: Text(_bookInfo.authors?.toString() ?? ''),
                    subtitle: Text('Автор(-ы)'),
                    onTap: () async {
                      if (_bookInfo.authors.isEmpty) {
                        return;
                      }
                      Map<int, String> choosedAuthor;
                      if (_bookInfo.authors.list.length == 1) {
                        choosedAuthor = _bookInfo.authors.list.first;
                      } else {
                        choosedAuthor =
                            await showDsModalBottomSheet<Map<int, String>>(
                          context: context,
                          title: 'Искать книги автора:',
                          builder: (context) {
                            return ListView(
                              physics: kBouncingAlwaysScrollableScrollPhysics,
                              addSemanticIndexes: false,
                              children: _bookInfo.authors.list.map((author) {
                                return ListTile(
                                  title: Text(author.values.first),
                                  onTap: () {
                                    Navigator.of(context).pop(author);
                                  },
                                );
                              }).toList(),
                            );
                          },
                        );
                      }
                      if (choosedAuthor == null) {
                        return;
                      }
                      Navigator.of(context).pushNamed(
                        AuthorPage.routeName,
                        arguments: choosedAuthor.keys.first,
                      );
                    },
                  ),
                  if (_bookInfo.translators?.isNotEmpty == true) ...[
                    Divider(indent: 16),
                    ListTile(
                      title: Text(
                        _bookInfo.translators.toString(),
                      ),
                      subtitle: Text('Переведено'),
                    ),
                  ],
                  if (_bookInfo.genres?.isNotEmpty == true) ...[
                    Divider(indent: 16),
                    ListTile(
                      title: Text(
                        _bookInfo.genres.toString(),
                      ),
                      subtitle: Text('Жанр(-ы)'),
                    ),
                  ],
                  if (_bookInfo.sequenceTitle?.isNotEmpty == true) ...[
                    Divider(indent: 16),
                    ListTile(
                      title: Text(
                        _bookInfo.sequenceTitle,
                      ),
                      subtitle: Text('Серия произведений'),
                      onTap: () async {
                        if (_bookInfo.sequenceId == null) {
                          return;
                        }
                        Navigator.of(context).pushNamed(
                          SequencePage.routeName,
                          arguments: _bookInfo.sequenceId,
                        );
                      },
                    ),
                  ],
                  if (_bookInfo.addedToLibraryDate?.isNotEmpty == true) ...[
                    Divider(indent: 16),
                    ListTile(
                      title: Text(
                        _bookInfo.addedToLibraryDate,
                      ),
                    ),
                  ],
                  if (_bookInfo.size?.isNotEmpty == true) ...[
                    Divider(indent: 16),
                    ListTile(
                      title: Text(
                        _bookInfo.size,
                      ),
                      subtitle: Text('Размер файла'),
                    ),
                  ],
                  if (_bookInfo.lemma?.isNotEmpty == true) ...[
                    Divider(),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Text(
                        'Аннотация:',
                        style: Theme.of(context).textTheme.headline5,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      child: Text(
                        _bookInfo.lemma,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                  StreamBuilder<double>(
                    stream: _downloadProgressController,
                    builder: (context, downloadProgressSnapshot) {
                      if (downloadProgressSnapshot.hasData) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(kCardBorderRadius),
                            child: LinearProgressIndicator(
                              value: downloadProgressSnapshot.data == 0.0
                                  ? null
                                  : downloadProgressSnapshot.data,
                              minHeight: 16,
                            ),
                          ),
                        );
                      }
                      var downloadButton = Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: DsOutlineButton(
                          child: Text('Скачать'),
                          onPressed: () => _onDownloadBookClick(_bookInfo),
                        ),
                      );
                      if (_bookInfo.localPath != null) {
                        return FutureBuilder(
                          future: File(_bookInfo.localPath).exists(),
                          builder: (context, bookFileExistsSnapshot) {
                            if (bookFileExistsSnapshot.data != true) {
                              return downloadButton;
                            }
                            return Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: DsOutlineButton(
                                child: Text('Открыть'),
                                onPressed: () => FileUtils.openFile(
                                  _bookInfo.localPath,
                                ),
                              ),
                            );
                          },
                        );
                      }
                      if (_bookInfo.downloadFormats != null ??
                          !downloadProgressSnapshot.hasData) {
                        return downloadButton;
                      }
                      return Container();
                    },
                  ),
                  SizedBox(height: 56),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onDownloadBookClick(BookInfo bookInfo) async {
    BookService.downloadBook(
      context,
      bookInfo,
      (downloadProgress) {
        if (_downloadProgressController.isClosed) return;
        _downloadProgressController.add(downloadProgress);
      },
    );
  }

  @override
  void dispose() {
    _downloadProgressController?.close();
    super.dispose();
  }
}
