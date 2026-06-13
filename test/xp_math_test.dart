import 'package:flutter_test/flutter_test.dart';
import 'package:operator_os/core/constants.dart';

void main() {
  group('xpForLevel', () {
    test('L2 = 200', () => expect(XpConfig.xpForLevel(2), 200));
    test('L3 = 450', () => expect(XpConfig.xpForLevel(3), 450));
    test('L4 = 800', () => expect(XpConfig.xpForLevel(4), 800));
    test('L5 = 1250', () => expect(XpConfig.xpForLevel(5), 1250));
    test('L10 = 5000', () => expect(XpConfig.xpForLevel(10), 5000));
    test('L15 = 11250', () => expect(XpConfig.xpForLevel(15), 11250));
  });

  group('levelForXp', () {
    test('0 XP = L1', () => expect(XpConfig.levelForXp(0), 1));
    test('199 XP = L1', () => expect(XpConfig.levelForXp(199), 1));
    test('200 XP = L2', () => expect(XpConfig.levelForXp(200), 2));
    test('449 XP = L2', () => expect(XpConfig.levelForXp(449), 2));
    test('450 XP = L3', () => expect(XpConfig.levelForXp(450), 3));
    test('799 XP = L3', () => expect(XpConfig.levelForXp(799), 3));
    test('800 XP = L4', () => expect(XpConfig.levelForXp(800), 4));
    test('1249 XP = L4', () => expect(XpConfig.levelForXp(1249), 4));
    test('1250 XP = L5', () => expect(XpConfig.levelForXp(1250), 5));
    test('3149 XP = L7', () => expect(XpConfig.levelForXp(3149), 7));
    test('3200 XP = L8', () => expect(XpConfig.levelForXp(3200), 8));
    test('4999 XP = L9', () => expect(XpConfig.levelForXp(4999), 9));
    test('5000 XP = L10', () => expect(XpConfig.levelForXp(5000), 10));
    test('11249 XP = L14', () => expect(XpConfig.levelForXp(11249), 14));
    test('11250 XP = L15', () => expect(XpConfig.levelForXp(11250), 15));
  });

  group('tierForLevel', () {
    test('L1 -> T1', () => expect(XpConfig.tierForLevel(1), 1));
    test('L2 -> T1', () => expect(XpConfig.tierForLevel(2), 1));
    test('L3 -> T2', () => expect(XpConfig.tierForLevel(3), 2));
    test('L4 -> T2', () => expect(XpConfig.tierForLevel(4), 2));
    test('L5 -> T2', () => expect(XpConfig.tierForLevel(5), 2));
    test('L6 -> T3', () => expect(XpConfig.tierForLevel(6), 3));
    test('L8 -> T3', () => expect(XpConfig.tierForLevel(8), 3));
    test('L9 -> T3', () => expect(XpConfig.tierForLevel(9), 3));
    test('L10 -> T4', () => expect(XpConfig.tierForLevel(10), 4));
    test('L15 -> T4', () => expect(XpConfig.tierForLevel(15), 4));
  });
}
