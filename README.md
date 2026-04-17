# Canuil - a .NET app written in pure IL

> **Name.** *Canuil* is a play on "Can you IL?" — the question that kicked this
> project off, posed to Claude Code (Opus 4.7).

Canuil is a small .NET 10 program whose every source file is Common Intermediate
Language (CIL, or just "IL"). No C#. No F#. No VB. No `csc`. No `dotnet build`
on a `.csproj`. The source files are `.il`, the toolchain is `ilasm` +
`ilverify`, and the output is ordinary managed DLLs that `dotnet` runs the same
way it would run anything Roslyn produced.

The point is to walk the middle rung of the abstraction ladder in public —
because most .NET programmers spend their careers on the top rung and almost
never see the one below.

## The three rungs

Every running .NET program exists at three levels of description at once, each
generated from the one above:

```
  ┌─────────────────────────────────────────────────┐
  │  High-level source   │  C# · F# · VB            │   what you write
  ├─────────────────────────────────────────────────┤
  │  Intermediate (IL)   │  .il / .dll metadata     │   what ships in assemblies
  ├─────────────────────────────────────────────────┤
  │  Native machine code │  x64 / ARM64 / …         │   what the CPU runs
  └─────────────────────────────────────────────────┘
```

**High level.** A language designed for humans: lambdas, LINQ, pattern
matching, `async`/`await`, records, computation expressions, `With` blocks.
Different languages optimize for different tastes, but they all compile to the
same thing.

**IL.** A stack-based virtual instruction set defined by ECMA-335. Typed,
verifiable, platform-neutral. Load two values onto a stack, call `add`, store
the result; declare a class, mark it sealed, give it a generic parameter.
Every compiled .NET assembly — yours, the BCL's, NuGet packages — is IL plus
metadata tables wrapped in a PE file. This is the layer where the runtime
actually understands your program.

**Native.** When your method is first called, the JIT reads the IL, does type
checks, picks registers, emits x64 or ARM64 instructions into memory, and jumps
to them. AOT does the same work ahead of time. The CPU never sees your C#; it
never really sees your IL either. But the IL is the contract that decides what
the native code must do.

## All three .NET languages produce IL

The part most people forget: **C#, F#, and Visual Basic are siblings, not a
hierarchy**. None of them compiles "down through" another. Each one is its own
frontend that emits IL directly:

| Language | Compiler      | Emits        |
|----------|---------------|--------------|
| C#       | `csc` (Roslyn) | IL + PE file |
| F#       | `fsc`          | IL + PE file |
| VB       | `vbc` (Roslyn) | IL + PE file |

