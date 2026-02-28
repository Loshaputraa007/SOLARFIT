class AppConfig {
  // Replace with your actual API keys
  static const String solarApiKey = 'AIzaSyB_0fmpsszvACYEs5LWBxbDF4gzbn_s1a8';
  static const String geminiApiKey = 'AIzaSyDiLpSt1MQUyUtvl1albAODz04NNTyun70';
  static const String mapsApiKey = 'AIzaSyB_0fmpsszvACYEs5LWBxbDF4gzbn_s1a8';
  
  // API Endpoints
  static const String solarApiBaseUrl = 'https://solar.googleapis.com/v1';
  
  // App Constants
  static const double defaultElectricityRate = 0.15; // $0.15/kWh default
  static const double federalTaxCredit = 0.30; // 30% ITC
  static const int systemLifespanYears = 25;
  static const double averagePanelWattage = 400.0; // 400W panels
  static const double pricePerWatt = 2.73; // Market rate $/watt
  
  // Free Tier Limits (for demo purposes)
  static const int solarApiMonthlyLimit = 10000;
  static const int geminiDailyLimit = 1500;
}
