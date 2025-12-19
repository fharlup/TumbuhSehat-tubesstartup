import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';

import 'package:mobile_tumbuh_sehat_v2/data/models/nutritionist_model.dart';
import 'package:mobile_tumbuh_sehat_v2/domain/repositories/chatbot_repository.dart';

part 'chatbot_state.dart';

class ChatbotCubit extends Cubit<ChatbotState> {
  final ChatbotRepository chatbotRepository;

  final types.User _user = const types.User(id: 'user');
  final types.User _bot = const types.User(
    id: 'bot',
    firstName: 'Sobat TumbuhSehat',
  );

  String? _threadId;

  // Data Dummy
  final List<NutritionistModel> availableNutritionists = [
    const NutritionistModel(
      id: 'ahli_1',
      name: 'Dr. Andi, Sp.GK',
      role: 'Ahli Gizi Klinis',
      isOnline: true,
    ),
    const NutritionistModel(
      id: 'ahli_2',
      name: 'Budi Santoso, S.Gz',
      role: 'Nutrisionis Olahraga',
      isOnline: false,
    ),
  ];

  ChatbotCubit({required this.chatbotRepository})
      : super(const ChatbotInitial());

  // --- LOGIKA UTAMA ---
  Future<void> selectNutritionistForConsultation(NutritionistModel nutritionist) async {
    emit(ChatbotLoading(
      messages: state.messages,
      selectedNutritionist: state.selectedNutritionist,
    ));

    try {
      // ============================================================
      // 1. MASUKKAN SERVER KEY DI SINI (Wajib!)
      // Format: SB-Mid-server-xxxxxxxxxxxx
      // ============================================================
      const String serverKey = "SB-Mid-server-iS0oDxiHU07Ld8EAbHnBMwqo"; 
      
      if (serverKey.contains("MASUKKAN")) {
         throw Exception("Server Key belum diisi di chatbot_cubit.dart!");
      }

      // 2. Request Token ke Midtrans
      final String snapToken = await _generateSnapToken(serverKey, nutritionist);

      // 3. Emit State agar UI membuka WebView
      emit(ChatbotPaymentRequired(
        nutritionist: nutritionist,
        snapToken: snapToken,
        messages: state.messages,
        selectedNutritionist: state.selectedNutritionist,
      ));
    } catch (e) {
      emit(ChatbotError(
        message: "Gagal memproses transaksi: $e",
        messages: state.messages,
        selectedNutritionist: state.selectedNutritionist,
      ));
    }
  }

  Future<String> _generateSnapToken(String serverKey, NutritionistModel nutritionist) async {
    final dio = Dio();
    final authHeader = base64Encode(utf8.encode('$serverKey:')); 
    final orderId = "ORDER-${DateTime.now().millisecondsSinceEpoch}";

    try {
      final response = await dio.post(
        'https://app.sandbox.midtrans.com/snap/v1/transactions',
        options: Options(
          headers: {
            'Authorization': 'Basic $authHeader',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
        data: {
          "transaction_details": {
            "order_id": orderId,
            "gross_amount": 50000, 
          },
          "item_details": [
            {
              "id": "CONSULT-${nutritionist.id}",
              "price": 50000,
              "quantity": 1,
              "name": "Konsultasi ${nutritionist.name}"
            }
          ],
          "customer_details": {
            "first_name": "User",
            "email": "user@tumbuhsehat.com",
            "phone": "08123456789"
          }
        },
      );
      return response.data['token'];
    } catch (e) {
      throw Exception("Gagal mendapatkan token: $e");
    }
  }

  // --- LOGIKA CHAT (AI & Human) ---
  void initChat({NutritionistModel? nutritionist}) {
    final isHuman = nutritionist != null;
    final chatPartner = types.User(
      id: isHuman ? nutritionist!.id : _bot.id,
      firstName: isHuman ? nutritionist!.name : _bot.firstName,
      imageUrl: isHuman ? nutritionist!.photoUrl : null,
    );

    final String initialText = isHuman
        ? 'Halo! Saya ${nutritionist!.name}. Pembayaran dikonfirmasi. Ada yang bisa saya bantu?'
        : 'Halo! Saya Sobat TumbuhSehat. Ada yang bisa saya bantu?';

    final initialMessage = types.TextMessage(
      author: chatPartner,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: initialText,
    );

    emit(ChatbotLoaded(
      messages: [initialMessage],
      selectedNutritionist: nutritionist,
    ));
  }

  void sendMessage(types.PartialText message) async {
    if (state is! ChatbotLoaded && state is! ChatbotLoading) return;

    final currentMessages = state.messages;
    final currentNutritionist = state.selectedNutritionist;

    final userMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    final updatedMessages = [userMessage, ...currentMessages];
    
    emit(ChatbotLoading(
      messages: updatedMessages,
      selectedNutritionist: currentNutritionist,
    ));

    if (currentNutritionist == null) {
      await _handleAIChat(message.text, updatedMessages);
    } else {
      await _handleHumanChat(message.text, updatedMessages, currentNutritionist);
    }
  }

  Future<void> _handleAIChat(String text, List<types.Message> currentMessages) async {
    final result = await chatbotRepository.getChatResponse(
      message: text,
      threadId: _threadId,
    );

    result.fold(
      (failure) {
        final errorMessage = types.TextMessage(
          author: _bot,
          id: const Uuid().v4(),
          text: 'Error: ${failure.message}',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        emit(ChatbotError(
          message: failure.message,
          messages: [errorMessage, ...currentMessages],
          selectedNutritionist: null,
        ));
      },
      (response) {
        final botMessage = types.TextMessage(
          author: _bot,
          id: const Uuid().v4(),
          text: response,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        emit(ChatbotLoaded(
          messages: [botMessage, ...currentMessages],
          selectedNutritionist: null,
        ));
      },
    );
  }

  Future<void> _handleHumanChat(
    String text, 
    List<types.Message> currentMessages, 
    NutritionistModel nutritionist
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    emit(ChatbotLoaded(
      messages: currentMessages, 
      selectedNutritionist: nutritionist,
    ));
  }
}