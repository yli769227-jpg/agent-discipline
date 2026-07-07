---
name: no-dead-code
version: 1.0.0
description: >-
  Never assume dead code (cross-agent safety). Before deleting any symbol (function/class/variable/file),
  grep every caller. After adding a file, update the project manifest. When multiple agents edit in
  parallel, re-read the latest file before editing — don't trust a cached copy. Triggers when about to
  delete a symbol, add a source file, or edit a file that may be concurrently modified.
  不假设 Dead Code:删任何符号前先 grep 所有调用方;新增文件后更新清单;多 agent 并行时编辑前先读最新文件;看到"像是没用"的符号先 grep 再说。
  消歧:多文件接口改造的逐文件 build 节奏归 incremental-build,本 skill 只管"删/改符号前证明安全"。
---

# Never Assume Dead Code / 不假设 Dead Code

> "Nobody uses this" is a hypothesis, not a fact. Grep proves it; memory doesn't.
> "没人用这个"是假设不是事实。grep 能证明,记忆不能。

## The discipline / 纪律

1. Before deleting a function/variable, grep **all** callers across the repo.
   删除函数/变量前,grep **所有**调用方。
2. After adding a file to the project, update the manifest (`package.json`, `go.mod`, exports index, etc.).
   新增文件后,更新项目清单(`package.json`、`go.mod`、导出索引等)。
3. With agents working in parallel, **re-read the latest file before editing** — never rely on a cached view.
   多 agent 并行时,**编辑前重新读最新文件**——绝不依赖缓存视图。

## When this triggers / 触发时机

- About to delete a function / class / variable / file.
- About to add a source file / module.
- About to edit a file that another agent may be modifying concurrently.
- You spot a symbol that "looks unused".

## Done criterion (verifiable) / 完成判据（可验证）

✅ Before the deletion, you ran a repo-wide grep for the symbol and it returned zero live callers (and you can show the search). New files are registered in the manifest. For a possibly-concurrent edit, there's a fresh Read of the file in this turn right before the edit.
⚠️ Grep found callers — those are not dead; handle them or stop.
❌ You deleted on the assumption it was unused, without searching. Restore and grep first.

## Worked examples / 实战反例

Real before/after cases for this discipline live in [EXAMPLES.md](./EXAMPLES.md) — read them before you act.
本纪律的真实 before/after 反例见 [EXAMPLES.md](./EXAMPLES.md) —— 动手前先对照。
