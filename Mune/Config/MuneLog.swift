import Foundation

enum MuneLog {
    static func debug(_ message: @autoclosure () -> String) {
        #if DEBUG
        print(message())
        #endif
    }
}
