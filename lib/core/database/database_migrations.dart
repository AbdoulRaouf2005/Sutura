/// Déclarations de schéma et migrations SQLite.
///
/// Le schéma suit le cahier des charges §5. Les migrations sont versionnées
/// via le numéro de version de la base (`app_database.dart`).
abstract final class DatabaseMigrations {
  /// Version courante du schéma.
  static const int schemaVersion = 1;

  /// Migrations indexées par version cible : `migrations[n]` s'exécute pour
  /// passer de la version `n - 1` à la version `n`.
  static const Map<int, List<String>> byVersion = <int, List<String>>{
    1: <String>[
      _createClients,
      _createMeasurementSets,
      _createMeasurements,
      _createGarmentModels,
      _createOrders,
      _createPayments,
      ..._createIndexes,
    ],
  };

  static const String _createClients = '''
CREATE TABLE clients (
  id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  phone TEXT NULL,
  notes TEXT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  is_archived INTEGER NOT NULL DEFAULT 0
)
''';

  static const String _createMeasurementSets = '''
CREATE TABLE measurement_sets (
  id TEXT PRIMARY KEY,
  client_id TEXT NOT NULL,
  garment_type TEXT NOT NULL,
  notes TEXT NULL,
  measured_at TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (client_id) REFERENCES clients (id)
)
''';

  static const String _createMeasurements = '''
CREATE TABLE measurements (
  id TEXT PRIMARY KEY,
  measurement_set_id TEXT NOT NULL,
  name TEXT NOT NULL,
  value REAL NOT NULL,
  unit TEXT NOT NULL DEFAULT 'cm',
  FOREIGN KEY (measurement_set_id) REFERENCES measurement_sets (id)
)
''';

  static const String _createGarmentModels = '''
CREATE TABLE garment_models (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NULL,
  description TEXT NULL,
  local_image_path TEXT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  is_archived INTEGER NOT NULL DEFAULT 0
)
''';

  static const String _createOrders = '''
CREATE TABLE orders (
  id TEXT PRIMARY KEY,
  client_id TEXT NOT NULL,
  garment_model_id TEXT NULL,
  model_name_snapshot TEXT NULL,
  model_image_snapshot_path TEXT NULL,
  measurement_set_id TEXT NULL,
  description TEXT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  total_price INTEGER NOT NULL,
  delivery_at TEXT NOT NULL,
  status TEXT NOT NULL,
  notes TEXT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (client_id) REFERENCES clients (id),
  FOREIGN KEY (garment_model_id) REFERENCES garment_models (id),
  FOREIGN KEY (measurement_set_id) REFERENCES measurement_sets (id)
)
''';

  static const String _createPayments = '''
CREATE TABLE payments (
  id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL,
  amount INTEGER NOT NULL,
  paid_at TEXT NOT NULL,
  method TEXT NULL,
  note TEXT NULL,
  FOREIGN KEY (order_id) REFERENCES orders (id)
)
''';

  static const List<String> _createIndexes = <String>[
    'CREATE INDEX idx_clients_name ON clients (full_name)',
    'CREATE INDEX idx_clients_phone ON clients (phone)',
    'CREATE INDEX idx_measurement_sets_client ON measurement_sets (client_id)',
    'CREATE INDEX idx_measurements_set ON measurements (measurement_set_id)',
    'CREATE INDEX idx_orders_client ON orders (client_id)',
    'CREATE INDEX idx_orders_delivery ON orders (delivery_at)',
    'CREATE INDEX idx_orders_status ON orders (status)',
    'CREATE INDEX idx_payments_order ON payments (order_id)',
  ];
}
