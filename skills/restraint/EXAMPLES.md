# EXAMPLES — Restraint / 克制律

> These are generalized anti-patterns, rewritten from real-world agent mishaps. Names, companies, and ticket numbers have been stripped — the failure mechanism is what matters.
> 以下是从真实踩坑改写的通用反例。人名、公司、工单号已脱敏,留下的是失败机制本身。

---

## Anti-pattern / 反例: The flag nobody asked for

The human says: "add retry to the HTTP client — it flakes on deploys." The agent ships:

```python
def request(url, *, enable_retry=True, max_retries=None, retry_strategy="exponential",
            retry_on=(500, 502, 503), retry_jitter=True, retry_config_path=None):
```

Six knobs, an env var `HTTP_RETRY_MODE`, a `RetryStrategy` enum with three variants, and a YAML config loader. The spec was one sentence.

用户说:"给 HTTP client 加个重试——部署时老抖。" agent 交付了 6 个可选参数、一个 `HTTP_RETRY_MODE` 环境变量、一个三成员的 `RetryStrategy` 枚举、外加 YAML 配置加载器。spec 只有一句话。

**Why it's wrong / 为什么错:**

Not one of those knobs has a present-day caller. Every parameter is a permanent API surface: it must be documented, tested across combinations (this one has 48), and honored forever. The diff *looks* diligent; the maintenance bill is real. This is the systematic bias — the model would rather emit more than the minimum.

没有一个开关存在今日调用方。每个参数都是永久 API 面:要写文档、要按组合测试(这套有 48 种组合)、要永远兼容。diff 看起来勤奋,维护账单是真的。这就是系统性偏差——模型总想输出超过下限的东西。

**The disciplined move / 正确做法:**

```python
_MAX_RETRIES = 3  # deploy flakes recover within ~3 attempts; revisit if a caller needs otherwise

def request(url):
    for attempt in range(_MAX_RETRIES + 1):
        ...  # exponential backoff, retry on 5xx only
```

Ship the concrete behavior the spec asked for. The day a *second real caller* needs a different retry count, promote the constant to a parameter — that's a five-minute change made exactly when it's justified.

> ✅ Retry implemented, 0 new parameters, 0 new config surface
> ⚠️ Retry count hardcoded at 3 with a revisit trigger in the comment
> ❌ Nothing speculative shipped

按 spec 实现具体行为。哪天出现**第二个真实调用方**需要不同的重试次数,再把常量升级成参数——那是个五分钟的改动,且恰好在被证明需要时才做。

---

## Anti-pattern / 反例: Guarding the impossible

A function receives `items: list[OrderLine]` from a caller that already validated the payload at the API boundary. The agent adds:

```python
def total(items: list[OrderLine]) -> Decimal:
    if items is None:                      # "just in case"
        return Decimal("0")
    if not isinstance(items, list):        # "defensive"
        return Decimal("0")
```

函数从已在 API 边界完成校验的调用方接收 `items: list[OrderLine]`。agent 还是加了 "以防万一" 的 None 检查和 isinstance 检查,失败时静默返回 0。

**Why it's wrong / 为什么错:**

The type and the caller's contract already exclude `None`. If it ever *is* `None`, that's a bug upstream — and this guard converts the bug into a silent `0` total on a real order. The guard doesn't add safety; it adds a place for bugs to hide. The test is "can untrusted data reach here?" — it can't; it was validated at the boundary.

类型和调用方契约已经排除了 `None`。如果真的传来 `None`,那是上游 bug——这个防御把 bug 转化成真实订单上一个静默的 0 元合计。防御没有增加安全,只是给 bug 加了藏身处。判据是"不受信数据到得了这里吗?"——到不了,边界已经验过。

**The disciplined move / 正确做法:**

Delete both guards. Validate at the trust boundary (the API deserializer), trust the contract inside. If you want a tripwire, `assert items is not None` fails loud instead of corrupting totals silently.

