import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../cuaderno/data/datasources/evidencia_local_datasource.dart';

class ActivityForm extends ConsumerStatefulWidget {
  final String type;
  final int campanaId;

  const ActivityForm({super.key, required this.type, required this.campanaId});

  @override
  ConsumerState<ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends ConsumerState<ActivityForm> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _montoController = TextEditingController();
  final _categoriaController = TextEditingController();
  DateTime _fecha = DateTime.now();
  bool _isSubmitting = false;
  File? _photoFile;
  final _imagePicker = ImagePicker();
  final _evidenciaDatasource = EvidenciaLocalDatasource();

  @override
  void dispose() {
    _descripcionController.dispose();
    _montoController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActividad = widget.type == 'Actividad';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.surfaceContainerHigh),
                ),
              ),
              child: Text(
                'Nueva ${widget.type}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 16),

            _buildDateField(context),
            const SizedBox(height: 16),

            if (!isActividad) ...[
              _buildTextField(
                controller: _montoController,
                label: 'Monto (S/)',
                hint: '0.00',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _categoriaController,
                label: 'Categoría',
                hint: 'Ej. Combustible, Insumos, Mano de obra',
              ),
              const SizedBox(height: 16),
            ],

            _buildDescriptionField(context),
            const SizedBox(height: 16),

            _buildPhotoSection(context),
            const SizedBox(height: 16),

            _buildSubmitButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_fecha);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fecha', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        TextFormField(
          readOnly: true,
          initialValue: dateStr,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_today, size: 20),
            prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _fecha,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _fecha = picked);
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(hintText: hint),
          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
        ),
      ],
    );
  }

  Widget _buildDescriptionField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Descripción', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        TextFormField(
          controller: _descripcionController,
          maxLines: 3,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: const InputDecoration(hintText: 'Detalle de la actividad...'),
          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
        ),
      ],
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Evidencia fotográfica', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        if (_photoFile != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_photoFile!, height: 120, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.photo_camera, size: 20),
                label: const Text('Cámara'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSecondaryContainer,
                  backgroundColor: AppColors.secondaryContainer,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library, size: 20),
                label: const Text('Galería'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSecondaryContainer,
                  backgroundColor: AppColors.secondaryContainer,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _takePhoto() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) {
      final saved = await _savePhotoLocal(picked.path);
      setState(() => _photoFile = saved);
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final saved = await _savePhotoLocal(picked.path);
      setState(() => _photoFile = saved);
    }
  }

  Future<File> _savePhotoLocal(String originalPath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final evidenciasDir = Directory('${appDir.path}/evidencias');
    if (!await evidenciasDir.exists()) {
      await evidenciasDir.create(recursive: true);
    }
    final fileName = 'evid_${DateTime.now().millisecondsSinceEpoch}${p.extension(originalPath)}';
    final savedFile = await File(originalPath).copy('${evidenciasDir.path}/$fileName');
    return savedFile;
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
              )
            : Text(
                'REGISTRAR',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final notifier = ref.read(cuadernoProvider.notifier);
      final fechaStr = '${_fecha.year}-${_fecha.month.toString().padLeft(2, '0')}-${_fecha.day.toString().padLeft(2, '0')}T${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:00';

      late int recordId;

      if (widget.type == 'Actividad') {
        recordId = await notifier.addActividad(widget.campanaId, _descripcionController.text.trim(), fechaStr);
      } else {
        final monto = double.tryParse(_montoController.text) ?? 0;
        recordId = await notifier.addTransaccion(
          widget.campanaId,
          tipo: widget.type == 'Gasto' ? 'gasto' : 'ingreso',
          categoria: _categoriaController.text.trim().isEmpty ? 'general' : _categoriaController.text.trim(),
          monto: monto,
          descripcion: _descripcionController.text.trim(),
          fecha: fechaStr,
        );
      }

      if (_photoFile != null) {
        await _evidenciaDatasource.saveEvidencia(
          relacionId: recordId,
          relacionTipo: widget.type == 'Actividad' ? 'actividad' : 'transaccion',
          rutaArchivo: _photoFile!.path,
        );
      }

      _descripcionController.clear();
      _montoController.clear();
      _categoriaController.clear();
      setState(() => _photoFile = null);
      ref.read(dashboardRefreshTrigger.notifier).update((s) => s + 1);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.type} registrada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
