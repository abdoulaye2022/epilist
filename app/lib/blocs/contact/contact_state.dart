// blocs/contact/contact_state.dart
import 'package:equatable/equatable.dart';
import 'package:epilist/models/feedback_models.dart';

abstract class ContactState extends Equatable {
  const ContactState();

  @override
  List<Object?> get props => [];
}

class ContactInitial extends ContactState {}

class ContactLoading extends ContactState {}

class FeedbackTypesLoaded extends ContactState {
  final List<FeedbackType> feedbackTypes;
  final List<PriorityLevel> priorities;

  const FeedbackTypesLoaded({
    required this.feedbackTypes,
    required this.priorities,
  });

  @override
  List<Object> get props => [feedbackTypes, priorities];
}

class FeedbackSent extends ContactState {
  final String message;
  final String feedbackId;

  const FeedbackSent({required this.message, required this.feedbackId});

  @override
  List<Object> get props => [message, feedbackId];
}

class ContactFailure extends ContactState {
  final String error;
  final Map<String, List<String>>? validationErrors;

  const ContactFailure({required this.error, this.validationErrors});

  @override
  List<Object?> get props => [error, validationErrors];
}
