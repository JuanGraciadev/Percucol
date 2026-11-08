import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/ui_helpers.dart';
import '../../providers/auth_provider.dart';

/// Pantalla de Perfil de Usuario para Percucol.
/// Permite tanto a Administradores como a Clientes consultar y actualizar
/// su información personal (Nombre, Teléfono, Dirección, Contraseña) y tema de la app.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  final _newPasswordController = TextEditingController();

  bool _isEditingPassword = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.updateProfile(
      name: _nameController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      newPassword: _isEditingPassword && _newPasswordController.text.isNotEmpty
          ? _newPasswordController.text
          : null,
    );

    if (!mounted) return;

    if (success) {
      UIHelpers.showSnackBar(
        context,
        message: '¡Perfil actualizado correctamente!',
        isSuccess: true,
      );
      setState(() {
        _isEditingPassword = false;
        _newPasswordController.clear();
      });
    } else {
      UIHelpers.showSnackBar(
        context,
        message: authProvider.errorMessage ?? 'Error al actualizar perfil',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Perfil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No has iniciado sesión'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                child: const Text('Iniciar Sesión'),
              ),
            ],
          ),
        ),
      );
    }

    final bool isAdmin = user.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar y Cabecera de Usuario
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: AppColors.primaryGold,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryGold,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isAdmin ? Icons.shield_rounded : Icons.music_note_rounded,
                              size: 18,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? AppColors.primaryGold.withValues(alpha: 0.15)
                            : AppColors.info.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isAdmin
                              ? AppColors.primaryGold.withValues(alpha: 0.4)
                              : AppColors.info.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        isAdmin ? 'ROL: ADMINISTRADOR' : 'ROL: CLIENTE / MÚSICO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isAdmin ? AppColors.secondaryGold : AppColors.info,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Acceso a Pedidos (si es cliente)
              if (!isAdmin) ...[
                ListTile(
                  tileColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  leading: const Icon(Icons.receipt_long_rounded, color: AppColors.primaryGold),
                  title: const Text('Mis Pedidos', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Historial y estado de entrega de tus compras'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.orders),
                ),
                const SizedBox(height: 16),
              ],

              // Preferencias de Tema
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: SwitchListTile(
                  title: const Text('Modo Oscuro (Dark Theme)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Paleta ébano y oro para ambiente musical', style: TextStyle(fontSize: 12)),
                  value: authProvider.isDarkMode,
                  activeThumbColor: AppColors.primaryGold,
                  onChanged: (_) => authProvider.toggleTheme(),
                ),
              ),
              const SizedBox(height: 24),

              // Formulario de Datos Personales
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Información Personal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Nombre
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'El nombre es requerido' : null,
              ),
              const SizedBox(height: 14),

              // Teléfono
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono de Contacto',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // Dirección
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección de Entrega',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // Opción para Cambiar Contraseña
              if (!_isEditingPassword)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.lock_reset_rounded, size: 18),
                    label: const Text('Cambiar mi contraseña'),
                    onPressed: () => setState(() => _isEditingPassword = true),
                  ),
                )
              else ...[
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    hintText: 'Mínimo 6 caracteres',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (_isEditingPassword && (v == null || v.length < 6)) {
                      return 'Mínimo 6 caracteres para la nueva contraseña';
                    }
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _isEditingPassword = false),
                    child: const Text('Cancelar cambio de clave', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Botón Guardar Cambios
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _saveProfileChanges,
                  child: authProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text(
                          'Guardar Información',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 18),

              // Botón Cerrar Sesión
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.outOfStockRed,
                    side: const BorderSide(color: AppColors.outOfStockRed, width: 1.2),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('Cerrar Sesión'),
                  onPressed: () async {
                    final confirm = await UIHelpers.showConfirmationDialog(
                      context,
                      title: '¿Cerrar Sesión?',
                      content: 'Se cerrará la sesión activa en este dispositivo.',
                      confirmLabel: 'Cerrar Sesión',
                      isDestructive: true,
                    );
                    if (confirm && context.mounted) {
                      await authProvider.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.index,
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

