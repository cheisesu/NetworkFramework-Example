//
//  Letter.swift
//  NetworkCommon
//
//  Created by Дмитрий Шелонин on 06.08.2022.
//

import Foundation

public struct Letter: Codable {
    public let id: UUID
    public let senderId: UUID
    public let receiverId: UUID
    public let date: Date
    public let text: String
    
    public init(id: UUID = UUID(uuid: UUID_NULL), senderId: UUID, receiverId: UUID, date: Date, text: String) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.date = date
        self.text = text
    }
}
