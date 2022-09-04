import Foundation
import NetworkCommon

let server = try Server(8888)
try server.startSync()
