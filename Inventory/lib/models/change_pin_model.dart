class ChangePinModel {
  final String oldPin;
  final String newPin;
  final String confirmPin;

  ChangePinModel({
    required this.oldPin,
    required this.newPin,
    required this.confirmPin,
  });

  bool isValid() {
    return oldPin.length == 4 && newPin.length == 4 && confirmPin.length == 4;
  }

  bool doPinsMatch() {
    return newPin == confirmPin;
  }

  bool isNewPinDifferent() {
    return oldPin != newPin;
  }
}
