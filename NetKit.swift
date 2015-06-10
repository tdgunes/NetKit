
//
//  Logger.swift
//  GeoPolicy - Socivy
//
//  Created by Taha Doğan Güneş on 10/06/15.
//  Copyright (c) 2015 Taha Doğan Güneş. All rights reserved.
//


import Foundation

private let _LoggerInstance = Logger()

class Logger {
    let DEBUG:Bool = true
    
    func log(object:AnyObject, message:String){
        if DEBUG {
            println("[\(object)] \(message)")
        }
    }
    class var sharedInstance: Logger {
        return _LoggerInstance
    }
}


//
//  LowLevelLayer.swift
//  GeoPolicy - Socivy
//
//  Created by Taha Doğan Güneş on 10/06/15.
//  Copyright (c) 2015 Taha Doğan Güneş. All rights reserved.
//


protocol LowLevelLayerDelegate {
    func requestFailWithError(error:NSError)
    func requestDidFinish(response:NSMutableData)
}


class LowLevelLayer: NSObject, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    
    var responseData : NSMutableData = NSMutableData()
    var delegate: LowLevelLayerDelegate?
    
    func request(urlRequest:NSMutableURLRequest){
        let conn = NSURLConnection(request:urlRequest, delegate: self, startImmediately: true)
    }
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        responseData = NSMutableData()
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        responseData.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        self.delegate?.requestDidFinish(responseData)
    }
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.delegate?.requestFailWithError(error)
    }
    
}

//
//  NetworkLibrary.swift
//  GeoPolicy - Socivy
//
//  Created by Taha Doğan Güneş on 10/06/15.
//  Copyright (c) 2015 Taha Doğan Güneş. All rights reserved.
//


enum HTTPMethod: String {
    case POST = "POST"
    case DELETE = "DELETE"
    case GET = "GET"
}

protocol NetworkLibraryDelegate {
    func requestFailWithError(errorCode:NetworkLibraryErrorCode, error:NSError?)
    func requestDidFinish(response:NSMutableData)
}
enum NetworkLibraryErrorCode: Int {
    case MalformedURL = 0
    case HasNSError = 1
}

class NetworkLibrary : LowLevelLayerDelegate{
    // configuration
    let tag = "nlib"
    let timeoutInterval = 20.0 // seconds
    var delegate : NetworkLibraryDelegate?
    
    // request details
    var url:String
    var httpMethod:HTTPMethod
    var responseData : NSMutableData? = NSMutableData()
    var headers:[String:String]?
    var postData:String?
    
    
    // handlers
    var completionHandler:((response:NSMutableData)->())?
    var errorHandler:((error:NSError, errorCode:NetworkLibraryErrorCode)->Void)?
    
    init(url:String, headers:[String:String]?, postData:String?, httpMethod:HTTPMethod){
        self.url = url
        self.headers = headers
        self.postData = postData
        self.httpMethod = httpMethod
    }
    
    func request(){
        var lowLevelLayer = LowLevelLayer()
        lowLevelLayer.delegate = self
        if let urlRequest = self.generateHTTPRequest(){
            lowLevelLayer.request(urlRequest)
        }
    }
    
    func requestDidFinish(response: NSMutableData) {
        self.delegate?.requestDidFinish(response)
        if let handler = self.completionHandler {
            handler(response: response)
        }
    }
    
    func requestFailWithError(error: NSError) {
        self.delegate?.requestFailWithError(.HasNSError, error:error)
        if let handler = self.errorHandler {
            handler(error: error, errorCode: .HasNSError)
        }
    }
    
