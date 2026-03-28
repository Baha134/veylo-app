import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.pushReplacementNamed(context, '/home');
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Вход'),
            backgroundColor: AppColors.background,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: state is OtpSent
                  ? _buildOtpForm(context, state)
                  : _buildPhoneForm(context, state),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhoneForm(BuildContext context, AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text(
          'Введи номер\nтелефона',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Отправим SMS с кодом подтверждения',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            hintText: '+7 (___) ___-__-__',
            prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary),
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: state is AuthLoading
              ? null
              : () {
                  context.read<AuthBloc>().add(
                    SendOtpEvent(_phoneController.text.trim()),
                  );
                },
          child: state is AuthLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Получить код'),
        ),
      ],
    );
  }

  Widget _buildOtpForm(BuildContext context, AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text(
          'Введи код\nиз SMS',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Код отправлен на твой номер',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            hintText: '000000',
            counterText: '',
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: state is AuthLoading
              ? null
              : () {
                  context.read<AuthBloc>().add(
                    VerifyOtpEvent(_otpController.text.trim()),
                  );
                },
          child: state is AuthLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Подтвердить'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            context.read<AuthBloc>().add(CheckAuthStatus());
          },
          child: const Text(
            'Изменить номер',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
