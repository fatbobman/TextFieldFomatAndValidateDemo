//
//  ByPureSwiftUI.swift
//  TextFieldFomatAndValidate
//
//  Created by Yang Xu on 2021/10/11.
//

import Foundation
import SwiftUI

struct FormatAndValidateByPureSwiftUIView: View {
    @StateObject var intStore = NumberStore(text: "",
                                            type: .int,
                                            maxLength: 5,
                                            allowNagative: true,
                                            formatter: IntegerFormatStyle<Int>())

    @StateObject var doubleStore = NumberStore(text: "",
                                               type: .double,
                                               maxLength: .max,
                                               allowNagative: true,
                                               formatter: FloatingPointFormatStyle<Double>()
                                                   .precision(.fractionLength(0...3))
                                                   .rounded(rule: .towardZero))
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Int (-1000...1000) current:\(intStore.result ?? 0)")) {
                    TextField("-1000...1000", text: $intStore.text)
                        .formatAndValidate(intStore) { $0 < -1000 || $0 > 1000 }
                }

                Section(header: Text("Double (-1000...1000) \(doubleStore.result ?? 0 ,format: .number.precision(.fractionLength(0...3)))")) {
                    TextField("-1000...1000", text: $doubleStore.text)
                        .formatAndValidate(doubleStore) { $0 < -1000 || $0 > 1000 }
                }
            }
            .navigationTitle("By SwiftUI")
        }
    }
}

extension View {
    @ViewBuilder
    func formatAndValidate<T: Numeric, F: ParseableFormatStyle>(_ numberStore: NumberStore<T, F>, errorCondition: @escaping (T) -> Bool) -> some View {
        onChange(of: numberStore.text) { text in
            if let value = numberStore.getValue(),!errorCondition(value) {
                numberStore.error = false
            } else if text.isEmpty || text == numberStore.minusCharacter {
                numberStore.error = false
            } else { numberStore.error = true }
        }
        .foregroundColor(numberStore.error ? .red : .primary)
        .disableAutocorrection(true)
        .autocapitalization(.none)
        .onSubmit {
            if numberStore.text.count > 1 && numberStore.text.suffix(1) == numberStore.decimalSeparator {
                numberStore.text.removeLast()
            }
        }
    }
}

class NumberStore<T: Numeric, F: ParseableFormatStyle>: ObservableObject where F.FormatOutput == String, F.FormatInput == T {
    @Published var text: String
    let type: ValidationType
    let maxLength: Int
    let allowNagative: Bool
    private var backupText: String
    var error: Bool = false
    private let locale: Locale
    let formatter: F

    init(text: String = "",
         type: ValidationType,
         maxLength: Int = 18,
         allowNagative: Bool = false,
         formatter: F,
         locale: Locale = .current)
    {
        self.text = text
        self.type = type
        self.allowNagative = allowNagative
        self.formatter = formatter
        self.locale = locale
        backupText = text
        self.maxLength = maxLength == .max ? .max - 1 : maxLength
    }

    var result: T? {
        try? formatter.parseStrategy.parse(text)
    }

    func restore() {
        text = backupText
    }

    func backup() {
        backupText = text
    }

    lazy var decimalSeparator: String = {
        locale.decimalSeparator ?? "."
    }()

    private lazy var groupingSeparator: String = {
        locale.groupingSeparator ?? ""
    }()

    let minusCharacter = "-"

    private lazy var characters: String = {
        let number = "0123456789"
        switch type {
        case .int:
            return number + (allowNagative ? minusCharacter : "")
        case .double:
            return number + (allowNagative ? minusCharacter : "") + decimalSeparator
        }
    }()

    var minusCount: Int {
        text.components(separatedBy: minusCharacter).count - 1
    }

    // 检查是否为有效输入字符
    func characterValidator() -> Bool {
        text.allSatisfy { characters.contains($0) }
    }

    // 返回验证后的数字
    func getValue() -> T? {
        // 特殊处理（无内容、只有负号、浮点数首字母为小数点）
        if text.isEmpty || text == minusCharacter || (type == .double && text == decimalSeparator) {
            backup()
            return nil
        }

        // 用去除组分隔符后的字符串判断字符是否有效
        let pureText = text.replacingOccurrences(of: groupingSeparator, with: "")
        guard pureText.allSatisfy({ characters.contains($0) }) else {
            restore()
            return nil
        }

        // 处理多个小数点情况
        if type == .double {
            if text.components(separatedBy: decimalSeparator).count > 2 {
                restore()
                return nil
            }
        }

        // 多个负号情况
        if minusCount > 1 {
            restore()
            return nil
        }

        // 负号必须为首字母
        if minusCount == 1, !text.hasPrefix("-") {
            restore()
            return nil
        }

        // 判断长度
        guard text.count < maxLength + minusCount else {
            restore()
            return nil
        }

        // 将文字转换成数字，然后在转换为文字（保证文字格式正确）
        if let value = try? formatter.parseStrategy.parse(text) {
            let hasDecimalCharacter = text.contains(decimalSeparator)
            text = formatter.format(value)
            // 保护最后的小数点（不特别处理的话，转换回来的文字可能不包含小数点）
            if hasDecimalCharacter, !text.contains(decimalSeparator) {
                text.append(decimalSeparator)
            }
            backup()
            return value
        } else {
            restore()
            return nil
        }
    }

    enum ValidationType {
        case int
        case double
    }
}
