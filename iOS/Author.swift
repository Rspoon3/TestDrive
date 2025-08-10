//
//  Author.swift
//  TestDrive (iOS)
//
//  Created by Ricky Witherspoon on 8/9/25.
//

import Foundation
import SharingGRDB

@Table
struct Author: Codable, Hashable, Identifiable {
    @Column("id")
    let id: Int64
    
    @Column("name")
    var name: String = ""
    
    @Column("birth_year")
    var birthYear: Int? = nil
    
    @Column("nationality")
    var nationality: String = ""
    
    @Column("is_active")
    var isActive: Bool = true
    
    @Column("created_at")
    var createdAt: Date = Date()
}
