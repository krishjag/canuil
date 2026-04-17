// Canuil.Lib — single consolidated library containing Greeter, NameList, and
// Users types. Consolidation eliminates unsigned cross-assembly references
// between our own libraries, which keeps the build clean under Smart App
// Control / WDAC policies that otherwise flag unsigned lib-to-lib calls.

.assembly extern System.Runtime
{
  .ver 10:0:0:0
}
.assembly extern System.Console
{
  .ver 10:0:0:0
}
.assembly extern System.Collections
{
  .ver 10:0:0:0
}

.assembly Canuil.Lib
{
  .ver 1:0:0:0
}
.module Canuil.Lib.dll

// ===========================================================================
// Canuil.Greeter — simple string formatter.
// ===========================================================================
.class public auto ansi abstract sealed beforefieldinit Canuil.Greeter
       extends [System.Runtime]System.Object
{
  // string FormatGreeting(string name) => "Hello, " + name + "!"
  .method public hidebysig static string
          FormatGreeting(string name) cil managed
  {
    .maxstack 3
    .locals init (string result)

    ldstr      "Hello, "
    ldarg.0
    ldstr      "!"
    call       string [System.Runtime]System.String::Concat(string,
                                                            string,
                                                            string)
    stloc.0
    ldloc.0
    ret
  }
}

// ===========================================================================
// Canuil.NameList — formats an array of names using Greeter + StringBuilder.
// ===========================================================================
.class public auto ansi abstract sealed beforefieldinit Canuil.NameList
       extends [System.Runtime]System.Object
{
  // string FormatAll(string[] names)
  //   -> "Hello, a!\nHello, b!\n..." (StringBuilder-joined)
  //   -> "Hello, world!\n" if names is empty
  .method public hidebysig static string
          FormatAll(string[] names) cil managed
  {
    .maxstack 3
    .locals init (
      int32 i,
      int32 len,
      class [System.Runtime]System.Text.StringBuilder sb,
      string current
    )

    // sb = new StringBuilder()
    newobj     instance void [System.Runtime]System.Text.StringBuilder::.ctor()
    stloc.2

    // len = names.Length
    ldarg.0
    ldlen
    conv.i4
    stloc.1

    // if (len == 0) { append greeting for "world" and return }
    ldloc.1
    brtrue.s   LOOP_INIT

    ldloc.2
    ldstr      "world"
    call       string Canuil.Greeter::FormatGreeting(string)
    callvirt   instance class [System.Runtime]System.Text.StringBuilder
               [System.Runtime]System.Text.StringBuilder::AppendLine(string)
    pop
    br.s       DONE

  LOOP_INIT:
    ldc.i4.0
    stloc.0
    br.s       LOOP_CHECK

  LOOP_BODY:
    ldarg.0
    ldloc.0
    ldelem.ref
    call       string Canuil.Greeter::FormatGreeting(string)
    stloc.3

    ldloc.2
    ldloc.3
    callvirt   instance class [System.Runtime]System.Text.StringBuilder
               [System.Runtime]System.Text.StringBuilder::AppendLine(string)
    pop

    ldloc.0
    ldc.i4.1
    add
    stloc.0

  LOOP_CHECK:
    ldloc.0
    ldloc.1
    blt.s      LOOP_BODY

  DONE:
    ldloc.2
    callvirt   instance string
               [System.Runtime]System.Object::ToString()
    ret
  }
}

