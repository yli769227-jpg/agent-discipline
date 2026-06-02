// BUGGY on purpose — used by the demo to show `test-is-truth` catching it.
// It strips the "$" but forgets the thousands separator, so
// parsePrice("$1,299.50") returns 1 (parseFloat stops at the comma).
export function parsePrice(s) {
  return parseFloat(s.replace("$", ""));
}
