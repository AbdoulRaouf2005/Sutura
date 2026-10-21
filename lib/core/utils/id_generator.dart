import 'package:uuid/uuid.dart';

/// Génération d'identifiants stables (UUID v4) — cahier des charges §5.
const Uuid _uuid = Uuid();

String newId() => _uuid.v4();
