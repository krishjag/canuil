// Canuil MyApp — entry point, pure IL.
// Delegates formatting to Canuil.NameList (which itself calls Canuil.Greeter),
// then writes the result to the console, then runs the Users demo.

.assembly extern System.Runtime
{
  .ver 10:0:0:0
}
.assembly extern System.Console
{
  .ver 10:0:0:0
}
.assembly extern Canuil.Lib
{
  .ver 1:0:0:0
}

.assembly Canuil.App
{
  .ver 1:0:0:0
}
.module Canuil.App.dll

.class public auto ansi abstract sealed beforefieldinit Canuil.Program
       extends [System.Runtime]System.Object
{
  .method public hidebysig static int32 Main(string[] args) cil managed
  {
    .entrypoint
    .maxstack 2
    .locals init (string output)

    ldarg.0
    call       string [Canuil.Lib]Canuil.NameList::FormatAll(string[])
    stloc.0

    ldloc.0
    call       void [System.Console]System.Console::Write(string)

    // Users list demo — exercises System.Collections.Generic.List<User>.
    call       void [Canuil.Lib]Canuil.Users.Demo::Run()

    // Async demo — exercises a hand-rolled async state machine.
    call       void [Canuil.Lib]Canuil.Async.AsyncDemo::Run()

    ldc.i4.0
    ret
  }
}
