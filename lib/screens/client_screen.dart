import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './order_detail_screen.dart';
import './create_order_screen.dart';
import './catalog_screen.dart';
import './profile_screen.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  Color _getStatusBg(String status) {
    switch (status) {
      case 'En proceso':
        return const Color(0xFFE8F5E9);
      case 'Listo para prueba':
      case 'Listo para entrega':
        return const Color(0xFFFFF3E0);
      case 'Cancelado':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFE3F2FD);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'En proceso':
        return const Color(0xFF2E7D32);
      case 'Listo para prueba':
      case 'Listo para entrega':
        return const Color(0xFFE65100);
      case 'Cancelado':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF1565C0);
    }
  }

  Future<void> _cancelOrder(String orderId, String folio) async {
    await FirebaseFirestore.instance.collection('pedidos').doc(orderId).update({
      'estado': 'Cancelado',
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido $folio marcado como Cancelado'),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
    }
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
                          const Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                                const Text('✨', style: TextStyle(fontSize: 12)),
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
                  const Text('Módulo Clienta', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Color(0xFFD49B9B)),
              title: const Text('Pedidos', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.style, color: Colors.grey),
              title: const Text('Catálogo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CatalogScreen(isAdmin: false)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.grey),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen(isAdmin: false)),
                );
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
                .where('id_usuario', isEqualTo: _uid)
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen(isAdmin: false)),
              );
            },
            child: const CircleAvatar(
              backgroundColor: Color(0xFFD49B9B),
              radius: 16,
              child: Text('MG', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BIENVENIDA',
              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 4),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('usuarios').doc(_uid).snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final String name = (data?['nombre'] ?? 'María').toString().split(' ').first;
                return Text('Hola, $name ✨', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold));
              },
            ),
            const Text('¿Qué vamos a crear hoy?', style: TextStyle(color: Colors.grey, fontSize: 15)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('¿Qué necesitas?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
                    );
                  },
                  child: const Text('Ver servicios >', style: TextStyle(color: Color(0xFFD49B9B), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildServiceCard(
                    context: context,
                    icon: Icons.content_cut,
                    title: 'Ajustes y Reparaciones',
                    subtitle: 'Desde \$80.00',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildServiceCard(
                    context: context,
                    icon: Icons.edit_note,
                    title: 'Confección a Medida',
                    subtitle: 'Diseñemos juntas',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tus pedidos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Color(0xFFD49B9B), shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // LISTA EN TIEMPO REAL DE PEDIDOS DE LA CLIENTA DESDE FIRESTORE
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pedidos')
                  .where('id_usuario', isEqualTo: _uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: Color(0xFFD49B9B)),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Column(
                      children: [
                        Icon(Icons.checkroom_outlined, color: Colors.grey, size: 36),
                        SizedBox(height: 8),
                        Text('Aún no tienes pedidos registrados', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Presiona el botón + para solicitar tu primer arreglo.',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final String status = data['estado'] ?? 'En espera de aceptación';
                    final String folio = data['folio'] ?? '#000';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildOrderCard(
                        context: context,
                        orderId: doc.id,
                        id: folio,
                        title: data['titulo_prenda'] ?? 'Servicio',
                        date: 'Entrega · ${data['fecha_entrega'] ?? ''}',
                        statusText: status,
                        statusBg: _getStatusBg(status),
                        statusTextColor: _getStatusTextColor(status),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreateOrderScreen(initialService: title)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: const Color(0xFFD49B9B), size: 24),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required BuildContext context,
    required String orderId,
    required String id,
    required String title,
    required String date,
    required String statusText,
    required Color statusBg,
    required Color statusTextColor,
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
                    Text(id, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Colors.grey),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'details') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OrderDetailScreen(isAdmin: false, orderId: orderId)),
                    );
                  } else if (value == 'cancel') {
                    _cancelOrder(orderId, id);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'details',
                    child: Text('Ver detalles', style: TextStyle(fontSize: 13)),
                  ),
                  const PopupMenuItem<String>(
                    value: 'cancel',
                    child: Text('Cancelar pedido', style: TextStyle(fontSize: 13, color: Color(0xFFC62828))),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 11, color: statusTextColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OrderDetailScreen(isAdmin: false, orderId: orderId)),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 32,
                    alignment: Alignment.center,
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}