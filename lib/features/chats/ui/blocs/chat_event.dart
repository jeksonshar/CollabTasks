import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessages extends ChatEvent {
  final String chatId;

  const LoadMessages(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class SendMessageEvent extends ChatEvent {
  final String chatId;
  final String text;

  const SendMessageEvent(this.chatId, this.text);

  @override
  List<Object?> get props => [chatId, text];
}

class DeleteMessageEvent extends ChatEvent {
  final String chatId;
  final String messageId;

  const DeleteMessageEvent(this.chatId, this.messageId);

  @override
  List<Object?> get props => [chatId, messageId];
}
