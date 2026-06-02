---
name: first-principles
description: >-
  Reason from first principles. Build every conclusion from basic facts, challenge assumptions, and
  re-derive the approach from constraints — not from convention, "best practice", or industry defaults.
  Triggers when about to cite "the usual way" as a reason, copy a common template without saying why it
  fits this time, or make an architecture / topology / data-model choice. Reasoning over recall.
  第一性原理:从基本事实出发,挑战假设,从约束重推方案,不靠惯例/最佳实践/行业默认值。推理优先于回忆。
---

# First Principles / 第一性原理

> "It's how it's usually done" is not a reason. Re-derive it, or don't claim it.
> "通常这么做"不是理由。要么重新推导,要么别用它当依据。

## The discipline / 纪律

Reason from first principles — not "how it's usually done", but "why it must be done this way":
从第一性原理出发——不靠"通常怎么做",靠"为什么必须这样做":

1. Define the problem down to its most basic form. / 把问题定义到最基本形态。
2. Find the facts that can't be reduced further. / 找到不可再简化的事实。
3. List your assumptions explicitly — and challenge them. / 显式列出并挑战所有假设。
4. Strip away convention, best practice, industry defaults. / 剥掉惯例、最佳实践、行业默认值。
5. Rebuild the solution from constraints and goals alone. / 仅从约束和目标重新构建方案。

**Forbidden:** "this is the usual approach" as a justification. Reasoning over recall.
**禁止:** 拿"这是通常做法"当理由。推理优先于回忆。

## When this triggers / 触发时机

- About to make an architecture / data-model / service-split / protocol choice.
- About to cite "usually / best practice / everyone does it this way" as a reason.
- About to copy a common template without saying why it fits *this* case.
- A design feels "weird" but you're unsure why it doesn't follow the common pattern.

## Done criterion (verifiable) / 完成判据（可验证）

✅ The chosen approach is justified by *this project's* facts and constraints — there's an explicit "why this time", not just "this is conventional".
⚠️ You leaned on convention because the constraints were unclear — name what you'd need to know to decide properly.
❌ The only reason given is "it's standard". Re-derive from constraints before committing.
