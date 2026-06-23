import 'package:flutter/foundation.dart';

class Tenant extends ChangeNotifier {
  String _id;
  String _name;

  Tenant({required String id, required String name}) : _id = id, _name = name;

  String get id => _id;
  String get name => _name;

  void updateComune({required String id, required String name}) {
    _id = id;
    _name = name;
    notifyListeners();
  }

  /// Converte il nome del comune nel formato id Firestore
  /// Es. "Vibo Valentia" → "vibo-valentia"
  static String toId(String name) {
    return name.toLowerCase().replaceAll("'", '-').replaceAll(' ', '-');
  }
}
