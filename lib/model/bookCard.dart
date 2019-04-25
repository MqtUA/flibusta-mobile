import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BookCard {
  int id;
  Genres genres;
  int sequenceId;
  String sequenceTitle;
  String title;
  String size;
  DownloadFormats downloadFormats;
  Authors authors;
  Translators translators;
  double downloadProgress;

  BookCard({
    this.id,
    this.genres,
    this.sequenceId,
    this.sequenceTitle,
    this.title,
    this.size,
    this.downloadFormats,
    this.authors,
    this.translators,
  }): assert(id != null);
}

class DownloadFormats {
  DownloadFormats(this.list);

  List<Map<String, String>> list;

  bool get isNotEmpty {
    return list != null ? list.isNotEmpty : false;
  }

  bool get isEmpty {
    return list != null ? list.isEmpty : true;
  }

  @override
  String toString() {
    if (list == null || list.isEmpty) {
      return "";
    }
    var result = "";
    list.forEach((f) {
      result += f.keys.first;
      if (f != list.last) {
        result += ", ";
      }
    });
    return result;
  }

  static IconData getIconDataForFormat(String format) {
    switch (format) {
      case "скачать docx":
      case "docx":
        return FontAwesomeIcons.solidFileWord;
      case "fb2":
        return FontAwesomeIcons.bookReader;
      case "epub":
        return FontAwesomeIcons.leanpub;
      case "скачать pdf":
      case "pdf":
        return FontAwesomeIcons.solidFilePdf;
      default:
        return FontAwesomeIcons.book;
    }
  }
}

class Authors {
  Authors(this.list);
  
  List<Map<int, String>> list;
  
  bool get isNotEmpty {
    return list != null ? list.isNotEmpty : false;
  }

  bool get isEmpty {
    return list != null ? list.isEmpty : true;
  }

  @override
  String toString() {
    if (list == null || list.isEmpty) {
      return "Пустой массив";
    }
    var result = "";
    list.forEach((f) {
      result += f.values.first;
      if (f != list.last) {
        result += ", ";
      }
    });
    return result;
  }
}

class Translators {
  Translators(this.list);
  
  List<Map<int, String>> list;
  
  bool get isNotEmpty {
    return list != null ? list.isNotEmpty : false;
  }

  bool get isEmpty {
    return list != null ? list.isEmpty : true;
  }

  @override
  String toString() {
    if (list == null || list.isEmpty) {
      return "Пустой массив";
    }
    var result = "";
    list.forEach((f) {
      result += f.values.first;
      if (f != list.last) {
        result += ", ";
      }
    });
    return result;
  }
}

class Genres {
  Genres(this.list);
  
  List<Map<int, String>> list;
  
  bool get isNotEmpty {
    return list != null ? list.isNotEmpty : false;
  }

  bool get isEmpty {
    return list != null ? list.isEmpty : true;
  }

  @override
  String toString() {
    if (list == null || list.isEmpty) {
      return "Пустой массив";
    }
    var result = "";
    list.forEach((f) {
      result += f.values.first;
      if (f != list.last) {
        result += ", ";
      }
    });
    return result.replaceAll(RegExp(r'(\[|\])'), "");
  }
}