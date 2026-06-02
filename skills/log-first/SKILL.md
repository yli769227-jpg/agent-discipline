---
name: log-first
description: >-
  Log first (observability). New code must include key-path logging: connection established, state
  change, error, request/response. Triggers when you're about to write a new module, interface,
  async task, or external call — or when debugging code that has no logs. Writing buggy code is
  normal; locating the bug is the hard part.
  日志优先:新代码必须含关键路径日志(连接、状态变化、错误、请求/响应)。写代码犯错正常,定位问题才难。
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
   agent 写的代码同样适用——派写代码的子任务时要写明"加关键路径日志"。

## When this triggers / 触发时机

- About to write a new module / interface / external call / async task.
- Debugging a stretch of code that has no logs (add them first).
- Before handing an agent a code-writing sub-task (require "add key-path logs").

## Done criterion (verifiable) / 完成判据（可验证）

✅ For the new code, you can point to a log line at each key path: connect, state change, error, request/response — each greppable by a module prefix and carrying context.
⚠️ Some paths logged, some missing — name the gaps.
❌ The new code is silent. If it fails in prod, you'll be blind. Add logs before shipping.