That's why a C# program can call an F# library can call a VB class can call
the BCL (which, in its lower levels, is itself assembled from IL and C#). At
the IL layer the source language is forgotten — there are just types, methods,
signatures, and a stack.

Every language feature you can name lives as a pattern at this layer:

- `async`/`await` → a compiler-synthesized struct implementing
  `IAsyncStateMachine`, driven by `AsyncTaskMethodBuilder<T>` and a `switch`
  over `state` inside `MoveNext()`.
- `foreach` → a `GetEnumerator` / `MoveNext` / `Current` / `Dispose` loop with
  a `try`/`finally`.
- `lock (x) { … }` → `Monitor.Enter` / `Monitor.Exit` in a `try`/`finally`.
- Generics → `!0` for a class's type parameter, `!!0` for a method's, plus
  TypeSpec blobs the runtime specializes per instantiation.
- Closures → a compiler-generated display class whose fields hold the captured
  variables.

If you can see those patterns once, `async Task<int>` stops being magic and
starts being a data structure.

## The Canuil approach

Canuil writes those patterns directly, by hand. Concretely:

1. **Source: pure `.il` files.** [src/Lib/Canuil.Lib.il](src/Lib/Canuil.Lib.il)
   defines a greeter, a user value type, a `List<User>` demo, and a hand-rolled
   async state machine. [src/Program.il](src/Program.il) is the executable's
   entry point. [src/Tests/Tests.il](src/Tests/Tests.il) is a tiny test
   runner.
2. **Assembler: `ilasm`.** A Microsoft-supplied tool that turns `.il` text
   into a PE/COFF `.dll` with CLI metadata. Canuil downloads it as a NuGet
   package (`runtime.<rid>.Microsoft.NETCore.ILAsm`, v10.0.0) via
   [scripts/bootstrap.ps1](scripts/bootstrap.ps1) so the repo stays tool-free.
3. **Verifier: `ilverify`.** A `dotnet` global tool that walks each assembly
   and confirms every method is type-safe and verifiable — i.e. would pass the
   runtime's own verifier. Catches stack-shape errors, bad branches, illegal
   cross-type conversions.
4. **Runner: `dotnet`.** Canuil's DLLs are normal .NET 10 assemblies with
   `*.runtimeconfig.json` siblings, so the shared host runs them as-is. The JIT
   doesn't know or care that they came from hand-written IL.

No project file, no MSBuild, no `csproj`. [scripts/build.ps1](scripts/build.ps1)
orchestrates the four steps above on Windows, Linux, and macOS.

## What's inside

- **`Canuil.Greeter`** — `FormatGreeting(string)`; trivial method, good first
  read.
- **`Canuil.NameList`** — takes a `string[]`, formats each with `Greeter`,
  concatenates with `Environment.NewLine`.
- **`Canuil.Users.User`** — a value type (struct) with `Id` and `Name`, an
  `.ctor`, and an overridden `ToString()`.
- **`Canuil.Users.Demo`** — builds `List<User>`, adds three, prints them.
- **`Canuil.Async.ComputeStateMachine` + `AsyncDemo`** — an async `Task<int>`
  method written as its desugared state machine: a struct implementing
  `IAsyncStateMachine`, an `AsyncTaskMethodBuilder<int>` field, a `state`
  field, a `TaskAwaiter`, and a `MoveNext` that manually advances through
  states and reports completion. The kickoff method (`ComputeAsync`) creates
  the builder, calls `Start`, returns `builder.Task`. The demo calls
  `.GetAwaiter().GetResult()` so `Main` can stay sync.
- **`Canuil.Tests.Suite`** — five tests covering the above.

## Getting started

Prereqs: PowerShell 7+, .NET 10 SDK, git.

```sh
git clone <this repo>
cd canuil

# one-time: download the right ilasm for your OS into ./tools/
./scripts/bootstrap.ps1

# install the IL verifier (one-time, global)
dotnet tool install --global dotnet-ilverify

# build, verify, test, run
./scripts/build.ps1 -Target Test
./scripts/build.ps1 -Target Run
```

`scripts/build.ps1` targets:

- `Build` — assemble `.il` → `.dll`
- `Verify` — run `ilverify` against each output
- `Test` — build, verify, run `Canuil.Tests.dll`
- `Run` — build, verify, run `Canuil.App.dll`
- `All` *(default)* — Build + Verify

Expected `Run` output:

```
Hello, world!
User(1, Alice)
User(2, Bob)
User(3, Jagadish)
Count: 3
async: 3 + 4 = 7
```

## Layout

```
canuil/
├── scripts/
│   ├── bootstrap.ps1        # downloads ilasm NuGet for current OS → tools/
│   └── build.ps1            # assemble + verify + test + run
├── src/
│   ├── Lib/
│   │   └── Canuil.Lib.il    # all library code, consolidated
│   ├── Tests/
│   │   ├── Tests.il
│   │   └── Tests.runtimeconfig.json
│   ├── Program.il           # Canuil.App entry point
│   └── Canuil.App.runtimeconfig.json
├── tools/                   # gitignored; populated by bootstrap
└── build/                   # gitignored; ilasm outputs here
```

Everything under `build/` and `tools/` is derivative; only `scripts/` and
`src/` are source.

## Why bother?

Reading IL-by-hand code is the fastest way to build a durable mental model of
what the runtime actually does. It makes surprising performance numbers
explicable, it makes "magic" language features legible, and it makes the
difference between a generic's class parameter and its method parameter stop
being a mystery.

It is not a practical way to ship product code. Canuil isn't trying to be.

## CI

A GitHub Actions workflow ([.github/workflows/ci.yml](.github/workflows/ci.yml))
runs the same bootstrap → build → verify → test → run flow on
`windows-latest` and `ubuntu-latest` so the IL stays portable.
