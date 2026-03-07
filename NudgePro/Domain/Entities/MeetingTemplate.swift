import Foundation

struct MeetingTemplate: Identifiable {
    let id: String
    let name: String

    static let allBuiltIn: [MeetingTemplate] = [
        MeetingTemplate(id: "default", name: "Default"),
        MeetingTemplate(id: "standup", name: "Standup"),
        MeetingTemplate(id: "retro", name: "Retrospective"),
        MeetingTemplate(id: "planning", name: "Sprint Planning"),
        MeetingTemplate(id: "one_on_one", name: "1:1 Meeting"),
    ]
}
