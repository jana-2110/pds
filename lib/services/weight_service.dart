import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weight_model.dart';

class WeightService extends ChangeNotifier {
  late final List<WeightModel> _predefinedWeights;
  List<WeightModel> _customWeights = [];
  List<double> _deletedPredefinedWeights = [];
  
  static const String _prefsKey = 'custom_weights';
  static const String _deletedPrefsKey = 'deleted_predefined_weights';

  WeightService() {
    _predefinedWeights = _generatePredefinedWeights();
    _loadWeights();
  }

  Future<void> _loadWeights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final savedWeights = prefs.getStringList(_prefsKey);
      if (savedWeights != null) {
        _customWeights = savedWeights
            .map((s) => double.tryParse(s))
            .where((d) => d != null)
            .map((d) => WeightModel(normalizeWeight(d!), isCustom: true))
            .toList();
      }

      final deletedWeights = prefs.getStringList(_deletedPrefsKey);
      if (deletedWeights != null) {
        _deletedPredefinedWeights = deletedWeights
            .map((s) => double.tryParse(s))
            .where((d) => d != null)
            .map((d) => normalizeWeight(d!))
            .toList();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading weights: $e');
    }
  }

  Future<void> _saveCustomWeights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weightStrings = _customWeights.map((w) => w.formattedValue).toList();
      await prefs.setStringList(_prefsKey, weightStrings);
    } catch (e) {
      debugPrint('Error saving custom weights: $e');
    }
  }

  Future<void> _saveDeletedPredefinedWeights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weightStrings = _deletedPredefinedWeights.map((w) => w.toStringAsFixed(3)).toList();
      await prefs.setStringList(_deletedPrefsKey, weightStrings);
    } catch (e) {
      debugPrint('Error saving deleted predefined weights: $e');
    }
  }

  List<WeightModel> _generatePredefinedWeights() {
    const weights = [
      0.500, 1.000, 1.500, 2.000, 3.000, 4.000, 4.500, 5.000, 6.000, 7.000,
      8.000, 9.000, 10.000, 11.000, 12.000, 13.000, 14.000, 15.000, 16.000, 18.000,
      20.000, 25.000, 30.000, 35.000, 40.000
    ];
    return weights.map((w) => WeightModel(normalizeWeight(w))).toList();
  }

  double normalizeWeight(double value) {
    return double.parse(value.toStringAsFixed(3));
  }

  List<WeightModel> getAllWeights() {
    final filteredPredefined = _predefinedWeights
        .where((w) => !_deletedPredefinedWeights.contains(w.value))
        .toList();
    
    _customWeights.sort((a, b) => a.value.compareTo(b.value));
    return [...filteredPredefined, ..._customWeights];
  }

  bool addCustomWeight(double value) {
    final normalized = normalizeWeight(value);
    
    // Check if it already exists in the active view
    if (getAllWeights().any((w) => w.value == normalized)) {
      return false; // Already exists
    }
    
    // If the user adds back a deleted predefined weight, remove it from the deleted list
    if (_predefinedWeights.any((w) => w.value == normalized) && _deletedPredefinedWeights.contains(normalized)) {
      _deletedPredefinedWeights.remove(normalized);
      _saveDeletedPredefinedWeights();
      notifyListeners();
      return true;
    }
    
    _customWeights.add(WeightModel(normalized, isCustom: true));
    _saveCustomWeights();
    notifyListeners();
    return true;
  }
  
  bool removeWeight(double value) {
    final normalized = normalizeWeight(value);
    
    // Check if it's a custom weight
    final initialCustomLength = _customWeights.length;
    _customWeights.removeWhere((w) => w.value == normalized);
    
    if (_customWeights.length < initialCustomLength) {
      _saveCustomWeights();
      notifyListeners();
      return true;
    }
    
    // Check if it's a predefined weight
    if (_predefinedWeights.any((w) => w.value == normalized)) {
      if (!_deletedPredefinedWeights.contains(normalized)) {
        _deletedPredefinedWeights.add(normalized);
        _saveDeletedPredefinedWeights();
        notifyListeners();
        return true;
      }
    }

    return false;
  }

  bool weightExists(double value) {
    final normalized = normalizeWeight(value);
    return getAllWeights().any((w) => w.value == normalized);
  }
}
