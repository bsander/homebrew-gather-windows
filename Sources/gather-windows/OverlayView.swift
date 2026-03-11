import SwiftUI

/// Large centered number on semi-transparent dark background
struct OverlayView: View {
    let screenNumber: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)

            Text("\(screenNumber)")
                .font(.system(size: 200, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .ignoresSafeArea()
    }
}

/// Centered message on semi-transparent dark background
struct MessageOverlayView: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)

            Text(message)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(40)
        }
        .ignoresSafeArea()
    }
}
