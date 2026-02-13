import Foundation
import FirebaseCore

class FirebaseManager: ObservableObject {

    init() {
        FirebaseApp.configure()
        print("Firebase configured")
    }

}
