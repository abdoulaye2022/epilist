// blocs/contact/contact_bloc.dart - VERSION CORRIGÉE
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/services/contact_service.dart';
import 'package:epilist/models/feedback_models.dart';
import 'contact_event.dart';
import 'contact_state.dart';

class ContactBloc extends Bloc<ContactEvent, ContactState> {
  final ContactService contactService;

  ContactBloc({required this.contactService}) : super(ContactInitial()) {
    on<LoadFeedbackTypes>(_onLoadFeedbackTypes);
    on<SendFeedback>(_onSendFeedback);
    on<ClearContactState>(_onClearContactState);
  }

  Future<void> _onLoadFeedbackTypes(
    LoadFeedbackTypes event,
    Emitter<ContactState> emit,
  ) async {
    try {
      emit(ContactLoading());

      final data = await contactService.getFeedbackTypes();

      emit(
        FeedbackTypesLoaded(
          feedbackTypes: data['feedbackTypes'] as List<FeedbackType>,
          priorities: data['priorities'] as List<PriorityLevel>,
        ),
      );
    } catch (e) {
      emit(
        ContactFailure(
          error:
              'Erreur lors du chargement des types de feedback: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onSendFeedback(
    SendFeedback event,
    Emitter<ContactState> emit,
  ) async {
    try {
      emit(ContactLoading());

      final result = await contactService.sendFeedback(
        subject: event.subject,
        message: event.message,
        feedbackType: event.feedbackType,
        priority: event.priority,
        appVersion: event.appVersion,
        platform: event.platform,
        deviceInfo: event.deviceInfo,
      );

      emit(
        FeedbackSent(
          message: result['message'] ?? 'Feedback envoyé avec succès !',
          feedbackId: result['feedbackId'] ?? '',
        ),
      );
    } catch (e) {
      if (e is ContactValidationException) {
        emit(
          ContactFailure(
            error: e.message,
            validationErrors: e.validationErrors,
          ),
        );
      } else {
        emit(
          ContactFailure(
            error:
                e.toString().contains('Erreur')
                    ? e.toString()
                    : 'Erreur lors de l\'envoi du feedback: ${e.toString()}',
          ),
        );
      }
    }
  }

  void _onClearContactState(
    ClearContactState event,
    Emitter<ContactState> emit,
  ) {
    emit(ContactInitial());
  }
}
