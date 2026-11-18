# salam-envguard

`envguard` compares a project's `.env` file against its `.env.example` and tells you what
has drifted: keys you forgot to set, keys nobody documented, values left blank, and lines
a dotenv loader would misread. It is written in the
[Salam Programming Language](https://github.com/SalamLang/Salam).

It reports key names and line numbers only. Values are never stored or printed, so the
output is safe to paste into a CI log or an issue.

```console
$ envguard --example examples/drift/.env.example --env examples/drift/.env
examples/drift/.env:2: warning UNQUOTED_SPACE APP_NAME - value contains a space but is not quoted
examples/drift/.env:5: error DUPLICATE_KEY PORT - already defined on line 1
examples/drift/.env:6: error NO_EQUALS - line is not a KEY=value assignment
examples/drift/.env: warning MISSING_OPTIONAL_KEY SENTRY_DSN - listed on line 9 of examples/drift/.env.example with no value
examples/drift/.env:3: warning EMPTY_VALUE DATABASE_URL - has no value, but examples/drift/.env.example gives one
examples/drift/.env:4: warning EXTRA_KEY LEGACY_CACHE_HOST - not documented in examples/drift/.env.example
2 errors, 4 warnings (4 keys checked)
```

## Build

You need the Salam compiler, version 0.6.16 or newer
([releases](https://github.com/SalamLang/Salam/releases)).

```sh
salam build main.salam --output=build/envguard
```

On Windows, use `--output=build/envguard.exe`.

## Use

Run it in a project directory to check `.env` against `.env.example`:

```sh
envguard
```

| Option | Meaning |
| --- | --- |
| `--example PATH` | Template to check against. Default `.env.example`. |
| `--env PATH` | Real environment file. Default `.env`. |
| `--strict` | Treat every warning as an error. |
| `--format text\|json` | Output format. Default `text`. |
| `--help`, `--version` | Print usage or the version. |

Options that take a value also accept `--name=value`.

| Exit code | Meaning |
| --- | --- |
| 0 | No errors (warnings may have been printed). |
| 1 | At least one error. |
| 2 | A file was missing, was a directory, or was larger than 1 MiB. |
| 64 | The command line was not understood. |

In a CI job, `envguard --strict` fails the build on any drift.

### JSON output

`--format json` prints one object on one line (wrapped here for reading):

```json
{"example":".env.example","env":".env","keys_checked":4,"errors":1,"warnings":0,
 "issues":[{"code":"MISSING_KEY","severity":"error","file":".env","line":0,"key":"PORT",
            "detail":"listed on line 2 of .env.example"}]}
```

`line` is `0` when an issue is about a key that is absent, so has no line of its own.

## What it checks

Comparison between the two files:

| Code | Severity | Meaning |
| --- | --- | --- |
| `MISSING_KEY` | error | The template gives the key a value; the real file does not define the key. |
| `MISSING_OPTIONAL_KEY` | warning | The same, for a key the template leaves blank. |
| `EMPTY_VALUE` | warning | The template gives a sample value; the real value is blank. |
| `EXTRA_KEY` | warning | The real file defines a key the template does not mention. |

A key written as `NAME=` in the template is treated as optional.

Syntax, checked in both files:

| Code | Severity | Meaning |
| --- | --- | --- |
| `NO_EQUALS` | error | The line is not blank, not a comment and has no `=`. |
| `BAD_KEY` | error | The key is not letters, digits and underscores starting with a letter or underscore. |
| `UNTERMINATED_QUOTE` | error | A quoted value is never closed. |
| `TEXT_AFTER_QUOTE` | error | Something other than a comment follows the closing quote. |
| `DUPLICATE_KEY` | error | The key was already defined earlier in the same file. |
| `SPACE_AROUND_EQUALS` | warning | `KEY = value`: shells and dotenv loaders disagree about this. |
| `UNQUOTED_SPACE` | warning | The value contains a space and is not quoted. |
| `LOWERCASE_KEY` | warning | The key is not `UPPER_SNAKE_CASE`. |

The parser accepts an optional `export ` prefix, single- and double-quoted values,
backslash escapes inside double quotes, `#` comment lines, inline comments after a space,
and both LF and CRLF line endings.

## Limits

- Values that span several lines are not supported; each line is read on its own.
- Variable references such as `${OTHER}` are not expanded. A value is either blank or not.
- The syntax warnings follow common dotenv conventions, not one particular loader.

## Source layout

| File | Role |
| --- | --- |
| `main.salam` | Entry point: options, file reads, exit code. |
| `src/options.salam` | Command-line parsing. |
| `src/reader.salam` | File reading with a size limit. |
| `src/lexer.salam` | Classifies one line: blank, comment, assignment or invalid. |
| `src/envfile.salam` | Parses a whole file and finds duplicate keys. |
| `src/compare.salam` | Compares the real file with the template. |
| `src/report.salam` | Text and JSON output, counts, `--strict` promotion. |
| `src/json.salam` | JSON string escaping. |
| `src/model.salam` | The `Entry` and `Issue` records. |
| `tests/*_test.salam` | One test program per module. |

## Test

```sh
SALAM_BIN=/path/to/salam bash scripts/verify.sh
```

The script builds the tool and six test programs, runs them, checks the exit code of each
command-line case against the files in `examples/`, and confirms that no value appears in
the report. CI runs the same script on Linux and also builds the Docker image.

## Docker

The image is built from the official `basemax/salam` image.

```sh
docker build -t envguard .
docker run --rm -v "$PWD:/work" envguard --strict
```

## How this was made

The code, tests and documentation were written by an AI coding assistant (Claude) working
on behalf of the account owner, and built and tested with Salam 0.6.16 on Windows x64.

## License

MIT. See [LICENSE](LICENSE).
