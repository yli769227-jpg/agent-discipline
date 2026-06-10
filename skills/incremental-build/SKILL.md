---
name: incremental-build
description: >-
  Incremental build + interface-change protocol. Build after each file edit — never batch-edit
  several files then verify, because errors mask each other and fixing cost grows exponentially.
  Before changing an interface, grep every implementation (including mocks/tests) and change them all
  in one batch. Triggers when about to edit 3+ files in a row, modify a widely-implemented interface,
  or hand an agent a multi-file change.
  增量编译验证 + 接口变更协议:每编一个文件立即 build;改接口前先 grep 所有实现一次性全改。错误会互相掩盖。
---

# Incremental Build / 增量验证与接口变更协议

> Batch edits hide each other's errors. Verify after every file so a failure points at one change.
> 批量编辑会让错误互相掩盖。每个文件后都验证,失败才能指向单一变更。

## Incremental build / 增量编译验证

1. After **each** file edit, immediately run the matching build/check and confirm it compiles.
   每编辑完**一个**文件,立即运行对应的 build/检查,确认编译通过。
2. Never edit 3+ files before the first build — masked errors compound, fix cost grows exponentially.
   禁止连续编辑 3+ 文件后才首次 build——被掩盖的错误叠加,修复成本指数增长。
3. Agent sub-tasks must require "build after each file edit" in the task description.
   派给 agent 的任务描述里要写明"每文件编辑后 build 验证"。

## Interface-change protocol / 接口变更协议

1. **Search**: grep every type implementing the interface (including mocks / test doubles).
   **先搜**:grep 所有实现该接口的类型(含 mock / test double)。
2. **List**: enumerate each file + line that needs the change.
   **列清单**:列出每个要改的文件和行号。
3. **Change all at once**: interface definition + all implementations in the same edit batch.
   **一次性全改**:接口定义 + 所有实现在同一编辑批次内完成。
4. **Verify immediately**: build right after, confirm zero compile errors.
   **立即验证**:改完立即 build,确认零编译错误。

## When this triggers / 触发时机

- About to edit 3+ files in a row.
- About to modify an interface / trait / abstract class / protocol with many implementations.
- About to hand an agent a multi-file change.
- You've edited a batch and haven't built yet (stop and build now).

## Done criterion (verifiable) / 完成判据（可验证）

✅ Each edited file was built/checked before the next one; for interface changes, every implementation found by grep was updated in one batch and the build is green.
⚠️ A file was edited but the build/check couldn't run (no compiler, env not set up, etc.) — say so explicitly and treat it as unverified, don't move on as if it's green.
❌ Several files edited, no build yet — pause and verify before continuing.
