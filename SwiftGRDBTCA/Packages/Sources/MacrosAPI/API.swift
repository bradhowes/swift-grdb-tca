@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(
  module: "Macros",
  type: "Stringify"
)

@freestanding(expression)
public macro fourCharacterCode<T>(_ value: String) -> UInt = #externalMacro(
  module: "Macros",
  type: "FourCharactersCode"
)
