import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/entities/plantilla_cultivo.dart';

/// Lo que se imprime en la hoja de embarque compartida.
class HojaEmbarque {
  final int numero;
  final String cultivo;
  final String campana;
  final DateTime fecha;
  final String destino;
  final String chofer;
  final String placa;
  final String comisionista;
  final String envase;
  final String notas;
  final String anotadoPor;

  /// Peso promedio de un envase lleno (de la plantilla), para estimar kilos.
  final double? pesoEnvaseKg;

  /// `Enviada`, `Borrador` o `Liquidada`.
  final String estado;
  final List<Calidad> calidades;

  /// [fila][calidad]; las filas vacías no se imprimen.
  final List<List<int>> celdas;

  const HojaEmbarque({
    required this.numero,
    required this.cultivo,
    required this.campana,
    required this.fecha,
    required this.destino,
    required this.chofer,
    required this.placa,
    required this.comisionista,
    required this.envase,
    required this.notas,
    required this.anotadoPor,
    this.pesoEnvaseKg,
    required this.estado,
    required this.calidades,
    required this.celdas,
  });

  int totalFila(int f) => celdas[f].fold(0, (s, v) => s + v);
  int totalCol(int c) => celdas.fold(0, (s, fila) => s + fila[c]);
  int get total => celdas.fold(0, (s, fila) => s + fila.fold(0, (a, v) => a + v));
  double? get kilos => pesoEnvaseKg == null ? null : total * pesoEnvaseKg!;
  List<int> get filasConDatos => [for (var f = 0; f < celdas.length; f++) if (totalFila(f) > 0) f];

  /// Código de 12 caracteres sacado del contenido: si alguien cambia un
  /// número de la hoja, el código ya no coincide.
  String get codigo {
    final contenido = jsonEncode({
      'n': numero,
      'f': DateFormat('yyyy-MM-dd').format(fecha),
      'd': destino,
      'c': [for (final c in calidades) c.codigo],
      'm': celdas,
    });
    final h = sha256.convert(utf8.encode(contenido)).toString().toUpperCase();
    return '${h.substring(0, 4)}-${h.substring(4, 8)}-${h.substring(8, 12)}';
  }

  String get nombreArchivo => 'hoja_${numero}_${DateFormat('yyyy-MM-dd').format(fecha)}';
}

/// Vista previa de la hoja de embarque con opciones para compartirla como
/// imagen, PDF o texto (WhatsApp).
class CompartirHojaScreen extends StatefulWidget {
  final HojaEmbarque hoja;
  final String textoPlano;

  const CompartirHojaScreen({super.key, required this.hoja, required this.textoPlano});

  @override
  State<CompartirHojaScreen> createState() => _CompartirHojaScreenState();
}

class _CompartirHojaScreenState extends State<CompartirHojaScreen> {
  final _tarjeta = GlobalKey();
  bool _preparando = false;

