class WeightModel {
  final double value;
  final bool isCustom;
  
  WeightModel(this.value, {this.isCustom = false});

  String get formattedValue => value.toStringAsFixed(3);
}