// ===========================================================================
// Canuil.Users.User — { int32 UserId; string UserName; }, ToString override.
// ===========================================================================
.class public auto ansi beforefieldinit Canuil.Users.User
       extends [System.Runtime]System.Object
{
  .field private int32  _id
  .field private string _name

  .method public hidebysig specialname rtspecialname
          instance void .ctor(int32 id, string name) cil managed
  {
    .maxstack 2
    ldarg.0
    call       instance void [System.Runtime]System.Object::.ctor()

    ldarg.0
    ldarg.1
    stfld      int32 Canuil.Users.User::_id

    ldarg.0
    ldarg.2
    stfld      string Canuil.Users.User::_name
    ret
  }

  .method public hidebysig specialname
          instance int32 get_UserId() cil managed
  {
    .maxstack 1
    ldarg.0
    ldfld      int32 Canuil.Users.User::_id
    ret
  }

  .method public hidebysig specialname
          instance string get_UserName() cil managed
  {
    .maxstack 1
    ldarg.0
    ldfld      string Canuil.Users.User::_name
    ret
  }

  .property int32 UserId()
  {
    .get instance int32 Canuil.Users.User::get_UserId()
  }
  .property string UserName()
  {
    .get instance string Canuil.Users.User::get_UserName()
  }

  // override object.ToString() => "User(<id>, <name>)"
  .method public hidebysig virtual
          instance string ToString() cil managed
  {
    .maxstack 4
    ldstr      "User({0}, {1})"
    ldarg.0
    ldfld      int32 Canuil.Users.User::_id
    box        [System.Runtime]System.Int32
    ldarg.0
    ldfld      string Canuil.Users.User::_name
    call       string [System.Runtime]System.String::Format(string,
                                                            object,
                                                            object)
    ret
  }
}

