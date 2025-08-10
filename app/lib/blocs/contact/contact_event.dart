// blocs/contact/contact_event.dart
import 'package:equatable/equatable.dart';

abstract class ContactEvent extends Equatable {
  const ContactEvent();

  @override
  List<Object?> get props => [];
}

class LoadFeedbackTypes extends ContactEvent {}

class SendFeedback extends ContactEvent {
  final String subject;
  final String message;
  final String feedbackType;
  final String priority;
  final String? appVersion;
  final String? platform;
  final String? deviceInfo;

  const SendFeedback({
    required this.subject,
    required this.message,
    required this.feedbackType,
    required this.priority,
    this.appVersion,
    this.platform,
    this.deviceInfo,
  });

  @override
  List<Object?> get props => [
    subject,
    message,
    feedbackType,
    priority,
    appVersion,
    platform,
    deviceInfo,
  ];
}

class ClearContactState extends ContactEvent {}
