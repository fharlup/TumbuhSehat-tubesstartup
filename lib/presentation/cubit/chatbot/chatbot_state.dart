part of 'chatbot_cubit.dart';

sealed class ChatbotState extends Equatable {
  final List<types.Message> messages;
  final NutritionistModel? selectedNutritionist;

  const ChatbotState({
    required this.messages,
    this.selectedNutritionist,
  });

  @override
  List<Object?> get props => [messages, selectedNutritionist];
}

final class ChatbotInitial extends ChatbotState {
  const ChatbotInitial() : super(messages: const [], selectedNutritionist: null);
}

final class ChatbotLoading extends ChatbotState {
  const ChatbotLoading({
    required super.messages,
    super.selectedNutritionist,
  });
}

final class ChatbotLoaded extends ChatbotState {
  const ChatbotLoaded({
    required super.messages,
    super.selectedNutritionist,
  });
  
  ChatbotLoaded copyWith({
    List<types.Message>? messages,
    NutritionistModel? selectedNutritionist,
  }) {
    return ChatbotLoaded(
      messages: messages ?? this.messages,
      selectedNutritionist: selectedNutritionist ?? this.selectedNutritionist,
    );
  }
}

// State untuk memicu WebView Midtrans
final class ChatbotPaymentRequired extends ChatbotState {
  final NutritionistModel nutritionist;
  final String snapToken; // Token ini yang akan membuka WebView

  const ChatbotPaymentRequired({
    required this.nutritionist,
    required this.snapToken,
    required super.messages,
    super.selectedNutritionist,
  });

  @override
  List<Object?> get props => [nutritionist, snapToken, messages, selectedNutritionist];
}

final class ChatbotError extends ChatbotState {
  final String message;

  const ChatbotError({
    required this.message,
    required super.messages,
    super.selectedNutritionist,
  });

  @override
  List<Object?> get props => [message, messages, selectedNutritionist];
}