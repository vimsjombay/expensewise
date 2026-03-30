import 'package:flutter/material.dart';

class CurrencyProvider with ChangeNotifier {
  String _currency = '₹';

  String get currency => _currency;

  void setCurrency(String newCurrency) {
    _currency = newCurrency;
    notifyListeners();
  }
}
