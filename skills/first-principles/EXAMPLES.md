# EXAMPLES — First Principles / 第一性原理

Concrete anti-patterns where convention was used as a substitute for reasoning, and the disciplined re-derivation that should have replaced it.
拿惯例代替推理的反例,以及本应取而代之的第一性原理重推。

---

## Anti-pattern / 反例 1: "Microservices are usually split this way" / "通常微服务这么拆"

User: "We need to split this system into microservices."
AI (wrong): "Usually you split by DDD — user-service / order-service / payment-service / notification-service / inventory-service. Add a message bus and a service mesh."

用户:"我们要把这个系统拆成微服务。"
AI(错误):"通常按 DDD 拆 user / order / payment / notification / inventory 五个服务,再上消息总线 + service mesh。"

**Why it's wrong / 为什么错:** No one asked about current scale, the actual pain, team size, or ops capacity — the industry default was applied blindly. Result: 5 services maintained by 3 engineers (no owner), no transaction-boundary design (cross-service consistency leaks), and a service mesh that multiplies latency on a latency-sensitive workload.
没问规模、真实痛点、团队人数、运维能力,直接套行业默认。结果:5 个服务 3 个工程师无人维护;没有事务边界设计,跨服务一致性漂移;service mesh 把延迟拉高数倍,而业务恰恰对延迟敏感。

**The disciplined move / 正确做法:** State the basic facts first — monolith, low RPS, 3 engineers, weekly deploys, and the real pain is "a one-line frontend change waits on a backend deploy." The irreducible problem is *release coupling*, not *scale*. So the real cut is the **deployment unit**, not the service boundary. Re-derive options: (A) keep the monolith, split the frontend into its own CI/deploy — solves most of the pain, ops unchanged; (B) split into two services (BFF + core) to test the cost of splitting; (C) full microservices — not now, too few hands. Favor (A) → (B) incrementally.
先摆事实:单体、低 RPS、3 个工程师、周部署,真实痛点是"前端改一行要等后端 deploy"。不可简化的问题是 **release 耦合**,不是 scale。所以真正要切的是 **部署单元**,不是 service 边界。重推:(A) 单体不动,前端独立 CI/部署——解决大部分痛点且运维不变;(B) 拆两个服务(BFF + core)先验证拆分代价;(C) 全套微服务——人手不够,暂不做。倾向 (A) → (B) 渐进。

---

## Anti-pattern / 反例 2: "REST is the industry default, so use REST" / "REST 是行业默认就用 REST"

AI: "For your internal data-sync pipeline I recommend a REST API with JSON — it's the industry standard."
AI:"你们做内部数据同步管道,我建议 REST + JSON,这是业界标准。"

**Why it's wrong / 为什么错:** No questions about data volume, real-time requirements, number of consumers, or network topology. The "standard" was treated as the answer instead of a candidate.
没问数据量、实时性、消费者数量、网络拓扑,把"标准"当成答案而不是候选项。

**The disciplined move / 正确做法:** Pin the constraints, then derive. Volume: billions of events/day → JSON serialization saturates CPU. Latency: end-to-end under one second → synchronous HTTP pull can't meet it. Consumers: many downstreams → each polling the source is an N+1 problem. Network: same low-latency VPC. From the constraints: pull fails → need push; many consumers → need fan-out; high throughput → JSON fails → need binary encoding; low latency → avoid HTTP overhead. Conclusion: a streaming bus + binary serialization — not because it's "best practice," but because the constraints push you there.
钉死约束再推导。数据量:每日数十亿事件 → JSON 序列化吃满 CPU;实时性:端到端 < 1s → 同步 HTTP 拉模式做不到;消费者:多下游 → 每个都 poll 源是 N+1;网络:同 VPC 低延迟。从约束推:拉不行 → 要推;多消费者 → 要 fan-out;高吞吐 → JSON 不行 → 要二进制编码;低延迟 → 避开 HTTP overhead。结论:流式总线 + 二进制序列化——不是因为它是 best practice,而是约束推到这里。

---

## Anti-pattern / 反例 3: "All databases are designed this way" / "数据库都这么设计"

AI: "Add `created_at` / `updated_at` / `deleted_at` to the users table and use soft deletes — it's the default ORM pattern."
AI:"用户表加 `created_at` / `updated_at` / `deleted_at`,软删除,这是 ORM 默认模式。"

**Why it's wrong / 为什么错:** No questions about whether deleted records must actually be retained, or whether every query can tolerate carrying a `WHERE deleted_at IS NULL` filter. The default pattern was copied without checking it fits.
没问是否真要保留删除记录、能否容忍每条 SQL 都带 `WHERE deleted_at IS NULL`,直接复制默认模式而没验证是否适配。

**The disciplined move / 正确做法:** State the invariants. "Delete" is irreversible at the product level (a privacy regulation requires physical deletion); ~all queries fetch active users; history/audit already lives in a separate `audit_log` table. Now challenge the default: soft delete exists to give "recoverable mistakes + retained history" — but the regulation mandates physical deletion, and recovery is already covered by the audit log. Soft delete only adds cost here: a filter on every query, redundant indexes, and a data-leak risk if a filter is ever forgotten. Re-derive: physical delete + an `audit_log` event `user_deleted` with the payload. Not because "soft delete is an anti-pattern" in the abstract, but because *this* project's constraints lead there.
摆出不变式:产品层"删除"不可逆(合规要求物理删除);几乎所有查询都按 active 用户检索;历史/审计已在独立 `audit_log` 表。挑战默认:软删除是为了"误删可恢复 + 保留历史",但合规强制物理删,恢复需求已由 audit_log 满足。软删除在此只带来成本:每条查询都要过滤、索引冗余、一旦漏过滤就泄漏数据。重推:物理删除 + 在 `audit_log` 记 `user_deleted` 事件及 payload。不是因为"软删除是反模式"这种笼统话,而是 **这个** 项目的约束推出此结论。
