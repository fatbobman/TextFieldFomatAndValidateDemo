import UIKit

var greeting = "Hello, playground"

let formatter = IntegerFormatStyle<Int>()

let value = try? formatter.parseStrategy.parse("3,45,,66")
print(value)

