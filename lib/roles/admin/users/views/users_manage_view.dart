// Reescrito: usa AdminService (GET /api/admin/usuarios, antes apuntaba a un endpoint que no
// existia) y agrega chips de filtro, menu contextual de Suspender/Eliminar.
// Rediseño visual v2: RoleBadge y StatusBadge reemplazan los chips de rol/estado armados a
// mano (icono de cada fila ahora usa el mismo color que su RoleBadge, antes no coincidian).
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/safety_layout.dart';
import '../../../../core/widgets/safety_card.dart';
import '../../../../core/widgets/role_badge.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/skeleton_loader.dart';

enum _UserFilter { todos, ciudadanos, policias, suspendidos }

class UsersManageView extends StatefulWidget {
  const UsersManageView({super.key});

  @override
  State<UsersManageView> createState() => _UsersManageViewState();
}

class _UsersManageViewState extends State<UsersManageView> {
  bool _isLoading = true;
  List<dynamic> _allUsers = [];
  _UserFilter _filter = _UserFilter.todos;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final resultado = await AdminService.getUsuarios();
    if (mounted) {
      if (resultado['success'] == true) {
        setState(() {
          _allUsers = resultado['usuarios'] as List;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resultado['message'] ?? 'No se pudo cargar la lista.',
            ),
            backgroundColor: AppTheme.alertRed,
          ),
        );
      }
    }
  }

  List<dynamic> get _filteredUsers {
    switch (_filter) {
      case _UserFilter.ciudadanos:
        return _allUsers
            .where(
              (u) => (u['rol'] ?? '').toString().toLowerCase() == 'ciudadano',
            )
            .toList();
      case _UserFilter.policias:
        return _allUsers
            .where(
              (u) => (u['rol'] ?? '').toString().toLowerCase() == 'policia',
            )
            .toList();
      case _UserFilter.suspendidos:
        return _allUsers.where((u) => u['activo'] == false).toList();
      case _UserFilter.todos:
        return _allUsers;
    }
  }

  Future<void> _confirmarEliminar(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Eliminar permanentemente la cuenta de ${user['nombre']}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alertRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final resultado = await AdminService.eliminarUsuario(user['_id']);
    if (!mounted) return;
    if (resultado['success'] == true) {
      setState(() => _allUsers.removeWhere((u) => u['_id'] == user['_id']));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message'] ?? 'Usuario eliminado.'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultado['message'] ?? 'No se pudo eliminar el usuario.',
          ),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    }
  }

  Future<void> _toggleSuspender(Map<String, dynamic> user) async {
    final resultado = await AdminService.suspenderUsuario(user['_id']);
    if (!mounted) return;
    if (resultado['success'] == true) {
      setState(() => user['activo'] = resultado['activo']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultado['activo'] == true
                ? 'Usuario reactivado.'
                : 'Usuario suspendido.',
          ),
          backgroundColor: resultado['activo'] == true
              ? AppTheme.successGreen
              : AppTheme.alertAmber,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultado['message'] ?? 'No se pudo cambiar el estado.',
          ),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    }
  }

  Widget _buildFilterChip(String label, _UserFilter value, bool isDark) {
    final isActive = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isActive,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppTheme.accentCyan.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isActive
              ? AppTheme.accentCyan
              : (isDark ? Colors.white70 : Colors.black54),
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        ),
        backgroundColor: isDark ? AppTheme.bgSurface : Colors.white,
        side: BorderSide(
          color: isActive
              ? AppTheme.accentCyan
              : (isDark ? AppTheme.borderSubtle : Colors.grey.shade300),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final users = _filteredUsers;

    return SafetyLayout(
      showGradientBackground: true,
      appBar: AppBar(
        title: const Text('Gestión de Personal'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', _UserFilter.todos, isDark),
                  _buildFilterChip(
                    'Ciudadanos',
                    _UserFilter.ciudadanos,
                    isDark,
                  ),
                  _buildFilterChip('Policías', _UserFilter.policias, isDark),
                  _buildFilterChip(
                    'Suspendidos',
                    _UserFilter.suspendidos,
                    isDark,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchUsers,
              child: _isLoading
                  ? const SkeletonLoader(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    )
                  : users.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_alt_outlined,
                                  size: 60,
                                  color: isDark
                                      ? AppTheme.textMuted
                                      : Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay usuarios en este filtro',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppTheme.textSecondary
                                        : Colors.grey[700],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(duration: 400.ms),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      itemCount: users.length,
                      itemBuilder: (ctx, i) {
                        final u = users[i];
                        final rol = (u['rol'] ?? 'CIUDADANO')
                            .toString()
                            .toUpperCase();
                        final bool activo = u['activo'] != false;
                        final bool pendiente =
                            u['aprobacion_pendiente'] == true;

                        IconData roleIcon = Icons.person_rounded;
                        if (rol == 'POLICIA') {
                          roleIcon = Icons.local_police_rounded;
                        } else if (rol == 'ADMIN' || rol == 'ADMINISTRADOR') {
                          roleIcon = Icons.admin_panel_settings_rounded;
                        }
                        final Color roleColor = RoleBadge.colorFor(rol);

                        final String estadoStatus = pendiente
                            ? 'pendiente'
                            : (activo ? 'activo' : 'suspendido');

                        return SafetyCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: roleColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: roleColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Icon(
                                      roleIcon,
                                      color: roleColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          u['nombre'] ?? 'Sin Nombre',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: isDark
                                                ? AppTheme.textPrimary
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          u['email'] ?? 'Sin Correo',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark
                                                ? AppTheme.textSecondary
                                                : Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            RoleBadge(role: rol),
                                            StatusBadge(status: estadoStatus),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert_rounded,
                                      color: isDark
                                          ? AppTheme.textSecondary
                                          : Colors.grey[700],
                                    ),
                                    onSelected: (value) {
                                      if (value == 'suspender')
                                        _toggleSuspender(u);
                                      if (value == 'eliminar')
                                        _confirmarEliminar(u);
                                    },
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem(
                                        value: 'suspender',
                                        child: Text(
                                          activo ? 'Suspender' : 'Reactivar',
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'eliminar',
                                        child: Text(
                                          'Eliminar',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(
                              delay: Duration(milliseconds: 50 * i),
                              duration: 300.ms,
                            )
                            .slideX(
                              begin: 0.05,
                              end: 0,
                              duration: 300.ms,
                              curve: Curves.easeOut,
                            );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
