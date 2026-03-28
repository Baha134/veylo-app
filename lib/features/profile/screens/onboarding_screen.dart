import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _repo = ProfileRepository();
  int _currentStep = 0;

  // Шаг 1
  final _nicknameController = TextEditingController();
  int _age = 18;
  String? _selectedCity;

  // Шаг 2
  final Set<String> _selectedInterests = {};

  // Шаг 3
  File? _silhouetteFile;
  bool _isProcessing = false;
  bool _isSaving = false;

  static const List<String> _cities = [
    'Алматы',
    'Астана',
    'Шымкент',
    'Актобе',
    'Тараз',
    'Павлодар',
    'Усть-Каменогорск',
    'Семей',
    'Атырау',
    'Костанай',
    'Кызылорда',
    'Уральск',
    'Петропавловск',
    'Актау',
    'Темиртау',
    'Туркестан',
    'Кокшетау',
    'Талдыкорган',
    'Экибастуз',
    'Рудный',
    'Москва',
    'Санкт-Петербург',
    'Бишкек',
    'Ташкент',
    'Баку',
    'Тбилиси',
    'Минск',
    'Киев',
    'Берлин',
    'Лондон',
    'Дубай',
    'Стамбул',
    'Токио',
    'Сеул',
    'Нью-Йорк',
    'Лос-Анджелес',
    'Торонто',
    'Сидней',
    'Амстердам',
    'Париж',
  ];

  static const List<String> _allInterests = [
    '🎵 Музыка',
    '🎬 Кино',
    '📚 Книги',
    '🎮 Игры',
    '✈️ Путешествия',
    '🍕 Еда',
    '💪 Спорт',
    '🎨 Искусство',
    '💻 Технологии',
    '🌿 Природа',
    '📸 Фото',
    '🎭 Театр',
    '🏋️ Фитнес',
    '🧘 Медитация',
    '🐾 Животные',
    '🎯 Настолки',
    '🚴 Велоспорт',
    '🌙 Ночная жизнь',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep == 1 && !_validateStep2()) return;

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateStep1() {
    if (_nicknameController.text.trim().length < 2) {
      _showSnack('Никнейм должен быть минимум 2 символа');
      return false;
    }
    if (_selectedCity == null) {
      _showSnack('Выбери город');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_selectedInterests.length < 3) {
      _showSnack('Выбери минимум 3 интереса');
      return false;
    }
    return true;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _pickAndProcessPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isProcessing = true);

    try {
      final silhouette = await _generateSilhouette(File(picked.path));
      setState(() {
        _silhouetteFile = silhouette;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnack('Не удалось обработать фото. Попробуй другое.');
    }
  }

  Future<File> _generateSilhouette(File imageFile) async {
    final segmenter = SelfieSegmenter(
      mode: SegmenterMode.single,
      enableRawSizeMask: false,
    );

    final inputImage = InputImage.fromFile(imageFile);
    final mask = await segmenter.processImage(inputImage);
    await segmenter.close();

    if (mask == null) throw Exception('Маска не получена');

    // Читаем оригинальное изображение

    // Создаём силуэт: человек = тёмно-фиолетовый, фон = прозрачный
    final width = mask.width;
    final height = mask.height;
    final silhouette = img.Image(width: width, height: height);

    final confidence = mask.confidences;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final conf = confidence[idx];
        if (conf > 0.5) {
          // Человек — рисуем тёмно-фиолетовый пиксель
          silhouette.setPixelRgba(x, y, 60, 40, 120, 255);
        } else {
          // Фон — прозрачный
          silhouette.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }

    // Сохраняем PNG
    final tempDir = Directory.systemTemp;
    final outFile = File(
      '${tempDir.path}/silhouette_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await outFile.writeAsBytes(img.encodePng(silhouette));
    return outFile;
  }

  Future<void> _saveProfile() async {
    if (_silhouetteFile == null) {
      _showSnack('Добавь фото для силуэта');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Загружаем силуэт в Storage
      final avatarUrl = await _repo.uploadSilhouette(uid, _silhouetteFile!);

      // Сохраняем профиль в Firestore
      final profile = UserProfile(
        uid: uid,
        nickname: _nicknameController.text.trim(),
        age: _age,
        city: _selectedCity!,
        interests: _selectedInterests.toList(),
        avatarUrl: avatarUrl,
        isProfileComplete: true,
        isVisible: true,
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
      );

      await _repo.saveProfile(profile);

      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnack('Ошибка сохранения: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [_buildStep1(), _buildStep2(), _buildStep3()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: List.generate(3, (i) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              decoration: BoxDecoration(
                color: i <= _currentStep
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Шаг 1: Данные ───────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            'Расскажи о себе',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Это увидят другие пользователи',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 40),

          // Никнейм
          _label('Никнейм'),
          const SizedBox(height: 8),
          TextField(
            controller: _nicknameController,
            maxLength: 20,
            decoration: _inputDecoration('Например: Сокол_777'),
          ),
          const SizedBox(height: 24),

          // Возраст
          _label('Возраст: $_age'),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              thumbColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _age.toDouble(),
              min: 18,
              max: 35,
              divisions: 17,
              onChanged: (v) => setState(() => _age = v.round()),
            ),
          ),
          const SizedBox(height: 24),

          // Город
          _label('Город'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCity,
            decoration: _inputDecoration('Выбери город'),
            items: _cities
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _selectedCity = v),
            dropdownColor: AppColors.background,
          ),
          const SizedBox(height: 48),

          _primaryButton('Далее →', _nextStep),
        ],
      ),
    );
  }

  // ─── Шаг 2: Интересы ─────────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            'Твои интересы',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выбрано: ${_selectedInterests.length} (минимум 3)',
            style: TextStyle(
              fontSize: 15,
              color: _selectedInterests.length >= 3
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _allInterests.map((tag) {
              final selected = _selectedInterests.contains(tag);
              return GestureDetector(
                onTap: () => setState(() {
                  selected
                      ? _selectedInterests.remove(tag)
                      : _selectedInterests.add(tag);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 48),
          _primaryButton('Далее →', _nextStep),
        ],
      ),
    );
  }

  // ─── Шаг 3: Аватар ───────────────────────────────────────────────
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            'Твой силуэт',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Загрузи своё фото — другие увидят только силуэт. Реальное фото нигде не сохраняется.',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 40),

          // Превью силуэта
          Center(
            child: GestureDetector(
              onTap: _isProcessing ? null : _pickAndProcessPhoto,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: _isProcessing
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _silhouetteFile != null
                    ? ClipOval(
                        child: Image.file(_silhouetteFile!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 64,
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Нажми чтобы\nвыбрать фото',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          if (_silhouetteFile != null) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _pickAndProcessPhoto,
                child: const Text(
                  'Выбрать другое фото',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ),
          ],

          const SizedBox(height: 48),

          _isSaving
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _primaryButton(
                  _silhouetteFile != null
                      ? 'Создать профиль 🌸'
                      : 'Пропустить пока →',
                  _silhouetteFile != null ? _saveProfile : _saveWithoutPhoto,
                ),
        ],
      ),
    );
  }

  Future<void> _saveWithoutPhoto() async {
    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final profile = UserProfile(
        uid: uid,
        nickname: _nicknameController.text.trim(),
        age: _age,
        city: _selectedCity!,
        interests: _selectedInterests.toList(),
        avatarUrl: null,
        isProfileComplete: true,
        isVisible: true,
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
      );
      await _repo.saveProfile(profile);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnack('Ошибка: $e');
    }
  }

  // ─── Хелперы UI ──────────────────────────────────────────────────
  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6)),
    filled: true,
    fillColor: AppColors.primary.withValues(alpha: 0.05),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    counterStyle: TextStyle(
      color: AppColors.textSecondary.withValues(alpha: 0.5),
    ),
  );

  Widget _primaryButton(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
