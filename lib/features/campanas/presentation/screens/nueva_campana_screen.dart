import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/agro_control_app_bar.dart';

class NuevaCampanaScreen extends ConsumerStatefulWidget {
  const NuevaCampanaScreen({super.key});

  @override
  ConsumerState<NuevaCampanaScreen> createState() => _NuevaCampanaScreenState();
}

class _NuevaCampanaScreenState extends ConsumerState<NuevaCampanaScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _areaController = TextEditingController();
  final _alquilerController = TextEditingController();
  final _metaController = TextEditingController();
  final _notasController = TextEditingController();

  String? _tipoCultivo;
  DateTime? _fechaInicio;
  String _unidad = 'ha';
  bool _esAlquilada = false;
  String _periodoAlquiler = 'Mensual';
  bool _ubicacionObtenida = false;
  bool _isSubmitting = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _areaController.dispose();
    _alquilerController.dispose();
    _metaController.dispose();
    _notasController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AgroControlAppBar(
        showBackButton: true,
        section: 'Nueva campaña',
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('Nombre de la campaña'),
                      _buildCard(
                        child: TextFormField(
                          controller: _nombreController,
                          decoration: _inputDecoration(
                            hintText: 'ej. Tomate 2025',
                            prefixIcon: Icons.edit,
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel('Tipo de cultivo'),
                                _buildCard(
                                  child: DropdownButtonFormField<String>(
                                    isDense: true,
                                    initialValue: _tipoCultivo,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'tomate', child: Text('Tomate')),
                                      DropdownMenuItem(value: 'cebolla', child: Text('Cebolla')),
                                      DropdownMenuItem(value: 'ajo', child: Text('Ajo')),
                                      DropdownMenuItem(value: 'vainita', child: Text('Vainita')),
                                      DropdownMenuItem(value: 'papa', child: Text('Papa')),
                                      DropdownMenuItem(value: 'maiz', child: Text('Maíz')),
                                      DropdownMenuItem(value: 'trigo', child: Text('Trigo')),
                                      DropdownMenuItem(value: 'otro', child: Text('Otro')),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _tipoCultivo = v),
                                    validator: (v) =>
                                        v == null ? 'Seleccione' : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel('Fecha de inicio'),
                                _buildCard(
                                  child: InkWell(
                                    onTap: _pickDate,
                                    child: InputDecorator(
                                      decoration: _inputDecoration(
                                        prefixIcon: Icons.calendar_today,
                                      ),
                                      child: Text(
                                        _fechaInicio != null
                                            ? '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}'
                                            : 'Seleccionar',
                                        style: TextStyle(
                                          color: _fechaInicio != null
                                              ? AppColors.onSurface
                                              : AppColors.outline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildSectionLabel('Área plantada'),
                      _buildCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _areaController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(
                                  hintText: '0.00',
                                  prefixIcon: Icons.square_foot,
                                ),
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Requerido' : null,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 48,
                              color: AppColors.surfaceDim,
                            ),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _unidad,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'ha', child: Text('Ha')),
                                  DropdownMenuItem(
                                      value: 'topos', child: Text('Topos')),
                                  DropdownMenuItem(
                                      value: 'm2', child: Text('m²')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _unidad = v!),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildSectionLabel('Propiedad de la parcela'),
                      _buildCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _esAlquilada
                                      ? Icons.home_work
                                      : Icons.home,
                                  size: 20,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _esAlquilada ? 'Alquilada' : 'Propia',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                Switch(
                                  value: _esAlquilada,
                                  onChanged: (v) =>
                                      setState(() => _esAlquilada = v),
                                  activeThumbColor: AppColors.primary,
                                ),
                              ],
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: _esAlquilada
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Divider(
                                            color: AppColors.surfaceDim,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Costo de alquiler',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: AppColors
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  controller:
                                                      _alquilerController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration: _inputDecoration(
                                                    hintText: '0.00',
                                                    prefixIcon:
                                                        Icons.attach_money,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors
                                                      .secondaryContainer
                                                      .withValues(alpha: 0.3),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: DropdownButtonHideUnderline(
                                                  child: DropdownButton<String>(
                                                    value: _periodoAlquiler,
                                                    isDense: true,
                                                    items: const [
                                                      DropdownMenuItem(
                                                        value: 'Mensual',
                                                        child: Text('Mensual'),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 'Campaña',
                                                        child:
                                                            Text('Por campaña'),
                                                      ),
                                                    ],
                                                    onChanged: (v) =>
                                                        setState(() =>
                                                            _periodoAlquiler =
                                                                v!),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildSectionLabel('Ubicación'),
                      _buildCard(
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(
                                      () => _ubicacionObtenida = true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Ubicación obtenida (simulado)'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.my_location),
                                label: const Text('Obtener ubicación actual'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      AppColors.onSecondaryContainer,
                                  backgroundColor:
                                      AppColors.secondaryContainer,
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              height: 128,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.surfaceDim),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _ubicacionObtenida
                                        ? Icons.location_on
                                        : Icons.map,
                                    size: 36,
                                    color: AppColors.outlineVariant,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _ubicacionObtenida
                                        ? 'Ubicación registrada'
                                        : 'Sin ubicación registrada',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel('Meta de producción'),
                                _buildCard(
                                  child: TextFormField(
                                    controller: _metaController,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDecoration(
                                      hintText: '0',
                                      prefixIcon: Icons.flag,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel('Unidad meta'),
                                _buildCard(
                                  child: DropdownButtonFormField<String>(
                                    isDense: true,
                                    initialValue: 'kg',
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'kg', child: Text('Kg')),
                                      DropdownMenuItem(
                                          value: 'quintales',
                                          child: Text('Quintales')),
                                      DropdownMenuItem(
                                          value: 'arrobas',
                                          child: Text('Arrobas')),
                                    ],
                                    onChanged: (v) {},
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildSectionLabel('Notas adicionales'),
                      _buildCard(
                        child: TextFormField(
                          controller: _notasController,
                          maxLines: 3,
                          decoration: _inputDecoration(
                            hintText: 'Información adicional...',
                            prefixIcon: Icons.notes,
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.9),
                  border: Border(
                    top: BorderSide(color: AppColors.surfaceVariant),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submitForm,
                    icon: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Icon(Icons.add_circle),
                    label: Text(
                      _isSubmitting ? 'CREANDO...' : 'CREAR CAMPAÑA',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceDim),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AppColors.outline),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20, color: AppColors.onSurfaceVariant)
          : null,
      prefixIconConstraints:
          const BoxConstraints(minWidth: 48, minHeight: 48),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _fechaInicio = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una fecha de inicio')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final extensionValue = double.tryParse(_areaController.text) ?? 0;
      final tipoExtension = _unidad == 'ha' ? 'hectarea' : 'topo';

      final campana = await ref.read(campanaListProvider.notifier).createCampana(
            nombre: _nombreController.text.trim(),
            cultivo: _tipoCultivo ?? 'otro',
            extension: extensionValue,
            tipoExtension: tipoExtension,
            fechaInicio: _fechaInicio!,
          );

      if (!mounted) return;

      if (campana != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaña creada exitosamente')),
        );
        context.go('/campanas');
      } else {
        final error = ref.read(campanaListProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Error al crear campaña')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
