import 'package:flutter_riverpod/flutter_riverpod.dart';

final forgotPinViewModelProvider =
    StateNotifierProvider<ForgotPinViewModel, ForgotPinState>(
      (ref) => ForgotPinViewModel(),
    );

class ForgotPinState {
  final String mobileNumber;
  final String message;

  ForgotPinState({this.mobileNumber = '', this.message = ''});

  ForgotPinState copyWith({String? mobileNumber, String? message}) {
    return ForgotPinState(
      mobileNumber: mobileNumber ?? this.mobileNumber,
      message: message ?? this.message,
    );
  }
}

class ForgotPinViewModel extends StateNotifier<ForgotPinState> {
  ForgotPinViewModel() : super(ForgotPinState());

  void updateMobileNumber(String number) {
    state = state.copyWith(mobileNumber: number);
  }

  void submit() {
    final input = state.mobileNumber.trim();
    if (input.length == 11 && input.startsWith("09")) {
      state = state.copyWith(message: "PIN recovery sent to $input");
    } else {
      state = state.copyWith(
        message: "Please enter a valid 11-digit mobile number.",
      );
    }
  }

  void clearMessage() {
    state = state.copyWith(message: '');
  }
}
