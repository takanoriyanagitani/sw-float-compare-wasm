import Testing

import typealias FloatCompareWasm.IO
import typealias FloatCompareWasm.CompareFloat

@testable import struct FloatCompareWasm.CompareFloatConfig

struct CompareFloatConfigTests_wat2compare {

  @Test
  func invalidWat(){
    let invalidWat: String = """
      (module
    """

    let cfg: CompareFloatConfig = .newInstance()
    let icmp: IO<CompareFloat> = cfg.wat2compare(invalidWat)
    let rcmp: Result<CompareFloat, _> = icmp()
    if case .success(_) = rcmp {
      Issue.record("Expected to fail")
      return
    }
  }

  @Test
  func noFunc(){
    let wat: String = """
      (module
      )
    """

    let cfg: CompareFloatConfig = .newInstance()
    let icmp: IO<CompareFloat> = cfg.wat2compare(wat)
    let rcmp: Result<CompareFloat, _> = icmp()
    if case .success(_) = rcmp {
      Issue.record("Expected to fail")
      return
    }
  }

  @Test
  func dummyEqual(){
    let wat: String = """
      (module
        (func $cmp32f (param $_x f32) (param $_y f32) (result i32)
          i32.const 0
        )

        (export "compare_float32" (func $cmp32f))
      )
    """

    let cfg: CompareFloatConfig = .newInstance()
    let icmp: IO<CompareFloat> = cfg.wat2compare(wat)
    let rcmp: Result<CompareFloat, _> = icmp()
    let cmp: CompareFloat = try! rcmp.get()
    let rb: Result<Bool, _> = cmp(3.776, 3.777)
    let b: Bool = try! rb.get()
    #expect(b)
  }

  @Test
  func dummyNotEqual(){
    let wat: String = """
      (module
        (func $cmp32f (param $_x f32) (param $_y f32) (result i32)
          i32.const 42
        )

        (export "compare_float32" (func $cmp32f))
      )
    """

    let cfg: CompareFloatConfig = .newInstance()
    let icmp: IO<CompareFloat> = cfg.wat2compare(wat)
    let rcmp: Result<CompareFloat, _> = icmp()
    let cmp: CompareFloat = try! rcmp.get()
    let rb: Result<Bool, _> = cmp(3.776, 3.777)
    let eq: Bool = try! rb.get()
    let neq: Bool = !eq
    #expect(neq)
  }

  @Test
  func unexpectedArg(){
    let wat: String = """
      (module
        (func $cmp32f (param $_x i32) (param $_y f32) (result i32)
          i32.const 42
        )

        (export "compare_float32" (func $cmp32f))
      )
    """

    let cfg: CompareFloatConfig = .newInstance()
    let icmp: IO<CompareFloat> = cfg.wat2compare(wat)
    let rcmp: Result<CompareFloat, _> = icmp()
    let cmp: CompareFloat = try! rcmp.get()
    let rb: Result<Bool, _> = cmp(3.776, 3.777)
    if case .success(_) = rb {
      Issue.record("Expected to fail")
      return
    }
  }

  @Test
  func unexpectedReturn(){
    let wat: String = """
      (module
        (func $cmp32f (param $_x f32) (param $_y f32) (result f32)
          f32.const 42.0
        )

        (export "compare_float32" (func $cmp32f))
      )
    """

    let cfg: CompareFloatConfig = .newInstance()
    let icmp: IO<CompareFloat> = cfg.wat2compare(wat)
    let rcmp: Result<CompareFloat, _> = icmp()
    let cmp: CompareFloat = try! rcmp.get()
    let rb: Result<Bool, _> = cmp(3.776, 3.777)
    if case .success(_) = rb {
      Issue.record("Expected to fail")
      return
    }
  }

  @Test
  func almostEqual(){
    let ratiop: Float32 = 1.0
    let wat: String = """
      (module
        (func $cmp32f (param $x f32) (param $y f32) (result i32)
          ;; computes absolute difference
          local.get $x
          local.get $y
          f32.sub
          f32.abs

          local.get $x
          local.get $y
          f32.max

          ;; computes ratio: abs(x-y)/max(x,y), unit: %
          f32.div
          f32.const 100.0
          f32.mul

          ;; returns 0 if the ratio < 1%
          f32.const \( ratiop )
          f32.gt
        )

        (export "compare_float32" (func $cmp32f))
      )
    """

    let cfg: CompareFloatConfig = .newInstance()
    let icmp: IO<CompareFloat> = cfg.wat2compare(wat)
    let rcmp: Result<CompareFloat, _> = icmp()
    let cmp: CompareFloat = try! rcmp.get()
    #expect(try! cmp(3.777, 3.776).get())
    #expect(try! cmp(3.776, 3.776).get())
    #expect(try! cmp(3.775, 3.776).get())
    #expect(try! cmp(3.770, 3.776).get())
    #expect(!(try! cmp(3.700, 3.776).get()))
    #expect(!(try! cmp(3.000, 3.776).get()))
    #expect(!(try! cmp(0.000, 3.776).get()))
  }

}
