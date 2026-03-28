import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class SignOutEvent extends AuthEvent {}

class SendOtpEvent extends AuthEvent {
  final String phoneNumber;
  SendOtpEvent(this.phoneNumber);
  @override
  List<Object?> get props => [phoneNumber];
}

class VerifyOtpEvent extends AuthEvent {
  final String otp;
  VerifyOtpEvent(this.otp);
  @override
  List<Object?> get props => [otp];
}

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class OtpSent extends AuthState {
  final String verificationId;
  OtpSent(this.verificationId);
  @override
  List<Object?> get props => [verificationId];
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;

  AuthBloc() : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuth);
    on<SendOtpEvent>(_onSendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<SignOutEvent>(_onSignOut);
  }

  void _onCheckAuth(CheckAuthStatus event, Emitter<AuthState> emit) {
    final user = _auth.currentUser;
    emit(user != null ? AuthAuthenticated() : AuthUnauthenticated());
  }

  Future<void> _onSendOtp(SendOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final completer = Completer<AuthState>();
    await _auth.verifyPhoneNumber(
      phoneNumber: event.phoneNumber,
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
        if (!completer.isCompleted) completer.complete(AuthAuthenticated());
      },
      verificationFailed: (e) {
        if (!completer.isCompleted)
          completer.complete(AuthError(e.message ?? 'Ошибка'));
      },
      codeSent: (verificationId, _) {
        _verificationId = verificationId;
        if (!completer.isCompleted) completer.complete(OtpSent(verificationId));
      },
      codeAutoRetrievalTimeout: (_) {
        if (!completer.isCompleted) completer.complete(AuthUnauthenticated());
      },
    );
    emit(await completer.future);
  }

  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: event.otp,
      );
      await _auth.signInWithCredential(credential);
      emit(AuthAuthenticated());
    } catch (e) {
      emit(AuthError('Неверный код. Попробуй ещё раз.'));
    }
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    await _auth.signOut();
    emit(AuthUnauthenticated());
  }
}
