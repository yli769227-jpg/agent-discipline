---
name: test-quality
version: 1.0.0
description: >-
  Test quality nine rules. test-is-truth demands that "done" is backed by a test verdict; this skill
  governs whether the tests themselves are worth trusting. Coding agents over-generate tests:
  mock-heavy suites asserting implementation details, near-duplicate bodies differing by one value,
  tests that re-verify the framework. Triggers when about to write or generate tests, review a diff
  containing tests, or QA-review a sub-agent's test output.
  测试质量九规:test-is-truth 管"完成必须有测试结论",本 skill 管"测试本身写得好不好"。agent 会过度生成测试——mock 堆山、近似重复、测框架不测逻辑。
---

# Test Quality Nine Rules / 测试质量九规

> Before writing any test, answer: "What bug does this catch that no other test catches?" No answer, no test.
> 写任何测试前先答:"它能抓到什么别的测试抓不到的 bug?"答不出就不写。

## The discipline / 纪律

1. **Test behavior, not implementation.** Assert return values and observable side effects. Never assert that an internal helper was called with specific arguments — that breaks on every refactor and catches nothing.
   **测行为不测实现。** 断言返回值和可观察副作用;永不断言"内部函数被以某参数调用过"——重构必碎,什么也抓不到。
2. **Every mock must be justified.** Mock only at system boundaries: network/HTTP, LLM APIs, databases, external file I/O, clock & randomness, third-party SDKs. Never mock internal classes to isolate a "unit". When you mock a boundary, assert what the caller *does with the response*.
   **每个 mock 要有正当性。** 只在系统边界 mock;禁止 mock 内部类来隔离"单元"。mock 边界后,断言调用方拿响应做了什么。
3. **One scenario per test; variants go data-driven.** Same setup differing only in values → merge into `parametrize` / `test.each` / `DataProvider`.
   **一个场景一个测试,变体走参数化。** setup 相同只差值的合并成数据驱动。
4. **Every test must justify its existence.** Delete tests that only catch typos, verify dataclass defaults, or exercise trivial pass-throughs.
   **每个测试自证价值。** 只能抓 typo 的、验证默认值的、测平凡透传的,删。
5. **Name tests for the scenario.** `test_<scenario>_<expected_outcome>` — reads like a requirement, not an echo of the function signature.
   **测试名说场景。** 读起来像需求,不是函数签名回声。
6. **Production regression tests are sacred.** A test reproducing a real production bug is always justified; reference the incident and never delete it. Exempt from rule 4.
   **生产回归测试神圣不可删。** 复现真实生产 bug 的测试永远正当,注明事故来源,豁免第 4 条。
7. **Don't test framework guarantees.** If the test would still pass with all your custom code deleted, it tests the framework, not the project.
   **不测框架保证。** 把项目自定义代码全删了还能过的测试,测的是框架。
8. **State and value objects are real, never mocked.** Construct real DTOs/entities. Mocking state hides field-name typos and validation errors — exactly the bugs worth catching. Painful construction is design feedback: add a builder, don't mock.
   **状态与值对象永不 mock。** 构造真实例;mock 状态恰好藏住字段 typo 和校验错误。构造太痛苦是设计反馈,加 builder 而不是 mock。
9. **Infrastructure under test gets real infrastructure.** When persistence *is* the subject, run a real test database with real migrations; mocking the session there tests nothing. Mocking is fine when persistence is only a side effect.
   **测基础设施就上真基础设施。** 持久化是被测对象时跑真库真迁移;只是副作用时才可 mock。

**Severity / 严重度:** rules 1, 2, 8 = must-fix (they hide real bugs) · rules 3, 4, 5, 7 = should-fix (bloat) · rule 6 = sacred (never delete) · rule 9 = note, don't block.
**分档:** 1/2/8 必须修(藏真 bug) · 3/4/5/7 应该修(膨胀) · 6 神圣 · 9 记录不阻塞。

## When this triggers / 触发时机

- About to write or generate tests (put the nine rules in a sub-agent's task brief too).
- Reviewing a diff or MR that contains test changes.
- QA / inspector reviewing a sub-agent's test output.
- Noticing unusually high mock density or near-duplicate test bodies.

## Done criterion (verifiable) / 完成判据（可验证）

✅ Every mock in the diff sits on a system boundary you can name; no test asserts internal call arguments; no two tests differ only by values; state objects are constructed real.
⚠️ Should-fix violations (bloat, naming, framework tests) noted and queued — acceptable for small changes.
❌ A must-fix violation ships: an internal mock, an implementation-detail assertion, or a mocked DTO. Fix before merge.

## Worked examples / 实战反例

Real before/after cases for this discipline live in [EXAMPLES.md](./EXAMPLES.md) — read them before you act.
本纪律的真实 before/after 反例见 [EXAMPLES.md](./EXAMPLES.md) —— 动手前先对照。

---

*Adapted from [guard-skills](https://github.com/amElnagdy/guard-skills)' test-guard (MIT, Ahmed Nagdy), rebuilt for the agent-discipline verifiable-check format.*
