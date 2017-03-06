/*
 * Copyright (c) 2017 N26 GmbH.
 *
 * This file is part of Bob.
 *
 * Bob is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Bob is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Bob.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation

class PrefixedMessageSender: MessageSender {
    private let prefix: String
    private let sender: MessageSender
    
    init(prefix: String, sender: MessageSender) {
        self.prefix = prefix
        self.sender = sender
    }
    
    func send(_ message: String) {
        let prefixedMessage = "*" + self.prefix + "* " + message
        self.sender.send(prefixedMessage)
    }
    
}
