---
name: test-is-truth
description: >-
  Tests are the truth. "Done" means a verifiable test result, not "the code is written". Triggers
  before you tell the human a task is complete, before saying "should work", before merging a PR or
  closing an issue, and before handing a sub-task to another agent. Any completion claim must carry
  a ✅/❌/⚠️ three-part test conclusion.
  测试即结论:完成 = 可验证的测试结果,不是"代码写完了"。任何完成声明必须附 ✅/❌/⚠️ 三段式结论。
---

# Tests Are The Truth / 测试即结论

> Work ends when the test passes, not when the code is written.
> 工作的结束是测试通过,不是代码写完。

## The discipline / 纪律

1. Code written ≠ done. There must be an executable check proving the behavior is correct.
   写完代码不等于完成,必须有可执行的验证证明行为正确。
2. Tests must be falsifiable — not just "it ran", but the error paths too (bad input, dropped connection, timeout).
   测试必须可证伪——不只是"跑通了",还要覆盖错误路径(非法输入、断连、超时)。
3. A smoke test is the floor: run it end-to-end once and observe *actual* behavior, never imagined behavior.
   冒烟测试是底线:端到端真跑一次,观察**实际**行为,不靠想象。
4. When you hand a task to another agent, the task description must spell out the verification step.
   把任务派给别的 agent 时,任务描述必须写明验证步骤。
5. Test what you changed, not what you didn't. Target the actual change point.
   测你改的,不是测你没改的,靶向实际变更点。

## When this triggers / 触发时机

- About to say "done / should be fine / it works".
- About to merge a PR or close an issue.
- Handing a sub-task to an agent (its description must include verification).
- Just fixed a bug and about to wrap up.

## Done criterion (verifiable) / 完成判据（可验证）

Every completion claim ends in this exact shape:

```
✅ Passed:   <what was verified, and how>
❌ Failed:   <what broke, with the actual output>
⚠️ Untested: <what is NOT covered yet>
```

✅ The claim is backed by a real run with this three-part conclusion.
❌ You said "done" with no executed test. Not done — run it.
