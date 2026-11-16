import 'package:uuid/uuid.dart';

/// Génération d'identifiants stables (UUID v4) — cahier des charges §5.
/// Instance partagée du générateur UUID.
const Uuid _uuid = Uuid();

/// Génère et retourne un nouvel identifiant unique (UUID v4).
String newId() => _uuid.v4();
