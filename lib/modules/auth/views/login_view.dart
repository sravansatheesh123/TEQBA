import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/theme_helper.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeHelper.isDark || ThemeHelper.isEyeComfort;
      final textPrim = ThemeHelper.textPrimary;
      final textSec = ThemeHelper.textSecondary;
      final primary = ThemeHelper.primaryColor;
      final cardBg = ThemeHelper.cardColor;
      final border = ThemeHelper.cardBorder;

      return Scaffold(
        backgroundColor: ThemeHelper.background,
        appBar: AppBar(
          backgroundColor: ThemeHelper.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.hub_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'REBS HRMS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textPrim,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Branding Header
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, primary.withValues(alpha: 0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Employee Portal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textPrim,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to mark attendance & manage leaves',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSec,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // 2. Login Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: border, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username / ID Field
                        Text(
                          'Employee ID / Email',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textPrim,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: controller.usernameController,
                          style: TextStyle(fontSize: 13, color: textPrim, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.badge_rounded, color: primary, size: 18),
                            hintText: 'Enter employee ID or email',
                            hintStyle: TextStyle(color: textSec.withValues(alpha: 0.6), fontSize: 12),
                            filled: true,
                            fillColor: ThemeHelper.surfaceVariant,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primary, width: 1.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Password Field
                        Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textPrim,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Obx(() {
                          final isVisible = controller.isPasswordVisible.value;
                          return TextField(
                            controller: controller.passwordController,
                            obscureText: !isVisible,
                            style: TextStyle(fontSize: 13, color: textPrim, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.lock_rounded, color: primary, size: 18),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                  color: textSec,
                                  size: 18,
                                ),
                                onPressed: () => controller.togglePasswordVisibility(),
                              ),
                              hintText: 'Enter password',
                              hintStyle: TextStyle(color: textSec.withValues(alpha: 0.6), fontSize: 12),
                              filled: true,
                              fillColor: ThemeHelper.surfaceVariant,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primary, width: 1.8),
                              ),
                            ),
                            onSubmitted: (_) => controller.login(),
                          );
                        }),
                        const SizedBox(height: 10),

                        // Remember Me row
                        Obx(() {
                          return Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: controller.rememberMe.value,
                                  activeColor: primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (val) => controller.rememberMe.value = val ?? true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => controller.rememberMe.value = !controller.rememberMe.value,
                                child: Text(
                                  'Keep me logged in',
                                  style: TextStyle(fontSize: 11.5, color: textSec, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          );
                        }),

                        // Error Banner (if any)
                        Obx(() {
                          if (controller.errorMessage.isEmpty) return const SizedBox.shrink();
                          return Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    controller.errorMessage.value,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFFDC2626),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 18),

                        // 4. Submit & Sign In Button
                        Obx(() {
                          final isBusy = controller.isLoading.value;
                          return Container(
                            width: double.infinity,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primary, primary.withValues(alpha: 0.85)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: isBusy ? null : () => controller.login(),
                              child: isBusy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.login_rounded, color: Colors.white, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Sign In to Workspace',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. Security & Offline Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_rounded, size: 13, color: textSec.withValues(alpha: 0.7)),
                      const SizedBox(width: 5),
                      Text(
                        'Secure corporate portal  •  Offline support enabled',
                        style: TextStyle(fontSize: 10.5, color: textSec.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
