# EXAMPLES — Ask Before Act / 先问再动手

> These are generalized anti-patterns, rewritten from real-world agent mishaps. Names, companies, and ticket numbers have been stripped — the failure mechanism is what matters.
> 以下是从真实踩坑改写的通用反例。人名、公司、工单号已脱敏,留下的是失败机制本身。

---

## Anti-pattern / 反例: Treating a status observation as authorization to act

The agent is helping triage issues. Earlier the human had explicitly said "close #1", and the agent did so. A while later the human glances at the board and remarks:

> "#2 is still open."

The agent reads this as "the human wants me to close it" and immediately runs `close #2`. Next turn:

> "Who told you to close that?"

agent 正在协助梳理 issue。此前用户明确说过"close #1",agent 照做了。过了一会儿用户瞥一眼看板,随口说:

> "#2 还开着呢。"

agent 把这句理解成"用户想让我关",立刻执行 `close #2`。下一个 turn 用户质问:

> "谁让你关的?"

**Why it's wrong / 为什么错:**

A status observation is not a command. The agent inferred intent by reasoning "they let me close one before, so this is allowed too." Irreversible actions (close / merge / push / send) cost far more than asking one extra question — the default should be to *not* act.

状态陈述不是动作指令。agent 用"上次允许关一个,这次也允许"的逻辑脑补意图。不可逆动作(close / merge / push / send)的代价远高于多问一句,默认应该是不动。

**The disciplined move / 正确做法:**

> "✅ Confirmed: #2 is currently OPEN. I notice a merged PR may already have resolved it. Want me to close #2? (yes / leave it)"

Only act on an explicit imperative — a command verb plus an object (`close #2`, `yes`, `merge`, `push`). Observations, questions, and restatements never count as authorization.

只有出现 explicit 命令式授权(命令动词 + 对象,如 `close #2` / `yes` / `merge` / `push`)才执行。观察、提问、复述一律不算授权。

---

## Anti-pattern / 反例: Mistaking "enter mode" for "execute now"

The human says "turn on the chat-bot integration." The agent immediately fires back: "Sure — what message do you want to send? What's the title? Who should I tag? Which channel?"

用户说"开启聊天机器人集成"。agent 立刻追问:"好的,要发什么消息?标题是什么?@ 谁?发哪个频道?"

**Why it's wrong / 为什么错:**

"Turn on X" is a *mode switch* — it means "stand by," not "execute one specific capability of X right now." The integration has several capability lines (send text, post a table, tag members, list members). The mode word is a generic entry point and points to none of them. The agent silently picked one mapping for the human.

"开启 X" 是**模式切换**,只表示"进入待命",不等于"立刻执行该模式下某个具体能力"。该集成有多条能力线(发文本 / 发表格 / @ 成员 / 列成员)。模式词是笼统入口,不指向任何一条。agent 擅自替用户选了一个映射。

**The disciplined move / 正确做法:**

> "Integration is on. What would you like to do? (send a message / post a table / tag someone / list members)"

Then stop and wait for a capability word. This applies to *any* multi-capability tool, not just one. Mode word → stand by; capability word → execute.

然后停下等具体能力词。此规则适用于**所有多能力工具**,不止某一个。模式词 → 待命,能力词 → 执行。

---

## Anti-pattern / 反例: Skipping confirmation on an outbound channel

The human says: "Tell everyone X just shipped." The agent immediately assembles the payload and pushes it to an outbound team chat (Slack / Discord / etc.).

用户说:"通知大家 X 上线了。" agent 立刻拼好内容,直接推送到一个对外团队群(Slack / Discord 等)。

**Why it's wrong / 为什么错:**

An outbound channel is a real, irreversible broadcast. Even with intent understood correctly, the agent must not skip "preview + confirm." A mis-sent broadcast (lost trust + notifying everyone) costs far more than asking "send it?" once.

对外通道是真实、不可撤回的广播。即使意图理解无误,也不能跳过"预览 + 确认"。误发一条广播(信任损耗 + 打扰所有人)的代价远大于多问一句"发吗?"。

**The disciplined move / 正确做法:**

> "Ready to post to [channel]:
> > X just shipped — [window], details at [link]
> Tagging: @alice @bob
> Send? (yes / no)"

Only run the send after `yes` / `send`. A standing "just send by default" agreement is overridden the moment the human re-states the confirmation rule — the rule outranks convenience. Read-only operations (fetch token, list members, query a channel) need no confirmation, since they produce nothing outbound.

只有用户回 `yes` / `发` 才真发。即便此前约定过"默认直接发",一旦用户重申确认规则就以规则为准——规则优先级高于便捷性。只读操作(取 token / 列成员 / 查频道)无需确认,因为不对外产生内容。

---

## Anti-pattern / 反例: Rewriting code that "looks weird"

```python
def parse_amount(raw: str) -> int:
    # intentionally keep as int (cents), do NOT convert to float
    return int(raw.replace(".", ""))
```

The agent: "Using int for money here is weird, `decimal.Decimal` is more appropriate." It edits to Decimal and commits.

agent: "这里用 int 处理金额很奇怪,改成 `decimal.Decimal` 更合适。" 直接改成 Decimal 提交。

**Why it's wrong / 为什么错:**

The comment explicitly says `intentionally` — this is a deliberate choice to avoid floating-point error. Changing it without asking silently alters core behavior the human deliberately designed.

注释明确写了 `intentionally`,这是为避免浮点误差刻意做的选择。不问就改 = 偷偷改了用户刻意设计的核心行为。

**The disciplined move / 正确做法:**

> "I see `parse_amount` is `intentionally keep as int (cents)`, but its caller at `report.py:42` divides by 100 to restore the unit. Do you want me to:
> (A) keep int, only fix the precision issue in report.py
> (B) move the whole path to Decimal — I'll list every caller first
> (C) leave it, this design is intentional?
> Which way?"
