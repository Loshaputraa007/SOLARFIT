import 'package:flutter/material.dart';
import '../models/solar_data.dart';
import '../models/quote_analysis.dart';
import '../services/gemini_service.dart';

class QuoteAnalyzerScreen extends StatefulWidget {
  final SolarData solarData;

  const QuoteAnalyzerScreen({
    Key? key,
    required this.solarData,
  }) : super(key: key);

  @override
  State<QuoteAnalyzerScreen> createState() => _QuoteAnalyzerScreenState();
}

class _QuoteAnalyzerScreenState extends State<QuoteAnalyzerScreen> {
  final TextEditingController _quoteController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  QuoteAnalysis? _analysis;
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _quoteController.dispose();
    super.dispose();
  }

  Future<void> _analyzeQuote() async {
    if (_quoteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter quote details')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysis = null;
    });

    try {
      final solarDataContext = {
        'systemSizeKw': widget.solarData.systemSizeKw.toStringAsFixed(1),
        'annualProductionKwh': widget.solarData.annualProductionKwh.toStringAsFixed(0),
        'estimatedCost': widget.solarData.estimatedCost,
        'optimalSystemKw': widget.solarData.systemSizeKw.toStringAsFixed(1),
        'annualUsageKwh': widget.solarData.annualProductionKwh.toStringAsFixed(0),
      };

      final analysis = await _geminiService.analyzeInstallerQuote(
        _quoteController.text,
        solarDataContext,
      );

      setState(() {
        _analysis = analysis;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Analyzer'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue.shade700, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI-Powered Fraud Detection',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Protect yourself from overpricing and predatory terms',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quote Input
            const Text(
              'Enter Installer Quote Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Paste the quote or enter key details: system size, price, financing terms',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _quoteController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Example:\n'
                    'System: 8kW\n'
                    'Price: \$28,000\n'
                    'Financing: 6.9% APR, 20 years\n'
                    'Panels: 400W each\n'
                    'Warranty: 25 years',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.orange.shade600,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Analyze Button
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeQuote,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.analytics),
              label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze with AI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            // Analysis Results
            if (_analysis != null) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // Verdict Header
              _VerdictHeader(verdict: _analysis!.overallVerdict),

              const SizedBox(height: 24),

              // Red Flags
              if (_analysis!.hasRedFlags) ...[
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(
                      '${_analysis!.redFlags.length} RED FLAGS DETECTED',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ..._analysis!.redFlags.map((flag) {
                  return _RedFlagCard(redFlag: flag);
                }).toList(),
              ] else ...[
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No Major Red Flags',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'This quote appears fair. Still ask the questions below to verify.',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Recommended Questions
              if (_analysis!.recommendedQuestions.isNotEmpty) ...[
                const Text(
                  'RECOMMENDED QUESTIONS TO ASK:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: _analysis!.recommendedQuestions.map((question) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.help_outline,
                                size: 20,
                                color: Colors.orange.shade600,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  question,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _VerdictHeader extends StatelessWidget {
  final String verdict;

  const _VerdictHeader({required this.verdict});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String title;
    String subtitle;

    switch (verdict.toUpperCase()) {
      case 'AVOID':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        title = 'AVOID THIS QUOTE';
        subtitle = 'Multiple serious red flags detected';
        break;
      case 'PROCEED_WITH_CAUTION':
      case 'CAUTION':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        icon = Icons.warning;
        title = 'PROCEED WITH CAUTION';
        subtitle = 'Some concerns found - ask questions before signing';
        break;
      case 'FAIR':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        icon = Icons.thumb_up;
        title = 'FAIR QUOTE';
        subtitle = 'Quote seems reasonable - still verify details';
        break;
      case 'GOOD':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.verified;
        title = 'GOOD QUOTE';
        subtitle = 'Competitive pricing and fair terms';
        break;
      default:
        bgColor = Colors.grey.shade50;
        textColor = Colors.grey.shade700;
        icon = Icons.info;
        title = 'ANALYSIS COMPLETE';
        subtitle = 'Review the findings below';
    }

    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RedFlagCard extends StatelessWidget {
  final RedFlag redFlag;

  const _RedFlagCard({required this.redFlag});

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;

    switch (redFlag.severity) {
      case 'high':
        borderColor = Colors.red.shade700;
        bgColor = Colors.red.shade50;
        break;
      case 'medium':
        borderColor = Colors.orange.shade700;
        bgColor = Colors.orange.shade50;
        break;
      default:
        borderColor = Colors.yellow.shade700;
        bgColor = Colors.yellow.shade50;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  redFlag.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    redFlag.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              redFlag.description,
              style: const TextStyle(fontSize: 14),
            ),
            if (redFlag.financialImpact != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: borderColor),
                    const SizedBox(width: 4),
                    Text(
                      redFlag.financialImpact!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: borderColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
