import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'glass.dart';

/// Piezas compartidas por los formularios de registro (gasto, labor,
/// ingreso, incidencia): mismo estilo, botones grandes y poco texto.

final _amount = NumberFormat('#,##0.00', 'es_419');
String formatSoles(double v) => 'S/ ${_amount.format(v)}';

/// Abre un formulario como hoja inferior a casi toda la pantalla.
Future<void> showRecordSheet(BuildContext context, Widget sheet) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    builder: (_) => FractionallySizedBox(heightFactor: 0.95, child: sheet),
  );
}

/// Esqueleto de un formulario: cabecera, contenido desplazable y barra de guardado fija.
class RecordSheetScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final List<Widget> children;
  final Widget saveBar;

  const RecordSheetScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.onDateChanged,
    required this.children,
    required this.saveBar,
  });

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) onDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(999)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone_android_rounded, size: 13, color: AppColors.warning),
                        const SizedBox(width: 5),
                        Text(
                          'Se guarda en el teléfono',
                          style: text.labelSmall?.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GlassCircleButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Cerrar',
                    size: 38,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(title, style: text.headlineSmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.eco_outlined, size: 15, color: AppColors.accent),
                  const SizedBox(width: 5),
                  Expanded(child: Text(subtitle, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ActionChip(
                    avatar: Icon(Icons.event_rounded, size: 16, color: AppColors.accent),
                    label: Text(isToday ? 'Hoy' : DateFormat('d MMM', 'es').format(date)),
                    onPressed: () => _pickDate(context),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ...children,
            ],
          ),
        ),
        saveBar,
      ],
    );
  }
}

/// Barra inferior fija con el total (opcional) y el botón de guardar.
class RecordSaveBar extends StatelessWidget {
  final String label;
  final bool saving;
  final VoidCallback onSave;
  final double? total;

  const RecordSaveBar({super.key, required this.label, required this.saving, required this.onSave, this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).bottomSheetTheme.backgroundColor,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (total != null) ...[
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total', style: Theme.of(context).textTheme.labelSmall),
                  Text(formatSoles(total!), style: AppTheme.display(fontSize: 22, color: AppColors.text)),
                ],
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: AgroActionButton(
                label: saving ? 'Guardando…' : label,
                icon: Icons.save_rounded,
                primary: true,
                height: 56,
                onPressed: saving ? () {} : onSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Título numerado de un paso del formulario.
class StepTitle extends StatelessWidget {
  final int number;
  final String title;
  final Widget? action;

  const StepTitle({super.key, required this.number, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Text('$number', style: text.labelSmall?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: text.labelSmall?.copyWith(color: AppColors.textMuted, letterSpacing: 1.1, fontWeight: FontWeight.w700),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Píldora grande seleccionable con icono (categorías, tipos).
class SelectPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SelectPill({super.key, required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onAccent : AppColors.text;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.ctaGradient : null,
          color: selected ? null : AppColors.accentSoft,
          borderRadius: BorderRadius.circular(999),
          border: selected ? null : Border.all(color: AppColors.cardBorder),
          boxShadow: selected ? [BoxShadow(color: AppColors.palette.ctaGlow, blurRadius: 16, spreadRadius: -4)] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: selected ? fg : AppColors.accent),
            const SizedBox(width: 7),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
            ),
            if (selected) ...[
              const SizedBox(width: 5),
              Icon(Icons.check_rounded, size: 17, color: fg),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fila horizontal desplazable de [SelectPill].
class SelectPillRow<T> extends StatelessWidget {
  final List<(T value, String label, IconData icon)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  const SelectPillRow({super.key, required this.options, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (value, label, icon) = options[i];
          return SelectPill(icon: icon, label: label, selected: value == selected, onTap: () => onSelected(value));
        },
      ),
    );
  }
}

/// Chip pequeño seleccionable (labores, montos rápidos, extras).
class MiniChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool large;
  final VoidCallback onTap;

  const MiniChip({super.key, required this.label, required this.onTap, this.selected = false, this.large = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: large ? 42 : 34,
        padding: EdgeInsets.symmetric(horizontal: large ? 14 : 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.16) : AppColors.accentSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.accent : AppColors.cardBorder),
        ),
        // Row con tamaño mínimo: el chip mide lo que su texto, no todo el ancho.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? AppColors.accent : AppColors.text,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opciones grandes en columnas iguales (forma de pago, severidad…).
class OptionTiles<T> extends StatelessWidget {
  final List<(T value, String label, IconData icon)> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final Color? Function(T value)? colorOf;

  const OptionTiles({super.key, required this.options, required this.selected, required this.onSelected, this.colorOf});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        for (final (i, (value, label, icon)) in options.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Builder(builder: (context) {
              final isSelected = value == selected;
              final color = colorOf?.call(value) ?? AppColors.accent;
              return GestureDetector(
                onTap: () => onSelected(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 64,
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.14) : AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? color : AppColors.cardBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20, color: isSelected ? color : AppColors.textMuted),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: text.labelSmall?.copyWith(
                          color: isSelected ? color : AppColors.textMuted,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

/// Monto grande centrado, con teclado numérico y montos rápidos.
class AmountInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String caption;
  final List<int> quickAmounts;

  const AmountInput({
    super.key,
    required this.controller,
    required this.onChanged,
    this.caption = 'MONTO',
    this.quickAmounts = const [10, 50, 100, 500],
  });

  static double parse(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.track.withValues(alpha: AppColors.palette.isDark ? 0.35 : 0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                caption,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700),
              ),
              TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                style: AppTheme.display(fontSize: 34, color: AppColors.text),
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: '0.00',
                  prefixText: 'S/ ',
                  prefixStyle: AppTheme.display(fontSize: 24, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final (i, inc) in quickAmounts.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Material(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      final current = parse(controller);
                      final next = current + inc;
                      controller.text = next.toStringAsFixed(next % 1 == 0 ? 0 : 2);
                      onChanged();
                    },
                    child: SizedBox(
                      height: 48,
                      child: Center(child: Text('+S/ $inc', style: AppTheme.display(fontSize: 14, color: AppColors.accent))),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Foto opcional (comprobante, evidencia) desde cámara o galería.
class PhotoPickerTile extends StatelessWidget {
  final File? photo;
  final ValueChanged<ImageSource> onPick;
  final String title;
  final String hint;

  const PhotoPickerTile({
    super.key,
    required this.photo,
    required this.onPick,
    this.title = 'Foto del comprobante',
    this.hint = 'Boleta, recibo o cuaderno',
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(14)),
            child: photo == null
                ? Icon(Icons.photo_outlined, color: AppColors.accent)
                : Image.file(photo!, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(photo == null ? title : 'Foto lista', style: text.titleSmall),
                Text(photo == null ? hint : 'Se subirá al sincronizar', style: text.bodySmall),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Galería',
            onPressed: () => onPick(ImageSource.gallery),
            icon: Icon(Icons.photo_library_outlined, color: AppColors.accent),
          ),
          IconButton.filled(
            tooltip: 'Cámara',
            style: IconButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.onAccent),
            onPressed: () => onPick(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_rounded),
          ),
        ],
      ),
    );
  }
}

/// Cuadro de resumen en palabras antes de guardar.
class RecordSummary extends StatelessWidget {
  final String text;

  const RecordSummary({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(18)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, color: AppColors.accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resumen', style: theme.titleSmall),
                const SizedBox(height: 2),
                Text(text, style: theme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
