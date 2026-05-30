// ignore_for_file: constant_identifier_names

import 'package:flutter/widgets.dart';

/// Subset of SF Symbols 6 icons vendored from flutter_cupertino_symbols
/// to avoid dependency issues while maintaining precise iOS 26 demo aesthetics.
///
/// If a new icon is needed, copy the SFSymbols.ttf file and add the mapping here.
class SFSymbols {
  SFSymbols._();

  static const IconData bubble_left_and_bubble_right =
      IconData(2565, fontFamily: 'SFSymbols', fontPackage: null);
  static const IconData checkmark =
      IconData(2020, fontFamily: 'SFSymbols', fontPackage: null);
  static const IconData checkmark_circle =
      IconData(2010, fontFamily: 'SFSymbols', fontPackage: null);
  static const IconData chevron_right =
      IconData(1946, fontFamily: 'SFSymbols', fontPackage: null);
  static const IconData line_horizontal_3_decrease =
      IconData(64838, fontFamily: 'SFSymbols', fontPackage: null);
  static const IconData person_crop_circle =
      IconData(64056, fontFamily: 'SFSymbols', fontPackage: null);
  static const IconData person_fill =
      IconData(64010, fontFamily: 'SFSymbols', fontPackage: null);
  static const IconData pin =
      IconData(63844, fontFamily: 'SFSymbols', fontPackage: null);
  static const IconData square_and_pencil =
      IconData(62794, fontFamily: 'SFSymbols', fontPackage: null);
  static const IconData trash =
      IconData(62185, fontFamily: 'SFSymbols', fontPackage: null);
  static const IconData xmark_bin =
      IconData(61757, fontFamily: 'SFSymbols', fontPackage: null);
}
