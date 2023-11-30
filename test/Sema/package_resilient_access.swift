// RUN: %empty-directory(%t)
// RUN: split-file %s %t

// RUN: %target-swift-frontend -emit-module %t/Utils.swift \
// RUN:   -module-name Utils -swift-version 5 -I %t \
// RUN:   -package-name mypkg \
// RUN:   -enable-library-evolution \
// RUN:   -emit-module -emit-module-path %t/Utils.swiftmodule

// RUN: %target-swift-frontend -typecheck %t/Client.swift -I %t -swift-version 5 -package-name mypkg -verify

// RUN: %target-swift-frontend -emit-sil %t/Client.swift -package-name mypkg -I %t > %t/Client.sil
// RUN: %FileCheck %s < %t/Client.sil


//--- Utils.swift

// Resilient; public. Acessed indirectly.
public struct PublicStruct {
  public var data: Int
}

// Non-resilient; non-public. Accessed directly.
package struct PkgStruct {
  package var data: Int
}

// Non-resilient but accessed indirectly since generic.
package struct PkgStructGeneric<T> {
  package var data: T
}

// Non-resilient but accessed indirectly; member is of a resilient type.
package struct PkgStructWithPublicMember {
  package var member: PublicStruct
}

// Non-resilient but accessed indirectly; contains existential.
package struct PkgStructWithPublicExistential {
  package var member: any PublicProto
}

// Non-resilient but accessed indirectly; contains existential.
package struct PkgStructWithPkgExistential {
  package var member: any PkgProto
}

// Resilient; public. Acessed indirectly.
public protocol PublicProto {
  var data: Int { get set }
}

// Non-resilient but acessed indirectly; existential.
package protocol PkgProto {
  var data: Int { get set }
}


//--- Client.swift
import Utils

package func f(_ arg: PublicStruct) -> Int {
  return arg.data
}

// CHECK: // f(_:)
// CHECK-NEXT: sil @$s6Client1fySi5Utils12PublicStructVF : $@convention(thin) (@in_guaranteed PublicStruct) -> Int {
// CHECK-NEXT: // %0 "arg"                                       // users: %3, %1
// CHECK-NEXT: bb0(%0 : $*PublicStruct):
// CHECK-NEXT:   debug_value %0 : $*PublicStruct, let, name "arg", argno 1, expr op_deref // id: %1
// CHECK-NEXT:   %2 = alloc_stack $PublicStruct                  // users: %7, %6, %5, %3
// CHECK-NEXT:   copy_addr %0 to [init] %2 : $*PublicStruct      // id: %3
// CHECK-NEXT:   // function_ref PublicStruct.data.getter
// CHECK-NEXT:   %4 = function_ref @$s5Utils12PublicStructV4dataSivg : $@convention(method) (@in_guaranteed PublicStruct) -> Int // user: %5
// CHECK-NEXT:   %5 = apply %4(%2) : $@convention(method) (@in_guaranteed PublicStruct) -> Int // user: %8
// CHECK-NEXT:   destroy_addr %2 : $*PublicStruct                // id: %6
// CHECK-NEXT:   dealloc_stack %2 : $*PublicStruct               // id: %7
// CHECK-NEXT:   return %5 : $Int                                // id: %8
// CHECK-NEXT: } // end sil function '$s6Client1fySi5Utils12PublicStructVF'

// CHECK: // PublicStruct.data.getter
// CHECK-NEXT: sil @$s5Utils12PublicStructV4dataSivg : $@convention(method) (@in_guaranteed PublicStruct) -> Int

package func g(_ arg: PkgStruct) -> Int {
  return arg.data
}

