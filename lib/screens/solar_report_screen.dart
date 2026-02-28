import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/solar_data.dart';
import '../utils/download_helper.dart';
import 'ai_chat_screen.dart';
import 'quote_analyzer_screen.dart';

class SolarReportScreen extends StatefulWidget {
  final SolarData solarData;

  const SolarReportScreen({
    Key? key,
    required this.solarData,
  }) : super(key: key);

  @override
  State<SolarReportScreen> createState() => _SolarReportScreenState();
}

class _SolarReportScreenState extends State<SolarReportScreen> {
  GoogleMapController? _mapController;
  bool _isSavingPdf = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar Report'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        actions: [
          if (_isSavingPdf)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Save as PDF',
              onPressed: _generateAndSavePdf,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 3D Roof Map
            SizedBox(
              height: 250,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    widget.solarData.latitude,
                    widget.solarData.longitude,
                  ),
                  zoom: 20,
                  tilt: 45,
                ),
                mapType: MapType.satellite,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                markers: {
                  Marker(
                    markerId: const MarkerId('roof'),
                    position: LatLng(
                      widget.solarData.latitude,
                      widget.solarData.longitude,
                    ),
                  ),
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
              ),
            ),

            // Address
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.solarData.address,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const Divider(),

            // Suitability Score
            _SuitabilityCard(solarData: widget.solarData),

            // Solar Metrics Grid
            _MetricsGrid(solarData: widget.solarData),

            // Financial Summary
            _FinancialCard(solarData: widget.solarData),

            // Key Insights
            if (widget.solarData.keyInsights.isNotEmpty)
              _KeyInsightsCard(insights: widget.solarData.keyInsights),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    icon: _isSavingPdf 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.picture_as_pdf),
                    label: Text(_isSavingPdf ? 'Generating PDF...' : 'Save Solar Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSavingPdf ? null : _generateAndSavePdf,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.chat),
                    label: const Text('Ask AI Questions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AIChatScreen(
                            solarData: widget.solarData,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.document_scanner),
                    label: const Text('Analyze Installer Quote'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade600,
                      side: BorderSide(color: Colors.orange.shade600),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuoteAnalyzerScreen(
                            solarData: widget.solarData,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Helper to remove any characters that cause font errors in PDF
  String _cleanText(String text) {
    return text.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
  }

  Future<void> _generateAndSavePdf() async {
    setState(() => _isSavingPdf = true);

    try {
      final data = widget.solarData;
      final doc = pw.Document();
      final orange = PdfColor.fromHex('#E65100');
      final green = PdfColor.fromHex('#2E7D32');
      final grey = PdfColor.fromHex('#616161');
      final dateStr = DateFormat('MMMM d, yyyy').format(data.analysisDate);
      final address = _cleanText(data.address);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context ctx) => [
            // ── Header ──────────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: orange,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SolarFit Scout Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    address,
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
                  ),
                  pw.Text(
                    'Generated on $dateStr',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.white),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ── Suitability Score ────────────────────────────────────
            _pdfSectionTitle('SUITABILITY SCORE', orange),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${data.suitabilityScore} / 100',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: data.suitabilityScore > 75 ? green : orange,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(data.scoreExplanation,
                      style: pw.TextStyle(fontSize: 11, color: grey)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── Solar Metrics ────────────────────────────────────────
            _pdfSectionTitle('SOLAR METRICS', orange),
            pw.SizedBox(height: 8),
            _pdfTable([
              ['System Size', '${data.systemSizeKw.toStringAsFixed(1)} kW'],
              ['Max Panels', '${data.maxPanels} panels'],
              ['Annual Production', '${(data.annualProductionKwh / 1000).toStringAsFixed(1)} MWh'],
              ['Sunshine Hours', '${data.sunshineHoursPerYear.toStringAsFixed(0)} hrs/year'],
              ['Carbon Offset', '~ ${data.treesEquivalent} trees/year'],
              if (data.imageryDate != null) ['Imagery Date', data.imageryDate!],
            ]),
            pw.SizedBox(height: 16),

            // ── Financial Summary ────────────────────────────────────
            _pdfSectionTitle('FINANCIAL SUMMARY', orange),
            pw.SizedBox(height: 8),
            _pdfTable([
              ['Estimated System Cost', '\$${data.estimatedCost.toStringAsFixed(0)}'],
              ['After 30% Federal Tax Credit', '\$${data.afterTaxCredit.toStringAsFixed(0)}'],
              ['Annual Energy Savings', '\$${data.annualSavings.toStringAsFixed(0)}'],
              ['Payback Period', '${data.paybackYears.toStringAsFixed(1)} years'],
              ['25-Year Profit', '\$${data.twentyFiveYearProfit.toStringAsFixed(0)}'],
            ]),
            pw.SizedBox(height: 16),

            // ── Key Insights ─────────────────────────────────────────
            if (data.keyInsights.isNotEmpty) ...[  
              _pdfSectionTitle('KEY INSIGHTS', orange),
              pw.SizedBox(height: 8),
              ...data.keyInsights.map(
                (insight) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('- ',
                          style: pw.TextStyle(color: orange, fontSize: 12)),
                      pw.Expanded(
                        child: pw.Text(_cleanText(insight),
                            style: pw.TextStyle(fontSize: 11, color: grey)),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
            ],

            // ── Footer ───────────────────────────────────────────────
            pw.Divider(),
            pw.SizedBox(height: 6),
            pw.Text(
              'This report was generated by SolarFit Scout. Always consult a certified solar installer before making investment decisions.',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      final fileName = 'SolarFit_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (mounted) {
        if (kIsWeb) {
          // On Web, use direct browser download instead of share menu
          FileSaver.saveBytes(bytes, fileName);
        } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          // On Desktop, use file_picker to "Save As" directly
          String? outputFile = await FilePicker.platform.saveFile(
            dialogTitle: 'Save Solar Report',
            fileName: fileName,
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );

          if (outputFile != null) {
            final file = File(outputFile);
            await file.writeAsBytes(bytes);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report saved successfully!')),
              );
            }
          }
        } else {
          // On Mobile (Android/iOS), use the share sheet
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(bytes);

          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path, mimeType: 'application/pdf')],
              subject: 'SolarFit Scout Report – $address',
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingPdf = false);
    }
  }

  // ── PDF helper widgets ────────────────────────────────────────────

  pw.Widget _pdfSectionTitle(String title, PdfColor color) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: color,
        letterSpacing: 1.2,
      ),
    );
  }

  pw.Widget _pdfTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
      },
      children: rows.map((row) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: pw.Text(row[0],
                  style: const pw.TextStyle(fontSize: 11)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: pw.Text(
                row[1],
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _SuitabilityCard extends StatelessWidget {
  final SolarData solarData;

  const _SuitabilityCard({required this.solarData});

  @override
  Widget build(BuildContext context) {
    final score = solarData.suitabilityScore;
    final color = score > 75
        ? Colors.green
        : score > 50
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'SUITABILITY SCORE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '/100',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              solarData.scoreExplanation,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final SolarData solarData;

  const _MetricsGrid({required this.solarData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR SOLAR POTENTIAL',
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
                children: [
                  _MetricRow(
                    icon: Icons.solar_power,
                    label: 'System Size',
                    value: '${solarData.systemSizeKw.toStringAsFixed(1)} kW',
                  ),
                  const Divider(),
                  _MetricRow(
                    icon: Icons.bolt,
                    label: 'Annual Energy',
                    value: '${(solarData.annualProductionKwh / 1000).toStringAsFixed(1)} MWh',
                  ),
                  const Divider(),
                  _MetricRow(
                    icon: Icons.park,
                    label: 'Carbon Offset',
                    value: '${solarData.treesEquivalent} trees',
                  ),
                  const Divider(),
                  _MetricRow(
                    icon: Icons.grid_4x4,
                    label: 'Max Panels',
                    value: '${solarData.maxPanels} panels',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.orange.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialCard extends StatelessWidget {
  final SolarData solarData;

  const _FinancialCard({required this.solarData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FINANCIAL SNAPSHOT',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FinancialRow(
                    label: 'Estimated Cost',
                    value: '\$${solarData.estimatedCost.toStringAsFixed(0)}',
                    isBold: false,
                  ),
                  _FinancialRow(
                    label: 'After Tax Credit (30%)',
                    value: '\$${solarData.afterTaxCredit.toStringAsFixed(0)}',
                    isBold: true,
                    valueColor: Colors.green.shade700,
                  ),
                  const Divider(),
                  _FinancialRow(
                    label: 'Annual Savings',
                    value: '\$${solarData.annualSavings.toStringAsFixed(0)}',
                    isBold: false,
                  ),
                  _FinancialRow(
                    label: 'Payback Period',
                    value: '${solarData.paybackYears.toStringAsFixed(1)} years',
                    isBold: false,
                  ),
                  const Divider(),
                  _FinancialRow(
                    label: '25-Year Profit',
                    value: '\$${solarData.twentyFiveYearProfit.toStringAsFixed(0)}',
                    isBold: true,
                    valueColor: Colors.green.shade700,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _FinancialRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyInsightsCard extends StatelessWidget {
  final List<String> insights;

  const _KeyInsightsCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KEY INSIGHTS',
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
                children: insights.map((insight) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb,
                          size: 20,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            insight,
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
      ),
    );
  }
}
