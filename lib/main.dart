import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MiAplicacion());
}

class MiAplicacion extends StatefulWidget {
  const MiAplicacion({super.key});

  @override
  State<MiAplicacion> createState() => _MiAplicacionState();
}

class _MiAplicacionState extends State<MiAplicacion> {
  final almacenamiento = SharedPreferencesAsync();
  final controlador = TextEditingController();
  final navegador = GlobalKey<NavigatorState>();

  List<Map<String, dynamic>> tareas = [];
  bool oscuro = false;
  bool cargando = true;

  // Guarda los cambios en el orden en que se realizan.
  Future<void> guardados = Future<void>.value();

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  // Recupera las actividades y el tema guardados.
  Future<void> cargarDatos() async {
    try {
      final contenido =
          await almacenamiento.getString('agenda_universitaria');

      if (contenido != null) {
        final datos = jsonDecode(contenido) as Map<String, dynamic>;

        tareas = (datos['tareas'] as List)
            .map((elemento) => Map<String, dynamic>.from(elemento))
            .toList();

        oscuro = datos['oscuro'] as bool? ?? false;
      }
    } catch (_) {
      // La aplicación puede utilizarse aunque falle la lectura.
    }

    if (!mounted) return;

    setState(() {
      cargando = false;
    });
  }

  // Conserva las actividades y el modo de visualización.
  void guardarDatos() {
    final contenido = jsonEncode({
      'tareas': tareas,
      'oscuro': oscuro,
    });

    guardados = guardados.then((_) async {
      try {
        await almacenamiento.setString(
          'agenda_universitaria',
          contenido,
        );
      } catch (_) {
        if (mounted) {
          mostrarMensaje('No fue posible guardar los cambios.');
        }
      }
    });
  }