// CHECK: // g(_:)
// CHECK-NEXT: sil @$s6Client1gySi5Utils9PkgStructVF : $@convention(thin) (@in_guaranteed PkgStruct) -> Int {
// CHECK-NEXT: // %0 "arg"                                       // users: %3, %1
// CHECK-NEXT: bb0(%0 : $*PkgStruct):
// CHECK-NEXT:   debug_value %0 : $*PkgStruct, let, name "arg", argno 1, expr op_deref // id: %1
// CHECK-NEXT:   %2 = alloc_stack $PkgStruct                     // users: %7, %6, %5, %3
// CHECK-NEXT:   copy_addr %0 to [init] %2 : $*PkgStruct         // id: %3
// CHECK-NEXT:   // function_ref PkgStruct.data.getter
// CHECK-NEXT:   %4 = function_ref @$s5Utils9PkgStructV4dataSivg : $@convention(method) (@in_guaranteed PkgStruct) -> Int // user: %5
// CHECK-NEXT:   %5 = apply %4(%2) : $@convention(method) (@in_guaranteed PkgStruct) -> Int // user: %8
// CHECK-NEXT:   destroy_addr %2 : $*PkgStruct                   // id: %6
// CHECK-NEXT:   dealloc_stack %2 : $*PkgStruct                  // id: %7
// CHECK-NEXT:   return %5 : $Int                                // id: %8
// CHECK-NEXT: } // end sil function '$s6Client1gySi5Utils9PkgStructVF'

// CHECK: // PkgStruct.data.getter
// CHECK-NEXT: sil @$s5Utils9PkgStructV4dataSivg : $@convention(method) (@in_guaranteed PkgStruct) -> Int

package func m<T>(_ arg: PkgStructGeneric<T>) -> T {
  return arg.data
}

// CHECK: // m<A>(_:)
// CHECK-NEXT: sil @$s6Client1myx5Utils16PkgStructGenericVyxGlF : $@convention(thin) <T> (@in_guaranteed PkgStructGeneric<T>) -> @out T {
// CHECK-NEXT: // %0 "$return_value"                             // user: %6
// CHECK-NEXT: // %1 "arg"                                       // users: %4, %2
// CHECK-NEXT: bb0(%0 : $*T, %1 : $*PkgStructGeneric<T>):
// CHECK-NEXT:   debug_value %1 : $*PkgStructGeneric<T>, let, name "arg", argno 1, expr op_deref // id: %2
// CHECK-NEXT:   %3 = alloc_stack $PkgStructGeneric<T>           // users: %8, %7, %6, %4
// CHECK-NEXT:   copy_addr %1 to [init] %3 : $*PkgStructGeneric<T> // id: %4
// CHECK-NEXT:   // function_ref PkgStructGeneric.data.getter
// CHECK-NEXT:   %5 = function_ref @$s5Utils16PkgStructGenericV4dataxvg : $@convention(method) <τ_0_0> (@in_guaranteed PkgStructGeneric<τ_0_0>) -> @out τ_0_0 // user: %6
// CHECK-NEXT:   %6 = apply %5<T>(%0, %3) : $@convention(method) <τ_0_0> (@in_guaranteed PkgStructGeneric<τ_0_0>) -> @out τ_0_0
// CHECK-NEXT:   destroy_addr %3 : $*PkgStructGeneric<T>         // id: %7
// CHECK-NEXT:   dealloc_stack %3 : $*PkgStructGeneric<T>        // id: %8
// CHECK-NEXT:   %9 = tuple ()                                   // user: %10
// CHECK-NEXT:   return %9 : $()                                 // id: %10
// CHECK-NEXT: } // end sil function '$s6Client1myx5Utils16PkgStructGenericVyxGlF'

// CHECK: // PkgStructGeneric.data.getter
// CHECK-NEXT: sil @$s5Utils16PkgStructGenericV4dataxvg : $@convention(method) <τ_0_0> (@in_guaranteed PkgStructGeneric<τ_0_0>) -> @out τ_0_0


package func n(_ arg: PkgStructWithPublicMember) -> Int {
  return arg.member.data
}

