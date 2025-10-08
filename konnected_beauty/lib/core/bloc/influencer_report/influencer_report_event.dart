import 'package:equatable/equatable.dart';

abstract class InfluencerReportEvent extends Equatable {
  const InfluencerReportEvent();
  @override
  List<Object?> get props => [];
}

class SubmitInfluencerReport extends InfluencerReportEvent {
  final String message;
  const SubmitInfluencerReport(this.message);

  @override
  List<Object?> get props => [message];
}
