class SolarData {
  final String address;
  final double latitude;
  final double longitude;
  final double roofAreaM2;
  final int maxPanels;
  final double systemSizeKw;
  final double annualProductionKwh;
  final double sunshineHoursPerYear;
  final int roofSegmentCount;
  final DateTime analysisDate;
  final String? imageryDate;
  
  // Calculated fields
  final int suitabilityScore;
  final String scoreExplanation;
  final String productionSummary;
  final int treesEquivalent;
  final List<String> keyInsights;
  
  // Financial data
  final double estimatedCost;
  final double afterTaxCredit;
  final double annualSavings;
  final double paybackYears;
  final double twentyFiveYearProfit;
  
  SolarData({
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.roofAreaM2,
    required this.maxPanels,
    required this.systemSizeKw,
    required this.annualProductionKwh,
    required this.sunshineHoursPerYear,
    required this.roofSegmentCount,
    required this.analysisDate,
    this.imageryDate,
    required this.suitabilityScore,
    required this.scoreExplanation,
    required this.productionSummary,
    required this.treesEquivalent,
    required this.keyInsights,
    required this.estimatedCost,
    required this.afterTaxCredit,
    required this.annualSavings,
    required this.paybackYears,
    required this.twentyFiveYearProfit,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'roofAreaM2': roofAreaM2,
      'maxPanels': maxPanels,
      'systemSizeKw': systemSizeKw,
      'annualProductionKwh': annualProductionKwh,
      'sunshineHoursPerYear': sunshineHoursPerYear,
      'roofSegmentCount': roofSegmentCount,
      'analysisDate': analysisDate.toIso8601String(),
      'imageryDate': imageryDate,
      'suitabilityScore': suitabilityScore,
      'scoreExplanation': scoreExplanation,
      'productionSummary': productionSummary,
      'treesEquivalent': treesEquivalent,
      'keyInsights': keyInsights,
      'estimatedCost': estimatedCost,
      'afterTaxCredit': afterTaxCredit,
      'annualSavings': annualSavings,
      'paybackYears': paybackYears,
      'twentyFiveYearProfit': twentyFiveYearProfit,
    };
  }
  
  factory SolarData.fromJson(Map<String, dynamic> json) {
    return SolarData(
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      roofAreaM2: json['roofAreaM2'],
      maxPanels: json['maxPanels'],
      systemSizeKw: json['systemSizeKw'],
      annualProductionKwh: json['annualProductionKwh'],
      sunshineHoursPerYear: json['sunshineHoursPerYear'],
      roofSegmentCount: json['roofSegmentCount'],
      analysisDate: DateTime.parse(json['analysisDate']),
      imageryDate: json['imageryDate'],
      suitabilityScore: json['suitabilityScore'],
      scoreExplanation: json['scoreExplanation'],
      productionSummary: json['productionSummary'],
      treesEquivalent: json['treesEquivalent'],
      keyInsights: List<String>.from(json['keyInsights']),
      estimatedCost: json['estimatedCost'],
      afterTaxCredit: json['afterTaxCredit'],
      annualSavings: json['annualSavings'],
      paybackYears: json['paybackYears'],
      twentyFiveYearProfit: json['twentyFiveYearProfit'],
    );
  }
}
