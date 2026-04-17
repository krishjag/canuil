// Canuil IL test runner — pure IL.
// Each test is a static void method. Main wraps each call in a try/catch,
// tracks pass/fail counts, and returns the failure count as the exit code.
// Assertions throw System.Exception on mismatch.

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

.assembly Canuil.Tests
{
  .ver 1:0:0:0
}
.module Canuil.Tests.dll

// ---------------------------------------------------------------------------
// Assertion helpers
// ---------------------------------------------------------------------------
.class public auto ansi abstract sealed beforefieldinit Canuil.Tests.Assert
       extends [System.Runtime]System.Object
{
  // Throws System.Exception("expected '<e>' got '<a>'") if strings differ.
  .method public hidebysig static void
          Equal(string expected, string actual) cil managed
  {
    .maxstack 5

    ldarg.0
    ldarg.1
    call       bool [System.Runtime]System.String::op_Equality(string, string)
    brtrue.s   OK

    // msg = "expected '" + expected + "' got '" + actual   (Concat/4)
    ldstr      "expected '"
    ldarg.0
    ldstr      "' got '"
    ldarg.1
    call       string [System.Runtime]System.String::Concat(string,
                                                            string,
                                                            string,
                                                            string)
    // msg = msg + "'"                                        (Concat/2)
    ldstr      "'"
    call       string [System.Runtime]System.String::Concat(string,
                                                            string)
    newobj     instance void [System.Runtime]System.Exception::.ctor(string)
    throw

  OK:
    ret
  }
}