    func generateHTTPRequest() -> NSMutableURLRequest? {
        Logger.sharedInstance.log(tag, message: url)
        
        if let url = NSURL(string:self.url){
            var urlRequest = NSMutableURLRequest(URL: url)
            
            urlRequest.timeoutInterval = timeoutInterval
            urlRequest.HTTPMethod = self.httpMethod.rawValue
            if let data = self.postData{
                Logger.sharedInstance.log(tag, message: "HTTP Body: '\(data)'")
                urlRequest.HTTPBody = data.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            }
            Logger.sharedInstance.log(tag, message: "HTTP Method: '\(self.httpMethod.rawValue)'")
            
            if let concreteHeaders = self.headers {
                for (key,value) in concreteHeaders {
                    Logger.sharedInstance.log(tag, message: "$\(self.httpMethod.rawValue)['\(key)'] = '\(value)'")
                    urlRequest.setValue(value, forHTTPHeaderField: key)
                }
            }

            
            return urlRequest
        }
        
        self.delegate?.requestFailWithError(NetworkLibraryErrorCode.MalformedURL, error:nil)
        return nil
    }

    
    deinit{
        Logger.sharedInstance.log(tag, message: "Bye")
        
    }
    
}

//
//  JSON.swift
//  GeoPolicy
//
//  Created by Taha Doğan Güneş on 10/06/15.
//  Copyright (c) 2015 Taha Doğan Güneş. All rights reserved.
//

//
//  APITools.swift
//  OzU Carpool
//
//  Created by Taha Doğan Güneş on 08/10/14.
//  Copyright (c) 2014 TDG. All rights reserved.
//

import Foundation
import UIKit

//
//  json.swift
//  json
//
//  Created by Dan Kogai on 7/15/14.
//  Copyright (c) 2014 Dan Kogai. All rights reserved.


