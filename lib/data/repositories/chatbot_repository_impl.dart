import 'package:dartz/dartz.dart'; // Pastikan ada dartz
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/repositories/chatbot_repository.dart';
import '../../core/error/failures.dart'; // Sesuaikan path failure kamu
import 'package:flutter_dotenv/flutter_dotenv.dart';
class ChatbotRepositoryImpl implements ChatbotRepository {
  late final GenerativeModel _model;
  ChatSession? _chatSession;

  ChatbotRepositoryImpl() {
    final apiKey = dotenv.env['GEMINI_API_KEY']!;

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system("""
        Kamu adalah 'Sobat TumbuhSehat', seorang Ahli Gizi profesional, ramah, dan empatik.

        Tugasmu:
        1. Menjawab pertanyaan seputar gizi, nutrisi, diet sehat, pencegahan stunting, dan kesehatan keluarga.
        2. Gunakan bahasa Indonesia yang sopan dan mudah dipahami.
        3. Jangan mendiagnosa penyakit berat.
        4. Tolak topik di luar kesehatan dengan sopan.
        5. Jawaban maksimal 3 paragraf.
      """),
    );
  }

  @override
  Future<Either<Failure, String>> getChatResponse({
    required String message,
    String? threadId,
  }) async {
    try {
      _chatSession ??= _model.startChat();
      final response = await _chatSession!.sendMessage(Content.text(message));

      if (response.text == null) {
        return const Left(ServerFailure("AI tidak memberikan respon."));
      }

      return Right(response.text!);
    } catch (e) {
      return Left(ServerFailure("Gagal terhubung ke Gemini: $e"));
    }
  }
}
