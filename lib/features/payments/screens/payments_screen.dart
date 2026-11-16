import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/repositories/order_repository.dart';
import '../../../core/repositories/payment_repository.dart';
import '../../../core/state/data_controller.dart';
import '../../../core/state/data_events_listener.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/id_generator.dart';
import '../../../shared/formatters/formatters.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../orders/models/order.dart';
import '../models/payment.dart';

/// Écran de gestion des paiements d'une commande : liste, ajout,
/// total payé et solde (§4.6).
class PaymentsScreen extends StatefulWidget {
  /// Crée l'écran des paiements pour la commande [orderId].
  const PaymentsScreen({super.key, required this.orderId});

  /// Identifiant de la commande concernée.
  final String orderId;

  /// Crée l'état associé à cet écran.
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

/// État de [PaymentsScreen] gérant le chargement et les actions sur les paiements.
class _PaymentsScreenState extends State<PaymentsScreen>
    with DataEventsListener<PaymentsScreen> {
  /// Dépôt des paiements.
  final PaymentRepository _payments = PaymentRepository();

  /// Dépôt des commandes.
  final OrderRepository _orders = OrderRepository();

  /// Futur contenant les données des paiements de la commande.
  Future<_PaymentsData>? _future;

  /// Indique si des modifications ont été effectuées depuis l'ouverture.
  bool _changed = false;

  /// Entités dont les changements déclenchent un rechargement.
  @override
  Set<DataEntity> get dataEntities => const <DataEntity>{
    DataEntity.payments,
    DataEntity.orders,
  };

  /// Initialise l'état et charge les paiements.
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Recharge les paiements lorsque les données écoutées changent.
  @override
  void onDataChanged() => _load();

  /// Lance le chargement des paiements de la commande.
  void _load() {
    setState(() {
      _future = _fetch();
    });
  }

  /// Récupère la commande, ses paiements et le solde calculé.
  Future<_PaymentsData> _fetch() async {
    final Order? order = await _orders.findById(widget.orderId);
    if (order == null) throw StateError('Commande introuvable');
    final List<Payment> payments = await _payments.listForOrder(widget.orderId);
    // Calcul du total payé pour déterminer le solde.
    final int paid = await _payments.totalPaidForOrder(widget.orderId);
    return _PaymentsData(
      totalPrice: order.totalPrice,
      payments: payments,
      balance: OrderBalance(totalPrice: order.totalPrice, totalPaid: paid),
    );
  }

  /// Ouvre le formulaire d'ajout puis recharge si un paiement a été créé.
  Future<void> _addPayment() async {
    final _PaymentsData? data = await _future;
    if (!mounted || data == null) return;
    final bool? added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _PaymentForm(orderId: widget.orderId),
      ),
    );
    if (added == true) {
      _changed = true;
    }
  }

  /// Supprime un paiement après confirmation utilisateur.
  Future<void> _deletePayment(Payment payment) async {
    final bool confirmed = await confirmAction(
      context,
      title: 'Supprimer ce paiement ?',
      message:
          'Le versement de ${Formatters.money(payment.amount)} sera '
          'retiré de l\'historique de cette commande.',
      confirmLabel: 'Supprimer',
    );
    if (!confirmed) return;
    await _payments.delete(payment.id);
    if (!mounted) return;
    _changed = true;
  }

  /// Construit l'interface de gestion des paiements.
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        // Retourne un indicateur de modification à l'écran appelant.
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Paiements')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addPayment,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un paiement'),
        ),
        body: FutureBuilder<_PaymentsData>(
          future: _future,
          builder:
              (BuildContext context, AsyncSnapshot<_PaymentsData> snapshot) {
                // Affichage d'un indicateur pendant le chargement.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Affichage d'un état d'erreur en cas d'échec.
                if (snapshot.hasError || !snapshot.hasData) {
                  return ErrorState(
                    message: 'Impossible de charger les paiements.',
                    onRetry: _load,
                  );
                }
                final _PaymentsData data = snapshot.data!;
                return Column(
                  children: <Widget>[
                    _BalanceSummary(balance: data.balance),
                    Expanded(
                      child: data.payments.isEmpty
                          ? const EmptyState(
                              icon: Icons.payments_outlined,
                              message:
                                  'Aucun paiement enregistré pour '
                                  'cette commande.',
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                0,
                                AppSpacing.lg,
                                AppSpacing.xxl * 2,
                              ),
                              itemCount: data.payments.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (BuildContext context, int index) {
                                final Payment payment = data.payments[index];
                                return _PaymentTile(
                                  payment: payment,
                                  onDelete: () => _deletePayment(payment),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
        ),
      ),
    );
  }
}

/// Données agrégées pour l'écran des paiements.
class _PaymentsData {
  /// Crée un conteneur des données de paiements.
  const _PaymentsData({
    required this.totalPrice,
    required this.payments,
    required this.balance,
  });

  /// Prix total de la commande.
  final int totalPrice;

  /// Liste des paiements enregistrés.
  final List<Payment> payments;

  /// Solde financier de la commande.
  final OrderBalance balance;
}

/// Carte résumant le total payé et le solde restant.
class _BalanceSummary extends StatelessWidget {
  /// Crée le résumé financier.
  const _BalanceSummary({required this.balance});

  /// Solde financier à afficher.
  final OrderBalance balance;

  /// Construit le résumé du solde.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _summary(
                  context,
                  'Total payé',
                  Formatters.money(balance.totalPaid),
                  AppSemanticColors.of(context).success,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).colorScheme.outline,
              ),
              Expanded(
                child: _summary(
                  context,
                  balance.isOverpaid ? 'Trop-perçu' : 'Reste à payer',
                  Formatters.money(
                    // Affiche le montant trop-perçu ou le reste à payer.
                    balance.isOverpaid
                        ? balance.overpaidAmount
                        : balance.remaining,
                  ),
                  balance.isSettled
                      ? AppSemanticColors.of(context).success
                      : (balance.isOverpaid
                            ? Theme.of(context).colorScheme.primary
                            : AppSemanticColors.of(context).warning),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit un bloc de résumé avec un libellé et une valeur colorée.
  Widget _summary(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Tuile affichant un paiement avec son détail et l'action de suppression.
class _PaymentTile extends StatelessWidget {
  /// Crée une tuile de paiement.
  const _PaymentTile({required this.payment, required this.onDelete});

  /// Paiement à afficher.
  final Payment payment;

  /// Action de suppression du paiement.
  final VoidCallback onDelete;

  /// Construit la tuile de paiement.
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.payments_outlined)),
        title: Text(
          Formatters.money(payment.amount),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          <String>[
            Formatters.date(payment.paidAt),
            if (payment.method != null) payment.method!.label,
            if (payment.note != null && payment.note!.isNotEmpty) payment.note!,
          ].join(' • '),
        ),
        trailing: IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Supprimer',
        ),
      ),
    );
  }
}

