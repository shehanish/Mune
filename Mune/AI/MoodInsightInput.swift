//
//  MoodInsightInput.swift
//  Mend
//
//  Created by Shehani Hansika on 12.05.26.
//


import Foundation

struct MoodInsightInput: Encodable {
    let startDate: Date
    let endDate: Date
    let moodCounts: [String: Int]
    let notes: [String]
}