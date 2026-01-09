import Foundation

class RateLimiter {
    private let queue = DispatchQueue(label: "com.bizdatacollector.ratelimiter")
    private var lastRequestTime: Date?
    private let minDelay: TimeInterval
    
    init(requestsPerSecond: Double) {
        self.minDelay = 1.0 / requestsPerSecond
    }
    
    func perform(_ operation: @escaping () -> Void) {
        queue.async {
            if let lastTime = self.lastRequestTime {
                let elapsed = Date().timeIntervalSince(lastTime)
                let delayNeeded = max(0, self.minDelay - elapsed)
                
                if delayNeeded > 0 {
                    Thread.sleep(forTimeInterval: delayNeeded)
                }
            }
            
            self.lastRequestTime = Date()
            operation()
        }
    }
}