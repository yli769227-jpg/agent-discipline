# EXAMPLES — no-dead-code

Real-world anti-patterns for the "don't assume dead code" discipline, recast as generic, reusable lessons.
"不假设 Dead Code"纪律的真实反例,重铸为通用、可复用的教训。

---

## Anti-pattern / 反例 1: "Nothing calls this function, delete it" / "这个函数没人调,删了吧"

The agent skims the code and sees:
AI 翻代码看到:

```python
def legacy_normalize_amount(x): ...
```

What the agent did (wrong): saw no other use in the same file, so it just deleted it.
错误行为:没看到本文件其他位置用,就直接删掉。

Fallout: CI failed, because:
后果:CI 失败,因为:

- a migration script imports it;
  一个 migration 脚本在 import 它;
- a compatibility test exercises it;
  一个兼容性测试在测它;
- a scheduled (cron) job calls a script that uses it.
  一个定时任务调用的脚本用到它。

**Why it's wrong / 为什么错:**

"No caller in this file" ≠ "no caller in the repo." Call sites live in scripts, tests, and scheduled jobs you didn't open.
"本文件无调用" ≠ "全仓无调用"。调用方藏在你没打开的脚本、测试和定时任务里。

**The disciplined move / 正确做法:**

Grep every reference before deleting:
删前先搜全仓引用:

```
$ rg -l "legacy_normalize_amount" --type=py
src/legacy.py
scripts/migration_v2.py
scripts/normalize_old.py
tests/test_legacy_compat.py
```

> Not dead code — 3 call sites + 1 test. To remove it, choose:
> 不是 dead code,有 3 个调用方 + 1 个测试。要删的话:
> (A) delete the 4 references + test + docs together / 同步删 4 个引用 + 测试 + 文档;
> (B) mark `@deprecated`, wait for downstream cleanup / 标 `@deprecated` 等下游清理;
> (C) leave it / 不动。
> Which do you prefer? A scheduled job uses it, so (A) carries production risk.
> 你倾向哪个?有定时任务在用,(A) 有线上风险。

---

## Anti-pattern / 反例 2: New file, forgot to wire it into the project manifests / 新增文件忘了挂到项目清单

Task: add a new module `src/auth/oauth.py`.
任务:加一个新模块 `src/auth/oauth.py`。

What the agent did (wrong): wrote the code and called it done.
错误行为:写完代码就完事。

Fallout:
后果:

- `__init__.py` didn't export it → external imports fail. / `__init__.py` 没 export → 外部 import 不到。
- `pyproject.toml` `packages` didn't list it → wheel build drops it. / 打包丢失。
- `mypy.ini` not configured → type checking skips it. / 类型检查跳过。
- `requirements.txt` missing the new `authlib` dependency → deploy crashes. / 部署崩。

**Why it's wrong / 为什么错:**

A source file isn't "in the project" until the manifests know about it. Adding the `.py` is only half the change.
源文件不被清单认识,就不算"进了项目"。写好 `.py` 只是改了一半。

**The disciplined move / 正确做法:**

After adding a source file, explicitly tick this table before saying "done":
新增文件后,显式打勾这张表,再说"完成":

| Ecosystem / 生态 | Manifests to sync after adding a source file / 新增源文件后必须同步的清单 |
|---|---|
| Python | `__init__.py` exports / `pyproject.toml` packages / `requirements.txt` new deps / `mypy.ini` |
| Node/TS | `package.json` dependencies / `tsconfig.json` include / `index.ts` re-export |
| Go | `go.mod` (new deps) / package import / `go.sum` |
| Rust | `Cargo.toml` dependencies / `lib.rs` mod / feature flags |

---

## Anti-pattern / 反例 3: Parallel agents edit the same file, stale caches collide / 多 agent 并行,各改各的,缓存打架

A main thread launches two agents in parallel:
主线程派两个 agent 并行:

- Agent A: add field `feature_flag_x` to `config.py`.
- Agent B: add field `feature_flag_y` to `config.py`.

Both base their edits on the *original* `config.py`.
两个 agent 都基于"最初的 config.py"做 Edit。

Fallout: A commits first, adding `feature_flag_x`. B then commits based on its cached old copy, and its edit **overwrites** A's change — `feature_flag_x` is lost.
后果:A 先提交加上 `feature_flag_x`。B 紧跟着基于缓存的旧文件提交,Edit **覆盖** A 的改动,`feature_flag_x` 丢了。

**Why it's wrong / 为什么错:**

An agent's in-memory view of a file goes stale the moment a sibling agent writes to it. Editing from a cached version silently clobbers concurrent work.
兄弟 agent 一旦写入,你内存里的文件视图就过期了。基于缓存版本编辑会无声覆盖并发工作。

**The disciplined move / 正确做法:**

Declare the protocol explicitly when dispatching:
派任务时显式声明协议:

> Before editing `config.py`, re-Read the latest file content (don't trust the version you saw last round), then Edit. If you find a field someone else added, append on top of it — never overwrite.
> 编辑 `config.py` **之前**,先用 Read 重新读最新内容(不要相信上一轮看到的版本),再 Edit。发现已有别人加的字段,在合并基础上 append,不要覆盖。

Safer still: don't let two agents edit the same file in parallel — serialize them. The ceiling for file-conflict safety is engineering practice + version control, not AI intuition.
更稳:不让两个 agent 并行改同一文件,串行排队。文件冲突的天花板是"工程素质" + "VCS",不是"AI 直觉"。
