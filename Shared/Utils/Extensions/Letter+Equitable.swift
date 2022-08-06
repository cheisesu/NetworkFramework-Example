//
//  Letter+Equitable.swift
//  NetworkFramework-Example
//
//  Created by Дмитрий Шелонин on 06.08.2022.
//

import Foundation
import NetworkCommon

extension Letter: Equatable {
    public static func == (lhs: Letter, rhs: Letter) -> Bool {
        return lhs.id == rhs.id
    }
}
