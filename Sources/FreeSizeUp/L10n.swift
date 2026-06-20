import Foundation

struct L10n {
    @MainActor
    static func tr(_ key: String) -> String {
        let language = Settings.shared.language
        
        if language == "system" {
            return NSLocalizedString(key, comment: "")
        }
        
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }
        
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
