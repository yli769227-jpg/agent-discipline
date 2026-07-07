---
name: log-first
version: 1.0.0
description: >-
  Log first (observability). New code must include key-path logging: connection established, state
  change, error, request/response. Triggers when you're about to write a new module, interface,
  async task, or external call — or when debugging code that has no logs. Writing buggy code is
  normal; locating the bug is the hard part.
  日志优先:新代码必须含关键路径日志(连接、状态变化、错误、请求/响应)。触发:写新模块/接口/异步任务/外部调用,或 debug 无日志代码时。写代码犯错正常,定位问题才难。
  不触发:纯改文案/配置、纯重命名、写测试断言,或模块已有完整关键路径日志。
---

# Log First / 日志优先

> Writing buggy code is normal. Locating the bug is the hard part — logs are how you win that part.
> 写代码犯错是正常的,定位问题才是真正困难的——日志就是你赢下这一关的方式。

## The discipline / 纪律

1. All new code carries key-path logs: connection established, state change, error raised, request/response.
   所有新代码带关键路径日志:连接建立、状态变化、错误发生、请求/响应。
2. Keep log format consistent and prefix each line with a module tag so it greps cleanly.
   日志格式统一,每行带模块前缀,便于 grep。
3. Error logs must carry context: which operation, which arguments, which error.
   错误日志必须带上下文:什么操作、什么参数、什么错误。
4. This applies to agent-written code too — a sub-task to write code must require key-path logging.
   agent 写的代码同样适用——派写代码的子任务时要写明"加关键路径日志"。(派子任务的完整必含项见 agent-team 的「派子任务必含清单」)

## When this triggers / 触发时机

- About to write a new module / interface / external call / async task.
- Debugging a stretch of code that has no logs (add them first).
- Before handing an agent a code-writing sub-task (require "add key-path logs").

## Done criterion (verifiable) / 完成判据（可验证）

✅ A grep over the new code (e.g. `grep -nE 'log\.(info|warn|error)' <file>`) shows a line at each key path — connect, state change, error, request/response — each module-prefixed and carrying context.
⚠️ Some paths logged, some missing — name the gaps.
❌ The new code is silent. If it fails in prod, you'll be blind. Add logs before shipping.

## Worked examples / 实战反例

Real before/after cases for this discipline live in [EXAMPLES.md](./EXAMPLES.md) — read them before you act.
本纪律的真实 before/after 反例见 [EXAMPLES.md](./EXAMPLES.md) —— 动手前先对照。