// ---------------------------------------------------------------------------
// Reporting helpers
// ---------------------------------------------------------------------------
.class public auto ansi abstract sealed beforefieldinit Canuil.Tests.Report
       extends [System.Runtime]System.Object
{
  .method public hidebysig static void Pass(string name) cil managed
  {
    .maxstack 2
    ldstr      "PASS "
    ldarg.0
    call       string [System.Runtime]System.String::Concat(string, string)
    call       void [System.Console]System.Console::WriteLine(string)
    ret
  }

  .method public hidebysig static void
          Fail(string name,
               class [System.Runtime]System.Exception ex) cil managed
  {
    .maxstack 4
    ldstr      "FAIL "
    ldarg.0
    ldstr      ": "
    ldarg.1
    callvirt   instance string
               [System.Runtime]System.Exception::get_Message()
    call       string [System.Runtime]System.String::Concat(string,
                                                            string,
                                                            string,
                                                            string)
    call       void [System.Console]System.Console::WriteLine(string)
    ret
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
.class public auto ansi abstract sealed beforefieldinit Canuil.Tests.Suite
       extends [System.Runtime]System.Object
{
  .method public hidebysig static void Greeter_Basic() cil managed
  {
    .maxstack 2
    .locals init (string actual)

    ldstr      "Jagadish"
    call       string [Canuil.Lib]Canuil.Greeter::FormatGreeting(string)
    stloc.0

    ldstr      "Hello, Jagadish!"
    ldloc.0
    call       void Canuil.Tests.Assert::Equal(string, string)
    ret
  }

  .method public hidebysig static void NameList_Empty() cil managed
  {
    .maxstack 3
    .locals init (string actual, string expected)

    // actual = Canuil.NameList.FormatAll(new string[0])
    ldc.i4.0
    newarr     [System.Runtime]System.String
    call       string [Canuil.Lib]Canuil.NameList::FormatAll(string[])
    stloc.0

    // expected = "Hello, world!" + Environment.NewLine
    ldstr      "Hello, world!"
    call       string [System.Runtime]System.Environment::get_NewLine()
    call       string [System.Runtime]System.String::Concat(string, string)
    stloc.1

    ldloc.1
    ldloc.0
    call       void Canuil.Tests.Assert::Equal(string, string)
    ret
  }

  // Delegates to Canuil.Users.SelfTest::ListAddAndIndex in the library so the
  // List<User> generic instantiation stays module-local. Throws on failure.
  .method public hidebysig static void Users_List_AddAndIndex() cil managed
  {
    .maxstack 0
    call void [Canuil.Lib]Canuil.Users.SelfTest::ListAddAndIndex()
    ret
  }

  .method public hidebysig static void NameList_Multi() cil managed
  {
    .maxstack 5
    .locals init (string actual, string expected, string nl)

    // names = new[] { "Alice", "Bob" }
    ldc.i4.2
    newarr     [System.Runtime]System.String
    dup
    ldc.i4.0
    ldstr      "Alice"
    stelem.ref
    dup
    ldc.i4.1
    ldstr      "Bob"
    stelem.ref
    call       string [Canuil.Lib]Canuil.NameList::FormatAll(string[])
    stloc.0

    // nl = Environment.NewLine
    call       string [System.Runtime]System.Environment::get_NewLine()
    stloc.2

    // expected = "Hello, Alice!" + nl + "Hello, Bob!" + nl
    ldstr      "Hello, Alice!"
    ldloc.2
    ldstr      "Hello, Bob!"
    ldloc.2
    call       string [System.Runtime]System.String::Concat(string,
                                                            string,
                                                            string,
                                                            string)
    stloc.1

    ldloc.1
    ldloc.0
    call       void Canuil.Tests.Assert::Equal(string, string)
    ret
  }

  // Delegates to Canuil.Async.AsyncDemo::SelfTestCompute in the library so
  // the cross-assembly call pattern here stays minimal (SAC-safe). Throws on
  // mismatch.
  .method public hidebysig static void Async_Compute() cil managed
  {
    .maxstack 3
    ldc.i4.3
    ldc.i4.4
    ldc.i4.7
    call void [Canuil.Lib]Canuil.Async.AsyncDemo::SelfTestCompute(int32, int32, int32)
    ret
  }
}

// ---------------------------------------------------------------------------
// Test runner — entry point.
// Each test gets an isolated try/catch; failures accumulate, exit code = #failed.
// ---------------------------------------------------------------------------
.class public auto ansi abstract sealed beforefieldinit Canuil.Tests.Runner
       extends [System.Runtime]System.Object
{
  .method public hidebysig static int32 Main(string[] args) cil managed
  {
    .entrypoint
    .maxstack 4
    .locals init (int32 passed,
                  int32 failed,
                  class [System.Runtime]System.Exception ex,
                  string summary)

    ldc.i4.0
    stloc.0
    ldc.i4.0
    stloc.1

    // --- Test 1: Greeter_Basic ---
    .try
    {
      call     void Canuil.Tests.Suite::Greeter_Basic()
      ldstr    "Greeter_Basic"
      call     void Canuil.Tests.Report::Pass(string)
      ldloc.0
      ldc.i4.1
      add
      stloc.0
      leave.s  AFTER_1
    }
    catch [System.Runtime]System.Exception
    {
      stloc.2
      ldstr    "Greeter_Basic"
      ldloc.2
      call     void Canuil.Tests.Report::Fail(string,
                                              class [System.Runtime]System.Exception)
      ldloc.1
      ldc.i4.1
      add
      stloc.1
      leave.s  AFTER_1
    }
  AFTER_1:

    // --- Test 2: NameList_Empty ---
    .try
    {
      call     void Canuil.Tests.Suite::NameList_Empty()
      ldstr    "NameList_Empty"
      call     void Canuil.Tests.Report::Pass(string)
      ldloc.0
      ldc.i4.1
      add
      stloc.0
      leave.s  AFTER_2
    }
    catch [System.Runtime]System.Exception
    {
      stloc.2
      ldstr    "NameList_Empty"
      ldloc.2
      call     void Canuil.Tests.Report::Fail(string,
                                              class [System.Runtime]System.Exception)
      ldloc.1
      ldc.i4.1
      add
      stloc.1
      leave.s  AFTER_2
    }
  AFTER_2:

    // --- Test 3: NameList_Multi ---
    .try
    {
      call     void Canuil.Tests.Suite::NameList_Multi()
      ldstr    "NameList_Multi"
      call     void Canuil.Tests.Report::Pass(string)
      ldloc.0
      ldc.i4.1
      add
      stloc.0
      leave.s  AFTER_3
    }
    catch [System.Runtime]System.Exception
    {
      stloc.2
      ldstr    "NameList_Multi"
      ldloc.2
      call     void Canuil.Tests.Report::Fail(string,
                                              class [System.Runtime]System.Exception)
      ldloc.1
      ldc.i4.1
      add
      stloc.1
      leave.s  AFTER_3
    }
  AFTER_3:

    // --- Test 4: Users_List_AddAndIndex ---
    .try
    {
      call     void Canuil.Tests.Suite::Users_List_AddAndIndex()
      ldstr    "Users_List_AddAndIndex"
      call     void Canuil.Tests.Report::Pass(string)
      ldloc.0
      ldc.i4.1
      add
      stloc.0
      leave.s  AFTER_4
    }
    catch [System.Runtime]System.Exception
    {
      stloc.2
      ldstr    "Users_List_AddAndIndex"
      ldloc.2
      call     void Canuil.Tests.Report::Fail(string,
                                              class [System.Runtime]System.Exception)
      ldloc.1
      ldc.i4.1
      add
      stloc.1
      leave.s  AFTER_4
    }
  AFTER_4:

    // --- Test 5: Async_Compute ---
    .try
    {
      call     void Canuil.Tests.Suite::Async_Compute()
      ldstr    "Async_Compute"
      call     void Canuil.Tests.Report::Pass(string)
      ldloc.0
      ldc.i4.1
      add
      stloc.0
      leave.s  AFTER_5
    }
    catch [System.Runtime]System.Exception
    {
      stloc.2
      ldstr    "Async_Compute"
      ldloc.2
      call     void Canuil.Tests.Report::Fail(string,
                                              class [System.Runtime]System.Exception)
      ldloc.1
      ldc.i4.1
      add
      stloc.1
      leave.s  AFTER_5
    }
  AFTER_5:

    // summary = "Results: {passed} passed, {failed} failed"
    ldstr      "Results: {0} passed, {1} failed"
    ldloc.0
    box        [System.Runtime]System.Int32
    ldloc.1
    box        [System.Runtime]System.Int32
    call       string [System.Runtime]System.String::Format(string,
                                                            object,
                                                            object)
    call       void [System.Console]System.Console::WriteLine(string)

    ldloc.1
    ret
  }
}
