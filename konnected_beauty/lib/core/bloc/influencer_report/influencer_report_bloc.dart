import 'package:flutter_bloc/flutter_bloc.dart';
import 'influencer_report_event.dart';
import 'influencer_report_state.dart';
import '../../services/api/reports_service.dart';

class InfluencerReportBloc
    extends Bloc<InfluencerReportEvent, InfluencerReportState> {
  final ReportsService reportsService;

  InfluencerReportBloc({ReportsService? service})
      : reportsService = service ?? ReportsService(),
        super(InfluencerReportInitial()) {
    on<SubmitInfluencerReport>(_onSubmit);
  }

  Future<void> _onSubmit(
    SubmitInfluencerReport event,
    Emitter<InfluencerReportState> emit,
  ) async {
    final trimmed = event.message.trim();
    if (trimmed.isEmpty) {
      emit(const InfluencerReportError('Message is empty'));
      return;
    }
    emit(InfluencerReportLoading());
    final result = await reportsService.sendInfluencerReport(message: trimmed);
    if (result['success'] == true) {
      emit(InfluencerReportSuccess(result['message'] ?? ''));
    } else {
      emit(InfluencerReportError(
          result['message'] ?? 'Failed to submit report'));
    }
  }
}
