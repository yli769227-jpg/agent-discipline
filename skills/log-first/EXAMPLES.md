# EXAMPLES — log-first

> Real anti-patterns from the field, rewritten as generic, de-identified cases. The mechanism is preserved; the people, places, and project specifics are gone.
> 真实踩坑改写成的通用反例,去掉人/地/项目,只保留可复用的机制。

---

## Anti-pattern / 反例: Errors swallowed silently — nobody knows what happened

```python
def fetch_user(user_id: str) -> dict | None:
    try:
        resp = httpx.get(f"{API}/users/{user_id}", timeout=5)
        return resp.json()
    except Exception:
        return None
```

**Why it's wrong / 为什么错:**

On error it returns `None`. The caller gets an empty result but **cannot tell whether it was a 404, a timeout, or a JSON parse failure**. During a production incident, all you can do is guess.

出错时返回 `None`,调用方拿到空,但**分不清是 404、timeout 还是 JSON 解析错**。生产事故时只能猜。

**The disciplined move / 正确做法:**

```python
import logging
log = logging.getLogger("user_api")

def fetch_user(user_id: str) -> dict | None:
    log.info("[user_api] fetch_user start user_id=%s", user_id)
    try:
        resp = httpx.get(f"{API}/users/{user_id}", timeout=5)
        log.info("[user_api] fetch_user resp status=%s len=%d",
                 resp.status_code, len(resp.content))
        resp.raise_for_status()
        return resp.json()
    except httpx.TimeoutException as e:
        log.error("[user_api] fetch_user TIMEOUT user_id=%s err=%s", user_id, e)
        return None
    except httpx.HTTPStatusError as e:
        log.error("[user_api] fetch_user HTTP_ERROR user_id=%s status=%s",
                  user_id, e.response.status_code)
        return None
    except Exception:
        log.exception("[user_api] fetch_user UNEXPECTED user_id=%s", user_id)
        return None
```

Key elements: module prefix `[user_api]`, inputs, a summary of the response, and classified errors with context.

要点:模块前缀 `[user_api]`、入参、出参摘要、错误分类 + 上下文。

---

## Anti-pattern / 反例: State transitions with no logs — no replay after the fact

```python
class Order:
    def pay(self):
        if self.status == "pending":
            self.status = "paid"
    def ship(self):
        if self.status == "paid":
            self.status = "shipped"
```

**Why it's wrong / 为什么错:**

A user complains "I ordered but it never shipped." The DB shows `status=pending`, but you **cannot tell** whether it was ever paid and then reverted, or which caller triggered which transition.

用户投诉"下了单为啥没发货",查 DB 看到 `status=pending`,但**无法判断**中间是否支付过又被改回去、是哪个调用方触发的。

**The disciplined move / 正确做法:**

```python
class Order:
    def _transition(self, frm, to, actor):
        log.info("[order:%s] state %s -> %s by=%s ts=%s",
                 self.id, frm, to, actor, time.time())
        self.status = to

    def pay(self, actor="user"):
        if self.status != "pending":
            log.warning("[order:%s] pay rejected current=%s", self.id, self.status)
            return False
        self._transition("pending", "paid", actor)
        return True
```

Key elements: log every state transition with actor + timestamp; rejected transitions are logged too. When something breaks, `grep "[order:12345]"` reconstructs the whole timeline in one shot.

要点:每次状态跃迁都打日志,带 actor + timestamp,被拒的跃迁也打;出问题 `grep "[order:12345]"` 一行还原全过程。

---

## Anti-pattern / 反例: Scattered log format — impossible to grep

```
2026-01-20 10:00:01 ok
2026-01-20 10:00:02 starting
2026-01-20 10:00:03 done
2026-01-20 10:00:04 error: something failed
```

**Why it's wrong / 为什么错:**

No module prefix, no operation name, no ID. When something goes wrong you cannot grep out "what was user 42 doing at the time."

没有模块前缀、操作名、ID,出事根本 grep 不出"用户 42 当时在干嘛"。

**The disciplined move / 正确做法:**

```
2026-01-20 10:00:01 [auth] login start user_id=42 ip=1.2.3.4
2026-01-20 10:00:02 [auth] login ok user_id=42 session=abc
2026-01-20 10:00:03 [order] create start user_id=42 sku=X
2026-01-20 10:00:04 [order] create FAIL user_id=42 sku=X err=InventoryEmpty
```

`grep "user_id=42" app.log` reconstructs that user's full path.

`grep "user_id=42" app.log` 即可还原该用户完整路径。
