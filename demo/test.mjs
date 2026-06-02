// Tiny real test. Usage: node demo/test.mjs <impl-path>
// Exits non-zero on failure so the result is honest, never narrated.
const implPath = process.argv[2] ?? "./src/parse-price.mjs";
const { parsePrice } = await import(implPath);

const input = "$1,299.50";
const want = 1299.5;
const got = parsePrice(input);

if (got !== want) {
  console.log(`❌ Failed: parsePrice(${JSON.stringify(input)}) — expected ${want}, got ${got}`);
  process.exit(1);
}
console.log(`✅ Passed: parsePrice(${JSON.stringify(input)}) → ${got}`);
