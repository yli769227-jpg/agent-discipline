# Demo / 演示

A reproducible, **honest** demo of the `test-is-truth` discipline: same agent, same task — one
ships a bug confidently, the other is forced to prove it works. Every ✅/❌ is a real `node` test
run (see [`test.mjs`](test.mjs)); nothing is staged.

> `test-is-truth` 的可复现**真实**演示:同一 agent、同一任务——一个自信地交付 bug,另一个被逼着证明它真的能跑。每个 ✅/❌ 都是真跑出来的。

## Run it in your terminal / 直接在终端跑

```bash
bash demo/run-demo.sh          # paced for viewing
NO_SLEEP=1 bash demo/run-demo.sh   # instant, for CI / quick check
```

The buggy implementation ([`src/parse-price.mjs`](src/parse-price.mjs)) returns `1` for
`"$1,299.50"` because `parseFloat` stops at the thousands separator. The fixed version
([`src/parse-price.fixed.mjs`](src/parse-price.fixed.mjs)) strips it.

## Record the GIF / 录制 GIF

Uses [VHS](https://github.com/charmbracelet/vhs) for a deterministic, re-recordable result:

```bash
brew install vhs
vhs demo/demo.tape      # writes assets/demo.gif
```

Edit [`demo.tape`](demo.tape) to tweak font size, theme, or dimensions. Keep the font ≥ 18pt so the
text stays readable when embedded in the top README.

> 用 VHS 录制确定性 GIF,字号保持 ≥18pt 以便在 README 首屏清晰可读。
