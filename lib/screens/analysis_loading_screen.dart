import 'package:flutter/material.dart';
import '../services/solar_api_service.dart';
import '../services/gemini_service.dart';
import '../models/solar_data.dart';
import 'solar_report_screen.dart';

class AnalysisLoadingScreen extends StatefulWidget {
  final String address;
  final double latitude;
  final double longitude;

  const AnalysisLoadingScreen({
    Key? key,
    required this.address,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  State<AnalysisLoadingScreen> createState() => _AnalysisLoadingScreenState();
}

class _AnalysisLoadingScreenState extends State<AnalysisLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final SolarApiService _solarService = SolarApiService();
  final GeminiService _geminiService = GeminiService();

  String _currentStep = 'Fetching 3D building model...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _analyzeRoof();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _analyzeRoof() async {
    try {
      // Step 1: Fetch building insights
      setState(() {
        _currentStep = 'Fetching 3D building model...';
        _progress = 0.2;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      final rawData = await _solarService.getBuildingInsights(
        widget.latitude,
        widget.longitude,
      );

      // Step 2: Extract metrics
      setState(() {
        _currentStep = 'Calculating sun exposure...';
        _progress = 0.4;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      // Step 3: Get user's electricity bill (for now, use default)
      // In production, prompt user for this
      final monthlyBill = 150.0; // Default $150/month
      final metrics = _solarService.extractSolarMetrics(rawData, monthlyElectricityBill: monthlyBill);
      final suitabilityScore = _solarService.calculateSuitabilityScore(metrics);

      final financials = _solarService.calculateFinancials(metrics, monthlyBill);

      // Step 4: Generate AI report
      setState(() {
        _currentStep = 'Generating personalized report with AI...';
        _progress = 0.7;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      final aiReport = await _geminiService.generateSolarReport(
        metrics,
        financials,
      );

      // Step 5: Complete
      setState(() {
        _currentStep = 'Complete!';
        _progress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to report
      if (mounted) {
        final solarData = SolarData(
          address: widget.address,
          latitude: widget.latitude,
          longitude: widget.longitude,
          roofAreaM2: (metrics['roofAreaM2'] as num).toDouble(),
          maxPanels: metrics['maxPanels'] as int,
          systemSizeKw: (metrics['systemSizeKw'] as num).toDouble(),
          annualProductionKwh: (metrics['annualProductionKwh'] as num).toDouble(),
          sunshineHoursPerYear: (metrics['sunshineHoursPerYear'] as num).toDouble(),
          roofSegmentCount: metrics['roofSegmentCount'] as int,
          analysisDate: DateTime.now(),
          imageryDate: metrics['imageryDate'] as String?,
          suitabilityScore: (aiReport['suitabilityScore'] as num?)?.toInt() ?? suitabilityScore,
          scoreExplanation: aiReport['scoreExplanation'] as String? ?? 'Your roof has good solar potential.',
          productionSummary: aiReport['productionSummary'] as String? ?? 'Generates significant clean energy.',
          treesEquivalent: (aiReport['treesEquivalent'] as num?)?.toInt() ?? (metrics['treesEquivalent'] as int? ?? 50),
          keyInsights: List<String>.from(aiReport['keyInsights'] as List? ?? []),
          estimatedCost: (financials['estimatedCost'] as num).toDouble(),
          afterTaxCredit: (financials['afterTaxCredit'] as num).toDouble(),
          annualSavings: (financials['annualSavings'] as num).toDouble(),
          paybackYears: (financials['paybackYears'] as num).toDouble(),
          twentyFiveYearProfit: (financials['twentyFiveYearProfit'] as num).toDouble(),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SolarReportScreen(solarData: solarData),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentStep = 'Error: ${e.toString()}';
        });

        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Analysis Error'),
            content: Text(
              e.toString().contains('404')
                  ? 'No solar data available for this location. Try a different address.'
                  : 'Failed to analyze roof: ${e.toString()}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to search
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Solar Icon
              RotationTransition(
                turns: _animationController,
                child: Icon(
                  Icons.wb_sunny,
                  size: 100,
                  color: Colors.orange.shade600,
                ),
              ),

              const SizedBox(height: 48),

              const Text(
                'Analyzing your roof with AI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.orange.shade600,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                '${(_progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 32),

              // Current Step
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (!_currentStep.startsWith('Error'))
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange.shade600,
                          ),
                        ),
                      )
                    else
                      Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _currentStep,
                        style: TextStyle(
                          fontSize: 14,
                          color: _currentStep.startsWith('Error')
                              ? Colors.red.shade700
                              : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Steps Checklist
              _StepItem(
                icon: Icons.satellite_alt,
                text: 'Fetching 3D building model',
                isComplete: _progress > 0.2,
              ),
              const SizedBox(height: 12),
              _StepItem(
                icon: Icons.wb_sunny,
                text: 'Calculating sun exposure',
                isComplete: _progress > 0.4,
              ),
              const SizedBox(height: 12),
              _StepItem(
                icon: Icons.auto_awesome,
                text: 'Generating AI insights',
                isComplete: _progress > 0.7,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isComplete;

  const _StepItem({
    required this.icon,
    required this.text,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isComplete ? Icons.check_circle : icon,
          color: isComplete ? Colors.green.shade600 : Colors.grey.shade400,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isComplete ? Colors.grey.shade800 : Colors.grey.shade500,
              decoration: isComplete ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ],
    );
  }
}
