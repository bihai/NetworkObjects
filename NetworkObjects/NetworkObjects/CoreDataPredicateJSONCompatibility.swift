//
//  CoreDataPredicateJSONCompatibility.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 2/2/15.
//  Copyright (c) 2015 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Internal Extensions

extension NSPredicate {
    
    func toJSON(#entity: NSEntityDescription, managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String) -> [String : AnyObject] {
        
        NSException(name: NSInternalInconsistencyException, reason: "NSPredicate cannot be converted to JSON, only its subclasses", userInfo: nil).raise()
        
        return [String: AnyObject]()
    }
    
    convenience init?(JSONObject: [String: AnyObject]) {
        
        self.init(format: "")
        
        return nil
    }
}

extension NSComparisonPredicate {
    
    override func toJSON(#entity: NSEntityDescription, managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String) -> [String: AnyObject] {
        
        if self.predicateOperatorType == NSPredicateOperatorType.CustomSelectorPredicateOperatorType {
            
            NSException(name: NSInternalInconsistencyException, reason: "Comparison Predicates with NSCustomSelectorPredicateOperatorType cannot be serialized to JSON for NetworkObjects Server/Store use", userInfo: nil).raise()
        }
        
        var jsonObject = [String: AnyObject]()
        
        // set primitive parameters
        jsonObject[SearchComparisonPredicateParameter.Operator.rawValue] = predicateOperatorType.rawValue
        jsonObject[SearchComparisonPredicateParameter.Option.rawValue] = options.rawValue
        jsonObject[SearchComparisonPredicateParameter.Modifier.rawValue] = comparisonPredicateModifier.rawValue
        
        // set expressions
        jsonObject[SearchComparisonPredicateParameter.LeftExpression.rawValue] = leftExpression.toJSON(entity: entity, managedObjectContext: managedObjectContext, resourceIDAttributeName: resourceIDAttributeName)
        jsonObject[SearchComparisonPredicateParameter.RightExpression.rawValue] = rightExpression.toJSON(entity: entity,managedObjectContext: managedObjectContext, resourceIDAttributeName: resourceIDAttributeName)
        
        return jsonObject
    }
    
}

extension NSCompoundPredicate {
    
    override func toJSON(#entity: NSEntityDescription, managedObjectContext: NSManagedObjectContext, resourceIDAttributeName: String) -> [String: AnyObject] {
        
        var jsonObject = [String: AnyObject]()
        
        // compound type is string
        jsonObject[SearchCompoundPredicateParameter.PredicateType.rawValue] = SearchCompoundPredicateType(compoundPredicateTypeValue: self.compoundPredicateType).rawValue
        
        var subpredicateJSONArray = [[String: AnyObject]]()
        
        for predicate in self.subpredicates as [NSPredicate] {
            
            let predicateJSONObject = predicate.toJSON(entity: entity, managedObjectContext: managedObjectContext, resourceIDAttributeName: resourceIDAttributeName)
            
            subpredicateJSONArray.append(predicateJSONObject)
        }
        
        // set subpredicates
        jsonObject[SearchCompoundPredicateParameter.Subpredicates.rawValue] = subpredicateJSONArray
        
        return jsonObject
    }
}

// MARK: Functions

func SearchComparisonPredicateOptionsToNSComparisonPredicateOptions(comparisonPredicateOptions: [SearchComparisonPredicateOption]) -> NSComparisonPredicateOptions {
    
    var rawOptionValue: UInt = NSComparisonPredicateOptions.allZeros.rawValue
    
    for option in comparisonPredicateOptions {
        
        let convertedOption = option.toComparisonPredicateOptions()
        
        rawOptionValue = rawOptionValue | convertedOption.rawValue
    }
    
    return NSComparisonPredicateOptions(rawOptionValue)
}

// MARK: - Enumerations

/** The different types of predicates supported for search requests. */
public enum SearchPredicateType: String {
    
    /** The predicate is a comparison type (NSComparisonPredicate). */
    case Comparison = "Comparison"
    
    /** The predicate is a compound type (NSCompoundPredicate). */
    case Compound = "Compound"
}

// MARK: Comparison Predicate

/** The parameters for a comparison predicate. */
public enum SearchComparisonPredicateParameter: String {
    
