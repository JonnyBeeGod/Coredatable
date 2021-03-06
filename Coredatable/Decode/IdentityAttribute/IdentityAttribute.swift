//
//  IdentityAttribute.swift
//  Coredatable
//
//  Created by Manu on 09/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

public struct IdentityAttribute {
    internal let propertyNames: [String]
    fileprivate init(_ propertyNames: Set<String>) {
        self.propertyNames = Array(propertyNames)
    }
    public static var no: IdentityAttribute { IdentityAttribute([]) }
    
    internal var strategy: IdentityAttributeStrategy {
        switch propertyNames.count {
        case 0:
            return NoIdentityAttributesStrategy()
        case 1:
            return SingleIdentityAttributeStrategy(propertyName: propertyNames[0])
        default:
            return CompositeIdentityAttributeStrategy(propertyNames: propertyNames)
        }
    }
}

extension IdentityAttribute: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public init(stringLiteral value: Self.StringLiteralType) {
        self = IdentityAttribute(Set([value]))
    }
}

extension IdentityAttribute: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = String
    public init(arrayLiteral elements: String...) {
        self = IdentityAttribute(Set(elements))
    }
}

internal protocol IdentityAttributeStrategy {
    func existingObject<ManagedObject: CoreDataDecodable>(context: NSManagedObjectContext, decoder: Decoder) throws -> ManagedObject?
    func decodeArray<ManagedObject: CoreDataDecodable>(context: NSManagedObjectContext, decoder: Decoder) throws -> [ManagedObject]
}