/// init
public class JSON {
    private let _value:AnyObject
    /// pass the object that was returned from
    /// NSJSONSerialization
    public init(_ obj:AnyObject) { self._value = obj }
    /// pass the JSON object for another instance
    public init(_ json:JSON){ self._value = json._value }
}
/// class properties
extension JSON {
    public typealias NSNull = Foundation.NSNull
    public typealias NSError = Foundation.NSError
    public class var null:NSNull { return NSNull() }
    /// constructs JSON object from string
    public convenience init(string:String) {
        var err:NSError?
        let enc:NSStringEncoding = NSUTF8StringEncoding
        var obj:AnyObject? = NSJSONSerialization.JSONObjectWithData(
            string.dataUsingEncoding(enc)!, options:nil, error:&err
        )
        self.init(err != nil ? err! : obj!)
    }
    /// parses string to the JSON object
    /// same as JSON(string:String)
    public class func parse(string:String)->JSON {
        return JSON(string:string)
    }
    public class func loads(string:String)->JSON {
        return JSON(string:string)
    }
    /// constructs JSON object from the content of NSURL
    public convenience init(nsurl:NSURL) {
        var enc:NSStringEncoding = NSUTF8StringEncoding
        var err:NSError?
        let str:String? =
        NSString(
            contentsOfURL:nsurl, usedEncoding:&enc, error:&err
        ) as String?
        if err != nil { self.init(err!) }
        else { self.init(string:str!) }
    }
    /// fetch the JSON string from NSURL and parse it
    /// same as JSON(nsurl:NSURL)
    public class func fromNSURL(nsurl:NSURL) -> JSON {
        return JSON(nsurl:nsurl)
    }
    /// constructs JSON object from the content of URL
    public convenience init(url:String) {
        if let nsurl = NSURL(string:url) as NSURL? {
            self.init(nsurl:nsurl)
        } else {
            self.init(NSError(
                domain:"JSONErrorDomain",
                code:400,
                userInfo:[NSLocalizedDescriptionKey: "malformed URL"]
                )
            )
        }
    }
    /// fetch the JSON string from URL in the string
    public class func fromURL(url:String) -> JSON {
        return JSON(url:url)
    }
    /// does what JSON.stringify in ES5 does.
    /// when the 2nd argument is set to true it pretty prints
    public class func stringify(obj:AnyObject, pretty:Bool=false) -> String! {
        if !NSJSONSerialization.isValidJSONObject(obj) {
            JSON(NSError(
                domain:"JSONErrorDomain",
                code:422,
                userInfo:[NSLocalizedDescriptionKey: "not an JSON object"]
                ))
            return nil
        }
        return JSON(obj).toString(pretty:pretty)
    }
}
/// instance properties
extension JSON {
    /// access the element like array
    public subscript(idx:Int) -> JSON {
        switch _value {
        case let err as NSError:
            return self
        case let ary as NSArray:
            if 0 <= idx && idx < ary.count {
                return JSON(ary[idx])
            }
            return JSON(NSError(
                domain:"JSONErrorDomain", code:404, userInfo:[
                    NSLocalizedDescriptionKey:
                    "[\(idx)] is out of range"
                ]))
        default:
            return JSON(NSError(
                domain:"JSONErrorDomain", code:500, userInfo:[
                    NSLocalizedDescriptionKey: "not an array"
                ]))
        }
    }
    /// access the element like dictionary
    public subscript(key:String)->JSON {
        switch _value {
        case let err as NSError:
            return self
        case let dic as NSDictionary:
            if let val:AnyObject = dic[key] { return JSON(val) }
            return JSON(NSError(
                domain:"JSONErrorDomain", code:404, userInfo:[
                    NSLocalizedDescriptionKey:
                    "[\"\(key)\"] not found"
                ]))
        default:
            return JSON(NSError(
                domain:"JSONErrorDomain", code:500, userInfo:[
                    NSLocalizedDescriptionKey: "not an object"
                ]))
        }
    }
    /// access json data object
    public var data:AnyObject? {
        return self.isError ? nil : self._value
    }
    /// Gives the type name as string.
    /// e.g.  if it returns "Double"
    ///       .asDouble returns Double
    public var type:String {
        switch _value {
        case is NSError:        return "NSError"
        case is NSNull:         return "NSNull"
        case let o as NSNumber:
            switch String.fromCString(o.objCType)! {
            case "c", "C":              return "Bool"
            case "q", "l", "i", "s":    return "Int"
            case "Q", "L", "I", "S":    return "UInt"
            default:                    return "Double"
            }
        case is NSString:               return "String"
        case is NSArray:                return "Array"
        case is NSDictionary:           return "Dictionary"
        default:                        return "NSError"
        }
    }
    /// check if self is NSError
    public var isError:      Bool { return _value is NSError }
    /// check if self is NSNull
    public var isNull:       Bool { return _value is NSNull }
    /// check if self is Bool
    public var isBool:       Bool { return type == "Bool" }
    /// check if self is Int
    public var isInt:        Bool { return type == "Int" }
    /// check if self is UInt
    public var isUInt:       Bool { return type == "UInt" }
    /// check if self is Double
    public var isDouble:     Bool { return type == "Double" }
    /// check if self is any type of number
    public var isNumber:     Bool {
        if let o = _value as? NSNumber {
            let t = String.fromCString(o.objCType)!
            return  t != "c" && t != "C"
        }
        return false
    }
    /// check if self is String
    public var isString:     Bool { return _value is NSString }
    /// check if self is Array
    public var isArray:      Bool { return _value is NSArray }
    /// check if self is Dictionary
    public var isDictionary: Bool { return _value is NSDictionary }
    /// check if self is a valid leaf node.
    public var isLeaf:       Bool {
        return !(isArray || isDictionary || isError)
    }
    /// gives NSError if it holds the error. nil otherwise
    public var asError:NSError? {
        return _value as? NSError
    }
    /// gives NSNull if self holds it. nil otherwise
    public var asNull:NSNull? {
        return _value is NSNull ? JSON.null : nil
    }
    /// gives Bool if self holds it. nil otherwise
    public var asBool:Bool? {
        switch _value {
        case let o as NSNumber:
            switch String.fromCString(o.objCType)! {
            case "c", "C":  return Bool(o.boolValue)
            default:
                return nil
            }
        default: return nil
        }
    }
    /// gives Int if self holds it. nil otherwise
    public var asInt:Int? {
        switch _value {
        case let o as NSNumber:
            switch String.fromCString(o.objCType)! {
            case "c", "C":
                return nil
            default:
                return Int(o.longLongValue)
            }
        default: return nil
        }
    }
    /// gives Double if self holds it. nil otherwise
    public var asDouble:Double? {
        switch _value {
        case let o as NSNumber:
            switch String.fromCString(o.objCType)! {
            case "c", "C":
                return nil
            default:
                return Double(o.doubleValue)
            }
        default: return nil
        }
    }
    // an alias to asDouble
    public var asNumber:Double? { return asDouble }
    /// gives String if self holds it. nil otherwise
    public var asString:String? {
        switch _value {
        case let o as NSString:
            return o as String
        default: return nil
        }
    }
    /// if self holds NSArray, gives a [JSON]
    /// with elements therein. nil otherwise
    public var asArray:[JSON]? {
        switch _value {
        case let o as NSArray:
            var result = [JSON]()
            for v:AnyObject in o { result.append(JSON(v)) }
            return result
        default:
            return nil
        }
    }
    
