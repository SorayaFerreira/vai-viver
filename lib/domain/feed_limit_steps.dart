/// Minutes the daily feed limit stepper moves through: 1-minute steps up to 5
/// (handy for testing on the device), then 5-minute steps.
int nextFeedLimit(int minutes) => minutes < 5 ? minutes + 1 : minutes + 5;

int previousFeedLimit(int minutes) {
  if (minutes > 5) return minutes - 5;
  return minutes > 1 ? minutes - 1 : 1;
}
