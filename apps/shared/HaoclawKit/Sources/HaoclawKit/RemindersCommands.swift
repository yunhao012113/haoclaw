import Foundation

public enum HaoclawRemindersCommand: String, Codable, Sendable {
    case list = "reminders.list"
    case add = "reminders.add"
}

public enum HaoclawReminderStatusFilter: String, Codable, Sendable {
    case incomplete
    case completed
    case all
}

public struct HaoclawRemindersListParams: Codable, Sendable, Equatable {
    public var status: HaoclawReminderStatusFilter?
    public var limit: Int?

    public init(status: HaoclawReminderStatusFilter? = nil, limit: Int? = nil) {
        self.status = status
        self.limit = limit
    }
}

public struct HaoclawRemindersAddParams: Codable, Sendable, Equatable {
    public var title: String
    public var dueISO: String?
    public var notes: String?
    public var listId: String?
    public var listName: String?

    public init(
        title: String,
        dueISO: String? = nil,
        notes: String? = nil,
        listId: String? = nil,
        listName: String? = nil)
    {
        self.title = title
        self.dueISO = dueISO
        self.notes = notes
        self.listId = listId
        self.listName = listName
    }
}

public struct HaoclawReminderPayload: Codable, Sendable, Equatable {
    public var identifier: String
    public var title: String
    public var dueISO: String?
    public var completed: Bool
    public var listName: String?

    public init(
        identifier: String,
        title: String,
        dueISO: String? = nil,
        completed: Bool,
        listName: String? = nil)
    {
        self.identifier = identifier
        self.title = title
        self.dueISO = dueISO
        self.completed = completed
        self.listName = listName
    }
}

public struct HaoclawRemindersListPayload: Codable, Sendable, Equatable {
    public var reminders: [HaoclawReminderPayload]

    public init(reminders: [HaoclawReminderPayload]) {
        self.reminders = reminders
    }
}

public struct HaoclawRemindersAddPayload: Codable, Sendable, Equatable {
    public var reminder: HaoclawReminderPayload

    public init(reminder: HaoclawReminderPayload) {
        self.reminder = reminder
    }
}
