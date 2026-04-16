# rspec-undefined

[日本語 / Japanese: README.md](README.md)

An RSpec extension for explicitly expressing **"the spec is undefined"** inside tests.

AI can now realistically write test code, but when the spec itself is undefined or the behavior is non-deterministic, even AI cannot write tests. In the end, deciding the spec remains a human's job.

When deriving an *as-is specification* from a legacy system, this library solves the "we can't write tests because the spec isn't decided yet" problem by **writing the undefined-ness into the test itself and carving it out**.

> **Note on terminology:** the original phrasing *as-is specification* (Japanese: 現行踏襲仕様書 / *genkō-tōshū shiyōsho*) is a concept developed in Japan for describing how one documents a legacy system's current behavior as the starting point of a specification. This README uses "as-is specification" / "current-behavior specification" as the English rendering of that concept. See the linked Zenn article (Japanese) for the background.

## Concept

Built as a way to fulfill the two responsibilities — *"AI writes the tests"* and *"humans decide the spec"* — at separate points in time.

- **Pin the current behavior into tests** (AI can do this)
- **But mark whether that is the correct spec as undefined** with `be_undefined`
- **Undefined items are aggregated into a report** → this directly becomes a list of open questions
- **Deciding the correct spec is done later, by a human**

More on the concept (in Japanese): <https://zenn.dev/tokium_dev/articles/0b426c6d002e3e>

## Installation

Add the following to your Gemfile:

```ruby
gem "rspec-undefined", git: "https://github.com/tomoyukiinoue/rspec-undefined.git"
```

## Usage

Require it in `spec/spec_helper.rb`:

```ruby
require "rspec/undefined"
```

### Matchers

```ruby
expect(value).to be_undefined                                   # no category
expect(value).to be_undefined(:boundary)                        # category only
expect(total).to be_undefined(:boundary, expected: 100)         # tentative expected value (== comparison)
expect(users.map(&:id)).to be_undefined(:order, expected: match_array([1, 2, 3])) # matcher-based
expect(value).to be_undefined(eq(3), :rounding)                 # inner matcher + category
```

If you pass a raw value to `expected:`, it is compared with `==`. If you pass an RSpec matcher, it is evaluated via `matches?`. The value is only *recorded* (in normal mode it always passes), and you can see how it diverges from the current behavior in the report.

### Example declarations

```ruby
undefined "order on deletion is undefined"
undefined "re-operation after cancel", category: :state_transition
undefined "with inline expectations" do
  expect(something).to eq(42)
end
```

### Strict mode

With the environment variable `RSPEC_UNDEFINED_STRICT=1`, every example that uses `undefined` fails.

## Example output

A summary like the following is emitted at the end of the test run:

```
Undefined spec items:
  1) [matcher] {boundary} be_undefined expected=:__any__ actual=100 matched=true (spec/user_spec.rb:12)
  2) [declaration] {deletion} deletion behavior is undefined (spec/user_spec.rb:30)

undefined: 2
by category:
  boundary: 1
  deletion: 1
```

## Categories

You can tag the *kind* of "spec oversight" with a Symbol category. The 13 standard categories are:

