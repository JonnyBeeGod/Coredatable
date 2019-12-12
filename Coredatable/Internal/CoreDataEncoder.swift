//
//  CoreDataEncoder.swift
//  Coredatable
//
//  Created by Manu on 12/12/2019.
//  Copyright © 2019 Manuel García-Estañ. All rights reserved.
//

import Foundation

internal final class CoreDataEncoder<ManagedObject: CoreDataEncodable> {
    private typealias Keys = ManagedObject.CodingKeys
    private typealias KeyedContainer = KeyedEncodingContainer<Keys.Standard>
    
    let encoder: Encoder
    private var skippableRelationships: Set<NSRelationshipDescription>
    
    internal init(encoder: Encoder, skippingRelationships: Set<NSRelationshipDescription> = []) {
        self.encoder = encoder
        self.skippableRelationships = skippingRelationships
    }
    
    func encode(_ object: ManagedObject) throws {
        let container = encoder.container(keyedBy: ManagedObject.CodingKeys.Standard.self)
        try encode(object, with: container)
    }
    
    private func encode(_ object: ManagedObject, with container: KeyedContainer) throws {
        try object.entity.propertiesByName.forEach { property in
            guard let key = ManagedObject.CodingKeys(propertyName: property.key)
                else { return }
            
            if let attribute = property.value as? NSAttributeDescription {
                try encode(attribute, object: object, key: key, container: container)
            } else if let property = property.value as? NSRelationshipDescription {
                try encode(property, object: object, key: key, container: container)
            }
        }
    }
    
    func encode(_ array: [ManagedObject]) throws {
        var container = encoder.unkeyedContainer()
        try array.forEach {
            let childContainer = container.nestedContainer(keyedBy: Keys.Standard.self)
            try encode($0, with: childContainer)
        }
    }
    
    private func encode(_ attribute: NSAttributeDescription, object: ManagedObject, key: Keys, container: KeyedContainer) throws {
        var container = container
        if let value = object.value(forKey: key.propertyName) {
            try container.encodeAny(value, forKey: key.standarized)
        } else {
            try container.encodeNil(forKey: key.standarized)
        }
    }
    
    private func encode(_ relationship: NSRelationshipDescription, object: ManagedObject, key: Keys, container: KeyedContainer) throws {
        guard !skippableRelationships.contains(relationship) else {
            return
        }
        
        _ = relationship.inverseRelationship.map { skippableRelationships.insert($0) }
        
        var container = container
        let standardKey = key.standarized
        guard let value = object.value(forKey: key.propertyName) else {
            try container.encodeNil(forKey: key.standarized)
            return
        }

        
        let className = relationship.destinationEntity?.managedObjectClassName ?? ""
        let theClass: AnyClass? = NSClassFromString(className)
        let childEncoder = container.superEncoder(forKey: standardKey)
        
        if relationship.isToMany {
            let array: [AnyCoreDataEncodable]
            if let set = value as? NSOrderedSet {
                array = set.array.compactMap { $0 as? AnyCoreDataEncodable }
            } else if let set = value as? NSSet {
                array = set.allObjects.compactMap { $0 as? AnyCoreDataEncodable }
            } else {
                array = []
            }
        
            if let encodableClass = theClass as? AnyCoreDataEncodable.Type {
                try encodableClass.encode(array, to: childEncoder, skipping: skippableRelationships)
            } else if let encodableClass = theClass as? Encodable.Type {
                #warning("Test this")
                try encodableClass.encode(array, to: childEncoder)
            } else {
                #warning("NO encodable error")
            }
        } else {
            if let encodable = value as? AnyCoreDataEncodable {
                try encodable.encode(to: childEncoder, skipping: skippableRelationships)
            } else if let encodable = value as? Encodable {
                try encodable.encode(to: childEncoder)
            } else {
                #warning("NO encodable error")
            }
        }
        
        try container.encodeNil(forKey: key.standarized)
    }
}


