/// Mock IFSC → bank / branch. Live: Razorpay / Cashfree / NPCI lookup later.
({String bank, String branch})? lookupIfsc(String raw) {
  final ifsc = raw.trim().toUpperCase().replaceAll(' ', '');
  if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) return null;
  final code = ifsc.substring(0, 4);
  final bank = _banks[code];
  if (bank == null) return null;
  // Mock branch label — backend returns real branch from IFSC master.
  final branch = switch (code) {
    'BARB' => 'Kumbakonam Branch',
    'HDFC' => 'MG Road Branch',
    'ICIC' => 'Andheri East Branch',
    'SBIN' => 'Local Head Office Branch',
    'UTIB' => 'Koramangala Branch',
    'KKBK' => 'Bandra West Branch',
    _ => 'Main Branch',
  };
  return (bank: bank, branch: branch);
}

const _banks = <String, String>{
  'SBIN': 'State Bank of India',
  'BARB': 'Bank of Baroda',
  'BKID': 'Bank of India',
  'MAHB': 'Bank of Maharashtra',
  'CNRB': 'Canara Bank',
  'CBIN': 'Central Bank of India',
  'IDIB': 'Indian Bank',
  'IOBA': 'Indian Overseas Bank',
  'PSIB': 'Punjab & Sind Bank',
  'PUNB': 'Punjab National Bank',
  'UCBA': 'UCO Bank',
  'UBIN': 'Union Bank of India',
  'UTIB': 'Axis Bank',
  'BDBL': 'Bandhan Bank',
  'CSBK': 'CSB Bank',
  'CIUB': 'City Union Bank',
  'DCBL': 'DCB Bank',
  'DLXB': 'Dhanlaxmi Bank',
  'FDRL': 'Federal Bank',
  'HDFC': 'HDFC Bank',
  'ICIC': 'ICICI Bank',
  'IBKL': 'IDBI Bank',
  'IDFB': 'IDFC First Bank',
  'INDB': 'IndusInd Bank',
  'JAKA': 'Jammu & Kashmir Bank',
  'KARB': 'Karnataka Bank',
  'KVBL': 'Karur Vysya Bank',
  'KKBK': 'Kotak Mahindra Bank',
  'NTBL': 'Nainital Bank',
  'RATN': 'RBL Bank',
  'SIBL': 'South Indian Bank',
  'TMBL': 'Tamilnad Mercantile Bank',
  'YESB': 'Yes Bank',
  'AUBL': 'AU Small Finance Bank',
  'ESAF': 'ESAF Small Finance Bank',
  'EQUI': 'Equitas Small Finance Bank',
  'JSFB': 'Jana Small Finance Bank',
  'SURY': 'Suryoday Small Finance Bank',
  'UJVN': 'Ujjivan Small Finance Bank',
  'UTKS': 'Utkarsh Small Finance Bank',
  'AIRP': 'Airtel Payments Bank',
  'IPOS': 'India Post Payments Bank',
  'FINO': 'Fino Payments Bank',
  'JIOP': 'Jio Payments Bank',
  'PYTM': 'Paytm Payments Bank',
  'NSPB': 'NSDL Payments Bank',
  'CITI': 'Citibank',
  'DBSS': 'DBS Bank India',
  'DEUT': 'Deutsche Bank',
  'HSBC': 'HSBC',
  'SCBL': 'Standard Chartered Bank',
};
