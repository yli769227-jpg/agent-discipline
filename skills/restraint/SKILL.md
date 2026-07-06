---
name: restraint
description: >-
  Restraint (anti-overproduction). LLMs are systematically biased toward emitting MORE — more code,
  more parameters, more guards, more abstractions — than the spec requires. The cure is restraint,
  not knowledge: before every line, ask "does the spec need this, today?" Triggers when about to add
  an optional parameter / config flag / new abstraction / new dependency / catch-all handler, or to
  build an unrequested "while I'm at it" feature.
  克制律(反过度输出):模型的系统性偏差是"多输出"。解药是克制不是知识:每写一行先问"spec 今天需要这个吗?"。
---

# Restraint / 克制律

> Nine of the fifteen documented LLM code failure modes share one root cause: the model would rather emit more than the minimum the spec requires. Every "helpful extra" looks diligent in a diff and costs maintenance forever.
> 已被记录的 15 种 LLM 代码失败模式里,有 9 种同根:模型总想输出比 spec 要求更多的东西。每个"贴心的多余"在 diff 里都显得勤奋,维护成本却是永久的。

## The discipline / 纪律

1. **No guards for impossible cases.** If the type or the caller's contract already excludes it, don't null-check it. The test is not "could this theoretically be wrong" but "can untrusted data reach here". Validate at trust boundaries (external input, payloads, deserialized data); trust the contract inside them.
   **不给不可能的情况加防御。** 类型或调用方契约已排除的情况不加检查。判据不是"理论上会不会错",而是"不受信数据到得了这里吗"。边界必须验证,边界之内信任契约。
2. **No speculative configurability.** No optional parameter, config flag, env var, or feature toggle without a present-day caller. Catch yourself writing `enable_*` / `use_*_v2` / `*_mode` → delete it, ship the concrete behavior.
   **不写投机配置。** 没有今日调用方的可选参数/配置项/环境变量/开关一律不写。发现在写 `enable_*`,删掉,直接实现具体行为。
3. **No premature abstraction.** One concrete implementation = inline it. No interface, factory, registry, or base class until a second real user exists. The wrong abstraction is worse than duplication (Sandi Metz).
   **不过早抽象。** 只有一个实现就内联。第二个真实使用者出现前,不引入 interface/factory/registry/基类。错误的抽象比重复更糟。
4. **No dependency for trivial work.** Check the stdlib, the installed deps, and whether a few local lines do the job. A dependency is permanent maintenance and supply-chain surface — add one only for complexity you shouldn't re-implement.
   **不为琐事加依赖。** 先查标准库、已装依赖、几行本地代码。依赖是永久维护面,只为不该自己重写的真复杂度而加。
5. **No swallowed errors.** Catch only the specific error you can recover from; otherwise let it propagate. Returning null/empty-success from a catch is forbidden unless the contract documents it. (Training reward shaping taught models to suppress exceptions — consciously fight that instinct.)
   **不吞异常。** 只捕获能恢复的具体错误,否则让它传播。catch 里返回 null/空成功是禁手。(训练奖励让模型学会压制异常——要有意识地对抗这个本能。)
6. **Exceptions need an exit.** A justified violation of any rule above gets a comment naming the overridden principle, the reason, and a revisit trigger. An exception without a revisit trigger is itself a finding on the next review.
   **例外必须带出口。** 违反上述任何一条的正当例外,注释注明:被覆盖的原则 + 理由 + 重审触发条件。没有重审触发条件的例外,本身就是下次 review 的 finding。

**The floor (never cut for simplicity):** trust-boundary validation · error handling that prevents data loss · security measures (auth, escaping, parameterized queries, secrets) · behavior the user explicitly requested. Removing these is a behavior change, not a cleanup.
**底线(克制不许砍到这里):** 信任边界验证 · 防数据丢失的错误处理 · 安全措施 · 用户明确要求过的行为。删这些是行为变更,不是清理。

## When this triggers / 触发时机

- About to add an optional parameter, config flag, env var, or feature toggle.
- About to introduce an interface / factory / registry / base class.
- About to write a try-catch or a "just in case" check.
- About to install a new package.
- About to build a feature nobody asked for, "while I'm at it".
- Reviewing code (yours or a sub-agent's) that shows any of the above.

## Done criterion (verifiable) / 完成判据（可验证）

✅ Every new parameter, flag, abstraction, and dependency in the diff has a present-day caller you can point to; every catch handles a specific recoverable error; documented exceptions carry a revisit trigger.
⚠️ Something speculative survived with a written justification + revisit trigger — acceptable, revisit when it fires.
❌ The diff contains a guard/flag/abstraction/dependency with no current user, or a catch-all that swallows errors. Delete it before shipping.

---

*Adapted from the failure-mode catalog of [guard-skills](https://github.com/amElnagdy/guard-skills) (MIT, Ahmed Nagdy), rebuilt for the agent-discipline verifiable-check format.*
