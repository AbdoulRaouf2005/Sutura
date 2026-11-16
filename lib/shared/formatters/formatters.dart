import 'package:intl/intl.dart';

/// Formatage des dates et montants (§10).
///
/// La locale d'affichage est le français ; on initialise les formats via des
/// instances explicites pour éviter de dépendre de l'initialisation globale.
abstract final class Formatters {
  /// Format de date courte, sans heure.
  static final DateFormat _dayFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

  /// Format de date et d'heure combinées.
  static final DateFormat _dateTimeFormat = DateFormat(
    'dd/MM/yyyy à HH:mm',
    'fr_FR',
  );

  /// Date au format court français : `20/10/2026`.
  static String date(DateTime value) => _dayFormat.format(value);

  /// Date et heure.
  static String dateTime(DateTime value) => _dateTimeFormat.format(value);

  /// Montant en FCFA, sans décimales, séparateur de milliers : `1 200 FCFA`.
  static String money(int amount, {String currency = 'FCFA'}) {
    final NumberFormat format = NumberFormat('#,##0', 'fr_FR');
    // L'espace fine insécable du format français est remplacée par une
    // espace normale pour un rendu homogène.
    return '${format.format(amount).replaceAll('\u202F', ' ')} $currency';
  }

  /// Valeur de mensuration : `92 cm`.
  ///
  /// [unit] est ajoutée telle quelle (par exemple `cm`).
  static String measurement(double value, String unit) {
    final NumberFormat format = NumberFormat('#,##0.##', 'fr_FR');
    return '${format.format(value)} $unit';
  }
}
