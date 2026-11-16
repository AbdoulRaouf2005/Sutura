import 'package:flutter/material.dart';

import '../../core/theme/app_semantic_colors.dart';

/// Affiche une boîte de dialogue de confirmation pour une action destructive
/// (cahier des charges §4.2 et guide §9).
///
/// [title] et [message] décrivent l'action ; [confirmLabel] et [cancelLabel]
/// personnalisent les boutons. Quand [destructive] est vrai, le bouton de
/// confirmation prend la couleur d'erreur.
///
/// Retourne `true` si l'utilisateur confirme.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmer',
  String cancelLabel = 'Annuler',
  bool destructive = true,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          // Annulation : la boîte renvoie `false`.
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          // Confirmation : bouton coloré en rouge si l'action est destructive.
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: AppSemanticColors.of(ctx).error,
                  )
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  // Une fermeture sans choix est traitée comme une annulation.
  return result ?? false;
}

/// Message d'erreur / succès standardisé en bas d'écran.
///
/// [isError] applique la couleur d'erreur au bandeau.
void showAppSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  // Remplace le message courant pour éviter d'empiler les bandeaux.
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppSemanticColors.of(context).error : null,
      ),
    );
}
