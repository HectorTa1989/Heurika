import Foundation

enum KeyboardKey: Equatable, Hashable {
    case character(String)
    case backspace
    case space
    case returnKey
    case shift
    case switchToNumbers
    case switchToSymbols
    case switchToLetters
    case globe
}

enum KeyboardLayer {
    case letters, numbers, symbols
}

/// Pure layout data — deliberately has no UIKit/SwiftUI import so it's cheap
/// to unit test and impossible to accidentally couple to view code.
enum KeyboardLayoutProvider {

    static func rows(for layer: KeyboardLayer, shifted: Bool) -> [[KeyboardKey]] {
        switch layer {
        case .letters: return letterRows(shifted: shifted)
        case .numbers: return numberRows
        case .symbols: return symbolRows
        }
    }

    private static func letterRows(shifted: Bool) -> [[KeyboardKey]] {
        let rows = [
            "qwertyuiop",
            "asdfghjkl",
            "zxcvbnm"
        ]
        let charRows: [[KeyboardKey]] = rows.map { row in
            row.map { .character(shifted ? String($0).uppercased() : String($0)) }
        }
        return [
            charRows[0],
            charRows[1],
            [.shift] + charRows[2] + [.backspace],
            [.switchToNumbers, .globe, .space, .returnKey]
        ]
    }

    private static let numberRows: [[KeyboardKey]] = {
        let row1 = "1234567890".map { KeyboardKey.character(String($0)) }
        let row2 = "-/:;()$&@\"".map { KeyboardKey.character(String($0)) }
        let row3: [KeyboardKey] = [.switchToSymbols] + ".,?!'".map { .character(String($0)) } + [.backspace]
        return [row1, row2, row3, [.switchToLetters, .globe, .space, .returnKey]]
    }()

    private static let symbolRows: [[KeyboardKey]] = {
        let row1 = "[]{}#%^*+=".map { KeyboardKey.character(String($0)) }
        let row2 = "_\\|~<>€£¥•".map { KeyboardKey.character(String($0)) }
        let row3: [KeyboardKey] = [.switchToNumbers] + ".,?!'".map { .character(String($0)) } + [.backspace]
        return [row1, row2, row3, [.switchToLetters, .globe, .space, .returnKey]]
    }()
}
