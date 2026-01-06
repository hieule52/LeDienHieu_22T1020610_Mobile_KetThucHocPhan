import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address_model.dart';

class AddressController extends ChangeNotifier {
  List<AddressModel> _addresses = [];
  bool _isLoading = false;

  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;

  AddressModel? get defaultAddress {
    if (_addresses.isEmpty) return null;
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return _addresses.first;
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  Future<void> loadAddresses() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('user_addresses');
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      _addresses = jsonList.map((e) => AddressModel.fromJson(e)).toList();
    } else {
      // Mock initial data if empty
      if (_addresses.isEmpty) {
        _addresses = [
          AddressModel(
            id: _generateId(),
            name: 'Le Dien Hieu',
            phone: '0123456789',
            province: 'Huế',
            ward: 'Huế',
            specificAddress: '77 Nguyễn Huệ',
            isDefault: true,
          ),
        ];
        await _saveToPrefs();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAddress(AddressModel address) async {
    if (address.isDefault) {
      // Set others to non-default
      _addresses = _addresses.map((a) => a.copyWith(isDefault: false)).toList();
    } else if (_addresses.isEmpty) {
      // First address must be default
      address = address.copyWith(isDefault: true);
    }

    _addresses.add(address);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> updateAddress(AddressModel address) async {
    if (address.isDefault) {
      _addresses = _addresses.map((a) => a.copyWith(isDefault: false)).toList();
    }

    final index = _addresses.indexWhere((a) => a.id == address.id);
    if (index != -1) {
      _addresses[index] = address;
      await _saveToPrefs();
      notifyListeners();
    }
  }

  Future<void> deleteAddress(String id) async {
    final address = _addresses.firstWhere((a) => a.id == id);
    _addresses.removeWhere((a) => a.id == id);

    // If deleted default, make first available default
    if (address.isDefault && _addresses.isNotEmpty) {
      _addresses[0] = _addresses[0].copyWith(isDefault: true);
    }

    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(_addresses.map((e) => e.toJson()).toList());
    await prefs.setString('user_addresses', data);
  }
}
