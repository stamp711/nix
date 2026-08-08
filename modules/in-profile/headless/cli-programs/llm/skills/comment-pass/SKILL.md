---
name: comment-pass
description: >
  Take the reasoning back out of the comments, descriptions and names once the code works.
  Run on a change that is written and passing, before handing it over, or when the user
  says "comment pass", "comment quality" or "audit the comments".
---

# Comment pass

Reasoning written into the comments while coding is scaffolding: thinking between the
lines is how the holes get closed, and it is worth writing. Take it down once the code
works. A comment slot is for what the thing **is**; what usually sits there instead is
the record of how the author arrived.

Run this on a change that already works, over every comment, doc comment and name it
touches.

The examples here are Nix, from the repository this was written in. Nothing in the checks
is about syntax: a JSDoc block, a docstring and a `#` line fail in the same ways, and the
worked examples are worth reading in any language for the drafts they went through.

Every time a line changes, step back and run the checks again from the top. A rewrite
that repairs the defect it was aimed at routinely breaks a different one: naming the
referent while switching a value's noun phrase to a verb, cutting motive by deleting the
line that said what the thing is.

## Expect this to be slow

A comment that reads fine is the normal state of a bad comment: it was written by someone
who already knew the answer, and it reads fine to them. Assume every line needs a rewrite
until it survives the checks below, and expect three or four drafts before one holds. The
worked examples at the end are real, and none of them was right before the fourth pass.

Two habits that make the difference: say out loud what the code below the comment is,
before reading the comment; and re-read the comment as someone who has never seen this
file, cannot ask anyone, and has the code in front of them.

## What a comment is for

A reader who lands here cold can already read the code. From the code alone they cannot
get:

- what this thing **is**, at a glance, without executing it in their head
- a fact that lives outside this file: a measured limit, an upstream behaviour, a
  platform quirk
- what breaks if the code is changed in the obvious way

Everything else is derivable, or is your history: how it works, what you tried first,
what you rejected. Cut it.

## Most lines need no comment

Decide delete-or-keep before deciding how to word it. Rewriting is the reflex, and it
turns a bad comment into a plausible one instead of removing it. The right number is
usually smaller than the number already there, and for most lines it is zero.

**Keep test.** If this comment were gone, what would a reader get wrong? Name it. If
nothing, the comment goes, however true it is.

A comment is not a fix for unclear code. When a line seems to need a paragraph, the name
or the split is what needs changing.

## History belongs to the log

Never in the file, whatever the state of the code:

- what it used to be: "previously", "moved from", "added for #36". The change description
  holds this, and the file copy goes stale at the next move.
- who asked for it, who wrote it, when.
- commented-out code. Delete it; it is in the log.
- a `TODO` that is a wish. One is worth keeping only when it says what would let it be
  removed, and what it is waiting on.

A temporary state is the one thing here that does belong in the file, and it takes a
marker so nobody mistakes it for a description:

```nix
# The Linux build, for hosts that run it as a container. NOTE: Still v0.0.28.
```

`Still v0.0.28` is not a property of the line below it. It is a fact expected to stop
being true, so it says what it is waiting on, like a `TODO`, and it goes when that lands.

## The checks

Apply all of them to every line. They fail different things.

**Subject.** The subject of the sentence must be the code below it. A subject that is a
flag, an upstream tool, a platform, or a rejected alternative means the sentence is
background and the reader has to work out the connection themselves.

**Consequence.** A comment that states a constraint must say what happens without it.
Two facts side by side with no "so" is trivia, however true.

**Referent.** Every "it", "this", "one", "the same" must have exactly one possible
antecedent in the sentence. "An empty one" and "for the same reason" read as complete
sentences and say nothing.

**Kind.** A function gets a verb and its result: "Get the decrypted paths for some secret
names." A value gets a noun phrase. Do not describe a function as though it were the
thing it returns.

**Duplication.** Search the change for the same fact stated elsewhere. The second copy is
the one that goes stale.

**Staleness.** After a rename or a reshape, grep for comments that still describe the old
shape. A comment describing an older implementation is worse than no comment.

**Deletion.** Would a reader delete the _code_ as pointless without this line? If yes,
keep one clause of why, no more. This is the only thing that buys motive a place.

## Cut on sight

| Smell                                   | Why                                                    |
| --------------------------------------- | ------------------------------------------------------ |
| `A, not B`, `rather than`, `instead of` | the road not taken; do not name the alternative at all |
| `so that we…`, `because we…`            | motive for a decision you already made                 |
| "upstream does the same"                | precedent                                              |
| restates the code below                 | derivable                                              |
| explains the mechanism                  | the reader needs the effect, not the trace             |

## Worked examples

Each of these went through every draft shown. The last line is what shipped.

**A wrapper around a shell script.** The final version's subject is the script, and the
mechanism is gone: a reader who wants it can look up what BSD `mv` does.

```nix
# An application, not a bare script, for the same reason agenix uses one: launchd
# hands us a PATH of BSD tools, and these flags are coreutils'.
# The flags below are coreutils', and launchd hands us a PATH of BSD tools.
# agenix wraps its own script for the same reason.
# The `mv -T` below is GNU's, and the PATH launchd hands a job has BSD's, which
# rejects that flag. The script carries its own coreutils.
# The script carries coreutils for the GNU's `mv -T` on darwin.
```

