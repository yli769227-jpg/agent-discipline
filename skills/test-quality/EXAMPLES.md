# EXAMPLES — Test Quality Nine Rules / 测试质量九规

> These are generalized anti-patterns, rewritten from real-world agent mishaps. Names, companies, and ticket numbers have been stripped — the failure mechanism is what matters.
> 以下是从真实踩坑改写的通用反例。人名、公司、工单号已脱敏,留下的是失败机制本身。

---

## Anti-pattern / 反例: Mocking your own code to "isolate the unit"

Testing `OrderService.checkout()`, the agent mocks the *internal* `PriceCalculator`:

```python
def test_checkout(mocker):
    calc = mocker.patch("orders.service.PriceCalculator")
    calc.return_value.total.return_value = Decimal("99.00")
    svc = OrderService()
    svc.checkout(order)
    calc.return_value.total.assert_called_once_with(order.lines, currency="EUR")
```

测 `OrderService.checkout()` 时,agent 把**内部类** `PriceCalculator` mock 掉,然后断言它"被以某参数调用过一次"。

**Why it's wrong / 为什么错:**

Two violations at once. (1) `PriceCalculator` is not a system boundary — it's the project's own code; mocking it means the real pricing logic runs in *zero* tests of checkout. A rounding bug in the calculator ships green. (2) The assertion checks *how* checkout talks to its collaborator, not *what* checkout produces. Rename the keyword argument in a refactor and the test breaks with behavior fully intact — the test punishes refactoring and catches nothing.

一次踩两条。(1) `PriceCalculator` 不是系统边界,是项目自己的代码;mock 掉它意味着 checkout 的所有测试里真实计价逻辑一次都没跑过,计算器里的舍入 bug 全绿出厂。(2) 断言测的是 checkout 怎么**称呼**协作者,不是 checkout **产出**什么。重构改个关键字参数名,行为原封不动测试却碎——这种测试惩罚重构,什么也抓不到。

**The disciplined move / 正确做法:**

```python
def test_checkout_charges_line_total_including_vat():
    svc = OrderService()                      # real calculator inside
    result = svc.checkout(order_with(lines=[line(price="82.64", qty=1)], vat=0.21))
    assert result.charged == Decimal("100.00")   # 82.64 * 1.21, rounded half-up
```

Real collaborator, assert the observable outcome. Mock only if checkout crosses a real boundary (the payment gateway HTTP call) — and then assert what checkout *does with the gateway's response*, not the call signature.

> ✅ Pricing logic actually executes in the checkout path
> ✅ Refactors that preserve behavior keep the test green

真协作者,断言可观察结果。只有当 checkout 跨真实边界(支付网关 HTTP 调用)时才 mock——且断言 checkout 拿网关响应**做了什么**,不是调用签名。

---

## Anti-pattern / 反例: The mocked DTO that hid a typo

```python
def test_send_welcome(mocker):
    user = mocker.Mock()
    user.email = "a@b.com"
    send_welcome(user)
```

Production code reads `user.emial` (typo). `Mock` cheerfully returns a new Mock for any attribute — the test passes. The typo reaches prod; welcome emails silently go to `<Mock id=0x…>` and the ESP drops them for a week.

生产代码里写的是 `user.emial`(typo)。`Mock` 对任何属性都笑脸相迎地返回新 Mock——测试通过。typo 进了 prod,欢迎邮件静默发往 `<Mock id=0x…>`,ESP 连丢一周。

**Why it's wrong / 为什么错:**

`User` is a state object — it has no behavior worth faking and constructing it costs three lines. Mocking state disables exactly the checks that catch real bugs: attribute-name typos, missing fields, validation errors. This is rule 8, a must-fix: state and value objects are constructed real, never mocked.

`User` 是状态对象——没有值得伪造的行为,构造成本三行。mock 状态恰好关掉了能抓真 bug 的那类检查:属性名 typo、缺字段、校验错误。这是第 8 条,必须修档:状态与值对象永远真实构造,不 mock。

**The disciplined move / 正确做法:**

```python
def test_send_welcome_uses_the_users_address():
    user = User(id=1, email="a@b.com", locale="en")   # real object
    outbox = send_welcome(user)
    assert outbox.to == "a@b.com"
```

With a real `User`, `user.emial` raises `AttributeError` in the first test run. If constructing `User` takes 30 fields and hurts — that's design feedback: add a test builder (`a_user(email="a@b.com")`), don't reach for `Mock`.

> ✅ Typo caught at test time, not by a week of dropped mail

