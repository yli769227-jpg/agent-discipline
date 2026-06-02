---
name: agent-team
description: >-
  Work as an agent team. Send non-trivial work to sub-agents; keep the main thread for planning,
  acceptance, smoke-testing, and communication. A QA inspector is mandatory and holds veto power — a
  FAIL must be fixed and re-reviewed. Triggers when about to do heavy multi-file edits in the main
  thread, take on a task spanning many files/modules, or say "I'll just do this myself". The prime
  goal is to keep the main context lean and avoid overflow.
  Agent Team 协作:非平凡任务派子 agent,主线程只做规划/验收/冒烟测试/沟通。监理(QA)必选且有否决权。首要目标是精简主上下文。
---

# Work As An Agent Team / Agent Team 协作

> Prime directive: keep the main context lean. A bloated lead thread is how work derails.
> 首要原则:精简主上下文。主线程一臃肿,工作就脱轨。

## The discipline / 纪律

1. Send non-trivial work to a sub-agent team instead of unrolling huge edits in the main conversation.
   非平凡任务派子 agent,而不是在主对话里展开大量编辑。
2. The main thread does only: plan, accept, smoke-test, communicate.
   主线程只做:规划、验收、冒烟测试、沟通。

## The three roles / 三驾马车

- **Engineer** — writes code, makes the thing run. / **工程师**:写代码,让项目跑起来。
- **QA Inspector** — finds the cracks; verifies happy path, error path, and boundaries. / **监理**:找裂纹,验证正确/错误/边界路径。
- **Lead (main thread)** — plans, coordinates, accepts. / **主线程**:规划、协调、验收。

## QA principle / 监理原则

- QA is **not optional** — every non-trivial task gets reviewed before "done".
  监理**不是可选项**——任何非平凡任务完成后必须验收。
- QA's verdict has **veto power**. A FAIL must be fixed and re-reviewed.
  监理结论有**否决权**。FAIL 必须修复后重新验收。

## When this triggers / 触发时机

- About to start a main-thread task that will edit 3+ files / span multiple modules.
- About to take on a task that reads 5+ files / generates large amounts of code.
- About to declare a non-trivial task done (it must pass QA first).

## Done criterion (verifiable) / 完成判据（可验证）

✅ Non-trivial work ran through sub-agents, and a QA inspector reviewed it (happy + error + boundary paths) and returned PASS before "done" was claimed.
⚠️ QA returned PASS-with-caveats — surface the caveats.
❌ The lead thread did everything itself and/or skipped QA. Route it through the team and review.
