public func compose<T, U, V>(
  _ f: @escaping (T) -> Result<U, Error>,
  _ g: @escaping (U) -> Result<V, Error>
) -> (T) -> Result<V, Error> {
  return {
    let t: T = $0
    let ru: Result<U, _> = f(t)
    return ru.flatMap {
      let u: U = $0
      return g(u)
    }
  }
}
