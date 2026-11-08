import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/ui_helpers.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

/// Pantalla CRUD para la administración de Usuarios de Percucol.
/// Permite listar usuarios, cambiar roles entre Administrador y Cliente, y eliminar cuentas.
class UsersCrudScreen extends StatefulWidget {
  const UsersCrudScreen({super.key});

  @override
  State<UsersCrudScreen> createState() => _UsersCrudScreenState();
}

class _UsersCrudScreenState extends State<UsersCrudScreen> {
  final _searchController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openRoleDialog(UserModel user) {
    String currentRole = user.role.toLowerCase();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Gestionar Rol: ${user.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selecciona el nivel de acceso en la plataforma para este usuario:',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RadioGroup<String>(
                    groupValue: currentRole,
                    onChanged: (val) {
                      if (val != null) setDialogState(() => currentRole = val);
                    },
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'client',
                          title: const Text('Cliente / Músico', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Acceso a catálogo, compras y perfil', style: TextStyle(fontSize: 12)),
                        ),
                        RadioListTile<String>(
                          value: 'admin',
                          title: const Text('Administrador', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Acceso total al panel de administración y CRUDs', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    final success = await userProvider.changeUserRole(user.id!, currentRole);
                    if (!context.mounted) return;
                    if (success) {
                      Navigator.pop(ctx);
                      UIHelpers.showSnackBar(
                        context,
                        message: 'Rol de ${user.name} actualizado a $currentRole',
                        isSuccess: true,
                      );
                    }
                  },
                  child: const Text('Guardar Rol'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.id;

    final filteredUsers = userProvider.users.where((u) {
      if (_filter.isEmpty) return true;
      return u.name.toLowerCase().contains(_filter) ||
          u.email.toLowerCase().contains(_filter);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _filter = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar usuario por nombre o correo...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _filter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filter = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Listado de usuarios
          Expanded(
            child: userProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 64,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No se encontraron usuarios',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filteredUsers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final isMe = user.id == currentUserId;
                          final bool isAdmin = user.isAdmin;

                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isMe
                                    ? AppColors.primaryGold.withValues(alpha: 0.5)
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                width: isMe ? 1.5 : 1.0,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: isAdmin
                                    ? AppColors.primaryGold.withValues(alpha: 0.2)
                                    : AppColors.info.withValues(alpha: 0.2),
                                child: Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isAdmin ? AppColors.primaryGold : AppColors.info,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryGold.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'TÚ',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondaryGold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                    ),
                                  ),
                                  if (user.phone.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      user.phone,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  // Badge de Rol
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isAdmin
                                          ? AppColors.primaryGold.withValues(alpha: 0.15)
                                          : AppColors.info.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isAdmin
                                            ? AppColors.primaryGold.withValues(alpha: 0.4)
                                            : AppColors.info.withValues(alpha: 0.4),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      isAdmin ? 'ROL: ADMINISTRADOR' : 'ROL: CLIENTE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isAdmin ? AppColors.secondaryGold : AppColors.info,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.shield_outlined, size: 20),
                                    color: AppColors.secondaryGold,
                                    tooltip: 'Cambiar Rol',
                                    onPressed: () => _openRoleDialog(user),
                                  ),
                                  if (!isMe)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                      color: AppColors.outOfStockRed,
                                      tooltip: 'Eliminar Usuario',
                                      onPressed: () async {
                                        final confirm = await UIHelpers.showConfirmationDialog(
                                          context,
                                          title: '¿Eliminar Usuario?',
                                          content: 'Se eliminará la cuenta de "${user.name}" (${user.email}).',
                                          confirmLabel: 'Sí, eliminar',
                                        );

                                        if (confirm && context.mounted) {
                                          final success = await userProvider.deleteUser(user.id!);
                                          if (!context.mounted) return;
                                          if (success) {
                                            UIHelpers.showSnackBar(
                                              context,
                                              message: 'Usuario eliminado del sistema',
                                              isSuccess: true,
                                            );
                                          }
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

