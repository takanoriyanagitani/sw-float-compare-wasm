public typealias IO<T> = () -> Result<T, Error>

public func Bind<T, U>(
  _ io: @escaping IO<T>,
  _ mapper: @escaping (T) -> IO<U>
) -> IO<U> {
  return {
    let rt: Result<T, _> = io()
    return rt.flatMap {
      let t: T = $0
      return mapper(t)()
    }
  }
}

public func Of<T>(_ t: T) -> IO<T> {
  return { .success(t) }
}

public func Lift<T, U>(
  _ pure: @escaping (T) -> Result<U, Error>
) -> (T) -> IO<U> {
  return {
    let t: T = $0
    return {
      pure(t)
    }
  }
}
