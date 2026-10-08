# klara

Humanize plugin for Claude Code and Codex that makes the agent write the way people do, choosing wording
from [references](#references) instead of intuition.

Named after the observant robot in *[Klara and the Sun](https://en.wikipedia.org/wiki/Klara_and_the_Sun)*.

## Install

### Claude Code

```sh
claude plugin marketplace add cokestrawberry/klara
claude plugin install klara@klara
```

In a Claude Code session that is already running, run `/reload-plugins` to apply the change.

While the plugin is enabled, its output style applies automatically and overrides your
`outputStyle` setting. If another enabled plugin also forces its output style, Claude Code uses
the style of the plugin it loads first. To turn the style off, disable the plugin:

```sh
claude plugin disable klara@klara
```

In a Claude Code session that is already running, run `/reload-plugins` to apply the change.

### Codex

```sh
codex plugin marketplace add cokestrawberry/klara
codex plugin add klara@klara
```

The plugin adds the rules through a [`SessionStart` hook](https://learn.chatgpt.com/docs/hooks),
and Codex skips a plugin's hooks until you trust them. In Codex CLI, open `/hooks`, review the
klara hook, and trust it; the rules apply from the next session. To turn them off, open `/plugins`
and press Space on klara. The IDE extension does not support plugins.

## How to use

There is no command to run. Once the rules apply as described in [Install](#install), use
Claude Code or Codex as usual; the agent's responses follow the rules below.

In Claude Code, the style applies to the main conversation and to a
[fork](https://code.claude.com/docs/en/sub-agents#fork-the-current-conversation), a subagent that
starts with the whole conversation so far. Other subagents
[run their own system prompt](https://code.claude.com/docs/en/output-styles#how-output-styles-work),
so text they write does not follow the rules.

In Codex, the hook adds the rules as developer context when a session starts, resumes, is
cleared, or is compacted. It does not run for subagents, so a subagent has the rules only when
the conversation it starts with includes them:

- A subagent that starts with the whole conversation so far has them until its own conversation
  is compacted. Compaction drops them, and the hook does not add them again.
- A subagent that starts with only the most recent turns lacks the rules added when the session
  started, however many turns it copies.
- A subagent that starts with none of the conversation lacks them.

Text a subagent writes without the rules does not follow them. `/review` runs in a subagent that
starts with none of the conversation, and Codex shows you the review that subagent writes, so the
review does not follow the rules either.

## Chat apps

The plugin's rules apply only in Claude Code and Codex. Claude chat and Cowork
[ignore a plugin's output styles][platform-support], so adding klara there does not apply the
rules. In the Claude and ChatGPT chat apps, paste the rules into the instructions that apply to
every conversation instead:

| App | Plans | File | Paste into |
| --- | --- | --- | --- |
| ChatGPT | Free, Go | [chat/light.md][light] | Custom instructions |
| ChatGPT | Plus, Pro, Business, Enterprise, Edu | [chat/full.md][full] | Custom instructions |
| Claude | All | [chat/light.md][light] | Instructions for Claude |

- **Custom instructions**: in ChatGPT, open Settings > Personalization, turn on Enable
  customization, and paste the file's contents into Custom instructions. In the iOS and Android
  apps, open Settings > Customize ChatGPT instead.
- **Instructions for Claude**: in Claude, open Settings and paste the file's contents into
  Instructions for Claude, under Account or General. They
  [apply to all of your conversations][claude-instructions].

ChatGPT [saves up to 1,500 characters][chatgpt-instructions] of custom instructions on Free and
Go, and up to 5,000 on Plus, Pro, Business, Enterprise, and Edu. Claude's documentation gives no
limit for Instructions for Claude, so the table uses the 1,500-character file there. The plans,
limits, and settings above were checked on 2026-10-02.

`chat/full.md` holds the rules without the parts that apply only to Claude Code and Codex.
`chat/light.md` shortens them further and leaves out the observed cases. The
[evals](#evaluate) run only in Claude Code, so they do not score either file.

[full]: chat/full.md
[light]: chat/light.md
[platform-support]: https://claude.com/docs/plugins/platform-support
[claude-instructions]: https://support.claude.com/en/articles/10185728-understanding-claude-s-personalization-features
[chatgpt-instructions]: https://help.openai.com/en/articles/8096356-chatgpt-custom-instructions

## References

| When | Korean | English |
| --- | --- | --- |
| Defining an IT term | [TTA 정보통신용어사전][tta] | [SEVOCAB][sevocab] |
| A term specific to one technology | Its official documentation | Its official documentation |
| Meaning of a general word | [표준국어대사전][stdict] | [Oxford Advanced American Dictionary][oaad] |
| Usage of a general word or phrase | [우리말샘][opendict] | Example sentences in [Oxford][oaad] |

SEVOCAB covers software and systems engineering terms. English follows American usage; British
usage is not treated as a problem.

[tta]: https://terms.tta.or.kr
[sevocab]: https://pascal.computer.org
[stdict]: https://stdict.korean.go.kr
[opendict]: https://opendict.korean.go.kr
[oaad]: https://www.oxfordlearnersdictionaries.com/us/

## Rules

- **Wording from references.** The agent takes terms and phrasing from the references above, and
  writes a plain Korean word instead of a transliteration, or the English spelling when there is
  none. Text in your repository and on its PRs, issues, and commits is not a basis for wording,
  because who wrote it cannot be verified.
- **Shapes to avoid.** The agent avoids sentence shapes that mark text as generated and have been
  flagged more than once, such as cleft constructions ("~하는 것은 ~입니다"), announcing a count
  before a list, invented metaphors, and literal translations ("~에서 왔습니다" for "came from").
- **Check before sending.** The agent runs these checks on the finished text, in chat answers as
  much as in anything committed or posted.

The full rules are in [language-and-tone.md](plugins/klara/output-styles/language-and-tone.md).

## Examples

The rules record every case below, and each has an eval case in
[plugins/klara/evals](plugins/klara/evals).

The rules record these replacements:

| Draft wording | Replacement | Why |
| --- | --- | --- |
| 잡, 윈도우 | 작업, 구간 | A plain Korean word instead of a transliteration |
| 나이틀리, 스텁, 어서션 | nightly, stub, assertion | No Korean word, so the English spelling |
| 감사 레코드 | 감사 로그의 한 줄 | No reference lists the compound, and 감사 로그 is the whole log |

For these two, the rules record only the principle. The rewrites are illustrations of it,
not output the eval checked:

| Draft wording | Example rewrite | Why |
| --- | --- | --- |
| 정기 배포 cutover 진행 예정 | 정기 배포 진행 예정 | A term of art needs a defining reference |
| 사용하지 않는 `legacyMode` 변수 은퇴 | 사용하지 않는 `legacyMode` 변수 삭제 | 은퇴 is not used in that sense |

## Evaluate

The cases in [plugins/klara/evals](plugins/klara/evals) score the style with
[`claude plugin eval`](https://code.claude.com/docs/en/plugin-evals), which needs Claude Code
v2.1.269 or later. Each case runs with and without the plugin, and every run calls the model on
your account. Granting `Bash` runs every command in Claude Code's
[sandbox](https://code.claude.com/docs/en/sandboxing), which needs macOS, Linux with `bubblewrap`
and `socat` installed, or WSL2 on Windows; elsewhere every run is refused. The grants below let
the agent look words up in the [references](#references) and write its result to a file, as it
would in a normal session:

```sh
claude plugin eval plugins/klara --no-publish --allow-tools Bash Write \
  "WebFetch(domain:terms.tta.or.kr)" "WebFetch(domain:pascal.computer.org)" \
  "WebFetch(domain:stdict.korean.go.kr)" "WebFetch(domain:opendict.korean.go.kr)" \
  "WebFetch(domain:oxfordlearnersdictionaries.com)" \
  "WebFetch(domain:www.oxfordlearnersdictionaries.com)"
```

Results are written to `plugins/klara/evals/results/`.

## Token usage

The rules add input tokens to every session, and they can lead the agent to look words up before
it answers. These figures were measured on 2026-10-02 at commit `0ab4d6f` with
[scripts/token-usage/measure.ps1](scripts/token-usage/measure.ps1):

- Claude Code 2.1.287 with `claude-sonnet-5-5`, run through `claude plugin eval`
- Codex CLI 0.160.0 with `gpt-6-luna`, the default model of a free ChatGPT account, run through
  `codex exec --json`

The tasks are the eight cases that [plugins/klara/evals](plugins/klara/evals) held at that commit
and a [control task](scripts/token-usage/control/case.yaml) with no wording to choose: fixing a small
Python function. Each task ran under each of these conditions:

1. No plugin.
2. Plugin with web access: `WebFetch` for the reference sites in Claude Code; live web search and
   network access in Codex.
3. Plugin without web access: no `WebFetch` in Claude Code; no web search and no network access
   in Codex.

Each value is the mean number of tokens per run, input and output together, cached or not, rounded
to a whole token:

| Condition | Claude Code: eval cases | Claude Code: control | Codex: eval cases | Codex: control |
| --- | ---: | ---: | ---: | ---: |
| 1. No plugin | 20,840 | 21,792 | 39,122 | 27,369 |
| 2. Plugin with web access | 27,787 | 24,888 | 70,766 | 37,108 |
| 3. Plugin without web access | 24,318 | 24,856 | 50,631 | 24,663 |

Claude Code made a web request in two runs, both in one eval case under condition 2: it fetched a
reference page with `WebFetch`, and TTA answered one of the two requests with HTTP 400. Codex
searched the web in the eval cases under condition 2. Under condition 3, two of its sixteen
eval-case runs ran `curl` to fetch a page from 우리말샘 instead, and both requests failed. Neither
tool made a web request in the control task. Turning web search off also removes the web search
tool from the request, so condition 3 differs from condition 2 by more than the requests.

`claude plugin details klara` reports `~0 tok` added to every session, and `/context` has no row
for the output style, so neither shows what the rules add. The figures above come from the token
counts that Claude Code and Codex recorded for each run.

### Codex hook on later turns

This was measured in an interactive Codex session on 2026-10-01, sending `ok` after each step.
Tokens are the input and output of the turn that followed:

| Step before `ok` | Rules added | Tokens |
| --- | --- | ---: |
| Start `codex` | Yes | 14,909 |
| `/compact` | Yes | 14,915 |
| `/clear` | Yes | 14,914 |
| Quit, then `codex resume --last` | Yes, and the earlier copy stays | 15,943 |

The session log reports no tokens for the `/compact` step itself, so the table leaves it out.

### Measure again

```powershell
powershell -File scripts/token-usage/measure.ps1 -Agent claude -WorkRoot <dir> -Runs 2
powershell -File scripts/token-usage/measure.ps1 -Agent codex -WorkRoot <dir> -Runs 2
```

The script writes one row per run to `<dir>/<agent>-runs.csv`, including cached input tokens and
the characters that web requests returned, and keeps each run's trace in `<dir>/traces/`. Every
run calls the model on your account. The figures above come from PowerShell 7.6.6 on macOS.

Codex runs every condition with the `config.toml`, plugins, and `AGENTS.md` in its
[home directory](https://learn.chatgpt.com/docs/agent-configuration/agents-md) (`~/.codex` unless
`CODEX_HOME` is set). To measure your copy of this repository without them, set `CODEX_HOME` to
an empty directory and install klara from the copy:

```powershell
$env:CODEX_HOME = '<empty dir>'
codex login
codex plugin marketplace add <repo dir>
codex plugin add klara@klara
```

Then open `codex` in the same shell, trust the klara hook in `/hooks` as in [Install](#install),
quit, and run the script from that shell.

## Sponsor

[![Sponsor](https://img.shields.io/badge/Sponsor-EA4AAA?style=for-the-badge&logo=githubsponsors&logoColor=white)](https://github.com/sponsors/cokestrawberry)

You can support klara through GitHub Sponsors.
