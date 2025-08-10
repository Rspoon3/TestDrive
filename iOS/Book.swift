import Foundation
import SharingGRDB

@Table
struct Book: Codable, Hashable, Identifiable {
    @Column("id")
    let id: Int64
    
    @Column("title")
    var title: String = ""
    
    @Column("author")
    var author: String = ""
    
    @Column("year_published")
    var yearPublished: Int = 2024
    
    @Column("is_available")
    var isAvailable: Bool = true
    
    @Column("created_at")
    var createdAt: Date = Date()
}
