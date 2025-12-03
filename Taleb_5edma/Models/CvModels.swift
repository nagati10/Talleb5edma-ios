// CvModels.swift
//  Taleb_5edma

import Foundation

/// Réponse de ton backend CV (même structure que sur Android)
struct CvStructuredResponse: Codable {
    let name: String?
    let email: String?
    let phone: String?
    let experience: [String]
    let education: [String]
    let skills: [String]
}

/// Body pour PATCH /user/me/cv/profile
struct CreateProfileFromCvRequest: Codable {
    let name: String?
    let email: String?
    let phone: String?
    let experience: [String]?
    let education: [String]?
    let skills: [String]?
}
