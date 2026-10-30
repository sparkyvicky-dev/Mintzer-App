import '../l10n/s.dart';

String formatInr(int n) {
  final sign = n < 0 ? '-' : '';
  final s = n.abs().toString();
  if (s.length <= 3) return '₹$sign$s';
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '₹$sign${parts.join(',')},$last3';
}

/// PAN records arrive in capitals. Show them as a normal name.
String personName(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return t;
  final letters = t.replaceAll(RegExp(r'[^A-Za-z]'), '');
  if (letters.isEmpty || letters != letters.toUpperCase()) return t;
  return t.split(RegExp(r'\s+')).map((word) {
    if (word.isEmpty) return word;
    final lower = word.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }).join(' ');
}

/// IST greeting — time-of-day only until PAN; then `Morning, FirstName`.
String homeGreeting(String name) {
  final h = _istHour();
  final n = name.trim();
  final withName = n.isNotEmpty;
  if (h >= 5 && h < 12) {
    if (withName) return S.t('home_hi_am', {'name': n});
    return S.e('Morning');
  }
  if (h >= 12 && h < 17) {
    if (withName) {
      // l10n-missing
      return 'Afternoon, $n';
    }
    return S.e('Afternoon');
  }
  if (h >= 17 && h < 22) {
    if (withName) return S.t('home_hi_pm', {'name': n});
    // l10n-missing
    return 'Evening';
  }
  if (h >= 22 || h < 5) {
    if (withName) {
      // l10n-missing
      return 'Night, $n';
    }
    return S.e('Night');
  }
  if (withName) return S.t('home_hi', {'name': n});
  // l10n-missing
  return 'Hi';
}

int _istHour() {
  final ist = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  return ist.hour;
}

/// One idle subtitle per Home open — pool by time of day (never timer-rotates).
String pickHomeIdleSub() {
  final h = _istHour();
  final pool = h >= 5 && h < 12
      ? kHomeSubsMorning
      : h >= 12 && h < 17
          ? kHomeSubsAfternoon
          : h >= 17 && h < 22
              ? kHomeSubsEvening
              : kHomeSubsNight;
  return pool[DateTime.now().microsecond % pool.length];
}

const kHomeSubsMorning = [
  'You woke up. Rare.',
  'Card to cash. Free.',
  'Chai first. Then this.',
  'The bed lost.',
  'Points stay. Cash too.',
  'Too early for big plans.',
  'Alarm did its job.',
  'Turn limit into bank',
  'Sun\'s up. You\'re up.',
  'Coffee owes you one.',
  'Order more. Limits rise.',
  'Snooze lost this round.',
  'Morning hair. Live deals.',
  'Swipe. Cash comes back.',
  'The day is still innocent.',
  'Blink. You\'re already here.',
  'No fee. Real cash.',
  'This hour is for the brave.',
  'Soft light. Sharp card.',
  'Bank points, plus cash',
  'You vs the blanket.',
  'Early. The good kind.',
  'More orders, more limit',
  'Deals don\'t do mornings. You do.',
  'Start before the chaos.',
];

const kHomeSubsAfternoon = [
  'Post-lunch courage. Fake.',
  'Limit out. Cash in.',
  'Midday energy is a rumor.',
  'Lunch can wait one deal.',
  'Card points. Wallet cash.',
  'The slump is undefeated.',
  'Halfway. Still here.',
  'Easy. Limit to bank.',
  'Rice coma. Card ready.',
  'Nobody\'s watching. Perfect.',
  'Use it. Limits follow.',
  'The meeting can wait.',
  'Stomach full. Ideas empty.',
  'Spend there. Cash here.',
  'This hour needs a small win.',
  'Blink and it\'s evening.',
  'Conversion is free',
  'Work face. Home brain.',
  'Snacks are a strategy.',
  'Points on every swipe',
  'The long part of the day.',
  'One tab. Then back.',
  'Another order, more room',
  'The afternoon waved first.',
  'You opened this on purpose.',
];

const kHomeSubsEvening = [
  'Traffic\'s bad. This isn\'t.',
  'Tonight\'s swipe, as cash',
  'The sofa is calling.',
  'You survived the day.',
  'Reward points, untouched',
  'Shoes off. Card out.',
  'The group chat can wait.',
  'Limit into the bank',
  'Evening energy is a myth.',
  'Dinner can start after.',
  'Orders up. Limits up.',
  'The sun clocked out.',
  'Prime time for a tiny win.',
  'Free to turn it to cash',
  'Work ended. You didn\'t.',
  'Lights low. Deals up.',
  'Card in. Wallet up.',
  'One deal. Then the couch.',
  'Today was long. This is short.',
  'Points stack on the spend',
  'The day quit. You didn\'t.',
  'Home. Finally.',
  'Keep the card moving',
  'Nothing else after this.',
  'Evening. You made it.',
];

const kHomeSubsNight = [
  'Still up. Respect.',
  'Late swipe. Still cash.',
  'Sleep is winning. Barely.',
  'The ceiling fan knows.',
  'Points count at night',
  'Bed is right there.',
  'This hour is unofficial.',
  'From limit to bank',
  'Night owl, or just stuck?',
  'Everyone\'s asleep but you.',
  'Order. Limit. Repeat.',
  'The phone glow suits you.',
  'Tomorrow can start later.',
  'Card to cash. Still free.',
  'Quiet house. You\'re not.',
  'Late ideas. Questionable.',
  'No fee at this hour',
  'One glance. Then sleep.',
  'The night shift is you.',
  'Unused limit can move',
  'Bold of you to be awake.',
  'Deals don\'t have a bedtime.',
  'Both points and cash',
  'Lights out after this.',
  'You and the dark. That\'s it.',
];

/// @Deprecated — use [pickHomeIdleSub]
const kHomeIdleSubs = kHomeSubsAfternoon;
