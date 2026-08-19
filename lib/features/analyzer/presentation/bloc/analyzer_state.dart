import 'package:equatable/equatable.dart';
import '../../../../models/repo_analysis.dart';

abstract class AnalyzerState extends Equatable {
  const AnalyzerState();

  @override
  List<Object?> get props => [];
}

class AnalyzerInitial extends AnalyzerState {}

class AnalyzerLoading extends AnalyzerState {}

class AnalyzerSuccess extends AnalyzerState {
  final RepoAnalysis analysis;

  const AnalyzerSuccess(this.analysis);

  @override
  List<Object?> get props => [analysis];
}

class AnalyzerError extends AnalyzerState {
  final String message;

  const AnalyzerError(this.message);

  @override
  List<Object?> get props => [message];
}
