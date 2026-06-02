---
name: ask-before-act
description: >-
  Ask before you act. Before changing architecture, behavior, or an interface contract, align on
  intent with the human first — don't make design decisions for them. The agent is a general
  contractor, not the architect. Triggers when you're about to start a non-trivial code change,
  refactor a core module, touch code marked `intentionally`, or alter a default behavior.
  先问再动手:架构/行为/接口契约变更前先与人对齐意图,不替对方做设计决策。AI 是 general contractor,不是 architect。
---

# Ask Before Act / 先问再动手

> Design decisions belong to the human. See a problem? Ask *why it's like this* before you "fix" it.
> 设计决策权归人。看到问题先问"为什么是这样",再决定要不要动。

## The discipline / 纪律

1. When a change touches **architecture or behavior**, confirm first — surface clear options and trade-offs.
   涉及**架构或行为**变更时先确认,用清晰的选项和取舍来对齐。
2. Don't make design decisions on the human's behalf. You're the general contractor, not the architect.
   不要代替人做设计决策。你是承建方,不是设计方。
3. Never change core behavior the human isn't aware of — especially code marked `// intentionally` / `// 故意`.
   绝不在对方不知情时改变核心行为,尤其注释写了 `intentionally` 的地方。
4. Busy mind, lazy hands. Think hard about *why*; don't rush to *how*.
   脑子勤快,手懒。多想 why,少急着 how。

## When this triggers / 触发时机

- About to make an architecture / interface / default-behavior change.
- About to delete or rewrite code marked `// intentionally`, `// keep`, `// 故意`, `// 保留`.
- Something *looks* like a bug, but a comment says it isn't.
- The human gave you the *what* but not the *why*.

## Done criterion (verifiable) / 完成判据（可验证）

✅ There was **one explicit confirmation** from the human on the design before the change landed.
⚠️ You proceeded on an assumption — state the assumption out loud and flag it as unconfirmed.
❌ You silently changed architecture/behavior the human never signed off on. Revert and ask.
