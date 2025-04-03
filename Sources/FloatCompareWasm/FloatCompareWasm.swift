import Foundation

import func WAT.wat2wasm
import class WasmKit.Engine
import struct WasmKit.Function
import struct WasmKit.Instance
import struct WasmKit.Module
import class WasmKit.Store
import enum WasmKit.Value
import func WasmKit.parseWasm

/// Converts the wat source to a wasm bytes.
public func str2wasmBytes(_ wat: String) -> Result<[UInt8], Error> {
  Result(catching: { try wat2wasm(wat) })
}

/// Parses the wasm bytes and creates a wasm `Module`.
public func wasm2module(_ wasm: [UInt8]) -> Result<Module, Error> {
  Result(catching: { try parseWasm(bytes: wasm) })
}

/// Loads the file and returns its content.
public func filename2string(_ filename: String) -> IO<String> {
  return {
    Result(catching: { try String(contentsOfFile: filename) })
  }
}

/// Parses the wat source and creates a wasm `Module`.
public func str2module(_ wat: String) -> Result<Module, Error> {
  compose(
    str2wasmBytes,
    wasm2module
  )(wat)
}

/// Loads the wat source and creates a wasm `Module`.
public func filename2module(_ filename: String) -> IO<Module> {
  Bind(
    filename2string(filename),
    Lift(str2module)
  )
}

/// Creates a wasm `Instance` using the specifield `Module` and the `Engine`.
public func instantiate(mdl: Module, eng: Engine = Engine()) -> Result<Instance, Error> {
  let store: Store = Store(engine: eng)
  return Result(catching: {
    try mdl.instantiate(store: store)
  })
}

/// Creates a wasm `Instance` using the wasm `Module`.
public func module2instance(_ mdl: Module) -> Result<Instance, Error> {
  instantiate(mdl: mdl)
}

/// Parses the wat source and creates a wasm `Instance`.
public func str2instance(_ wat: String) -> Result<Instance, Error> {
  compose(
    str2module,
    module2instance
  )(wat)
}

/// Reads the wat file and creates a wasm `Instance`.
public func filename2instance(_ filename: String) -> IO<Instance> {
  Bind(
    filename2module(filename),
    Lift(module2instance)
  )
}

/// Creates a function which converts the `Instance` to a wasm `Function`.
public func instance2func(
  funcname: String = "compare_float"
) -> (Instance) -> Result<Function, Error> {
  return {
    let i: Instance = $0
    guard let f = i.exports[function: funcname] else {
      return .failure(
        FloatCompareWasmErr.invalidArgument(
          "function \( funcname ) missing"
        ))
    }

    return .success(f)
  }
}

/// Compares the float values and returns true if they are "equal".
public typealias CompareFloat = (Float32, Float32) -> Result<Bool, Error>

/// Creates ``CompareFloat`` using the specified wasm `Function`.
public func compare_equal(
  _ wfunc: Function
) -> CompareFloat {
  return {
    let x: Float32 = $0
    let y: Float32 = $1
    let rvalues: Result<[Value], _> = Result(catching: {
      try wfunc([.f32(x.bitPattern), .f32(y.bitPattern)])
    })
    let rval: Result<Value, _> = rvalues.flatMap {
      let values: [Value] = $0
      guard 1 == values.count else {
        return .failure(
          FloatCompareWasmErr.invalidArgument(
            "unexpected return values count: \( values.count )"
          ))
      }
      return .success(values[0])
    }
    return rval.flatMap {
      let v: Value = $0
      guard case let .i32(i) = v else {
        return .failure(
          FloatCompareWasmErr.invalidArgument(
            "unexpected value got: \( v )"
          ))
      }
      return .success(0 == i)
    }
  }
}

/// Creates a function which creates ``CompareFloat`` by using the `Instance`.
public func instance2compare(
  funcname: String = "compare_float"
) -> (Instance) -> Result<CompareFloat, Error> {
  return {
    let instance: Instance = $0
    let i2f: (Instance) -> Result<Function, _> = instance2func(
      funcname: funcname
    )
    let rf: Result<Function, _> = i2f(instance)
    return rf.map {
      let f: Function = $0
      return compare_equal(f)
    }
  }
}

/// Creates ``CompareFloat`` using the specified wat source.
public struct CompareFloatConfig {

  public let funcname: String

  public init(funcname: String = "compare_float32") {
    self.funcname = funcname
  }

  public static func newInstance() -> Self { Self() }

  public func to_compare(_ instance: Instance) -> Result<CompareFloat, Error> {
    instance2compare(
      funcname: self.funcname
    )(instance)
  }

  public func filename2compare(_ watName: String) -> IO<CompareFloat> {
    Bind(
      filename2instance(watName),
      Lift(self.to_compare)
    )
  }

  public func wat2compare(_ wat: String) -> IO<CompareFloat> {
    Bind(
      Lift(str2instance)(wat),
      Lift(self.to_compare)
    )
  }

}
