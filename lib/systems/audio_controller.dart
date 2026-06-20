class AudioController {
  int _curseIntensity = 0;

  int get curseIntensity => _curseIntensity;

  void playAttack() {}

  void playHit() {}

  void playContract() {}

  void playRunEnd() {}

  void setCurseIntensity(int curseCount) {
    _curseIntensity = curseCount.clamp(0, 12);
  }
}
