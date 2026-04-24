import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UsersManageView extends StatefulWidget {
  const UsersManageView({super.key});

  @override
  State<UsersManageView> createState() => _UsersManageViewState();
}

class _UsersManageViewState extends State<UsersManageView> {
  bool _isLoading = true;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
          'https://sgeo-backend-production.up.railway.app/api/usuarios',
        ),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success' && mounted) {
          setState(() => _users = data['usuarios'] ?? []);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Personal'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchUsers),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUsers,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _users.isEmpty
            ? ListView(
                children: const [
                  SizedBox(
                    height: 500,
                    child: Center(child: Text('No hay usuarios registrados')),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: _users.length,
                itemBuilder: (ctx, i) {
                  final u = _users[i];
                  final rol = (u['rol'] ?? 'CIUDADANO')
                      .toString()
                      .toUpperCase();

                  IconData roleIcon = Icons.person;
                  Color roleColor = Colors.blue;

                  if (rol == 'POLICIA') {
                    roleIcon = Icons.local_police;
                    roleColor = Colors.green;
                  }
                  if (rol == 'ADMIN') {
                    roleIcon = Icons.security;
                    roleColor = Colors.red;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: roleColor.withOpacity(0.2),
                        child: Icon(roleIcon, color: roleColor),
                      ),
                      title: Text(u['nombre'] ?? 'Sin Nombre'),
                      subtitle: Text('Rol: $rol | Correo: ${u['email']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.block, color: Colors.redAccent),
                        tooltip: "Suspender",
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Intervención de usuarios estará disponible en la prox V.',
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
