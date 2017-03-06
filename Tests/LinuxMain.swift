//
//  LinuxMain.swift
//  Bob
//
//  Created by Vincent Audoire on 2/5/17.
//
//
#if os(Linux)

import XCTest
@testable import BobTests

XCTMain([
    testCase(CommandFactoryTests.allTests),
    testCase(CommandProcessorTests.allTests),
    testCase(PrefixedMessageSenderTests.allTests),
    testCase(CommandExecutorTests.allTests),
    ])

#endif
