//
//  ByIntrospect.swift
//  TextFieldFomatAndValidate
//
//  Created by Yang Xu on 2021/10/11.
//

import Foundation
import Introspect
import SwiftUI

struct FormatAndValidateByIntrospectView: View {
    @State var intValue: Int = 0
    @State var doubleValue: Double = 0

    let intDelegate = ValidationDelegate(type: .int, maxLength: 6)
    let doubleDelegate = ValidationDelegate(type: .double, allowNagative: true)

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Int (0...1000)  current:\(intValue)")) {
                    TextField("0...1000", value: $intValue, format: .number)
                        .addTextFieldDelegate(delegate: intDelegate)
                        .numberValidator(value: intValue) { $0 < 0 || $0 > 1000 }
                        .keyboardType(.numberPad)
                }
                Section(header: Text("Double (-1000...1000) current:\(doubleValue, format: .number.precision(.fractionLength(0...2)))")) {
                    TextField("-1000...1000", value: $doubleValue, format: .number.precision(.fractionLength(0...2)))
                        .addTextFieldDelegate(delegate: doubleDelegate)
                        .numberValidator(value: doubleValue, errorCondition: { $0 < -1000 || $0 > 1000 })
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("By IntrospectView")
        }
    }
}

extension View {
    func numberValidator<T: Numeric>(value: T, errorCondition: (T) -> Bool) -> some View {
        foregroundColor(errorCondition(value) ? .red : .primary)
    }

    func addTextFieldDelegate(delegate: UITextFieldDelegate) -> some View {
        introspectTextField { td in
            td.delegate = delegate
        }
    }
}

class ValidationDelegate: NSObject, UITextFieldDelegate {
    private let type: ValidationType
    private let maxLength: Int
    private let locale: Locale
    private let allowNagative: Bool

    private lazy var decimalSeparator: String = {
        locale.decimalSeparator ?? "."
    }()

    private lazy var groupingSeparator: String = {
        locale.groupingSeparator ?? ""
    }()

    var text:String = ""

    private lazy var characters: String = {
        let number = "0123456789"
        switch type {
        case .int:
            return number + (allowNagative ? minusCharacter : "")
        case .double:
            return number + (allowNagative ? minusCharacter : "") + decimalSeparator
        }
    }()

    private let minusCharacter = "-"
    private let numberCharacters = "0123456789"

    init(type: ValidationType, maxLength: Int = 18, allowNagative: Bool = false, locale: Locale = .current) {
        self.type = type
        self.maxLength = maxLength
        self.allowNagative = allowNagative
        self.locale = locale
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text ?? ""
        return validator(text: text, replacementString: string)
    }

    private func validator(text: String, replacementString string: String) -> Bool {
        // 判断有效字符
        guard string.allSatisfy({ characters.contains($0) }) else { return false }
        let totalText = text + string

        // 检查小数点
        if type == .double, text.contains(decimalSeparator), string.contains(decimalSeparator) {
            return false
        }

        // 检查负号
        let minusCount = totalText.components(separatedBy: minusCharacter).count - 1

        if minusCount > 1 {
            return false
        }
        if minusCount == 1, !totalText.hasPrefix("-") {
            return false
        }
        guard totalText.count < maxLength + minusCount else {
            return false
        }
        return true
    }

    enum ValidationType {
        case int
        case double
    }
}