// CHECK: // n(_:)
// CHECK-NEXT: sil @$s6Client1nySi5Utils25PkgStructWithPublicMemberVF : $@convention(thin) (@in_guaranteed PkgStructWithPublicMember) -> Int {
// CHECK-NEXT: // %0 "arg"                                       // users: %3, %1
// CHECK-NEXT: bb0(%0 : $*PkgStructWithPublicMember):
// CHECK-NEXT:   debug_value %0 : $*PkgStructWithPublicMember, let, name "arg", argno 1, expr op_deref // id: %1
// CHECK-NEXT:   %2 = alloc_stack $PkgStructWithPublicMember     // users: %16, %7, %6, %3
// CHECK-NEXT:   copy_addr %0 to [init] %2 : $*PkgStructWithPublicMember // id: %3
// CHECK-NEXT:   %4 = alloc_stack $PublicStruct                  // users: %15, %13, %9, %6
// CHECK-NEXT:   // function_ref PkgStructWithPublicMember.member.getter
// CHECK-NEXT:   %5 = function_ref @$s5Utils25PkgStructWithPublicMemberV6memberAA0eC0Vvg : $@convention(method) (@in_guaranteed PkgStructWithPublicMember) -> @out PublicStruct // user: %6
// CHECK-NEXT:   %6 = apply %5(%4, %2) : $@convention(method) (@in_guaranteed PkgStructWithPublicMember) -> @out PublicStruct
// CHECK-NEXT:   destroy_addr %2 : $*PkgStructWithPublicMember   // id: %7
// CHECK-NEXT:   %8 = alloc_stack $PublicStruct                  // users: %14, %12, %11, %9
// CHECK-NEXT:   copy_addr %4 to [init] %8 : $*PublicStruct      // id: %9
// CHECK-NEXT:   // function_ref PublicStruct.data.getter
// CHECK-NEXT:   %10 = function_ref @$s5Utils12PublicStructV4dataSivg : $@convention(method) (@in_guaranteed PublicStruct) -> Int // user: %11
// CHECK-NEXT:   %11 = apply %10(%8) : $@convention(method) (@in_guaranteed PublicStruct) -> Int // user: %17
// CHECK-NEXT:   destroy_addr %8 : $*PublicStruct                // id: %12
// CHECK-NEXT:   destroy_addr %4 : $*PublicStruct                // id: %13
// CHECK-NEXT:   dealloc_stack %8 : $*PublicStruct               // id: %14
// CHECK-NEXT:   dealloc_stack %4 : $*PublicStruct               // id: %15
// CHECK-NEXT:   dealloc_stack %2 : $*PkgStructWithPublicMember  // id: %16
// CHECK-NEXT:   return %11 : $Int                               // id: %17
// CHECK-NEXT: } // end sil function '$s6Client1nySi5Utils25PkgStructWithPublicMemberVF'

// CHECK: // PkgStructWithPublicMember.member.getter
// CHECK-NEXT: sil @$s5Utils25PkgStructWithPublicMemberV6memberAA0eC0Vvg : $@convention(method) (@in_guaranteed PkgStructWithPublicMember) -> @out PublicStruct


package func p(_ arg: PkgStructWithPublicExistential) -> any PublicProto {
  return arg.member
}

// CHECK: // p(_:)
// CHECK-NEXT: sil @$s6Client1py5Utils11PublicProto_pAC013PkgStructWithC11ExistentialVF : $@convention(thin) (@in_guaranteed PkgStructWithPublicExistential) -> @out any PublicProto {
// CHECK-NEXT: // %0 "$return_value"                             // user: %6
// CHECK-NEXT: // %1 "arg"                                       // users: %4, %2
// CHECK-NEXT: bb0(%0 : $*any PublicProto, %1 : $*PkgStructWithPublicExistential):
// CHECK-NEXT:   debug_value %1 : $*PkgStructWithPublicExistential, let, name "arg", argno 1, expr op_deref // id: %2
// CHECK-NEXT:   %3 = alloc_stack $PkgStructWithPublicExistential // users: %8, %7, %6, %4
// CHECK-NEXT:   copy_addr %1 to [init] %3 : $*PkgStructWithPublicExistential // id: %4
// CHECK-NEXT:   // function_ref PkgStructWithPublicExistential.member.getter
// CHECK-NEXT:   %5 = function_ref @$s5Utils30PkgStructWithPublicExistentialV6memberAA0E5Proto_pvg : $@convention(method) (@in_guaranteed PkgStructWithPublicExistential) -> @out any PublicProto // user: %6
// CHECK-NEXT:   %6 = apply %5(%0, %3) : $@convention(method) (@in_guaranteed PkgStructWithPublicExistential) -> @out any PublicProto
// CHECK-NEXT:   destroy_addr %3 : $*PkgStructWithPublicExistential // id: %7
// CHECK-NEXT:   dealloc_stack %3 : $*PkgStructWithPublicExistential // id: %8
// CHECK-NEXT:   %9 = tuple ()                                   // user: %10
// CHECK-NEXT:   return %9 : $()                                 // id: %10
// CHECK-NEXT: } // end sil function '$s6Client1py5Utils11PublicProto_pAC013PkgStructWithC11ExistentialVF'

