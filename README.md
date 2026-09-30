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
cleared, or is compacted. It does not run for subagents, which start with `SubagentStart` instead.

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
it answers. These figures were measured on 2026-10-01 at commit `c5058eb` with
[scripts/token-usage/measure.ps1](scripts/token-usage/measure.ps1):

- Claude Code 2.1.285 with `claude-sonnet-5-5`, run through `claude plugin eval`
- Codex CLI 0.159.2 with `gpt-6-luna`, the default model of a free ChatGPT account, run through
  `codex exec --json`

The tasks are the eight cases in [plugins/klara/evals](plugins/klara/evals) and a
[control task](scripts/token-usage/control/case.yaml) with no wording to choose: fixing a small
Python function. Each task ran twice under each condition:

1. No plugin.
2. Plugin with web access: `WebFetch` for the reference sites in Claude Code; live web search and
   network access in Codex.
3. Plugin without web access: no `WebFetch` in Claude Code; no web search and no network access
   in Codex.

Each value is the mean number of tokens per run, input and output together, cached or not, rounded
to a whole token:

| Condition | Claude Code: eval cases | Claude Code: control | Codex: eval cases | Codex: control |
| --- | ---: | ---: | ---: | ---: |
| 1. No plugin | 20,918 | 21,851 | 38,832 | 27,002 |
| 2. Plugin with web access | 23,738 | 24,334 | 71,354 | 29,065 |
| 3. Plugin without web access | 23,690 | 24,310 | 58,117 | 29,832 |

No Claude Code run made a web request. Across the eval cases, Codex made 23 web requests, counting
web searches and shell commands that fetch a URL, under condition 2. Under condition 3 it tried 12,
and every attempt failed to connect. It made none in the control task. Turning web search off also
removes the web search tool from the request, so condition 3 differs from condition 2 by more than
the requests.

`claude plugin details klara` reports `~0 tok` added to every session, and `/context` has no row
for the output style, so neither shows what the rules add. The figures above come from the token
counts that Claude Code and Codex recorded for each run.

### Codex hook on later turns

This was measured once in an interactive Codex session on 2026-10-01, sending `ok` after each
step. Tokens are the input and output of the turn that followed:

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
the characters that web requests returned, and keeps each run's trace in `<dir>/traces/`. The Codex
measurement needs klara installed with its hook trusted, as in [Install](#install). Every run
calls the model on your account. The figures above come from Windows PowerShell 5.1.

## Sponsor

[![Sponsor](https://img.shields.io/badge/Sponsor-EA4AAA?style=for-the-badge&logo=githubsponsors&logoColor=white)](https://github.com/sponsors/cokestrawberry)

You can support klara through GitHub Sponsors.
