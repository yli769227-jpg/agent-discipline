# EXAMPLES — check-versions

> Real anti-patterns from the field, rewritten as generic, de-identified cases. The mechanism is preserved; the people, places, and project specifics are gone.
> 真实踩坑改写成的通用反例,去掉人/地/项目,只保留可复用的机制。

---

## Anti-pattern / 反例: "It installed locally" ≠ "It builds on Linux CI"

An agent adds a web frontend to a Node project and locks dependencies on macOS:

```bash
npm install            # passes, 0 errors
git add package-lock.json && git commit && git push
```

Linux CI then fails immediately on `npm ci`:

```
Missing: @emnapi/core@... from lock file
Missing: @emnapi/runtime@... from lock file
```

The first fix attempt — `npm install --package-lock-only` — still fails. Only the second pass finds the real cause: `@emnapi/*` are **platform-specific optional dependencies** (pulled transitively, installed on Linux/Windows but not macOS). `npm ci` is strict by default, so the lock file must cover every possible transitive dependency. Only `npm install --include=optional` fills in the lock's `packages` field completely.

某 agent 给 Node 项目加前端,在 macOS 本地锁依赖:`npm install` 通过、0 错误,push 后 Linux CI 的 `npm ci` 立即报 `Missing: @emnapi/* from lock file`。第一次用 `npm install --package-lock-only` 修,还是挂。第二次才查清:`@emnapi/*` 是**平台相关 optional 依赖**(transitive 拉取,Linux/Windows 装、macOS 不装),`npm ci` 默认严格,lock 必须覆盖所有可能的 transitive,只有 `npm install --include=optional` 才补全 lock 的 `packages` 字段。

**Why it's wrong / 为什么错:**

The agent ran `npm install` because "that's how it's usually done," without checking how npm actually behaves under cross-platform + strict-CI conditions. "It worked locally" is the forge temperature of *your* version and *your* platform — it does not transfer to a Linux x64 container. Whenever package-manager, Node-version, or platform-suffixed behavior is involved (`@emnapi/*`, `@rollup/*-linux-*`, `@swc/core-linux-*`), the real behavior under *that* version/platform must be verified before writing the command.

agent 凭"npm install 通常这样"直接跑,没查 npm 在跨平台 + 严格 CI 下的实际行为。"本地通了"只是本地版本 / 本地平台的炉温,搬不到 Linux x64 容器。涉及包管理器、Node 版本、平台后缀(`@emnapi/*` / `@rollup/*-linux-*` / `@swc/core-linux-*`)行为时,必须先查该版本/平台下的实际行为再写命令。

**The disciplined move / 正确做法:**

For any new Node frontend + Linux CI project, when first locking dependencies:

```bash
# 1. Check the forge temperature first
node -v                                    # local vs CI consistent?
npm -v
grep "npm " .github/workflows/*.yml        # does CI use ci or install?

# 2. Pull all platform-optional deps in one shot
rm -rf node_modules package-lock.json
npm install --include=optional

# 3. Verify the lock covers them
grep -E "@emnapi|linux-x64|win32-x64" package-lock.json | head
```

If CI's `npm ci` reports `Missing: X from lock file` and X carries a platform suffix → `rm -rf node_modules package-lock.json && npm install --include=optional`. Do not investigate npm version or node_modules cache. And do not "fix" CI by switching it to `npm install` to bypass strictness — that lets the lock drift unchecked. The fix belongs in the local lock.

任何新建 Node 前端 + Linux CI 项目,初次锁 lock 时先查炉温(node/npm 版本、CI 用 ci 还是 install),再 `npm install --include=optional` 一次性拉全平台 optional 依赖,最后 grep 验证 lock 覆盖。CI 报带平台后缀的 `Missing: X` 直接重锁,不要去查 npm 版本或 cache,也不要把 CI 改成 `npm install` 绕过严格性——那样 lock 漂移就再也兜不住,治本在本地 lock。

---

## Anti-pattern / 反例: Assuming the active credential identity is the push target

An agent pushes to a repo and hits:

```
remote: Permission to <org-A>/<repo>.git denied to <user-A>
fatal: unable to access ...: The requested URL returned error: 403
```

It then starts debugging the credential helper / keychain / `git config --list` — the wrong layer entirely.

某 agent push 仓库时撞 `Permission to <org-A>/<repo>.git denied to <user-A>` 403,然后开始排查 credential helper / keychain / `git config` —— 走错层了。

**Why it's wrong / 为什么错:**

The machine has two CLI identities authenticated simultaneously. The git credential helper uses the token of whichever identity is currently **active**. Various operations, restarts, or other terminals can flip the active identity — and once the active one isn't the owner of the target repo, the host rejects the push. The agent started diagnosing the credential layer without first checking *who is currently active*. That is casting the sword without measuring the forge.

机器上同时认证了两个 CLI 身份,git credential helper 用**当前 active 身份**的 token。某些操作 / 重启 / 其他终端会切换 active 身份——一旦 active 不是目标仓库的属主,主机就拒绝 push。agent 没先查"当前 active 是谁"就排查 credential 层,等于不测炉温就铸剑。

**The disciplined move / 正确做法:**

When the error text names a specific identity (`denied to <user>`) and the target repo belongs to a different account, switch identity instead of diving into the credential layer:

```bash
<cli> auth switch -u <target-user>
<cli> auth setup-git
git push origin main
<cli> auth status            # confirm target-user is the active account
```

Rule: **when the error text contains a concrete identity, verify the identity is correct before investigating the credential layer.** For critical pushes (e.g. an automated publish), run an identity check *up front* to avoid the trap. Edge case: a `repo create --push` style command forks a child process for the push and may not inherit the helper config the parent shell set — there, don't retry setup-git; do a single token-in-URL push, then restore the remote to a clean URL.

报错文案点名具体身份且目标仓库属于另一账号时,先切身份(`auth switch` → `setup-git` → push → `auth status` 验证)而不是钻 credential 层。规则:**报错文案出现具体身份时,先查身份对不对,再查 credential 层。** 关键发布前提前跑一次身份检查可避坑。边界:`repo create --push` 类命令 fork 子进程推送、可能不继承父 shell 的 helper 配置,此时别重试 setup-git,直接 token-in-URL 推一次再把 remote 改回干净 URL。

---

## Anti-pattern / 反例: Writing Node `fetch` from memory; the installed version doesn't support it

```js
const res = await fetch("https://api.example.com/x");
```

Runs and throws `ReferenceError: fetch is not defined`.

跑起来报 `ReferenceError: fetch is not defined`。

**Why it's wrong / 为什么错:**

The agent assumed `fetch` is a Node global. But the project runs Node 16; `fetch` is only exposed by default in Node 18+. The assumption came from training-data memory, not from the installed runtime.

agent 假设 `fetch` 是 Node 全局,但项目用 Node 16,`fetch` 在 Node 18+ 才默认 expose。这个假设来自训练数据记忆,不是实际运行时。

**The disciplined move / 正确做法:**

```
$ node -v
v16.20.0
$ grep node package.json
"node": ">=16"
```

> Node 16 — no global fetch. Three options:
> (A) bump Node to 18+ (affects deploy)
> (B) use the `node-fetch` package (lightweight)
> (C) use `axios` / `undici` (which is already installed? checking package.json)
>
> Let me grep what HTTP client you currently use first.

先 `node -v` + 查 package.json 确认版本,确认 Node 16 无全局 fetch 后,给出三个方案(升 Node / node-fetch / 已装的 HTTP 客户端)并先 grep 项目现状,而不是直接凭记忆写。
