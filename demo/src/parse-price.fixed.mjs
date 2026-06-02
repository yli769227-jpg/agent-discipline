// Fixed version — strips both the currency symbol and the thousands separator.
export function parsePrice(s) {
  return parseFloat(s.replace(/[$,]/g, ""));
}
