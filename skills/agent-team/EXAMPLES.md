# EXAMPLES — Agent Team / Agent Team 协作

Concrete anti-patterns where the main thread did the work itself, skipped QA, or outsourced what it shouldn't — and the disciplined division of labor that should have replaced them.
主线程独自硬干、跳过监理、或外包了不该外包的活的反例,以及本应取而代之的分工纪律。

---

## Anti-pattern / 反例 1: The main thread swallows a task spanning many files / 主线程独自吞下跨多文件的任务

User: "Migrate the whole project from one database engine to another."
Main thread (wrong): reads and edits files one by one inline — a dozen files read, eight edited — until the context balloons past 200k tokens and even the user's original request is lost.

用户:"把整个项目从一个数据库引擎迁到另一个。"
主线程(错误):在主对话里逐文件 Read + Edit,读十几个、改八个,上下文冲到 200k+ token,连用户原始需求都记不清了。

**Why it's wrong / 为什么错:** The main context fills with implementation detail (SQL strings, session objects, migration scripts); the user can't see staged progress and has to hunt for the point in a wall of output; and no one accepts the result — "done" gets declared with no verification.
主上下文被实现细节(SQL 字符串、session 对象、迁移脚本)塞满;用户看不到分阶段进度,要在巨大输出里找重点;没人验收,迁完就说"完成"。

**The disciplined move / 正确做法:** The main thread plans and delegates. Plan into sub-tasks: (A) schema/DDL migration, (B) data-access layer switch, (C) test-suite adaptation. Dispatch an engineer agent for A ("touch only the migrations directory; return a schema diff + test result"), then a QA agent to accept A with ✅/❌/⚠️ (focus on whether nullable/index/foreign-key constraints survived). QA passes → move to B, same loop. The main thread does the smoke test (start the service, exercise login, read logs) and gives the user one merged report. Main context stays lean (~30k: plan + QA verdicts + smoke output); each sub-agent burns its own ~100k window and is discarded after use.
主线程只做规划与派工。拆子任务:(A) schema/DDL 迁移、(B) 数据访问层切换、(C) 测试套件适配。派工程师 agent 做 A("只动 migrations 目录,返回 schema diff + 测试结论"),再派监理 agent 对 A 出 ✅/❌/⚠️(重点查 nullable/索引/外键约束是否在迁移中丢失)。监理过 → 进 B,同样套路。主线程做冒烟测试(起服务、走登录、看日志),最后给用户一份合并报告。主上下文保持精简(约 30k:规划 + 监理结论 + 冒烟输出);每个子 agent 烧自己的约 100k 窗口,用完即弃。

---

## Anti-pattern / 反例 2: Skipping QA — the engineer self-reports "done" / 跳过监理,工程师自报"完成"

Main thread dispatches an engineer agent to write a new API endpoint. The agent returns "code written, done." The main thread relays "done" to the user.
主线程派工程师 agent 写一个新 API 接口,agent 返回"代码已写,完成",主线程直接告诉用户"完成"。

**Why it's wrong / 为什么错:** No one played QA. An engineer agent is biased toward proving its own work correct and lacks adversarial testing — "it compiles" is not "it works."
没人扮演监理。工程师 agent 倾向证明自己干得对,缺乏对抗性测试——"能编译"不等于"能工作"。

**The disciplined move / 正确做法:** After the engineer returns, the main thread **must** open a separate QA agent: run adversarial tests on the endpoint — happy path (valid input → success), error paths (duplicate key / missing field / over-long field / injection attempt / oversized payload), boundaries (length = limit−1 / limit / limit+1), and concurrency (simultaneous identical requests). Output ✅/❌/⚠️ with a reproduction command for each FAIL. If QA fails → back to the engineer → re-run QA. Only green counts as done.
工程师返回后,主线程 **必须** 再开一个监理 agent:对接口做对抗性测试——正确路径(有效输入 → 成功)、错误路径(重复键/缺字段/超长字段/注入尝试/超大 payload)、边界(长度 = 上限−1 / 上限 / 上限+1)、并发(同时发起相同请求)。输出 ✅/❌/⚠️,每个 FAIL 附复现命令。监理 FAIL → 回工程师修 → 再过监理。绿了才算完。

---

## Anti-pattern / 反例 3: Outsourcing communication to an agent / 把"沟通"也派给 agent

The main thread asks a sub-agent to draft the reply explaining "why we chose this approach," then pastes it to the user verbatim.
主线程让 sub-agent 起草"为什么这个方案要这么选"的回复,然后原样转贴给用户。

**Why it's wrong / 为什么错:** Communication is the main thread's non-outsourceable duty. When the user asks "why," they want an answer consistent with the *current main-thread context* — which the sub-agent doesn't have.
沟通是主线程不可外包的职责。用户问"为什么",要的是和当前主线程上下文一致的答案,而 sub-agent 没有这个上下文。

**The disciplined move / 正确做法:** Keep the division of labor clear:
保持分工清晰:

| Work type / 工作类型 | Who does it / 谁干 |
|---|---|
| Writing/editing code, multi-file edits / 写改代码、跨多文件编辑 | Engineer agent / 工程师 agent |
| Running tests, finding bugs, boundary checks / 跑测试、找 bug、边界验证 | QA agent / 监理 agent |
| Researching a library, searching the codebase, listing deps / 调研库、搜 codebase、列依赖 | Research agent / research agent |
| Planning/decomposition, cross-stage rollup, talking to the user / 规划拆分、跨阶段汇总、跟用户对话 | Main thread (not outsourced) / 主线程(不外包) |
| Accepting QA verdicts, deciding the next step / 验收监理结论、决定下一步 | Main thread (not outsourced) / 主线程(不外包) |
| Smoke testing, checking the user's original ask is met / 冒烟测试、核对用户原始诉求是否满足 | Main thread (not outsourced) / 主线程(不外包) |