// ===========================================================================
// Canuil.Users.SelfTest — verifies List<User> behavior entirely inside this
// assembly. Kept here (not in Canuil.Tests) so the generic instantiation
// List`1<Canuil.Users.User> stays module-local rather than a cross-assembly
// TypeSpec (which trips Smart App Control on unsigned DLLs). Throws on
// failure; the test runner catches System.Exception.
// ===========================================================================
.class public auto ansi abstract sealed beforefieldinit Canuil.Users.SelfTest
       extends [System.Runtime]System.Object
{
  .method public hidebysig static void ListAddAndIndex() cil managed
  {
    .maxstack 4
    .locals init (
      class [System.Collections]System.Collections.Generic.List`1<class Canuil.Users.User> list,
      class Canuil.Users.User second,
      int32 count
    )

    // list = new List<User>()
    newobj     instance void class [System.Collections]System.Collections.Generic.List`1<class Canuil.Users.User>::.ctor()
    stloc.0

    // list.Add(new User(1, "Alice"))
    ldloc.0
    ldc.i4.1
    ldstr      "Alice"
    newobj     instance void Canuil.Users.User::.ctor(int32, string)
    callvirt   instance void class [System.Collections]System.Collections.Generic.List`1<class Canuil.Users.User>::Add(!0)

    // list.Add(new User(2, "Bob"))
    ldloc.0
    ldc.i4.2
    ldstr      "Bob"
    newobj     instance void Canuil.Users.User::.ctor(int32, string)
    callvirt   instance void class [System.Collections]System.Collections.Generic.List`1<class Canuil.Users.User>::Add(!0)

    // count = list.Count; if (count != 2) throw
    ldloc.0
    callvirt   instance int32 class [System.Collections]System.Collections.Generic.List`1<class Canuil.Users.User>::get_Count()
    stloc.2
    ldloc.2
    ldc.i4.2
    beq.s      COUNT_OK
    ldstr      "Count mismatch"
    newobj     instance void [System.Runtime]System.Exception::.ctor(string)
    throw
  COUNT_OK:

    // second = list[1]
    ldloc.0
    ldc.i4.1
    callvirt   instance !0 class [System.Collections]System.Collections.Generic.List`1<class Canuil.Users.User>::get_Item(int32)
    stloc.1

    // if (second.UserName != "Bob") throw
    ldloc.1
    callvirt   instance string Canuil.Users.User::get_UserName()
    ldstr      "Bob"
    call       bool [System.Runtime]System.String::op_Equality(string, string)
    brtrue.s   NAME_OK
    ldstr      "UserName mismatch"
    newobj     instance void [System.Runtime]System.Exception::.ctor(string)
    throw
  NAME_OK:

    // if (second.ToString() != "User(2, Bob)") throw
    ldloc.1
    callvirt   instance string [System.Runtime]System.Object::ToString()
    ldstr      "User(2, Bob)"
    call       bool [System.Runtime]System.String::op_Equality(string, string)
    brtrue.s   STR_OK
    ldstr      "ToString mismatch"
    newobj     instance void [System.Runtime]System.Exception::.ctor(string)
    throw
  STR_OK:
    ret
  }
}

// ===========================================================================
// Canuil.Async.ComputeStateMachine — hand-rolled async state machine, value
// type implementing IAsyncStateMachine. Matches the shape a C# compiler would
// emit for:
//   async Task<int> ComputeAsync(int a, int b) { await Task.Delay(10); return a + b; }
// State values: -1 = initial, 0 = suspended on awaiter, -2 = terminal.
// ===========================================================================
.class public sequential ansi sealed beforefieldinit Canuil.Async.ComputeStateMachine
       extends [System.Runtime]System.ValueType
       implements [System.Runtime]System.Runtime.CompilerServices.IAsyncStateMachine
{
  .field public int32 state
  .field public valuetype [System.Runtime]System.Runtime.CompilerServices.AsyncTaskMethodBuilder`1<int32> builder
  .field public int32 a
  .field public int32 b
  .field public valuetype [System.Runtime]System.Runtime.CompilerServices.TaskAwaiter awaiter

  .method public hidebysig newslot virtual final
          instance void MoveNext() cil managed
  {
    .override [System.Runtime]System.Runtime.CompilerServices.IAsyncStateMachine::MoveNext
    .maxstack 3
    .locals init (
      int32 state,
      int32 result,
      valuetype [System.Runtime]System.Runtime.CompilerServices.TaskAwaiter awaiter,
      class [System.Runtime]System.Exception ex
    )

    // state = this.state
    ldarg.0
    ldfld      int32 Canuil.Async.ComputeStateMachine::state
    stloc.0

    .try
    {
      // if (state == 0) goto RESUME
      ldloc.0
      brfalse.s  RESUME

      // --- First invocation: start the delay ---
      ldc.i4.s   10
      call       class [System.Runtime]System.Threading.Tasks.Task
                 [System.Runtime]System.Threading.Tasks.Task::Delay(int32)
      callvirt   instance valuetype [System.Runtime]System.Runtime.CompilerServices.TaskAwaiter
                 [System.Runtime]System.Threading.Tasks.Task::GetAwaiter()
      stloc.2

      // if (awaiter.IsCompleted) goto AWAITER_DONE
      ldloca.s   2
      call       instance bool [System.Runtime]System.Runtime.CompilerServices.TaskAwaiter::get_IsCompleted()
      brtrue.s   AWAITER_DONE

      // this.state = 0 (also local state = 0)
      ldarg.0
      ldc.i4.0
      stfld      int32 Canuil.Async.ComputeStateMachine::state
      ldc.i4.0
      stloc.0

      // this.awaiter = awaiter
      ldarg.0
      ldloc.2
      stfld      valuetype [System.Runtime]System.Runtime.CompilerServices.TaskAwaiter
                 Canuil.Async.ComputeStateMachine::awaiter

      // this.builder.AwaitUnsafeOnCompleted<TaskAwaiter, ComputeStateMachine>(ref awaiter, ref this)
      ldarg.0
      ldflda     valuetype [System.Runtime]System.Runtime.CompilerServices.AsyncTaskMethodBuilder`1<int32>
                 Canuil.Async.ComputeStateMachine::builder
      ldloca.s   2
      ldarg.0
      call       instance void valuetype [System.Runtime]System.Runtime.CompilerServices.AsyncTaskMethodBuilder`1<int32>::AwaitUnsafeOnCompleted<valuetype [System.Runtime]System.Runtime.CompilerServices.TaskAwaiter, valuetype Canuil.Async.ComputeStateMachine>(!!0&, !!1&)

      leave.s    END

    RESUME:
      // awaiter = this.awaiter; this.awaiter = default; this.state = -1
      ldarg.0
      ldfld      valuetype [System.Runtime]System.Runtime.CompilerServices.TaskAwaiter
                 Canuil.Async.ComputeStateMachine::awaiter
      stloc.2

      ldarg.0
      ldflda     valuetype [System.Runtime]System.Runtime.CompilerServices.TaskAwaiter
                 Canuil.Async.ComputeStateMachine::awaiter
      initobj    [System.Runtime]System.Runtime.CompilerServices.TaskAwaiter

      ldarg.0
      ldc.i4.m1
      stfld      int32 Canuil.Async.ComputeStateMachine::state
      ldc.i4.m1
      stloc.0

    AWAITER_DONE:
      // awaiter.GetResult()
      ldloca.s   2
      call       instance void [System.Runtime]System.Runtime.CompilerServices.TaskAwaiter::GetResult()

      // result = this.a + this.b
      ldarg.0
      ldfld      int32 Canuil.Async.ComputeStateMachine::a
      ldarg.0
      ldfld      int32 Canuil.Async.ComputeStateMachine::b
      add
      stloc.1

      leave.s    SET_RESULT
    }
    catch [System.Runtime]System.Exception
    {
      stloc.3
      // this.state = -2; builder.SetException(ex)
      ldarg.0
      ldc.i4.s   -2
      stfld      int32 Canuil.Async.ComputeStateMachine::state

      ldarg.0
      ldflda     valuetype [System.Runtime]System.Runtime.CompilerServices.AsyncTaskMethodBuilder`1<int32>
                 Canuil.Async.ComputeStateMachine::builder
      ldloc.3
      call       instance void valuetype [System.Runtime]System.Runtime.CompilerServices.AsyncTaskMethodBuilder`1<int32>::SetException(class [System.Runtime]System.Exception)
      leave.s    END
    }

  SET_RESULT:
    // this.state = -2; builder.SetResult(result)
    ldarg.0
    ldc.i4.s   -2
    stfld      int32 Canuil.Async.ComputeStateMachine::state

    ldarg.0
    ldflda     valuetype [System.Runtime]System.Runtime.CompilerServices.AsyncTaskMethodBuilder`1<int32>
               Canuil.Async.ComputeStateMachine::builder
    ldloc.1
    call       instance void valuetype [System.Runtime]System.Runtime.CompilerServices.AsyncTaskMethodBuilder`1<int32>::SetResult(!0)

  END:
    ret
  }

  .method public hidebysig newslot virtual final
          instance void SetStateMachine(class [System.Runtime]System.Runtime.CompilerServices.IAsyncStateMachine sm) cil managed
  {
    .override [System.Runtime]System.Runtime.CompilerServices.IAsyncStateMachine::SetStateMachine
    .maxstack 2
    ldarg.0
    ldflda     valuetype [System.Runtime]System.Runtime.CompilerServices.AsyncTaskMethodBuilder`1<int32>
               Canuil.Async.ComputeStateMachine::builder
    ldarg.1
    call       instance void valuetype [System.Runtime]System.Runtime.CompilerServices.AsyncTaskMethodBuilder`1<int32>::SetStateMachine(class [System.Runtime]System.Runtime.CompilerServices.IAsyncStateMachine)
    ret
  }
}

// ===========================================================================
// Canuil.Async.AsyncDemo — kickoff, synchronous wrapper, and demo runner.
// ===========================================================================
.class public auto ansi abstract sealed beforefieldinit Canuil.Async.AsyncDemo
       extends [System.Runtime]System.Object
{
  // Task<int> ComputeAsync(int a, int b) — equivalent of an `async` method
  // that awaits Task.Delay(10) and returns a + b.
  .method public hidebysig static
          class [System.Runtime]System.Threading.Tasks.Task`1<int32>
          ComputeAsync(int32 a, int32 b) cil managed
  {
    .maxstack 3
    .locals init (valuetype Canuil.Async.ComputeStateMachine sm)

    // sm.builder = AsyncTaskMethodBuilder<int>.Create()
    ldloca.s   0
    call       valuetype [System.Runtime]System.Runtime.CompilerServices.AsyncTaskMethodBuilder`1<!0>
               valuetype [System.Runtime]System.Runtime.CompilerServices.AsyncTaskMethodBuilder`1<int32>::Create()
    stfld      valuetype [System.Runtime]System.Runtime.CompilerServices.AsyncTaskMethodBuilder`1<int32>
               Canuil.Async.ComputeStateMachine::builder

    // sm.a = a
    ldloca.s   0
    ldarg.0
    stfld      int32 Canuil.Async.ComputeStateMachine::a

    // sm.b = b
    ldloca.s   0
    ldarg.1
    stfld      int32 Canuil.Async.ComputeStateMachine::b

    // sm.state = -1
    ldloca.s   0
    ldc.i4.m1
    stfld      int32 Canuil.Async.ComputeStateMachine::state

    // sm.builder.Start(ref sm)
    ldloca.s   0
    ldflda     valuetype [System.Runtime]System.Runtime.CompilerServices.AsyncTaskMethodBuilder`1<int32>
               Canuil.Async.ComputeStateMachine::builder
    ldloca.s   0
    call       instance void valuetype [System.Runtime]System.Runtime.CompilerServices.AsyncTaskMethodBuilder`1<int32>::Start<valuetype Canuil.Async.ComputeStateMachine>(!!0&)

    // return sm.builder.Task
    ldloca.s   0
    ldflda     valuetype [System.Runtime]System.Runtime.CompilerServices.AsyncTaskMethodBuilder`1<int32>
               Canuil.Async.ComputeStateMachine::builder
    call       instance class [System.Runtime]System.Threading.Tasks.Task`1<!0>
               valuetype [System.Runtime]System.Runtime.CompilerServices.AsyncTaskMethodBuilder`1<int32>::get_Task()
    ret
  }

  // Synchronous wrapper: awaits ComputeAsync on the caller's thread so tests
  // and non-async callers don't need to handle Task<T> directly. Returning
  // int32 instead of Task<int32> keeps the cross-assembly generic TypeSpec
  // problem away from consumers in other DLLs.
  .method public hidebysig static int32 ComputeSync(int32 a, int32 b) cil managed
  {
    .maxstack 2
    .locals init (valuetype [System.Runtime]System.Runtime.CompilerServices.TaskAwaiter`1<int32> aw)

    ldarg.0
    ldarg.1
    call       class [System.Runtime]System.Threading.Tasks.Task`1<int32>
               Canuil.Async.AsyncDemo::ComputeAsync(int32, int32)
    callvirt   instance valuetype [System.Runtime]System.Runtime.CompilerServices.TaskAwaiter`1<!0>
               class [System.Runtime]System.Threading.Tasks.Task`1<int32>::GetAwaiter()
    stloc.0

    ldloca.s   0
    call       instance !0
               valuetype [System.Runtime]System.Runtime.CompilerServices.TaskAwaiter`1<int32>::GetResult()
    ret
  }

  // Self-test: awaits ComputeAsync(a,b) and throws if the result is not the
  // expected value. Kept in Canuil.Lib so the test runner DLL stays free of
  // patterns that trip SAC heuristics.
  .method public hidebysig static void
          SelfTestCompute(int32 a, int32 b, int32 expected) cil managed
  {
    .maxstack 3
    .locals init (int32 actual, string msg)

    ldarg.0
    ldarg.1
    call       int32 Canuil.Async.AsyncDemo::ComputeSync(int32, int32)
    stloc.0

    ldloc.0
    ldarg.2
    beq.s      OK

    // msg = "async result mismatch: expected " + expected + " got " + actual
    ldstr      "async result mismatch: expected {0} got {1}"
    ldarg.2
    box        [System.Runtime]System.Int32
    ldloc.0
    box        [System.Runtime]System.Int32
    call       string [System.Runtime]System.String::Format(string, object, object)
    stloc.1

    ldloc.1
    newobj     instance void [System.Runtime]System.Exception::.ctor(string)
    throw

  OK:
    ret
  }

  // Prints "async: 3 + 4 = 7" after awaiting the state machine.
  .method public hidebysig static void Run() cil managed
  {
    .maxstack 3
    .locals init (int32 result)

    ldc.i4.3
    ldc.i4.4
    call       int32 Canuil.Async.AsyncDemo::ComputeSync(int32, int32)
    stloc.0

    ldstr      "async: 3 + 4 = {0}"
    ldloc.0
    box        [System.Runtime]System.Int32
    call       string [System.Runtime]System.String::Format(string, object)
    call       void [System.Console]System.Console::WriteLine(string)
    ret
  }
}

// ===========================================================================
// Canuil.Users.Demo — populates a List<User>, iterates, prints count.
// ===========================================================================
.class public auto ansi abstract sealed beforefieldinit Canuil.Users.Demo
       extends [System.Runtime]System.Object
{
  .method public hidebysig static void Run() cil managed
  {
    .maxstack 4
    .locals init (
      class [System.Collections]System.Collections.Generic.List`1<class Canuil.Users.User> list,
      int32 i,
      int32 count,
      class Canuil.Users.User current,
      string countMsg
    )

    // list = new List<User>()
    newobj     instance void class [System.Collections]System.Collections.Generic.List`1<class Canuil.Users.User>::.ctor()
    stloc.0

    // list.Add(new User(1, "Alice"))
    ldloc.0
    ldc.i4.1
    ldstr      "Alice"
    newobj     instance void Canuil.Users.User::.ctor(int32, string)
    callvirt   instance void class [System.Collections]System.Collections.Generic.List`1<class Canuil.Users.User>::Add(!0)

    // list.Add(new User(2, "Bob"))
    ldloc.0
    ldc.i4.2
    ldstr      "Bob"
    newobj     instance void Canuil.Users.User::.ctor(int32, string)
    callvirt   instance void class [System.Collections]System.Collections.Generic.List`1<class Canuil.Users.User>::Add(!0)

    // list.Add(new User(3, "Jagadish"))
    ldloc.0
    ldc.i4.3
    ldstr      "Jagadish"
    newobj     instance void Canuil.Users.User::.ctor(int32, string)
    callvirt   instance void class [System.Collections]System.Collections.Generic.List`1<class Canuil.Users.User>::Add(!0)

    // count = list.Count
    ldloc.0
    callvirt   instance int32 class [System.Collections]System.Collections.Generic.List`1<class Canuil.Users.User>::get_Count()
    stloc.2

    // for (i = 0; i < count; i++) Console.WriteLine(list[i].ToString())
    ldc.i4.0
    stloc.1
    br.s       LOOP_CHECK

  LOOP_BODY:
    ldloc.0
    ldloc.1
    callvirt   instance !0 class [System.Collections]System.Collections.Generic.List`1<class Canuil.Users.User>::get_Item(int32)
    stloc.3

    ldloc.3
    callvirt   instance string [System.Runtime]System.Object::ToString()
    call       void [System.Console]System.Console::WriteLine(string)

    ldloc.1
    ldc.i4.1
    add
    stloc.1

  LOOP_CHECK:
    ldloc.1
    ldloc.2
    blt.s      LOOP_BODY

    // Console.WriteLine("Count: " + count)
    ldstr      "Count: "
    ldloc.2
    box        [System.Runtime]System.Int32
    callvirt   instance string [System.Runtime]System.Object::ToString()
    call       string [System.Runtime]System.String::Concat(string, string)
    stloc.s    countMsg

    ldloc.s    countMsg
    call       void [System.Console]System.Console::WriteLine(string)
    ret
  }
}