// CHECK: // PkgStructWithPublicExistential.member.getter
// CHECK-NEXT: sil @$s5Utils30PkgStructWithPublicExistentialV6memberAA0E5Proto_pvg : $@convention(method) (@in_guaranteed PkgStructWithPublicExistential) -> @out any PublicProto

package func q(_ arg: PkgStructWithPkgExistential) -> any PkgProto {
  return arg.member
}

// CHECK: // q(_:)
// CHECK-NEXT: sil @$s6Client1qy5Utils8PkgProto_pAC0c10StructWithC11ExistentialVF : $@convention(thin) (@in_guaranteed PkgStructWithPkgExistential) -> @out any PkgProto {
// CHECK-NEXT: // %0 "$return_value"                             // user: %6
// CHECK-NEXT: // %1 "arg"                                       // users: %4, %2
// CHECK-NEXT: bb0(%0 : $*any PkgProto, %1 : $*PkgStructWithPkgExistential):
// CHECK-NEXT:   debug_value %1 : $*PkgStructWithPkgExistential, let, name "arg", argno 1, expr op_deref // id: %2
// CHECK-NEXT:   %3 = alloc_stack $PkgStructWithPkgExistential   // users: %8, %7, %6, %4
// CHECK-NEXT:   copy_addr %1 to [init] %3 : $*PkgStructWithPkgExistential // id: %4
// CHECK-NEXT:   // function_ref PkgStructWithPkgExistential.member.getter
// CHECK-NEXT:   %5 = function_ref @$s5Utils013PkgStructWithB11ExistentialV6memberAA0B5Proto_pvg : $@convention(method) (@in_guaranteed PkgStructWithPkgExistential) -> @out any PkgProto // user: %6
// CHECK-NEXT:   %6 = apply %5(%0, %3) : $@convention(method) (@in_guaranteed PkgStructWithPkgExistential) -> @out any PkgProto
// CHECK-NEXT:   destroy_addr %3 : $*PkgStructWithPkgExistential // id: %7
// CHECK-NEXT:   dealloc_stack %3 : $*PkgStructWithPkgExistential // id: %8
// CHECK-NEXT:   %9 = tuple ()                                   // user: %10
// CHECK-NEXT:   return %9 : $()                                 // id: %10
// CHECK-NEXT: } // end sil function '$s6Client1qy5Utils8PkgProto_pAC0c10StructWithC11ExistentialVF'

// CHECK: // PkgStructWithPkgExistential.member.getter
// CHECK-NEXT: sil @$s5Utils013PkgStructWithB11ExistentialV6memberAA0B5Proto_pvg : $@convention(method) (@in_guaranteed PkgStructWithPkgExistential) -> @out any PkgProto

package func r(_ arg: PublicProto) -> Int {
  return arg.data
}

