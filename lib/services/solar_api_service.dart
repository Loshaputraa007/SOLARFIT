import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../config.dart';

class SolarApiService {
  Future<Map<String, dynamic>> getBuildingInsights(
    double latitude, 
    double longitude
  ) async {
    final url = Uri.parse(
      '${AppConfig.solarApiBaseUrl}/buildingInsights:findClosest?'
      'location.latitude=$latitude&'
      'location.longitude=$longitude&'
      'requiredQuality=HIGH&'
      'key=${AppConfig.solarApiKey}'
    );
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('No solar data available for this location. Try a different address.');
      } else {
        throw Exception('Solar API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  Map<String, dynamic> extractSolarMetrics(
    Map<String, dynamic> rawData, {
    double monthlyElectricityBill = 150.0,
  }) {
    try {
      final solarPotential = rawData['solarPotential'];
      final maxArrayPanels = solarPotential['maxArrayPanelsCount'] as int? ?? 0;
      final panelCapacityWatts =
          (solarPotential['panelCapacityWatts'] ?? AppConfig.averagePanelWattage)
              .toDouble();

      // solarPanelConfigs is ordered ASCENDING by panelsCount.
      // The LAST entry = maximum panels the roof can physically support.
      final configs = solarPotential['solarPanelConfigs'] as List? ?? [];

      // Residential cap: 20 kW max (most homes don't need more).
      // 20,000 W ÷ panelCapacityWatts = max reasonable panels.
      final maxResidentialPanels =
          (20000 / panelCapacityWatts).round().clamp(1, maxArrayPanels);

      int selectedPanels = 0;
      double annualProductionKwh = 0;

      if (configs.isNotEmpty) {
        // Walk through configs to find the largest one within our residential cap.
        // Because configs are ascending, we iterate and stop when we exceed the cap.
        Map<String, dynamic>? selectedConfig;

        for (final config in configs) {
          final panelCount = config['panelsCount'] as int? ?? 0;
          if (panelCount <= maxResidentialPanels) {
            selectedConfig = config;
          } else {
            break; // configs are ascending — no point checking further
          }
        }

        // If no config fits under the cap (very small roof), just use the smallest config
        selectedConfig ??= configs.first;

        selectedPanels = selectedConfig?['panelsCount'] as int? ?? maxResidentialPanels;
        annualProductionKwh =
            (selectedConfig?['yearlyEnergyDcKwh'])?.toDouble() ?? 0;
      }

      // Safety: never exceed what the roof physically supports
      selectedPanels = min(selectedPanels, maxArrayPanels);

      // System size in kW
      final systemSizeKw = (selectedPanels * panelCapacityWatts) / 1000;

      // Fallback: estimate from sunshine hours if API gives no production figure
      if (annualProductionKwh == 0) {
        final sunshineHours =
            solarPotential['maxSunshineHoursPerYear']?.toDouble() ?? 1500;
        // DC-to-AC derate factor ~0.80 (inverter losses, wiring, temperature etc.)
        annualProductionKwh = systemSizeKw * sunshineHours * 0.80;
      }

      // Carbon offset: use API factor if present, else 0.4 kg CO2/kWh (global average)
      final carbonOffsetKgPerMwh =
          (solarPotential['carbonOffsetFactorKgPerMwh'] ?? 400).toDouble();
      final annualCarbonOffsetKg =
          annualProductionKwh * carbonOffsetKgPerMwh / 1000;

      // Trees equivalent: one tree absorbs ~21 kg CO2/year
      final treesEquivalent = (annualCarbonOffsetKg / 21).round();

      // Extract imagery date
      String? imageryDate;
      if (rawData['imageryDate'] != null) {
        final date = rawData['imageryDate'];
        imageryDate =
            '${date['year']}-${date['month'].toString().padLeft(2, '0')}-${date['day'].toString().padLeft(2, '0')}';
      }

      return {
        'roofAreaM2': (solarPotential['maxArrayAreaMeters2'] ?? 0).toDouble(),
        'maxPanels': selectedPanels,
        'maxRoofPanels': maxArrayPanels,
        'systemSizeKw': systemSizeKw,
        'annualProductionKwh': annualProductionKwh,
        'sunshineHoursPerYear':
            (solarPotential['maxSunshineHoursPerYear'] ?? 0).toDouble(),
        'carbonOffsetKg': annualCarbonOffsetKg,
        'treesEquivalent': treesEquivalent,
        'roofSegmentCount':
            (solarPotential['roofSegmentStats']?.length ?? 1),
        'imageryDate': imageryDate,
        'panelCapacityWatts': panelCapacityWatts,
      };
    } catch (e) {
      throw Exception('Error parsing solar data: $e');
    }
  }

  int calculateSuitabilityScore(Map<String, dynamic> metrics) {
    int score = 0;

    // Roof capacity scoring (max 40 pts) — based on total roof potential
    final maxRoofPanels =
        (metrics['maxRoofPanels'] ?? metrics['maxPanels']) as int;
    score += min(40, (maxRoofPanels / 30 * 40).round());

    // Sunshine hours scoring (max 40 pts)
    final sunshineHours = metrics['sunshineHoursPerYear'] as double;
    score += min(40, (sunshineHours / 2000 * 40).round());

    // Roof complexity scoring (max 20 pts)
    final roofSegments = metrics['roofSegmentCount'] as int;
    if (roofSegments <= 2) {
      score += 20;
    } else if (roofSegments <= 4) {
      score += 15;
    } else {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  Map<String, dynamic> calculateFinancials(
    Map<String, dynamic> metrics,
    double monthlyElectricityBill,
  ) {
    final systemSizeKw = metrics['systemSizeKw'] as double;
    final annualProductionKwh = metrics['annualProductionKwh'] as double;

    // Derive electricity rate from the user's actual bill.
    // Assume average household uses electricity based on $0.15/kWh default.
    // This gives a reasonable per-kWh value to price the solar output.
    const electricityRate = AppConfig.defaultElectricityRate; // $/kWh

    // System installation cost (before incentives)
    final estimatedCost = systemSizeKw * 1000 * AppConfig.pricePerWatt;

    // After 30% federal ITC
    final afterTaxCredit = estimatedCost * (1 - AppConfig.federalTaxCredit);

    // Annual savings = full value of electricity produced.
    // Solar either offsets usage (saving you the retail rate) or
    // is sold back via net metering — either way you capture the full value.
    final annualSavings = annualProductionKwh * electricityRate;

    // Payback period (years to recoup the after-ITC cost from savings)
    final paybackYears =
        annualSavings > 0 ? afterTaxCredit / annualSavings : 99.0;

    // 25-year total profit with 0.5%/year panel degradation
    double totalSavings = 0;
    for (int year = 1; year <= AppConfig.systemLifespanYears; year++) {
      final degradationFactor = pow(0.995, year - 1);
      totalSavings += annualSavings * degradationFactor;
    }
    final twentyFiveYearProfit = totalSavings - afterTaxCredit;

    return {
      'estimatedCost': estimatedCost,
      'afterTaxCredit': afterTaxCredit,
      'annualSavings': annualSavings,
      'paybackYears': paybackYears,
      'twentyFiveYearProfit': twentyFiveYearProfit,
      'electricityRate': electricityRate,
    };
  }
}
