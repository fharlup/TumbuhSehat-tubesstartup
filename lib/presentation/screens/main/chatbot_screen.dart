import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:midtrans_snap/midtrans_snap.dart';
import 'package:midtrans_snap/models.dart';

// Sesuaikan import ini dengan nama project Anda
import 'package:mobile_tumbuh_sehat_v2/core/utils/responsive_helper.dart';
import 'package:mobile_tumbuh_sehat_v2/gen/assets.gen.dart';
import 'package:mobile_tumbuh_sehat_v2/injection_container.dart';
import 'package:mobile_tumbuh_sehat_v2/presentation/cubit/chatbot/chatbot_cubit.dart';
import 'package:mobile_tumbuh_sehat_v2/data/models/nutritionist_model.dart';
import 'package:mobile_tumbuh_sehat_v2/core/theme/ts_color.dart'; 
import 'package:mobile_tumbuh_sehat_v2/core/theme/ts_text_style.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ChatbotCubit>(), 
      child: const _ChatbotView(),
    );
  }
}

class _ChatbotView extends StatefulWidget {
  const _ChatbotView();

  @override
  State<_ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<_ChatbotView> {
  final _user = const types.User(id: 'user');

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatbotCubit, ChatbotState>(
      listener: (context, state) async {
        // --- LOGIKA BUKA HALAMAN SNAP (WEBVIEW) ---
        if (state is ChatbotPaymentRequired) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MidtransSnap(
                mode: MidtransEnvironment.sandbox, 
                token: state.snapToken, // Token didapat dari Cubit
                
                // --- BAGIAN PENTING: CLIENT KEY ---
                // Masukkan Client Key dari Dashboard Midtrans Sandbox Anda di sini
                // Format: SB-Mid-client-xxxxxxxxxxxx
                midtransClientKey: "SB-Mid-client-XXXXXXXXXXXX", 

                onPageStarted: (url) {
                  print("Midtrans Loading: $url");
                },
                onPageFinished: (url) {
                  print("Midtrans Finished: $url");
                },
              ),
            ),
          );

          // --- LOGIKA SETELAH BALIK DARI MIDTRANS ---
          if (result != null) {
            // Kita asumsikan jika result tidak null, user telah menyelesaikan flow pembayaran
            print("Midtrans Result: $result");
            
            if (!mounted) return;
            
            // Lanjut ke Chat dengan Dokter
            context.read<ChatbotCubit>().initChat(nutritionist: state.nutritionist);
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Pembayaran Berhasil! Konsultasi dimulai."),
                backgroundColor: Colors.green,
              ),
            );
          } else {
             // User menekan back sebelum selesai
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Pembayaran dibatalkan atau belum selesai.")),
            );
          }
        }
        
        // Handle Error
        if (state is ChatbotError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        // Tentukan apakah sedang mode Chat atau Menu
        final bool isChatting = state is ChatbotLoaded || 
                               (state is ChatbotLoading && state.selectedNutritionist != null);
        
        final activeNutritionist = state.selectedNutritionist;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: TSColor.monochrome.white,
            elevation: 1,
            leading: isChatting
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      // Tombol back mereset ke menu awal
                      context.read<ChatbotCubit>().emit(const ChatbotInitial());
                    },
                  )
                : const BackButton(color: Colors.black),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isChatting
                      ? (activeNutritionist?.name ?? 'Sobat TumbuhSehat')
                      : 'Konsultasi Gizi',
                  style: TSFont.getStyle(
                    context, 
                    TSFont.bold.large.withColor(TSColor.monochrome.black)
                  ),
                ),
                if (isChatting)
                  Text(
                    activeNutritionist?.role ?? 'AI Assistant',
                    style: TSFont.getStyle(
                      context,
                      TSFont.regular.small.withColor(TSColor.monochrome.grey)
                    ),
                  ),
              ],
            ),
          ),
          body: Stack(
            children: [
              // Background Pattern
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(Assets.images.pattern.path),
                    fit: ResponsiveHelper(context).isTablet
                        ? BoxFit.fill
                        : BoxFit.cover,
                    alignment: Alignment.topCenter,
                    opacity: 0.1,
                  ),
                ),
                // Switch antara Chat dan Menu
                child: isChatting
                    ? _buildChatInterface(context, state)
                    : _buildSelectionMenu(context),
              ),

              // Loading Overlay (Saat generate token)
              if (state is ChatbotLoading && state.messages.isEmpty)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGET MENU PILIHAN ---
  Widget _buildSelectionMenu(BuildContext context) {
    final cubit = context.read<ChatbotCubit>();
    
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          "Pilih Layanan Konsultasi",
          style: TSFont.getStyle(
            context,
            TSFont.bold.h2.withColor(TSColor.monochrome.black)
          ),
        ),
        const SizedBox(height: 16),
        
        // Opsi 1: AI (Gratis)
        _buildConsultationCard(
          context,
          title: "Tanya Sobat TumbuhSehat (AI)",
          subtitle: "Gratis • Jawaban instan",
          iconPath: Assets.icons.chatbotActive.path, 
          color: TSColor.mainTosca.primary,
          onTap: () => cubit.initChat(nutritionist: null),
        ),

        const SizedBox(height: 24),
        Text(
          "Chat dengan Ahli Gizi",
          style: TSFont.getStyle(
             context,
             TSFont.bold.h2.withColor(TSColor.monochrome.black)
          ),
        ),
        const SizedBox(height: 12),

        if (cubit.availableNutritionists.isEmpty)
           const Padding(
             padding: EdgeInsets.all(8.0),
             child: Text("Belum ada ahli gizi yang tersedia."),
           ),

        // Opsi 2: List Dokter (Berbayar)
        ...cubit.availableNutritionists.map((nutritionist) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildConsultationCard(
              context,
              title: nutritionist.name,
              subtitle: "Rp 50.000 / Sesi", 
              isOnline: nutritionist.isOnline, 
              iconPath: Assets.icons.profilActive.path, 
              color: TSColor.monochrome.white,
              textColor: TSColor.monochrome.black,
              hasBorder: true,
              // Memanggil fungsi Payment dulu, bukan langsung chat
              onTap: () => cubit.selectNutritionistForConsultation(nutritionist),
            ),
          );
        }),
      ],
    );
  }

  // --- WIDGET KARTU PILIHAN ---
  Widget _buildConsultationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String iconPath,
    required VoidCallback onTap,
    Color? color,
    Color textColor = Colors.white,
    bool hasBorder = false,
    bool isOnline = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: hasBorder ? Border.all(color: TSColor.monochrome.lightGrey) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: iconPath.endsWith('.svg') 
                  ? const Icon(Icons.person, color: Colors.white)
                  : Image.asset(iconPath, color: hasBorder ? TSColor.mainTosca.primary : Colors.white), 
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TSFont.getStyle(
                            context,
                            TSFont.bold.large.withColor(textColor)
                          ),
                        ),
                      ),
                      if (isOnline)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text("Online", style: TextStyle(fontSize: 10, color: Colors.green.shade800)),
                        )
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TSFont.getStyle(
                      context,
                      TSFont.regular.small.withColor(textColor.withOpacity(0.8))
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: textColor, size: 16),
          ],
        ),
      ),
    );
  }

  // --- WIDGET CHAT INTERFACE ---
  Widget _buildChatInterface(BuildContext context, ChatbotState state) {
    return Chat(
      messages: state.messages,
      onSendPressed: (partialText) {
        context.read<ChatbotCubit>().sendMessage(partialText);
      },
      user: _user,
      showUserAvatars: true,
      showUserNames: true,
      theme: DefaultChatTheme(
        backgroundColor: Colors.transparent,
        primaryColor: TSColor.mainTosca.primary,
        secondaryColor: TSColor.monochrome.lightGrey,
        inputBackgroundColor: TSColor.monochrome.white,
        inputTextColor: TSColor.monochrome.black,
        inputBorderRadius: const BorderRadius.all(Radius.circular(24)),
        inputContainerDecoration: BoxDecoration(
          color: TSColor.monochrome.white,
          border: Border(top: BorderSide(color: TSColor.monochrome.lightGrey)),
        ),
      ),
    );
  }
}