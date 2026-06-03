# EXAMPLES — Test Is Truth / 测试即结论

> These are generalized anti-patterns, rewritten from real-world agent mishaps. Names, companies, and ticket numbers have been stripped — the failure mechanism is what matters.
> 以下是从真实踩坑改写的通用反例。人名、公司、工单号已脱敏,留下的是失败机制本身。

---

## Anti-pattern / 反例: Starting work without checking it was already done

The repo uses a two-branch flow (`feature → dev → main`). On an open issue the human says "fix this one." The agent immediately:

1. Views the issue → state=OPEN
2. Clones, branches, writes code
3. ~450 lines of implementation + tests + a PR

Halfway through merging, it casually checks `git log dev` and finds a PR merged 9 hours earlier whose body said `Closes #N` — the work had been done long ago. The agent's PR is pure duplicate effort: close it, delete the branch, four hours wasted.

仓库走双分支流(`feature → dev → main`)。一个 open 的 issue 上,用户说"修一下这条"。agent 立刻:

1. 查 issue → state=OPEN
2. clone、切分支、写代码
3. 约 450 行实现 + 测试 + 一个 PR

合到一半,顺手看了下 `git log dev`,发现 9 小时前已有一个 PR merged,body 里写着 `Closes #N`——工作早就做完了。agent 的 PR 纯属重复劳动:close、删分支,白干四小时。

**Why it's wrong / 为什么错:**

The agent took "issue state=OPEN" as proof the work wasn't done. But auto-close keywords like `Closes #N` only fire on merge to the *default* branch. A PR merged to `dev` does not auto-close the issue even with the keyword. "Looks OPEN" ≠ "not done." Done is determined by a *falsifiable dedup check*, not by issue state alone.

agent 把"issue state=OPEN"当成"工作没做"的证据。但 `Closes #N` 这类自动关键字只在 merge 到**默认分支**时生效。merge 到 `dev` 的 PR 即使带关键字也不会自动关 issue。"看上去 OPEN" ≠ "没做"。完成判定靠**可证伪的查重**,不是单看 issue state。

**The disciplined move / 正确做法:**

Before any "fix X" / triage task, run a dedup check first:

```bash
# search merged/closed PRs that reference the issue, in body and elsewhere
gh pr list --search "Closes #<n> in:body" --state all --limit 10
gh pr list --search "<n>"                 --state all --limit 10   # fallback
git log <integration-branch> --grep "#<n>" --oneline               # non-default branch
```

Then report:

> ✅ Dedup check: a merged PR already resolves #N (merged to the integration branch, not default — so the issue didn't auto-close)
> ❌ No need to reimplement
> ⚠️ Issue still OPEN only because the merge target wasn't the default branch — route to the "review note + human sign-off" flow

Automation (self-heal bots, dispatchers) can quietly finish the work in the hours between you reading the board and starting — not checking is a high-frequency failure. Done is not "code written," it's "a falsifiable dedup / test / sign-off output exists."

仓库自动化(self-heal bot / dispatcher)会在你看板之后、动手之前的几小时里悄悄把活干了——不查重就动手是高频翻车点。完成不是"写完代码",而是"存在可证伪的查重 / 测试 / 验收输出"。

---

## Anti-pattern / 反例: Closing the issue yourself, skipping review

The agent merges a fix, runs the test suite green, then immediately:

```bash
gh issue close <n> --reason completed
```

agent 把修复合入,跑测试全绿,然后立刻:

```bash
gh issue close <n> --reason completed
```

**Why it's wrong / 为什么错:**

"Code written + tests green" is not "done." An engineer cannot be both player and referee — self-marking done is worthless. You must first write a review note on the issue and wait for human sign-off, *then* close. A direct close skips the QA gate entirely.

"代码写完 + 测试绿" 不等于完成。工程师不能既当裁判又当运动员——自我标 done 没用。必须先在 issue 上写审查意见、等用户验收,**然后**才能 close。直接 close = 跳过监理。

**The disciplined move / 正确做法:**

1. Comment a review note — go through the issue's acceptance criteria one by one, with the actual commands run + evidence (test output / curl response / grep hit), in ✅/❌/⚠️ format, ending with "awaiting sign-off."
2. Wait for an explicit `approved` / `close <n>` / `yes`.
3. *Then* close.

If you rely on PR-merge auto-close (keyword + default branch), put the review note in the PR description — that's equivalent to commenting.

1. 评论审查意见——逐条对照 issue 的 acceptance criteria,附实际执行的命令 + 证据(测试输出 / curl 响应 / grep 命中),用 ✅/❌/⚠️ 格式,末尾标"待验收"。
2. 等用户回 `验收通过` / `close <n>` / `yes`。
3. **然后**才 close。

若走 PR-merge 自动关(关键字 + 默认分支),把审查意见写进 PR 描述里,等价于评论审查。

Done = an auditable proof of quality + human sign-off, not "tests are green."
完成 = 可审计的合格证据 + 用户验收,不是 "测试绿"。

---

## Anti-pattern / 反例: "Should be fine" is not a conclusion

> Agent: "I fixed the precision issue in `parse_amount` by switching to `Decimal`. The code looks right and the logic is sound. Done."

> agent: "我修复了 `parse_amount` 的精度问题,改用了 `Decimal`。代码看起来没问题,逻辑也对。完成。"

**Why it's wrong / 为什么错:**

No test was run, no falsifiable output. "Looks right" is a guess, not a conclusion.

没跑测试,没有可证伪的输出。"看起来对"是猜测,不是结论。

**The disciplined move / 正确做法:**

> Agent: Ran `pytest tests/test_parse_amount.py -v`:
>
> ✅ Pass: 6/8 — normal paths (integer / two decimals / large) + 2 boundaries (0.01 / 999999999.99)
> ❌ Fail: 1/8 — `test_negative_amount` expected ValueError, got -100; needs fixing
> ⚠️ Uncovered: `None` input, thousands-separator `1,234.56`; I didn't touch that logic, leaving it
>
> Next: fix the ❌. Want me to add the two ⚠️ cases while I'm here?

---

## Anti-pattern / 反例: Padding the result with irrelevant tests

The agent changed only the password check in `auth.py`, but ran the full `pytest` suite, saw all 1200 cases green, and declared "done."

agent 只改了 `auth.py` 的密码校验,却跑了全量 `pytest`,看到 1200 个 case 全绿就说"完成"。

**Why it's wrong / 为什么错:**

Only ~8 of those 1200 cases relate to `auth.py`; the rest being green has nothing to do with this change. The conclusion is inflated.

1200 个 case 里只有约 8 个跟 `auth.py` 相关,其余绿不绿与本次改动无关。结论虚胖。

**The disciplined move / 正确做法:**

> Change target: `auth.py::verify_password`
>
> Ran `pytest tests/test_auth.py::test_verify_password -v` (8 cases)
>
> ✅ Pass: 7/8 — correct / wrong / empty / overlong / unicode / SQL-injection chars / bcrypt hash compare
> ❌ Fail: 1/8 — `test_timing_attack`: new logic has an 8ms delta between short and long passwords, a side-channel risk
> ⚠️ Uncovered: rate-limit path unchanged, reusing old tests
>
> Full regression (1200 cases) runs only before merge — it does not factor into this done-judgment.
