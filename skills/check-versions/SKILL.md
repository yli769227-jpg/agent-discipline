---
name: check-versions
description: >-
  Check the forge temperature before you cast. When touching a language feature, runtime behavior, or
  framework/SDK API, verify the actual installed version first, then read that version's docs, then
  write code. Triggers before using any concrete API (Node/Python/Go/Rust/any SDK), when you'd be
  trusting how-you-remember-it, or on version-sensitive errors. Never code from training-data version
  assumptions.
  先测炉温再铸剑:用任何 API 前先查实际版本→查该版本文档→再写代码。禁止凭训练数据的版本假设直接写代码。
---

# Check Versions / 先测炉温，再铸剑

> The API you remember and the API that's installed are not the same API until you've checked.
> 你记得的 API 和实际装着的 API,在你查证之前不是同一个 API。

## The discipline / 纪律

1. **Verify the version first** — run the version-check command, confirm the actual runtime/library version.
   **先确认版本**:执行版本检查命令,确认实际运行时/库版本。
2. **Then read the docs** — confirm how the feature actually behaves *in that version*.
   **再查文档**:用官方文档确认该版本下特性的实际行为。
3. **Then write code** — built on the confirmed version and docs.
   **后写代码**:基于已确认的版本和文档开发。

**Forbidden:** writing code that depends on a specific language feature based on a version assumption from training data.
**绝对禁止:** 基于训练数据里的版本假设,直接写依赖特定特性的代码。

## When this triggers / 触发时机

- About to use any concrete language / runtime / SDK / framework API.
- You suspect "I remember it's written like this" but aren't sure.
- A version-sensitive error (ESM/CJS, Python 3.x behavior diffs, deprecated Node APIs).
- Porting a snippet across projects.

## Done criterion (verifiable) / 完成判据（可验证）

✅ Before writing, you ran a version check (e.g. `node -v`, `pip show <pkg>`, `cargo tree`) and confirmed the API against *that* version's docs.
⚠️ You couldn't verify the version — say so, and mark the code as needing a version check.
❌ You wrote API-dependent code from memory with no version check. Stop and verify.
