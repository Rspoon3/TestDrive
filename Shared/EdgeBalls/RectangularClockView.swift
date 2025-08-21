import SwiftUI

struct RectangularClockView: View {
    @State private var showPath = true
    
    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geometry in
                let rect = CGRect(
                    x: 20,
                    y: 20,
                    width: geometry.size.width - 40,
                    height: geometry.size.height - 40
                )
                
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    RectangularClockFace(rect: rect, showPath: showPath)
                    
                    BallIndicator(rect: rect, date: timeline.date, timeUnit: .hours)
                    BallIndicator(rect: rect, date: timeline.date, timeUnit: .minutes)
                    BallIndicator(rect: rect, date: timeline.date, timeUnit: .seconds)
                    
                    Text(timeline.date.formatted(date: .omitted, time: .complete))
                        .foregroundStyle(.white)
                }
                .onTapGesture(count: 2) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showPath.toggle()
                    }
                }
            }
        }
    }
}

#Preview {
    RectangularClockView()
}
