import 'package:equatable/equatable.dart';

abstract class InfluencerReportState extends Equatable {
  const InfluencerReportState();
  @override
  List<Object?> get props => [];
}

class InfluencerReportInitial extends InfluencerReportState {}

class InfluencerReportLoading extends InfluencerReportState {}

class InfluencerReportSuccess extends InfluencerReportState {
  final String message;
  const InfluencerReportSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class InfluencerReportError extends InfluencerReportState {
  final String message;
  const InfluencerReportError(this.message);
  @override
  List<Object?> get props => [message];
}
