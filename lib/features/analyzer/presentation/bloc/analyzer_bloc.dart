import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/rules_engine.dart';
import 'analyzer_event.dart';
import 'analyzer_state.dart';

class AnalyzerBloc extends Bloc<AnalyzerEvent, AnalyzerState> {
  final RulesEngine _rulesEngine;

  AnalyzerBloc({RulesEngine? rulesEngine})
      : _rulesEngine = rulesEngine ?? RulesEngine(),
        super(AnalyzerInitial()) {
    on<AnalyzeRepoEvent>(_onAnalyzeRepo);
    on<ResetAnalyzerEvent>(_onReset);
  }

  Future<void> _onAnalyzeRepo(
    AnalyzeRepoEvent event,
    Emitter<AnalyzerState> emit,
  ) async {
    emit(AnalyzerLoading());
    try {
      final result = await _rulesEngine.analyzeRepo(event.url);
      emit(AnalyzerSuccess(result));
    } catch (e) {
      emit(AnalyzerError(e.toString()));
    }
  }

  void _onReset(
    ResetAnalyzerEvent event,
    Emitter<AnalyzerState> emit,
  ) {
    emit(AnalyzerInitial());
  }
}
