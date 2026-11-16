import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/clients/screens/client_detail_screen.dart';
import '../features/clients/screens/client_form_screen.dart';
import '../features/clients/screens/clients_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/gallery/screens/gallery_screen.dart';
import '../features/gallery/screens/garment_model_form_screen.dart';
import '../features/measurements/screens/measurement_detail_screen.dart';
import '../features/measurements/screens/measurement_form_screen.dart';
import '../features/measurements/screens/measurements_list_screen.dart';
import '../features/orders/screens/order_detail_screen.dart';
import '../features/orders/screens/order_form_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/payments/screens/payments_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import 'app_shell.dart';

/// Configuration de la navigation — `StatefulShellRoute` à quatre branches
/// persistantes (guide §6). Les routes des écrans détaillés (mensurations,
/// galerie, commandes, paiements) seront ajoutées au fur et à mesure.
abstract final class AppRouter {
  /// Clé de navigation racine utilisée pour les routes hors coquille.
  static final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>(
    debugLabel: 'root',
  );

  /// Instance du routeur principal de l'application.
  static final GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/accueil',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell shell,
        ) => AppShell(navigationShell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/accueil',
                builder: (_, _) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/clients',
                builder: (_, _) => const ClientsScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'nouveau',
                    builder: (_, _) => const ClientFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, GoRouterState state) => ClientDetailScreen(
                      clientId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: ':id/modifier',
                    builder: (_, GoRouterState state) =>
                        ClientFormScreen(clientId: state.pathParameters['id']),
                  ),
                  GoRoute(
                    path: ':id/mensurations',
                    builder: (_, GoRouterState state) => MeasurementsListScreen(
                      clientId: state.pathParameters['id']!,
                    ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'nouveau',
                        builder: (_, GoRouterState state) =>
                            MeasurementFormScreen(
                              clientId: state.pathParameters['id']!,
                            ),
                      ),
                      GoRoute(
                        path: ':setId',
                        builder: (_, GoRouterState state) =>
                            MeasurementDetailScreen(
                              clientId: state.pathParameters['id']!,
                              setId: state.pathParameters['setId']!,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/commandes',
                builder: (_, _) => const OrdersScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'nouvelle',
                    builder: (_, GoRouterState state) => OrderFormScreen(
                      preselectedClientId:
                          state.uri.queryParameters['clientId'],
                    ),
                  ),
                  GoRoute(
                    path: ':orderId',
                    builder: (_, GoRouterState state) => OrderDetailScreen(
                      orderId: state.pathParameters['orderId']!,
                    ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'modifier',
                        builder: (_, GoRouterState state) => OrderFormScreen(
                          orderId: state.pathParameters['orderId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'paiements',
                        builder: (_, GoRouterState state) => PaymentsScreen(
                          orderId: state.pathParameters['orderId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/reglages',
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/galerie',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const GalleryScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'nouveau',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const GarmentModelFormScreen(),
          ),
          GoRoute(
            path: ':modelId/modifier',
            parentNavigatorKey: _rootKey,
            builder: (_, GoRouterState state) => GarmentModelFormScreen(
              modelId: state.pathParameters['modelId'],
            ),
          ),
        ],
      ),
    ],
  );
}
