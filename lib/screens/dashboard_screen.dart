import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './order_detail_screen.dart';
import './measures_screen.dart';
import './catalog_screen.dart';
import './profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<String> _opcionesEstado = [
    'En espera de aceptación',
    'En proceso',
    'Listo para prueba',
    'Listo para entrega',
    'Entregado',
    'Cancelado',
  ];

  Future<void> _updateOrderStatus(
    String orderId,
    String newStatus,
    String clientId,
    String folio,
  ) async {
    await FirebaseFirestore.instance.collection('pedidos').doc(orderId).update({
      'estado': newStatus,
    });

    // Notificar a la clienta sobre el cambio de estado
    await FirebaseFirestore.instance.collection('notificaciones').add({
      'id_usuario': clientId,
      'id_pedido': orderId,
      'mensaje': 'Tu pedido $folio cambió a "$newStatus".',
      'leida': false,
      'fecha_envio': FieldValue.serverTimestamp(),
    });
  }

  void _showNotificationMenu(BuildContext context, List<QueryDocumentSnapshot> notifs) {
    showDialog(
      context: context,
      barrierColor: Colors.black12,
      builder: (BuildContext dialogContext) {
        return Stack(
          children: [
            Positioned(
              top: 60,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Notificaciones del Taller',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          if (notifs.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: const BoxDecoration(color: Color(0xFFD49B9B), shape: BoxShape.circle),
                              child: Text(
                                '${notifs.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 16),
                      if (notifs.isNotEmpty) ...[
                        ...notifs.take(3).map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('📌', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    data['mensaje'] ?? '',
                                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 12),
                        Center(
                          child: InkWell(
                            onTap: () async {
                              for (var doc in notifs) {
                                await doc.reference.update({'leida': true});
                              }
                              if (dialogContext.mounted) Navigator.pop(dialogContext);
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                'Marcar todas como leídas',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Center(
                            child: Text(
                              'No tienes notificaciones pendientes',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      drawer: Drawer(
        backgroundColor: const Color(0xFFF7F5F0),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
                      children: [
                        TextSpan(text: 'costura'),
                        TextSpan(text: '.', style: TextStyle(color: Color(0xFFD49B9B))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Módulo Costurera', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Color(0xFFD49B9B)),
              title: const Text('Pedidos', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.square_foot, color: Colors.grey),
              title: const Text('Medidas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MeasuresScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.style, color: Colors.grey),
              title: const Text('Catálogo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CatalogScreen(isAdmin: true)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.grey),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen(isAdmin: true)));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
            children: [
              TextSpan(text: 'costura'),
              TextSpan(text: '.', style: TextStyle(color: Color(0xFFD49B9B))),
            ],
          ),
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notificaciones')
                .where('para_rol', isEqualTo: 'costurera')
                .where('leida', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final notifs = snapshot.data?.docs ?? [];
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.black, size: 26),
                    onPressed: () => _showNotificationMenu(context, notifs),
                  ),
                  if (notifs.isNotEmpty)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Color(0xFFE57373), shape: BoxShape.circle),
                        child: Text(
                          '${notifs.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen(isAdmin: true)));
            },
            child: const CircleAvatar(
              backgroundColor: Color(0xFF2C3E50),
              radius: 16,
              child: Text('AC', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('pedidos').snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          final int pendientes = docs.where((d) {
            final st = (d.data() as Map<String, dynamic>)['estado'] ?? '';
            return st != 'Entregado' && st != 'Cancelado';
          }).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MÓDULO COSTURERA',
                  style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 4),
                const Text('Buenos días, Ana ✨', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const Text('Aquí tienes el resumen de tu taller.', style: TextStyle(color: Colors.grey, fontSize: 15)),
                const SizedBox(height: 20),

                // Métricas dinámicas
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.checkroom,
                        value: '$pendientes',
                        title: 'Pedidos activos',
                        subtitle: 'En taller',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.calendar_today_outlined,
                        value: '${docs.length}',
                        title: 'Total registrados',
                        subtitle: 'Historial',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),
                const Text('Pedidos del taller', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator(color: Color(0xFFD49B9B)))
                else if (docs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Center(
                      child: Text('No hay pedidos en el taller todavía.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  Column(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final String currentStatus = data['estado'] ?? 'En espera de aceptación';
                      final String validStatus =
                          _opcionesEstado.contains(currentStatus) ? currentStatus : _opcionesEstado.first;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildOrderCard(
                          orderId: doc.id,
                          clientId: data['id_usuario'] ?? '',
                          id: data['folio'] ?? '#000',
                          client: data['nombre_cliente'] ?? 'Clienta',
                          title: data['titulo_prenda'] ?? 'Pedido',
                          date: 'Entrega · ${data['fecha_entrega'] ?? ''}',
                          price: '\$${data['costo_total'] ?? '0.00'}',
                          currentStatus: validStatus,
                          onStatusChanged: (val) {
                            if (val != null) {
                              _updateOrderStatus(
                                doc.id,
                                val,
                                data['id_usuario'] ?? '',
                                data['folio'] ?? '#000',
                              );
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF8E8E93), size: 22),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildOrderCard({
    required String orderId,
    required String clientId,
    required String id,
    required String client,
    required String title,
    required String date,
    required String price,
    required String currentStatus,
    required ValueChanged<String?> onStatusChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF7F5F0), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.content_cut, color: Color(0xFFD49B9B), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$id · $client', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: const Color(0xFFF2F0EB), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currentStatus,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87, size: 20),
                      style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600),
                      onChanged: onStatusChanged,
                      items: _opcionesEstado.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderDetailScreen(isAdmin: true, orderId: orderId)),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0xFF2C3E50), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Ver detalles / Chat',
                        style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}