    public var asStringArray:[String]? {
        if let array = self.asArray{
            var result:[String] = []
            for i in array {
                if let item = i.asString{
                    result.append(item)
                }
                else{
                    return nil
                }
            }
            return result
        }
        return nil
    }
    
    /// if self holds NSDictionary, gives a [String:JSON]
    /// with elements therein. nil otherwise
    public var asDictionary:[String:JSON]? {
        switch _value {
        case let o as NSDictionary:
            var result = [String:JSON]()
            for (k:AnyObject, v:AnyObject) in o {
                result[k as! String] = JSON(v)
            }
            return result
        default: return nil
        }
    }
    /// Yields date from string
    public var asDate:NSDate? {
        if let dateString = _value as? NSString {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
            return dateFormatter.dateFromString(dateString as String)
        }
        return nil
    }
    /// gives the number of elements if an array or a dictionary.
    /// you can use this to check if you can iterate.
    public var length:Int {
        switch _value {
        case let o as NSArray:      return o.count
        case let o as NSDictionary: return o.count
        default: return 0
        }
    }
}
extension JSON : SequenceType {
    public func generate()->GeneratorOf<(AnyObject,JSON)> {
        switch _value {
        case let o as NSArray:
            var i = -1
            return GeneratorOf<(AnyObject, JSON)> {
                if ++i == o.count { return nil }
                return (i, JSON(o[i]))
            }
        case let o as NSDictionary:
            var ks = o.allKeys.reverse()
            return GeneratorOf<(AnyObject, JSON)> {
                if ks.isEmpty { return nil }
                let k = ks.removeLast() as! String
                return (k, JSON(o.valueForKey(k)!))
            }
        default:
            return GeneratorOf<(AnyObject, JSON)>{ nil }
        }
    }
    public func mutableCopyOfTheObject() -> AnyObject {
        return _value.mutableCopy()
    }
}
extension JSON : Printable {
    /// stringifies self.
    /// if pretty:true it pretty prints
    public func toString(pretty:Bool=false)->String {
        switch _value {
        case is NSError: return "\(_value)"
        case is NSNull: return "null"
        case let o as NSNumber:
            switch String.fromCString(o.objCType)! {
            case "c", "C":
                return o.boolValue.description
            case "q", "l", "i", "s":
                return o.longLongValue.description
            case "Q", "L", "I", "S":
                return o.unsignedLongLongValue.description
            default:
                switch o.doubleValue {
                case 0.0/0.0:   return "0.0/0.0"    // NaN
                case -1.0/0.0:  return "-1.0/0.0"   // -infinity
                case +1.0/0.0:  return "+1.0/0.0"   //  infinity
                default:
                    return o.doubleValue.description
                }
            }
        case let o as NSString:
            return o.debugDescription
        default:
            let opts = pretty
                ? NSJSONWritingOptions.PrettyPrinted : nil
            if let data = NSJSONSerialization.dataWithJSONObject(
                _value, options:opts, error:nil
                ) as NSData? {
                    if let nsstring = NSString(
                        data:data, encoding:NSUTF8StringEncoding
                        ) as NSString? {
                            return nsstring as String
                    }
            }
            return "YOU ARE NOT SUPPOSED TO SEE THIS!"
        }
    }
    public var description:String { return toString() }
}

