# EXAMPLES — incremental-build

Real-world anti-patterns for incremental build + interface-change discipline, recast as generic, reusable lessons.
增量编译验证 + 接口变更协议的真实反例,重铸为通用、可复用的教训。

---

## Anti-pattern / 反例 1: Edit 5 TS files, build last, get 400 errors / 连改 5 个 TS 文件,最后才 build,400 个错

Task: "Replace every `any` in the project with a concrete type."
任务:把项目里所有 `any` 替换成具体类型。

What the agent did (wrong):
错误行为:

1. Edit `user.ts` (introduce `User` type)
2. Edit `order.ts` (introduce `Order`, change `user` field to `User`)
3. Edit `payment.ts` (change `order` field to `Order`)
4. Edit `report.ts` (change many `any[]` → `User[]`)
5. Edit `index.ts` (re-export)
6. `tsc` → 412 errors, files cascading into each other
6. `tsc` → 输出 412 个错误,各文件互相 cascade

**Why it's wrong / 为什么错:**

- You can't tell which error is the root cause and which is a cascade.
  分不清哪个错是 root cause,哪个是 cascade。
- 412 errors invite "just roll it all back" — half a day of work wasted.
  412 个错让人放弃 → 全部回滚 → 白干。
- The errors mask each other, hiding the real type-design bug.
  错误互相掩盖,真正的类型设计 bug 看不出来。

**The disciplined move / 正确做法:**

1. Edit `user.ts` → `tsc -p . --noEmit` → ✅ 0 errors.
2. Edit `order.ts` → `tsc` → ❌ 3 errors (all in `order.ts`) → fix on the spot → ✅.
3. Edit `payment.ts` → `tsc` → ❌ 1 error (`order` field type changed, update the cast) → fix on the spot → ✅.
4. ...

Every step is a small, locatable, fixable stair — no 412-error avalanche.
每步都是"可定位 + 可修复"的小台阶,不会出现 412 个错的雪崩。

---

## Anti-pattern / 反例 2: Changed the interface, forgot the mocks must change too / 改了接口,忘了 mock 也要跟着改

```go
// Interface definition changed
type Storage interface {
    Get(ctx context.Context, key string) ([]byte, error)
    // newly added
    GetWithTTL(ctx context.Context, key string) ([]byte, time.Duration, error)
}
```

The agent only updated the `RealStorage` implementation, ran build → it compiled.
Then ran tests → a pile of test files failed to compile, because `MockStorage` / `FakeStorage` / `InMemStorage` never implemented `GetWithTTL`.
只改了 `RealStorage` 实现,跑 build → 编译过。跑测试 → 一堆测试编译失败,因为 `MockStorage` / `FakeStorage` / `InMemStorage` 都没实现 `GetWithTTL`。

**Why it's wrong / 为什么错:**

The build passes because production code doesn't depend on the mocks, but the whole test suite breaks. The fix is rework.
build 编译过是因为生产代码不依赖 mock,但测试套件全挂,补救要返工。

**The disciplined move / 正确做法:**

1. **Search first / 先搜**:
   ```
   $ rg -l "type \w+ struct" --type=go | xargs rg -l "func.*Get.*key string.*\[\]byte"
   storage/real.go
   storage/mock_test.go
   storage/inmem.go
   testutil/fake_storage.go
   ```
2. **List / 列清单**: interface def (`storage/storage.go`) + `RealStorage` + `MockStorage` + `InMemStorage` + `FakeStorage`.
3. **Change all at once / 一次性全改**: interface + all 4 implementations in the same edit batch.
4. **Verify immediately / 立即验证**: `go build ./... && go test ./...` → ✅ all pass.

---

## Anti-pattern / 反例 3: Agent sub-task didn't require "build after each file" / agent 子任务没要求"每文件 build"

A main thread hands an agent: "Add a `created_at` field to every model under `models/`."
主线程派 agent:"把 `models/` 目录下所有 model 加 `created_at` 字段。"

The agent (wrong) edited all 12 model files in one go, then built → 27 errors, because the migration script wasn't generated in step and some field names collided.
错误行为:一口气改了 12 个 model 文件,最后 build → 27 个错,因为 migration 没同步生成,某些字段命名冲突。

**Why it's wrong / 为什么错:**

The task description never specified an incremental-verification step, so the sub-agent defaulted to batch editing.
派任务时没规定增量验证步骤,sub-agent 默认批量改。

**The disciplined move / 正确做法:**

Use a task template that mandates the protocol:
派任务模板里写明协议:

> Task: add a `created_at` field (`DateTime`, default now) to every model under `models/`.
> 任务:给 `models/` 下所有 model 加 `created_at` 字段(`DateTime`,默认 now)。
>
> Protocol / 协议:
> - Edit one model file at a time. / 一次改一个 model 文件。
> - After each edit, immediately run `pytest tests/test_<model>.py -x`; only proceed when green. / 改完立即跑对应测试,绿了才进下一个。
> - Generate the matching migration alongside. / 同时生成对应 migration。
> - After all edits, run the full suite, output ✅/❌/⚠️. / 全部改完后跑全量测试。
>
> Forbidden / 禁止: editing all 12 files before the first test run. / 批量改 12 个文件后才第一次跑测试。