// CHECK: // r(_:)
// CHECK-NEXT: sil @$s6Client1rySi5Utils11PublicProto_pF : $@convention(thin) (@in_guaranteed any PublicProto) -> Int {
// CHECK-NEXT: // %0 "arg"                                       // users: %2, %1
// CHECK-NEXT: bb0(%0 : $*any PublicProto):
// CHECK-NEXT:   debug_value %0 : $*any PublicProto, let, name "arg", argno 1, expr op_deref // id: %1
// CHECK-NEXT:   %2 = open_existential_addr immutable_access %0 : $*any PublicProto to $*@opened({{.*}}, any PublicProto) Self // users: %6, %5, %4, %3
// CHECK-NEXT:   %3 = alloc_stack $@opened("{{.*}}", any PublicProto) Self // type-defs: %2; users: %8, %7, %6, %4
// CHECK-NEXT:   copy_addr %2 to [init] %3 : $*@opened("{{.*}}", any PublicProto) Self // id: %4
// CHECK-NEXT:   %5 = witness_method $@opened("{{.*}}", any PublicProto) Self, #PublicProto.data!getter : <Self where Self : Utils.PublicProto> (Self) -> () -> Int, %2 : $*@opened("{{.*}}", any PublicProto) Self : $@convention(witness_method: PublicProto) <τ_0_0 where τ_0_0 : PublicProto> (@in_guaranteed τ_0_0) -> Int // type-defs: %2; user: %6
// CHECK-NEXT:   %6 = apply %5<@opened("{{.*}}", any PublicProto) Self>(%3) : $@convention(witness_method: PublicProto) <τ_0_0 where τ_0_0 : PublicProto> (@in_guaranteed τ_0_0) -> Int // type-defs: %2; user: %9
// CHECK-NEXT:   destroy_addr %3 : $*@opened("{{.*}}", any PublicProto) Self // id: %7
// CHECK-NEXT:   dealloc_stack %3 : $*@opened("{{.*}}", any PublicProto) Self // id: %8
// CHECK-NEXT:   return %6 : $Int                                // id: %9
// CHECK-NEXT: } // end sil function '$s6Client1rySi5Utils11PublicProto_pF'

package func s(_ arg: PkgProto) -> Int {
  return arg.data
}

// CHECK: // s(_:)
// CHECK-NEXT: sil @$s6Client1sySi5Utils8PkgProto_pF : $@convention(thin) (@in_guaranteed any PkgProto) -> Int {
// CHECK-NEXT: // %0 "arg"                                       // users: %2, %1
// CHECK-NEXT: bb0(%0 : $*any PkgProto):
// CHECK-NEXT:   debug_value %0 : $*any PkgProto, let, name "arg", argno 1, expr op_deref // id: %1
// CHECK-NEXT:   %2 = open_existential_addr immutable_access %0 : $*any PkgProto to $*@opened("{{.*}}", any PkgProto) Self // users: %6, %5, %4, %3
// CHECK-NEXT:   %3 = alloc_stack $@opened("{{.*}}", any PkgProto) Self // type-defs: %2; users: %8, %7, %6, %4
// CHECK-NEXT:   copy_addr %2 to [init] %3 : $*@opened("{{.*}}", any PkgProto) Self // id: %4
// CHECK-NEXT:   %5 = witness_method $@opened("{{.*}}", any PkgProto) Self, #PkgProto.data!getter : <Self where Self : Utils.PkgProto> (Self) -> () -> Int, %2 : $*@opened("{{.*}}", any PkgProto) Self : $@convention(witness_method: PkgProto) <τ_0_0 where τ_0_0 : PkgProto> (@in_guaranteed τ_0_0) -> Int // type-defs: %2; user: %6
// CHECK-NEXT:   %6 = apply %5<@opened("{{.*}}", any PkgProto) Self>(%3) : $@convention(witness_method: PkgProto) <τ_0_0 where τ_0_0 : PkgProto> (@in_guaranteed τ_0_0) -> Int // type-defs: %2; user: %9
// CHECK-NEXT:   destroy_addr %3 : $*@opened("{{.*}}", any PkgProto) Self // id: %7
// CHECK-NEXT:   dealloc_stack %3 : $*@opened("{{.*}}", any PkgProto) Self // id: %8
// CHECK-NEXT:   return %6 : $Int                                // id: %9
// CHECK-NEXT: } // end sil function '$s6Client1sySi5Utils8PkgProto_pF'
