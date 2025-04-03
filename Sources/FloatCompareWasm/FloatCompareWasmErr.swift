/// Simple error type.
public enum FloatCompareWasmErr: Error {
  case invalidArgument(String)

  case unimplemented(String)
}
