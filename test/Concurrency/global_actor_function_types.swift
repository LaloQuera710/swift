// RUN: %target-typecheck-verify-swift -enable-experimental-concurrency
// REQUIRES: concurrency

actor SomeActor { }

@globalActor
struct SomeGlobalActor {
  static let shared = SomeActor()
}

@globalActor
struct OtherGlobalActor {
  static let shared = SomeActor()
}

func testConversions(f: @escaping @SomeGlobalActor (Int) -> Void, g: @escaping (Int) -> Void) {
  let _: Int = f // expected-error{{cannot convert value of type '@SomeGlobalActor (Int) -> Void' to specified type 'Int'}}

  let _: (Int) -> Void = f // expected-error{{converting function value of type '@SomeGlobalActor (Int) -> Void' to '(Int) -> Void' loses global actor 'SomeGlobalActor'}}
  let _: @SomeGlobalActor (Int) -> Void = g // okay

  // FIXME: this could be better.
  let _: @OtherGlobalActor (Int) -> Void = f // expected-error{{cannot convert value of type 'SomeGlobalActor' to specified type 'OtherGlobalActor'}}
}

@SomeGlobalActor func onSomeGlobalActor() -> Int { 5 }

func someSlowOperation() async -> Int { 5 }

func acceptOnSomeGlobalActor<T>(_: @SomeGlobalActor () -> T) { }

func testClosures() {
  // Global actors on synchronous closures become part of the type
  let cl1 = { @SomeGlobalActor in
    onSomeGlobalActor()
  }
  let _: Double = cl1 // expected-error{{cannot convert value of type '@SomeGlobalActor () -> Int' to specified type 'Double'}}

  // Global actors on async closures do not become part of the type
  let cl2 = { @SomeGlobalActor in
    await someSlowOperation()
  }
  let _: Double = cl2 // expected-error{{cannot convert value of type '() async -> Int' to specified type 'Double'}}

  // okay to be explicit
  acceptOnSomeGlobalActor { @SomeGlobalActor in
    onSomeGlobalActor()
  }

  acceptOnSomeGlobalActor {
    onSomeGlobalActor()
  }

  acceptOnSomeGlobalActor { () -> Int in
    let i = onSomeGlobalActor()
    return i
  }
}
