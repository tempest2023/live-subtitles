import SwiftUI

class ColorSchemeManager: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    
    func toggleColorScheme() {
        isDarkMode.toggle()
    }
} 