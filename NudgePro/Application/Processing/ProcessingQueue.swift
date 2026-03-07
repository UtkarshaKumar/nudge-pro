import Foundation

class ProcessingQueue {
    func processSession(_ session: Session) async throws -> Session {
        var processed = session
        processed.status = .completed
        return processed
    }
}