> ✅ Guards removed; boundary validation confirmed at the API layer (file:line)
> ❌ No silent-zero path remains

两个防御都删掉。信任边界(API 反序列化层)验证,边界之内信任契约。要留绊线就用 `assert`——大声失败,而不是静默污染合计金额。

---

## Anti-pattern / 反例: The factory with one product

Task: "integrate Stripe for checkout." The agent delivers `PaymentProvider` (abstract base), `PaymentProviderFactory`, `PaymentProviderRegistry`, `providers/stripe.py` — four files, one actual implementation. "So we can add PayPal later."

任务:"接 Stripe 支付。" agent 交付抽象基类 + 工厂 + 注册表 + `providers/stripe.py`——四个文件,一个真实现。理由:"以后好加 PayPal。"

**Why it's wrong / 为什么错:**

There is no PayPal. The abstraction was designed against one example, so its shape is a guess — and when the second provider actually arrives, it never fits the guessed interface; you refactor the abstraction *and* the indirection. The wrong abstraction is worse than duplication. Meanwhile every reader pays the indirection tax today.

PayPal 并不存在。这个抽象只对着一个样本设计,形状纯靠猜——等第二个 provider 真来了,几乎必然不符合猜出来的接口,到时候抽象和间接层要一起重构。错误的抽象比重复更糟,而每个读代码的人今天就在付间接税。

**The disciplined move / 正确做法:**

One concrete `stripe_checkout.py`. When PayPal *actually* lands on the roadmap, extract the interface from two real implementations — abstractions derived from two concrete cases fit; abstractions guessed from one don't.

> ✅ One file, zero indirection, checkout works end-to-end
> ⚠️ Revisit trigger: extract an interface when a second provider is scheduled

一个具体的 `stripe_checkout.py`。等 PayPal 真进 roadmap,再从**两个真实实现**里提取接口——从两个具体案例归纳的抽象才合身,从一个案例猜的不会。

---

## Anti-pattern / 反例: The catch that ate the outage

```python
def save_event(event):
    try:
        db.insert("events", event.to_row())
    except Exception:
        logger.debug("insert failed, skipping")   # keep the pipeline "resilient"
        return None
```

Three weeks later: the events table has a 14-hour hole. The DB had hit a disk-full error; every insert failed; the pipeline reported healthy the whole time. `debug` logs were off in prod.

三周后:events 表出现 14 小时空洞。数据库磁盘满,所有 insert 失败,流水线全程报告健康。prod 环境 `debug` 日志是关的。

**Why it's wrong / 为什么错:**

`except Exception` + return-None converts *every* failure — disk full, schema drift, auth expiry, a typo in `to_row` — into silent data loss. Nothing here is recoverable by this function, so nothing should be caught here. Training reward shaping taught models that unhandled exceptions look bad; in production, *swallowed* exceptions are what kill you.

`except Exception` + 返回 None 把**一切**失败——磁盘满、schema 漂移、凭证过期、`to_row` 里一个 typo——统统转化为静默数据丢失。这个函数没有任何它能恢复的错误,所以这里什么都不该捕获。训练奖励让模型觉得未处理异常很难看;生产上,被吞掉的异常才是杀手。

**The disciplined move / 正确做法:**

```python
def save_event(event):
    db.insert("events", event.to_row())   # let it propagate; the pipeline's retry/DLQ owns failure
```

If a *specific* recoverable case exists (e.g. duplicate-key on redelivery), catch exactly that one, and log it at a level prod actually emits.

> ✅ Only `DuplicateKeyError` caught (redelivery is expected and recoverable), logged at INFO
> ✅ Disk-full now fails loud → pager fires within one minute instead of 14 hours
> ❌ No catch-all remains

让异常传播,失败交给流水线自己的 retry/死信队列。若存在**具体**可恢复场景(如重投递的主键冲突),只捕那一个,且用 prod 真会输出的日志级别记录。