    case Key = "Key"
    case Value = "Value"
    case Operator = "Operator"
    case Options = "Options"
    case Modifier = "Modifier"
}

public enum SearchComparisonPredicateOperator: String {
    
    case LessThan = "<"
    case LessThanOrEqualTo = "<="
    case GreaterThan = ">"
    case GreaterThanOrEqualTo = ">="
    case EqualTo = "="
    case NotEqualTo = "!="
    case Matches = "MATCHES"
    case Like = "LIKE"
    case BeginsWith = "BEGINSWITH"
    case EndsWith = "ENDSWITH"
    case In = "IN"
    case Contains = "CONTAINS"
    case Between = "BETWEEN"
    
    public func toPredicateOperatorType() -> NSPredicateOperatorType {
        switch self {
        case .LessThan: return .LessThanPredicateOperatorType
        case .LessThanOrEqualTo: return .LessThanOrEqualToPredicateOperatorType
        case .GreaterThan: return .GreaterThanPredicateOperatorType
        case .GreaterThanOrEqualTo: return .GreaterThanOrEqualToPredicateOperatorType
        case .EqualTo: return .EqualToPredicateOperatorType
        case .NotEqualTo: return .NotEqualToPredicateOperatorType
        case .Matches: return .MatchesPredicateOperatorType
        case .Like: return .LikePredicateOperatorType
        case .BeginsWith: return .BeginsWithPredicateOperatorType
        case .EndsWith: return .EndsWithPredicateOperatorType
        case .In: return .InPredicateOperatorType
        case .Contains: return .ContainsPredicateOperatorType
        case .Between: return .BetweenPredicateOperatorType
        }
    }
    
    public init?(predicateOperatorTypeValue: NSPredicateOperatorType) {
        switch predicateOperatorTypeValue {
        case .LessThanPredicateOperatorType: self = .LessThan
        case .LessThanOrEqualToPredicateOperatorType: self = .LessThanOrEqualTo
        case .GreaterThanPredicateOperatorType: self = .GreaterThan
        case .GreaterThanOrEqualToPredicateOperatorType: self = .GreaterThanOrEqualTo
        case .EqualToPredicateOperatorType: self = .EqualTo
        case .NotEqualToPredicateOperatorType: self = .NotEqualTo
        case .MatchesPredicateOperatorType: self = .Matches
        case .LikePredicateOperatorType: self = .Like
        case .BeginsWithPredicateOperatorType: self = .BeginsWith
        case .EndsWithPredicateOperatorType: self = .EndsWith
        case .InPredicateOperatorType: self = .In
        case .ContainsPredicateOperatorType: self = .Contains
        case .BetweenPredicateOperatorType: self = .Between
        default: return nil
        }
    }
}

public enum SearchComparisonPredicateOption: String {
    
    case CaseInsensitive = "[c]"
    case DiacriticInsensitive = "[d]"
    case Normalized = "[n]"
    case LocaleSensitive = "[l]"
    
    public func toComparisonPredicateOptions() -> NSComparisonPredicateOptions {
        switch self {
        case .CaseInsensitive: return .CaseInsensitivePredicateOption
        case .DiacriticInsensitive: return .DiacriticInsensitivePredicateOption
        case .Normalized: return .NormalizedPredicateOption
        case .LocaleSensitive: return NSComparisonPredicateOptions(rawValue: 0x08)
        }
    }
    
    public init?(comparisonPredicateOptionsValue: NSComparisonPredicateOptions) {
        
        
    }
}

public enum

// MARK: - Compound Predicate

/** The parameters for a compound predicate. */
public enum SearchCompoundPredicateParameter: String {
    
    case PredicateType = "PredicateType"
    case Subpredicates = "Subpredicates"
}

/** Type of compound predicate. */
public enum SearchCompoundPredicateType: String {
    
    case Not = "Not"
    case And = "And"
    case Or = "Or"
    
    public init(compoundPredicateTypeValue: NSCompoundPredicateType) {
        switch compoundPredicateTypeValue {
        case .NotPredicateType: self = .Not
        case .AndPredicateType: self = .And
        case .OrPredicateType: self = .Or
        }
    }
    
    public func toCompoundPredicateType() -> NSCompoundPredicateType {
        switch self {
        case .Not: return .NotPredicateType
        case .And: return .AndPredicateType
        case .Or: return .OrPredicateType
        }
    }
}
