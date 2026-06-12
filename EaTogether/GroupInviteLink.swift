//
//  GroupInviteLink.swift
//  EaTogether
//
//  Created by Codex on 2026/06/08.
//

import Foundation

/// グループ招待用のDeep Linkを作成・解析します。
struct GroupInviteLink {
    static let scheme = "eatogether"
    static let host = "join"

    let groupId: String

    /// QRコードに入れる招待URLを作ります。
    var url: URL? {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = Self.host
        components.path = "/\(normalizedGroupId)"
        return components.url
    }

    /// Deep LinkからグループIDを取り出します。
    static func groupId(from url: URL) -> String? {
        guard url.scheme == scheme, url.host == host else { return nil }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }

        let queryGroupId = components.queryItems?
            .first(where: { $0.name == "groupId" })?
            .value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased() ?? ""
        if !queryGroupId.isEmpty {
            return queryGroupId
        }

        let pathGroupId = components.path
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        return pathGroupId.isEmpty ? nil : pathGroupId
    }

    private var normalizedGroupId: String {
        groupId.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}