**A helper whose absence would get it deleted.** Motive earned its place here, and only
after the referent was named: "any edit to it" left three candidates.

```nix
# The path a declaration sits at below the store path holding it. Ours are below our
# own source, whose name carries a hash of the whole repository, so the document
# would otherwise change with every edit to it.
# Get the path a declaration sits at, below the store path holding it.
# Ours sit below our own source, a store path of the flake.
# Without this, any edit to the flake rebuilds the document.
```

**A function described as its own output.** Deleting is a legitimate draft; the line that
came back says what the function fills, not why those values are safe to fill early.

```nix
# A template with the URL paths filled in. They are not secret, so they need not
# wait for my.age-template to render the rest.
# (deleted)
# Fill `@VLESS_PATH@` and the other pathNames in a template, from cfg.paths.
```

**A warning the type already gives.** Nothing replaced it. The option's type is `str`, so
a path is a type error before anything else runs, and the sentence was defending a case
the reader cannot reach. Check what the types, assertions and tests already say.

```nix
# Strings, not paths: under home-manager agenix hands out ones that only a shell
# can resolve.
# (deleted)
```

## Doc comments are a different surface

A doc comment is what a caller reads instead of the code: `///`, `/** */`, a docstring, a
schema `description`, a NixOS option `description`. It owes them the contract, what comes
back, and what it does to the world. It owes them nothing about how the body gets there.

The implementation's trade-offs belong to the reviewer, not the caller. "We hash the
contents rather than the path, because the path moves whenever the repository does" is a
sentence for whoever reviews the hash, while the caller only needs to know what the hash
covers.

## Names are part of the pass

A name must let someone who does not know the implementation say what the thing holds.
Where the data comes from, how it is passed around, and symmetry with another module are
what the author happened to be looking at, not reasons.

Names that lie are the ones this pass exists to catch:

- a `missing` flag also set when a render fails: it is `failed`
- a `sources` attribute holding hashes rather than paths: it is `ciphertextHashes`
- a `dir` argument that says only "a directory": it is `filesDir`

## Report what you cut

End the pass with one line per removal, so the deliberation is visible instead of silent:

```
render-script.nix:85  "agenix wraps its own script for the same reason"  precedent
file-type.nix:31      "Strings, not paths: …"                            the type says it
```

A pass that deleted nothing is the outcome to distrust: either the file was already
audited, or the reflex won and every comment came back reworded.

## Mechanics

First line stands alone. No em dashes. Prefer deleting a comment to shortening it twice.

After the first line, length is governed by clarity, not by a count. Two lines of piled
clauses read worse than six lines that each carry one thing. What holds up at length is
never prose: a concrete input and its output, a layout with a pointer at the part that
matters, a list of parallel items.

One fact per sentence. Subordination is where this goes wrong: a `which`, a `where` and a
colon in one sentence each look small, and every one of them makes the reader hold more
before anything resolves. Three short sentences beat one that carries three clauses.

A list is the tool for that, and not only for display. An item cannot subordinate to the
one above it, so the form does the cutting for you, and two items that turn out to say the
same thing are visible the moment they sit side by side.

```nix
# Derive a stable secret name from a .age file path, relative to the flake root.
# e.g. profiles/nixos/kvm-proxy/xray-proxy.env.age => profiles__nixos__kvm-proxy__xray-proxy.env
#
# Works for paths from any flake by stripping the /nix/store/<hash>-<name>/ prefix.
# In flake evaluation, all paths resolve to store paths with this structure:
#   /nix/store/abc123-source/hosts/ssh-config.age
#   ^^^^^^^^^^^^^^^^^^^^^^^^ 4 components when split by "/"
```

Cryptic code is the same rule, not an exemption from it. Say what the expression matches
and what about it is not visible. Then, when the pattern is genuinely hairy, decompose it:
one fragment per line, glossed in a few words. The list is the form that survives; the
same fragments as prose go stale the first time the pattern is tuned, and nobody re-reads
them anyway.

```nix
# A vim very-magic regex, to catch the `TODO(name):` form upstream misses
# (folke#326, folke#370).
# todo-comments highlights group 1 and takes its colour from the keyword in group 2.
# `%(…)` does not capture, so the optional (name) is not a third group.
#   - `.*<`          : lead + word start
#   - `((KEYWORDS)`  : group 1 opens, group 2 is the keyword
#   - `\s*%(\(…\))?` : opt ws + opt (name), inside group 1 so it pads at `:`
#   - `):`           : group 1 closes, colon
highlight.pattern = ''.*<((KEYWORDS)\s*%(\([^)]*\))?):'';
```

The prose above a list carries what the list cannot: why this pattern exists at all,
which dialect it is written in, and whose contract the groups answer to. It stops there.
Restating what the list already glosses is the failure this shape invites.

A pattern that is not hairy does not get the list. One line naming what it matches is the
whole comment:

```nix
# A whole name, so $token cannot match the start of $tokenId.        # which name?
# The whole of a placeholder name, so $token does not match inside $tokenId.
WORD = r"[A-Za-z_][A-Za-z0-9_]*"
```

Seven lines over one regex, one over another, seven over a naming helper. The length
followed what the reader needed, not how hard the code was to read.

A label naming the block below it is a comment like any other and lives by the same rule:
`# Caddy` over the Caddy block says what it is; the moment it explains, it is back under
the checks. Needing one every few lines is a sign the block wants splitting, not
labelling.
