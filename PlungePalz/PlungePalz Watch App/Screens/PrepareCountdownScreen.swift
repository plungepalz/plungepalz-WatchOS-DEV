import SwiftUI

struct PrepareCountdownScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject private var waterLockManager = WaterLockManager.shared
    @StateObject private var screenManager = WatchScreenManager()
    @State private var countdown: Double = 15
    private let totalTime: Double = 15
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    @State private var didNavigate = false

    var body: some View {

        // Screen Size
        let screenSize = screenManager.currentScreenSize

        // UI Constants
        let countdownTextTopPadding = WatchGlobalUIConfig.PrepareCountdownScreen.countdownTextTopPadding(for: screenSize)
        let countdownTextFontSize = WatchGlobalUIConfig.PrepareCountdownScreen.countdownTextFontSize(for: screenSize)
        let verticalGapBetweenTitleAndCircle = WatchGlobalUIConfig.PrepareCountdownScreen.verticalGapBetweenTitleAndCircle(for: screenSize)
        let circleSize = WatchGlobalUIConfig.PrepareCountdownScreen.circleSize(for: screenSize)
        
        VStack(spacing: 24) {
            Text("TURN ON WATER LOCK MODE TO START")
                .font(.system(size: countdownTextFontSize, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.top, countdownTextTopPadding)
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)

            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                    .frame(width: circleSize, height: circleSize)

                // Progress ring (reverse direction)
                Circle()
                    .trim(from: 0, to: CGFloat(countdown / totalTime))
                    .stroke(
                        waterLockManager.isSystemWaterLockEnabled ? Color.green : Color.red,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: circleSize, height: circleSize)
                    .animation(.easeInOut(duration: 0.05), value: countdown)

                // Center icon
                Image(systemName: waterLockManager.isSystemWaterLockEnabled ? "drop.degreesign.fill" : "drop.degreesign.slash.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundColor(waterLockManager.isSystemWaterLockEnabled ? .green : .red)
                    .animation(.easeInOut(duration: 0.3), value: waterLockManager.isSystemWaterLockEnabled)
            }
            .padding(.top, verticalGapBetweenTitleAndCircle)

            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
        .environment(\.watchScreenSize, screenManager.currentScreenSize)
        .onReceive(timer) { _ in
            if countdown > 0 {
                countdown -= 0.05
                waterLockManager.checkSystemWaterLockState()
            } else {
                if !waterLockManager.isSystemWaterLockEnabled {
                    countdown = totalTime // Restart countdown if Water Lock is not enabled
                } else if !didNavigate {
                    didNavigate = true
                    navigationManager.goToScreen(.countdownActivated)
                }
            }
        }
    }
}

#if DEBUG
struct PrepareCountdownScreen_Previews: PreviewProvider {
    static var previews: some View {
        PrepareCountdownScreen(navigationManager: NavigationManager())
    }
}
#endif