| Category | Example targets |
|---|---|
| `:boundary` | upper/lower limits, max counts, digit/char length, periods |
| `:nil_or_empty` | zero items, null, empty string, no input |
| `:uniqueness` | unique constraints, duplicate registration, concurrent registration |
| `:order` | ordering, sort rules |
| `:datetime` | date/time, timezone, Japanese/Gregorian calendar, leap year/second |
| `:encoding` | character encoding, emoji, surrogate pairs, half/full-width |
| `:rounding` | money rounding (half-up / banker's), currency, order of tax calculation |
| `:permission` | permission boundaries (view/edit/delete, delegated operations) |
| `:state_transition` | state transitions (re-operation after cancel, partial drop-off, timeout recovery) |
| `:concurrency` | optimistic/pessimistic locking, concurrent edit conflicts |
| `:deletion` | physical vs logical deletion, referencing deleted records |
| `:retroactive` | retroactive master changes (should past data show old or new value?) |
| `:idempotency` | external integrations (retries, duplicate-execution prevention) |

Project-specific categories can be registered via `register_categories`:

```ruby
RSpec::Undefined.configure do |c|
  c.register_categories :invoice_rounding, :legacy_auth
end

expect(total).to be_undefined(:invoice_rounding, expected: 1000)
```

Unregistered Symbols are shown in the formatter with a `*` marker so you notice the missing registration.

## Configuration

```ruby
RSpec::Undefined.configure do |c|
  c.report_path   = "tmp/undefined.json"
  c.report_format = :json                 # :json | :yaml | :csv | :markdown
  c.register_categories :my_cat
end
```

## Strict mode and the DSL

When `RSPEC_UNDEFINED_STRICT=1` is set, the following cause the example to fail:

- Any example that calls `be_undefined` (in any form)
- Any example declared with `undefined "..."` / `undefined "...", category: :sym` (with or without a block)

In strict mode, **the block passed to `undefined` is not executed — the example fails immediately**. Inline expectations inside the block only run in normal mode.

## Side effects of `require`

`require "rspec/undefined"` registers `before(:suite)` / `after(:suite)` hooks via `RSpec.configure` and mixes `be_undefined` into `RSpec::Matchers`. If you do not want this enabled in other test environments, restrict where you require it (e.g., only in `spec/spec_helper.rb`).

## Workflow

1. In normal mode, accumulate undefined items while pinning the current behavior into tests (AI can do this)
2. Periodically review the report, and let humans decide the undefined specs
3. Once mostly settled, enable `RSPEC_UNDEFINED_STRICT=1` in CI to prevent new undefined items from slipping in

When `rspec-undefined` is finally gone from your Gemfile, you have no undefined specs left. From there, whether to extend the system's life, replace it, build a harness, or improve it — that is a human's job.

## Supported Ruby / RSpec

| | Version |
|---|---|
| Ruby | `>= 2.0.0` |
| rspec-core | `>= 3.0, < 4` |

CI (GitHub Actions) tests **Ruby 2.2 / 2.7 / 3.1 / 3.3** in Docker containers. Ruby 2.0 is tested locally only, because its official Docker image no longer runs on current Docker (old manifest format).

## Local Docker testing

`bin/docker-test.sh` runs the tests across Ruby 2.0, 2.2, 2.7, 3.1, and 3.3:

```
bin/docker-test.sh
```

- Ruby 2.2+ uses the official `ruby:X.X` images
- Ruby 2.0 uses an amd64 image built from source via `docker/ruby-2.0.Dockerfile` (~7 min on first build, cached after)
- On Apple Silicon, Ruby 2.0 runs under amd64 emulation

On Ruby 2.0 / 2.2, the following tests are skipped conditionally:

- CSV reporter tests: skipped on Ruby < 2.3 because the `csv` gem (≥ 3.0) requires Ruby 2.3+
- YAML reporter tests: skipped on Ruby 2.0 because its Psych does not provide `YAML.safe_load`

## References

- [A Requirements Definition Guide for Users, 2nd Ed. — 128 key points for successful requirements definition (IPA, Japanese)](https://www.ipa.go.jp/archive/publish/tn20191220.html)
- [Non-Functional Requirements Grade (IPA, Japanese)](https://www.ipa.go.jp/archive/digital/iot-en-ci/jyouryuu/index.html)
- [User Guide for Successful System Rebuilds (IPA, Japanese)](https://www.ipa.go.jp/archive/publish/qv6pgp000000117x-att/000057294.pdf)
- [The idea of an *as-is specification* / 現行踏襲仕様書 (Zenn, Japanese)](https://zenn.dev/tokium_dev/articles/a8e7af3930a473)

## License

MIT
