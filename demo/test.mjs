// Tiny real test. Usage: node demo/test.mjs <impl-path>
// Exits non-zero on failure so the result is honest, never narrated.
import { pathToFileURL } from "node:url";
import { resolve } from "node:path";

// Resolve the arg as a filesystem path relative to cwd, then hand the loader a
// file:// URL. This way any path works (with or without "./", from any dir) —
// a bare relative path is never mistaken for a bare package specifier.
const implPath = process.argv[2] ?? "./src/parse-price.mjs";
const { parsePrice } = await import(pathToFileURL(resolve(implPath)).href);

const input = "$1,299.50";
const want = 1299.5;
const got = parsePrice(input);

if (got !== want) {
  console.log(`❌ Failed: parsePrice(${JSON.stringify(input)}) — expected ${want}, got ${got}`);
  process.exit(1);
}
console.log(`✅ Passed: parsePrice(${JSON.stringify(input)}) → ${got}`);