  void mostrarMensaje(String mensaje) {
    final contexto = navegador.currentContext;
    if (contexto == null) return;

    ScaffoldMessenger.of(contexto).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  // Agrega una actividad pendiente.
  void agregarTarea() {
    final texto = controlador.text.trim();

    if (texto.isEmpty) {
      mostrarMensaje('Escribe el nombre de una actividad.');
      return;
    }

    setState(() {
      tareas.add({
        'nombre': texto,
        'completada': false,
      });

      controlador.clear();
    });

    guardarDatos();
    mostrarMensaje('Actividad agregada.');
  }

  // Actualiza la actividad y recalcula el progreso.
  void cambiarEstado(int indice, bool valor) {
    setState(() {
      tareas[indice]['completada'] = valor;
    });

    guardarDatos();

    if (tareas.isNotEmpty &&
        tareas.every((tarea) => tarea['completada'] == true)) {
      mostrarMensaje('¡Completaste todas tus actividades!');
    }
  }

  void eliminarTarea(int indice) {
    setState(() {
      tareas.removeAt(indice);
    });

    guardarDatos();
    mostrarMensaje('Actividad eliminada.');
  }

  // Botón adicional que abre un cuadro informativo.
  void mostrarInformacion(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acerca de mi proyecto'),
        content: const Text(
          'Mi Agenda Universitaria está desarrollada con Flutter.\n\n'
          'Permite registrar actividades, marcarlas como completadas, '
          'eliminarlas y consultar el progreso.\n\n'
          'Incluye textos propios, diseño personalizado, modo oscuro '
          'y almacenamiento local.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completadas =
        tareas.where((tarea) => tarea['completada'] == true).length;

    final pendientes = tareas.length - completadas;

    final progreso =
        tareas.isEmpty ? 0.0 : completadas / tareas.length;

    // Ajusta el mensaje para singular y plural.
    final String mensajeProgreso;

    if (tareas.isEmpty) {
      mensajeProgreso = 'Agrega tu primera actividad.';
    } else if (pendientes == 0) {
      mensajeProgreso = '¡Excelente! Terminaste tus actividades.';
    } else if (pendientes == 1) {
      mensajeProgreso = 'Tienes 1 actividad por completar.';
    } else {
      mensajeProgreso =
          'Tienes $pendientes actividades por completar.';
    }

    return MaterialApp(
      navigatorKey: navegador,
      debugShowCheckedModeBanner: false,
      title: 'Mi Agenda Universitaria',
      themeMode: oscuro ? ThemeMode.dark : ThemeMode.light,

      // Diseño claro.
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00897B),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),

      // Diseño oscuro.
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF26A69A),
          brightness: Brightness.dark,
        ),
      ),

      home: Builder(
        builder: (context) {
          final colores = Theme.of(context).colorScheme;

          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Mi Agenda Universitaria',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: oscuro ? 'Modo claro' : 'Modo oscuro',
                  onPressed: () {
                    setState(() {
                      oscuro = !oscuro;
                    });

                    guardarDatos();
                  },
                  icon: Icon(
                    oscuro ? Icons.light_mode : Icons.dark_mode,
                  ),
                ),
                IconButton(
                  tooltip: 'Acerca del proyecto',
                  onPressed: () => mostrarInformacion(context),
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
            body: cargando
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 850,
                      ),
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          // Encabezado personalizado.
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF153B65),
                                  Color(0xFF00897B),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  color: Colors.white,
                                  size: 48,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Organiza tu día, alcanza tus metas',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Cada actividad completada es un paso adelante.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Tarjetas con el resumen.
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              tarjetaResumen(
                                context,
                                'Total',
                                tareas.length,
                                Icons.assignment_outlined,
                              ),
                              tarjetaResumen(
                                context,
                                'Pendientes',
                                pendientes,
                                Icons.schedule,
                              ),
                              tarjetaResumen(
                                context,
                                'Completadas',
                                completadas,
                                Icons.task_alt,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Barra de progreso.
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tu progreso: ${(progreso * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: progreso,
                                      minHeight: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(mensajeProgreso),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Formulario de nuevas actividades.
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Nueva actividad',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: controlador,
                                    maxLength: 100,
                                    textInputAction:
                                        TextInputAction.done,
                                    onSubmitted: (_) => agregarTarea(),
                                    decoration: InputDecoration(
                                      labelText:
                                          '¿Qué necesitas hacer?',
                                      hintText:
                                          'Ejemplo: Entregar proyecto Flutter',
                                      prefixIcon:
                                          const Icon(Icons.edit_note),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FilledButton.icon(
                                    onPressed: agregarTarea,
                                    icon: const Icon(Icons.add),
                                    label:
                                        const Text('Agregar actividad'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Mis actividades',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Mensaje cuando no hay actividades.
                          if (tareas.isEmpty)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(30),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.event_note,
                                      size: 52,
                                      color: Colors.teal,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Tu agenda está lista para comenzar',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Lista de actividades.
                          ...List.generate(tareas.length, (indice) {
                            final tarea = tareas[indice];
                            final terminada =
                                tarea['completada'] == true;

                            return Card(
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                leading: Checkbox(
                                  value: terminada,
                                  onChanged: (valor) {
                                    cambiarEstado(
                                      indice,
                                      valor ?? false,
                                    );
                                  },
                                ),
                                title: Text(
                                  tarea['nombre'] as String,
                                  style: TextStyle(
                                    decoration: terminada
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                                subtitle: Text(
                                  terminada
                                      ? 'Completada'
                                      : 'Pendiente',
                                ),
                                trailing: IconButton(
                                  tooltip: 'Eliminar actividad',
                                  onPressed: () =>
                                      eliminarTarea(indice),
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: colores.error,
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 20),

                          // Acceso al cuadro informativo.
                          Center(
                            child: TextButton.icon(
                              onPressed: () =>
                                  mostrarInformacion(context),
                              icon: const Icon(Icons.info_outline),
                              label:
                                  const Text('Acerca de mi proyecto'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  // Construye cada tarjeta del resumen.
  Widget tarjetaResumen(
    BuildContext context,
    String titulo,
    int cantidad,
    IconData icono,
  ) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                icono,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo),
                    Text(
                      '$cantidad',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}