/// Formulaire d'ajout d'un paiement pour une commande.
class _PaymentForm extends StatefulWidget {
  /// Crée le formulaire de paiement pour [orderId].
  const _PaymentForm({required this.orderId});

  /// Identifiant de la commande concernée.
  final String orderId;

  /// Crée l'état associé au formulaire.
  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

/// État du formulaire d'ajout d'un paiement.
class _PaymentFormState extends State<_PaymentForm> {
  /// Dépôt des paiements.
  final PaymentRepository _repo = PaymentRepository();

  /// Clé du formulaire pour la validation.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Contrôleur du champ montant.
  final TextEditingController _amount = TextEditingController();

  /// Contrôleur du champ note.
  final TextEditingController _note = TextEditingController();

  /// Date du versement.
  DateTime _paidAt = DateTime.now();

  /// Méthode de paiement sélectionnée.
  PaymentMethod? _method;

  /// Indique si un enregistrement est en cours.
  bool _saving = false;

  /// Libère les contrôleurs de texte.
  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Ouvre le sélecteur de date du versement.
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Date du versement',
    );
    if (picked != null) setState(() => _paidAt = picked);
  }

  /// Valide et enregistre le paiement.
  Future<void> _save() async {
    // Validation du formulaire avant enregistrement.
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _repo.insert(
        Payment(
          id: newId(),
          orderId: widget.orderId,
          amount: int.parse(_amount.text.trim()),
          paidAt: _paidAt,
          method: _method,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      // Gestion d'une erreur d'enregistrement.
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(
        context,
        message: 'L\'enregistrement a échoué. Réessayez.',
        isError: true,
      );
    }
  }

  /// Construit le formulaire d'ajout d'un paiement.
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Ajouter un paiement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                autofocus: true,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Montant *',
                  suffixText: 'FCFA',
                ),
                validator: (String? value) {
                  // Validation du montant saisi.
                  final int? amount = int.tryParse((value ?? '').trim());
                  if (amount == null || amount <= 0) {
                    return 'Saisissez un montant supérieur à zéro.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _DateTile(date: _paidAt, onTap: _pickDate),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<PaymentMethod>(
                initialValue: _method,
                decoration: const InputDecoration(
                  labelText: 'Méthode (facultative)',
                ),
                items: PaymentMethod.values
                    .map(
                      (PaymentMethod m) => DropdownMenuItem<PaymentMethod>(
                        value: m,
                        child: Text(m.label),
                      ),
                    )
                    .toList(),
                onChanged: (PaymentMethod? value) =>
                    setState(() => _method = value),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _note,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note (facultative)',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer le paiement'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tuile affichant la date sélectionnée et permettant de la modifier.
class _DateTile extends StatelessWidget {
  /// Crée une tuile de sélection de date.
  const _DateTile({required this.date, required this.onTap});

  /// Date actuellement sélectionnée.
  final DateTime date;

  /// Action déclenchée pour modifier la date.
  final VoidCallback onTap;

  /// Construit la tuile de date.
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.calendar_month_outlined),
        title: const Text('Date du versement'),
        subtitle: Text(Formatters.date(date)),
        trailing: const Icon(Icons.edit_outlined, size: 18),
        onTap: onTap,
      ),
    );
  }
}