用真 `User`,`user.emial` 在第一次跑测试时就抛 `AttributeError`。如果构造要填 30 个字段太痛苦——那是设计反馈:加 test builder,而不是抓起 `Mock`。

---

## Anti-pattern / 反例: Asserting the SQL string instead of the behavior

The suite "covers" the repository layer like this:

```javascript
it("builds the active-tasks query", () => {
  const sql = repo.activeTasksQuery();
  expect(sql).toMatch(/status IN \('pending', 'running'\)/);
});
```

Later a migration renames the states (`pending → queued`). The source SQL is updated; this regex isn't. The test now fails on correct code — or worse, someone "fixes" it by copying the new literal in, and it goes back to proving nothing except that a string equals itself.

测试用正则断言仓库层生成的 SQL 字符串。后来迁移把状态改名(`pending → queued`),源码 SQL 更新了,这个正则没跟上。测试开始对正确代码报错——或者更糟,有人把新字面量抄进断言"修好"它,于是它重新退化为"字符串等于它自己"的证明。

**Why it's wrong / 为什么错:**

The SQL text is an implementation detail (rule 1); the behavior is *which rows come back*. A string assertion can't tell a working query from a broken one — it would happily pass a query with the right literal and a wrong JOIN. And every schema literal now lives in two unlinked places that drift apart silently.

SQL 文本是实现细节(第 1 条);行为是**查回哪些行**。字符串断言分不清能跑的查询和坏掉的查询——字面量对了、JOIN 错了,它照样绿。而且每个 schema 字面量从此活在两个互不链接的地方,静默漂移。

**The disciplined move / 正确做法:**

```javascript
it("returns only tasks still being worked", async () => {
  await seed(db, [task({status: "queued"}), task({status: "running"}), task({status: "done"})]);
  const rows = await repo.activeTasks(db);       // real test DB, real migrations (rule 9)
  expect(rows.map(r => r.status).sort()).toEqual(["queued", "running"]);
});
```

Run it against a real test database with real migrations. When the state names change in one migration, this test follows the schema automatically — it verifies the contract, not the spelling.

> ✅ Catches wrong JOINs, wrong filters, and schema drift — none of which the regex could see

对真测试库 + 真迁移跑。状态名在迁移里改掉时,这个测试自动跟随 schema——它验证契约,不验证拼写。

---

## Anti-pattern / 反例: Eight copies of the same test

```python
def test_discount_10(): assert discount(100, "SAVE10") == 90
def test_discount_20(): assert discount(100, "SAVE20") == 80
def test_discount_30(): assert discount(100, "SAVE30") == 70
# ... five more, identical but for two numbers
```

Plus `test_discount_returns_a_number()` (checks `isinstance(result, int)`) and `test_discount_code_is_string()` (asserts a dataclass field default).

八个只差两个数字的复制粘贴测试,外加"返回值是数字"、"默认值是字符串"这类凑数测试。

**Why it's wrong / 为什么错:**

The eight bodies are one scenario with eight data points (rule 3) — as separate functions they bloat the suite, and when the discount logic changes you edit eight places. The `isinstance` and default-value tests can't catch any bug that matters (rules 4 and 7): delete all the custom logic and they still pass. Ask each test "what bug do you catch that no other test catches?" — these have no answer.

八个函数体是一个场景的八个数据点(第 3 条)——拆成独立函数只会膨胀,折扣逻辑一变要改八处。`isinstance` 和默认值测试抓不到任何要紧 bug(第 4、7 条):把自定义逻辑全删了它们照样过。对每个测试问"你能抓到什么别人抓不到的 bug?"——这几个答不出来。

**The disciplined move / 正确做法:**

```python
@pytest.mark.parametrize("code,expected", [
    ("SAVE10", 90), ("SAVE20", 80), ("SAVE30", 70),
    ("EXPIRED1", 100),          # expired code: no discount
    ("", 100),                  # boundary: empty code
    ("save10", 100),            # codes are case-sensitive — prod incident #<n>, never delete (rule 6)
])
def test_discount_applies_valid_codes_only(code, expected):
    assert discount(100, code) == expected
```

One scenario, data-driven, boundaries included; the trivia tests deleted. Note the incident-sourced case is marked sacred — it's exempt from "justify your existence" forever.

> ✅ 8 near-duplicates + 2 trivia tests → 1 parametrized test, 6 cases, more coverage than before

一个场景走参数化,带边界;凑数测试删除。注意那条来自生产事故的 case 标了来源——它永久豁免"自证价值"审查,神圣不可删。
