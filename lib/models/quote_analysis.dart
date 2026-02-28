class QuoteAnalysis {
  final List<RedFlag> redFlags;
  final List<String> recommendedQuestions;
  final String overallVerdict;
  final DateTime analysisDate;
  
  QuoteAnalysis({
    required this.redFlags,
    required this.recommendedQuestions,
    required this.overallVerdict,
    required this.analysisDate,
  });
  
  factory QuoteAnalysis.fromJson(Map<String, dynamic> json) {
    return QuoteAnalysis(
      redFlags: (json['redFlags'] as List)
          .map((e) => RedFlag.fromJson(e))
          .toList(),
      recommendedQuestions: List<String>.from(json['questions'] ?? json['recommendedQuestions'] ?? []),
      overallVerdict: json['verdict'] ?? json['overallVerdict'] ?? 'UNKNOWN',
      analysisDate: DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'redFlags': redFlags.map((e) => e.toJson()).toList(),
      'recommendedQuestions': recommendedQuestions,
      'overallVerdict': overallVerdict,
      'analysisDate': analysisDate.toIso8601String(),
    };
  }
  
  bool get hasRedFlags => redFlags.isNotEmpty;
  
  int get highSeverityCount => 
      redFlags.where((f) => f.severity == 'high').length;
}

class RedFlag {
  final String severity; // high, medium, low
  final String icon;
  final String title;
  final String description;
  final String? financialImpact;
  
  RedFlag({
    required this.severity,
    required this.icon,
    required this.title,
    required this.description,
    this.financialImpact,
  });
  
  factory RedFlag.fromJson(Map<String, dynamic> json) {
    return RedFlag(
      severity: json['severity'] ?? 'medium',
      icon: json['icon'] ?? '⚠️',
      title: json['title'] ?? 'ISSUE DETECTED',
      description: json['description'] ?? '',
      financialImpact: json['financialImpact'] ?? json['impact'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'severity': severity,
      'icon': icon,
      'title': title,
      'description': description,
      'financialImpact': financialImpact,
    };
  }
}
