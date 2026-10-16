// utils/chat_flow.dart - Ouvrir la discussion d'une liste partagée.
//
// Le ChatBloc n'est pas fourni globalement et le ChatService a besoin de
// son propre Dio authentifié : ce montage était écrit à la main dans
// list_detail_screen, donc la discussion n'existait que là. Il vit ici,
// une seule fois, et l'écran « Plus » s'en sert aussi.
import 'package:dio/dio.dart';
import 'package:epilist/blocs/chat/chat_bloc.dart';
import 'package:epilist/config/app_config.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/services/chat_service.dart';
import 'package:epilist/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> openListChat(
  BuildContext context, {
  required int listId,
  required String listName,
}) async {
  final token = await context.read<AuthService>().getToken();
  if (!context.mounted) return;

  final dio = Dio()
    ..options.baseUrl = AppConfig.baseUrl
    ..options.headers['Authorization'] = 'Bearer $token';

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => ChatBloc(chatService: ChatService(dio: dio)),
        child: ChatScreen(listId: listId, listName: listName),
      ),
    ),
  );
}
