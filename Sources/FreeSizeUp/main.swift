import Cocoa

// Initialize NSApplication and bind our AppDelegate
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Run application loop
app.run()
