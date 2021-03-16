//
//  UtilFunctions.swift
//  
//
//  Created by Chip Jarred on 2/22/21.
//

import Foundation

fileprivate let variableNameMap: [String: String] =
[
    "AppName": ProcessInfo.processInfo.processName,
]

// -------------------------------------
internal var runningDebugBuildInXCTest: Bool
{
    #if DEBUG
    let pInfo = ProcessInfo.processInfo
    return pInfo.environment["XCTestConfigurationFilePath"] != nil
    #else
    return false
    #endif
}

// -------------------------------------
internal func substituteVariables(in s: String) -> String
{
    var result = ""
    
    var i = s.startIndex
    while i != s.endIndex
    {
        let c = s[i]
        let nextI = s.index(after: i)
        
        /*
         If we're at the last character, it doesn't matter if it's special.
         If it's a backslash, there's nothing to escape.  If it's a $, there is
         no variable name.  Either way we treat it as literal, so just add it.
         */
        if nextI != s.endIndex
        {
            if c == "\\"
            {
                // '\' indicates to take an immediately following '\' or '$'
                // literally, otherwise it's just a '\' by itself.
                let nextChar = s[nextI]
                if "\\$".contains(nextChar)
                {
                    result.append(nextChar)
                    i = s.index(after: nextI)
                    continue
                }
            }
            else if c == "$"
            {
                // '$' introduces a variable name
                if let (value, end) = parseVariableName(in: s[nextI...])
                {
                    result.append(value)
                    i = end
                    continue
                }
            }
        }
        
        result.append(c)
        i = nextI
    }
    
    return result
}


// -------------------------------------
/**
 Obtain a localized string to use in place of `s`, from the `"Menus"` table.
 
 - Parameter s: The string to obtain a localized replacement
 
 - Returns: If a localization for `s` appears in the `"Menus"` table, that
    localized string will be returned.  Otherwise `s` is returned.
 */
@inline(__always)
internal func localize<S: StringProtocol>(_ s: S) -> String
{
    return Bundle.main
        .localizedString(forKey: String(s), value: nil, table: "Menus")
}

// -------------------------------------
/**
 Parse a variable of  the form, "(variablename)" and return its value with the
 position in `s` to continue parsing.
 
 Leading and trailing whitespace inside the parentheses is stripped.
 
 - Parameter s: A `Substring` whose beginning
 
 - Returns: If the variable name is well-formed, and if it is defined in the
    process's environment (or is a special valid name), its value is returned
    along with the the index `s` after the ")".   If the name is not
    well-formed or if it doesn't exist, `nil` is returned.
 */
fileprivate func parseVariableName(in s: Substring)
    -> (value: String, end: String.Index)?
{
    guard s.first == "(" else { return nil }
    
    guard let closeParenIndex = s.firstIndex(of: ")") else { return nil }
    
    let varName = removeLeadingAndTrailingWhitesapce(
        from: s[s.index(after: s.startIndex)..<closeParenIndex]
    )
    
    guard let value = value(for: varName) else { return nil }
    return (value, s.index(after: closeParenIndex))
}

// -------------------------------------
fileprivate func removeLeadingAndTrailingWhitesapce(from s: Substring)
    -> String
{
    var name = s[(s.firstIndex { !$0.isWhitespace } ?? s.startIndex)...]
    if let end = name.lastIndex(where: { !$0.isWhitespace }) {
        name = name[...end]
    }
    return String(name)
}

// -------------------------------------
fileprivate func value(for varName: String) -> String?
{
    let pInfo = ProcessInfo.processInfo
    
    if let varValue = variableNameMap[varName] { return varValue }
    
    return pInfo.environment[varName]
}
