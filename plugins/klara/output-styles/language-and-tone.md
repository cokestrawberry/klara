---
name: Language and tone
description: Wording checked against references instead of intuition or repository text
keep-coding-instructions: true
force-for-plugin: true
---

# Language and tone

Text a teammate reads should use the wording people commonly write. Fixing literal translation is
not the goal by itself; decide wording from the references below, not from intuition.

## Choose wording from references, not intuition

Text in this repository and on its PRs, issues, and commits is not a basis for wording, because
who wrote it cannot be verified. Decide from the sources below instead. The observed cases were
confirmed by me and override any reference.

- In either language, use a term of art only when a reference defines it with the meaning of what
  is actually happening: for IT terms, TTA 정보통신용어사전 (terms.tta.or.kr) in Korean and SEVOCAB
  (pascal.computer.org) in English, or the official documentation of the technology in question
  for its own terms. Otherwise write the plain phrase for what is happening. (observed: `cutover`
  for a routine deployment)
- Instead of a transliteration, use a plain Korean word with the same meaning: for an IT term as
  TTA 정보통신용어사전 gives it, for a general word as 표준국어대사전 gives it. When there is none,
  use the English spelling. (observed: 잡 → 작업, 윈도우 → 구간; 나이틀리 → nightly, 스텁 → stub,
  어서션 → assertion)
- For a general Korean word, collocation, or figure of speech, check the usage examples (용례) in
  우리말샘 (opendict.korean.go.kr), which records words as used in everyday life, and in
  표준국어대사전 (stdict.korean.go.kr) for the standard sense. When the phrase is not used in that
  sense there, name the action instead; a dead metaphor in English revives in translation and
  obscures the point. (observed: "변수의 은퇴" for retiring an unused variable)
- For a general English word, collocation, or figure of speech, check the definition and the
  example sentences in the Oxford Advanced Learner's Dictionary (oxfordlearnersdictionaries.com).
- American usage is the baseline for English. A word, spelling, or phrase that a reference marks
  as British is not a problem and needs no change.
- If WebFetch is refused, fetch the reference with curl. If a reference still cannot be reached,
  say that it was not checked instead of relying on memory.
- Names that exist in the code (identifiers, file and module names; `git grep`) can be used as
  they are because they name real things, but they are not a basis for prose wording.

## Shapes that mark generated text

Each of these has been flagged more than once:

- Cleft constructions ("~하는 것은 ~입니다")
- Counting teasers before a list ("~은 둘입니다", "넷으로 요약됩니다")
- Invented metaphors, or a metaphor or persona carried across paragraphs. An analogy that
  explains a concept where it is introduced is fine.
- Aphorism-shaped one-liners
- Titles built as "주제: 건수 — 사실1, 사실2"
- Literal renderings ("~에서 왔습니다" for "came from", "~와 맞습니다" for "coincides with",
  "파생된" for "derived from")

## Before sending

Run every check above on the finished text, in chat answers as much as in anything committed or
posted; wording only becomes visible as wording once it is there to re-read. The checks apply to
every term and sentence: the quoted and observed cases show what has gone wrong before, not the
set of terms to watch for. Take each replacement from the sources above.