  Future<Uint8List> _png() async {
    final boundary = _tarjeta.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final imagen = await boundary.toImage(pixelRatio: 3);
    final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  Future<void> _compartir(String formato) async {
    if (_preparando) return;
    setState(() => _preparando = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final hoja = widget.hoja;
      final texto = 'Hoja N.º ${hoja.numero} · ${hoja.total} ${hoja.envase}s${hoja.destino.isEmpty ? '' : ' a ${hoja.destino}'}';
      if (formato == 'texto') {
        await SharePlus.instance.share(ShareParams(text: widget.textoPlano));
        return;
      }
      final png = await _png();
      final dir = await getTemporaryDirectory();
      final File archivo;
      if (formato == 'imagen') {
        archivo = await File('${dir.path}/${hoja.nombreArchivo}.png').writeAsBytes(png);
      } else {
        final doc = pw.Document(title: texto, author: 'AgroControl');
        final img = pw.MemoryImage(png);
        doc.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (_) => pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain)),
        ));
        archivo = await File('${dir.path}/${hoja.nombreArchivo}.pdf').writeAsBytes(await doc.save());
      }
      await SharePlus.instance.share(ShareParams(
        files: [XFile(archivo.path, mimeType: formato == 'imagen' ? 'image/png' : 'application/pdf')],
        text: texto,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo preparar la hoja: $e')));
    } finally {
      if (mounted) setState(() => _preparando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget boton(IconData icon, String label, String formato, {bool primario = false}) => Expanded(
          child: AgroActionButton(
            label: label,
            icon: icon,
            primary: primario,
            height: 52,
            onPressed: () => _compartir(formato),
          ),
        );

    return AgroBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GlassCircleButton(icon: Icons.arrow_back_rounded, tooltip: 'Volver', onPressed: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: 12),
                  Text('Compartir hoja', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: RepaintBoundary(key: _tarjeta, child: HojaEmbarqueTarjeta(hoja: widget.hoja)),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.palette.navBackground,
            border: Border(top: BorderSide(color: AppColors.cardBorder)),
          ),
          child: SafeArea(
            top: false,
            child: _preparando
                ? const SizedBox(height: 52, child: Center(child: CircularProgressIndicator()))
                : Row(
                    children: [
                      boton(Icons.image_outlined, 'Imagen', 'imagen', primario: true),
                      const SizedBox(width: 8),
                      boton(Icons.picture_as_pdf_outlined, 'PDF', 'pdf'),
                      const SizedBox(width: 8),
                      boton(Icons.notes_rounded, 'Texto', 'texto'),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// Colores fijos de papel: la hoja compartida se ve igual en modo claro u oscuro.
const _papel = Color(0xFFFAF6EC);
const _borde = Color(0xFFD9CBA6);
const _tinta = Color(0xFF14263F);
const _tintaSuave = Color(0xFF5E6B7A);
const _dorado = Color(0xFFC9A24A);
const _verde = Color(0xFF1F5F3F);
const _franja = Color(0xFFF2EBDA);

/// La hoja de embarque con diseño de documento (lo que se exporta).
class HojaEmbarqueTarjeta extends StatelessWidget {
  final HojaEmbarque hoja;

  const HojaEmbarqueTarjeta({super.key, required this.hoja});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme;
    TextStyle cuerpo(double size, {Color color = _tinta, FontWeight peso = FontWeight.w500, double espacio = 0}) =>
        (base.bodyMedium ?? const TextStyle()).copyWith(fontSize: size, color: color, fontWeight: peso, letterSpacing: espacio, height: 1.25);
    TextStyle cifra(double size, {Color color = _tinta}) => AppTheme.display(fontSize: size, color: color);

    final fecha = DateFormat("d 'de' MMMM y", 'es').format(hoja.fecha);
    final filas = hoja.filasConDatos;
    final estadoColor = hoja.estado == 'Borrador' ? _tintaSuave : _verde;

    Widget dato(String etiqueta, String valor) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(etiqueta.toUpperCase(), style: cuerpo(9.5, color: _tintaSuave, peso: FontWeight.w700, espacio: 1.1)),
              const SizedBox(height: 3),
              Text(valor.isEmpty ? '—' : valor, maxLines: 2, overflow: TextOverflow.ellipsis, style: cuerpo(13, peso: FontWeight.w700)),
            ],
          ),
        );

    Widget celda(String v, {bool cabecera = false, bool total = false, int flex = 2}) => Expanded(
          flex: flex,
          child: Text(
            v,
            textAlign: TextAlign.center,
            style: cabecera
                ? cuerpo(11, color: total ? _verde : _tinta, peso: FontWeight.w800, espacio: 0.8)
                : cifra(13.5, color: total ? _verde : _tinta),
          ),
        );

    Widget fila(List<String> valores, {bool cabecera = false, Color? fondo}) => Container(
          color: fondo,
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
          child: Row(
            children: [
              for (final (i, v) in valores.indexed)
                celda(v, cabecera: cabecera, total: i == valores.length - 1, flex: i == 0 || i == valores.length - 1 ? 3 : 2),
            ],
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: _papel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borde, width: 3),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AGROCONTROL', style: cuerpo(22, peso: FontWeight.w800, espacio: 1.5)),
                    Text('COSECHA · HOJA N.º ${hoja.numero}', style: cuerpo(15, peso: FontWeight.w800, espacio: 1.2)),
                    const SizedBox(height: 4),
                    Text(
                      'HOJA DE EMBARQUE${hoja.destino.isEmpty ? '' : ' · ${hoja.destino.toUpperCase()}'}',
                      style: cuerpo(10.5, color: _tintaSuave, peso: FontWeight.w700, espacio: 1),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: estadoColor, borderRadius: BorderRadius.circular(8)),
                    child: Text('${hoja.estado.toUpperCase()}${hoja.estado == 'Borrador' ? '' : ' ✓'}',
                        style: cuerpo(10.5, color: Colors.white, peso: FontWeight.w800, espacio: 1)),
                  ),
                  const SizedBox(height: 8),
                  Text(fecha, style: cuerpo(11, color: _tintaSuave, peso: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 3, color: _tinta),
          const SizedBox(height: 12),
          // Datos del despacho
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(14), border: Border.all(color: _borde)),
            child: Column(
              children: [
                Row(children: [dato('Camión', hoja.placa), dato('Chofer', hoja.chofer), dato('Producto', hoja.cultivo)]),
                const SizedBox(height: 10),
                Row(children: [dato('Destino', hoja.destino), dato('Comisionista', hoja.comisionista), dato('Campaña', hoja.campana)]),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('HOJA COMPLETA (${hoja.envase.toUpperCase()}S) · ${filas.length} FILA${filas.length == 1 ? '' : 'S'}',
              style: cuerpo(11.5, color: _tintaSuave, peso: FontWeight.w800, espacio: 0.8)),
          const SizedBox(height: 8),
          // Matriz
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: _borde), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  fila(['FILA', for (final c in hoja.calidades) c.codigo, 'TOTAL'], cabecera: true, fondo: _franja),
                  for (final (i, f) in filas.indexed)
                    fila(
                      ['F${f + 1}', for (var c = 0; c < hoja.calidades.length; c++) hoja.celdas[f][c] == 0 ? '·' : '${hoja.celdas[f][c]}', '${hoja.totalFila(f)}'],
                      fondo: i.isOdd ? _franja.withValues(alpha: 0.5) : Colors.white,
                    ),
                  fila(['TOT', for (var c = 0; c < hoja.calidades.length; c++) '${hoja.totalCol(c)}', '${hoja.total}'], fondo: _franja),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [for (final c in hoja.calidades) '${c.codigo} = ${c.nombre}'].join(' · '),
            style: cuerpo(9.5, color: _tintaSuave),
          ),
          const SizedBox(height: 14),
          // Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: _tinta, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL EMBARCADO', style: cuerpo(11, color: _dorado, peso: FontWeight.w800, espacio: 1.4)),
                      const SizedBox(height: 2),
                      Text(
                          [
                            '${filas.length} filas · ${hoja.calidades.length} calidades',
                            if (hoja.kilos != null) '≈ ${NumberFormat('#,##0', 'es_419').format(hoja.kilos)} kg',
                          ].join(' · '),
                          style: cuerpo(10.5, color: Colors.white.withValues(alpha: 0.7))),
                    ],
                  ),
                ),
                Text('${hoja.total} ${hoja.envase.toUpperCase()}S', style: cifra(24, color: Colors.white)),
              ],
            ),
          ),
          if (hoja.notas.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('NOTAS', style: cuerpo(9.5, color: _tintaSuave, peso: FontWeight.w700, espacio: 1.1)),
            const SizedBox(height: 2),
            Text(hoja.notas, style: cuerpo(11.5)),
          ],
          const SizedBox(height: 14),
          Container(height: 1.5, color: _borde),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Anotado por', style: cuerpo(10, color: _tintaSuave)),
                    Text(hoja.anotadoPor.isEmpty ? '—' : hoja.anotadoPor, style: cuerpo(13, peso: FontWeight.w800).copyWith(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Código de la hoja', style: cuerpo(10, color: _tintaSuave)),
                  Text(hoja.codigo, style: cifra(12, color: _tintaSuave)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
