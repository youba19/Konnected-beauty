import 'package:flutter_bloc/flutter_bloc.dart';
import 'salon_report_event.dart';
import 'salon_report_state.dart';
import '../../services/api/reports_service.dart';

class SalonReportBloc extends Bloc<SalonReportEvent, SalonReportState> {
  final ReportsService reportsService;

  SalonReportBloc({ReportsService? service})
      : reportsService = service ?? ReportsService(),
        super(SalonReportInitial()) {
    on<SubmitSalonReport>(_onSubmit);
  }

  Future<void> _onSubmit(
    SubmitSalonReport event,
    Emitter<SalonReportState> emit,
  ) async {
    final trimmed = event.message.trim();
    if (trimmed.isEmpty) {
      emit(const SalonReportError('Message is empty'));
      return;
    }
    emit(SalonReportLoading());
    final result = await reportsService.sendSalonReport(message: trimmed);
    if (result['success'] == true) {
      emit(SalonReportSuccess(result['message'] ?? ''));
    } else {
      emit(SalonReportError(result['message'] ?? 'Failed to submit report'));
    }
  }
}
