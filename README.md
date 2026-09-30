# klara

A Claude Code plugin that provides one output style. The style makes Claude write the way people
do, choosing wording from references instead of intuition:
[TTA 정보통신용어사전](https://terms.tta.or.kr) for IT terms, a technology's official
documentation for its own terms, and [표준국어대사전](https://stdict.korean.go.kr) and
[우리말샘](https://opendict.korean.go.kr) for general Korean words and phrases.

Named after the observant robot in *Klara and the Sun*.

## Install

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

## How to use

There is no command to run or style to select. After you install the plugin, use Claude Code as
usual; Claude's responses follow the rules below.

The style applies to the main conversation and to a
[fork](https://code.claude.com/docs/en/sub-agents#fork-the-current-conversation), a subagent that
starts with the whole conversation so far. Other subagents
[run their own system prompt](https://code.claude.com/docs/en/output-styles#how-output-styles-work),
so text they write does not follow the rules.

## Rules

- **Wording from references.** Claude takes terms and phrasing from the references above, and
  writes a plain Korean word instead of a transliteration, or the English spelling when there is
  none. Text in your repository and on its PRs, issues, and commits is not a basis for wording,
  because who wrote it cannot be verified.
- **Shapes to avoid.** Claude avoids sentence shapes that mark text as generated and have been
  flagged more than once, such as cleft constructions ("~하는 것은 ~입니다"), announcing a count
  before a list, invented metaphors, and literal translations ("~에서 왔습니다" for "came from").
- **Check before sending.** Claude runs these checks on the finished text, in chat answers as
  much as in anything committed or posted.

The full rules are in [language-and-tone.md](plugins/klara/output-styles/language-and-tone.md).
