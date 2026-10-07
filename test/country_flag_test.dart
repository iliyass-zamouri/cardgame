import 'package:cardgame/data/ranking/ranking_api.dart';
import 'package:cardgame/ui/widgets/country_flag.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('flagEmoji maps codes and rejects invalid input', () {
    expect(flagEmoji('MA'), '🇲🇦');
    expect(flagEmoji('fr'), '🇫🇷');
    expect(flagEmoji(null), '');
    expect(flagEmoji('XYZ'), '');
    expect(flagEmoji('1A'), '');
  });

  test('RankingEntry parses countryCode', () {
    expect(RankingEntry.fromJson({'countryCode': 'US'}).countryCode, 'US');
    expect(RankingEntry.fromJson({}).countryCode, isNull);
  });
}
