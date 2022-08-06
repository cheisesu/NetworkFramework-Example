//
//  Letter+DateFormat.swift
//  NetworkFramework-Example
//
//  Created by Дмитрий Шелонин on 06.08.2022.
//

import Foundation
import NetworkCommon

extension Letter {
    var formattedDate: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "d MMM yyyy, HH:mm"
        }
        let result = formatter.string(from: date)
        return result
    }
}
