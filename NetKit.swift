
// var nkit = NetKit() // (async=true) optional
// var nkit = NetKit(baseURL:”http://google.com/”)

// HTTP Method



// nkit.request(type:.POST,

// nkit.addHeader(“Content-Type, “application/json”)

// nkit.post(url:“/api/associated/”, headers: ["Content-Type":"application/json"], data:: // optional 

// nkit.put
// nkit.delete
// nkit.get

// HTTP_511_NETWORK_AUTHENTICATION_REQUIRED = 511


enum HTTPMethod: String {
    case POST = "POST"
    case DELETE = "DELETE"
    case GET = "GET"
    case PUT = "PUT"
}

enum HTTPStatus: Int {
    case Continue = 100
    case SwitchingProtocols = 101
    case Processing = 102
    
    // Success
    case OK = 200
    case Created = 201
    case Accepted = 202
    case NonAuthoritativeInformation = 203
    case NoContent = 204
    case ResetContent = 205
    case PartialContent = 206
    case MultiStatus = 207
    case AlreadyReported = 208
    case IMUsed = 226
    
    // Redirections
    case MultipleChoices = 300
    case MovedPermanently = 301
    case Found = 302
    case SeeOther = 303
    case NotModified = 304
    case UseProxy = 305
    case SwitchProxy = 306
    case TemporaryRedirect = 307
    case PermanentRedirect = 308
    
    // Client Errors
    case BadRequest = 400
    case Unauthorized = 401
    case PaymentRequired = 402
    case Forbidden = 403
    case NotFound = 404
    case MethodNotAllowed = 405
    case NotAcceptable = 406
    case ProxyAuthenticationRequired = 407
    case RequestTimeout = 408
    case Conflict = 409
    case Gone = 410
    case LengthRequired = 411
    case PreconditionFailed = 412
    case RequestEntityTooLarge = 413
    case RequestURITooLong = 414
    case UnsupportedMediaType = 415
    case RequestedRangeNotSatisfiable = 416
    case ExpectationFailed = 417
    case ImATeapot = 418
    case AuthenticationTimeout = 419
    case UnprocessableEntity = 422
    case Locked = 423
    case FailedDependency = 424
    case UpgradeRequired = 426
    case PreconditionRequired = 428
    case TooManyRequests = 429
    case RequestHeaderFieldsTooLarge = 431
    case LoginTimeout = 440
    case NoResponse = 444
    case RetryWith = 449
    case UnavailableForLegalReasons = 451
    case RequestHeaderTooLarge = 494
    case CertError = 495
    case NoCert = 496
    case HTTPToHTTPS = 497
    case TokenExpired = 498
    case ClientClosedRequest = 499
    
    // Server Errors
    case InternalServerError = 500
    case NotImplemented = 501
    case BadGateway = 502
    case ServiceUnavailable = 503
    case GatewayTimeout = 504
    case HTTPVersionNotSupported = 505
    case VariantAlsoNegotiates = 506
    case InsufficientStorage = 507
    case LoopDetected = 508
    case BandwidthLimitExceeded = 509
    case NotExtended = 510
    case NetworkAuthenticationRequired = 511
    case NetworkTimeoutError = 599
}

enum NKError: Int {
    case MalformedURL = 0
    case HasNSError = 1
}

enum NKContentType: String  {
    //common aplication content types
    case JSON = "application/json"
    case XML = "application/xml"
    case ZIP = "application/zip"
    case GZIP = "application/gzip"
    case PDF = "application/pdf"

    //common image content types
    case JPEG = "image/jpeg"
    case PNG = "image/png"
    case TIFF = "image/tiff"
    case BMP = "image/bmp"
    case GIF = "image/gif"

    //common audio content types
    case MP4Audio = "audio/mp4"
    case OGG = "audio/ogg"
    case FLAC = "audio/flac"
    case WEBMAudio = "audio/webm"

    //common text content types
    case HTML = "text/html"
    case JAVASCRIPT = "text/javascript"
    case PLAIN = "text/plain"
    case RTF = "text/rtf"
    case XMLText = "text/xml"
    case CSV = "text/csv"
    
    //common video content types
    case AVI = "video/avi"
    case MPEG = "video/mpeg"
    case MP4Video = "video/mp4"
    case QuickTime = "video/quicktime"
    case WEBMVideo = "video/webm"
}

protocol NKDelegate {
    func didFailed(nkerror:NKError, nserror:NSError?)
    func didSucceed(response:NKResponse)
    func progress(percent:Float)
}

typealias CompletionHandler = (NKResponse)->()
typealias ErrorHandler = (NKError, NSError?)->()
typealias Progress = (percent:Float)->()

class NKResponse {
    var json: JSON?
    var status: HTTPStatus?
    var data: NSMutableData?
    var string: String?
}

class NetKit: HTTPLayerDelegate {
    

    var baseURL: String
    var timeoutInterval = 20.0 //seconds
    var delegate: NKDelegate?


    init(baseURL: String) {
        self.baseURL = baseURL
    }

    init(){
        self.baseURL = ""
    }

    func request(type: HTTPMethod, url: String?=nil, data: AnyObject? = nil, headers: [String:String]?=nil, completionHandler: CompletionHandler? = nil, errorHandler: ErrorHandler? = nil,progress: Progress? = nil) {
        var fullURL = self.getFullURL(url)
        switch type {
        case .POST:
            self.post(data: data, url:url, headers:headers, completionHandler: completionHandler, errorHandler: errorHandler, progress: progress)
            break
        case .PUT:
            self.put(data: data, url:url, headers:headers, completionHandler: completionHandler, errorHandler: errorHandler, progress: progress)
            break
        case .GET:
            self.get(url: url, headers:headers, completionHandler: completionHandler, errorHandler: errorHandler, progress: progress)
            break
        case .DELETE:
            self.delete(url: url, headers:headers, completionHandler: completionHandler, errorHandler: errorHandler, progress: progress)
            break
        }
    }

    func put(data: AnyObject? = nil, url: String?=nil, headers: [String:String]?=nil, completionHandler: CompletionHandler? = nil, errorHandler: ErrorHandler? = nil,progress: Progress? = nil) {
        var fullURL = self.getFullURL(url)

        if let request = self.generateURLRequest(fullURL, method: HTTPMethod.POST) {
            self.setHeaders(request, headers)
            if let concreteData: AnyObject = data {
                if let type = self.detectDataType(concreteData) {
                    self.setContentType(request, type)
                }

                request.HTTPBody = concreteData.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            }          
            var httpLayer = HTTPLayer(completionHandler, errorHandler, progress)
            httpLayer.delegate = self
            httpLayer.request(request)
        }
    }

    func get(url: String?=nil, headers: [String:String]?=nil, completionHandler: CompletionHandler? = nil, errorHandler: ErrorHandler? = nil,progress: Progress? = nil) {
        var fullURL = self.getFullURL(url)

        if let request = self.generateURLRequest(fullURL, method: HTTPMethod.GET) {
            self.setHeaders(request, headers)
            var httpLayer = HTTPLayer(completionHandler, errorHandler, progress)
            httpLayer.delegate = self
            httpLayer.request(request)
        }
    }

    func post(data: AnyObject? = nil, url: String?=nil, headers: [String:String]?=nil, completionHandler: CompletionHandler? = nil, errorHandler: ErrorHandler? = nil,progress: Progress? = nil) { //contentType, postData
        var fullURL = self.getFullURL(url)
        println("FullURL=\(fullURL)")
        if let request = self.generateURLRequest(fullURL, method: HTTPMethod.POST) {
//            self.setHeaders(request, headers)
//            if let concreteData: AnyObject = data {
//                if let type = self.detectDataType(concreteData) {
//                    self.setContentType(request, type)
//                }
                if let json = data! as? JSON {

                    let text = json.toString(pretty: true) as String
                    println("BODY=\(text)")
                    let data = text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)! as NSData
                    request.HTTPBody = data
                    
                    request.setValue("application/json",  forHTTPHeaderField:"Content-Type")
                }
//                else {
//                    request.HTTPBody = concreteData.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
//                }

//            }          
            var httpLayer = HTTPLayer(completionHandler, errorHandler, progress)
            httpLayer.delegate = self
            httpLayer.request(request)
        }
    }

    func delete(url: String?=nil, headers: [String:String]?=nil, completionHandler: CompletionHandler? = nil, errorHandler: ErrorHandler? = nil, progress: Progress? = nil) {
        var fullURL = self.getFullURL(url)

        if let request = self.generateURLRequest(fullURL, method: HTTPMethod.DELETE) {
            self.setHeaders(request, headers)
            var httpLayer = HTTPLayer(completionHandler, errorHandler, progress)
            httpLayer.delegate = self
            httpLayer.request(request)
        }
    }

    // MARK: HTTPLayerDelegate functions
    func requestDidFinish(response:NKResponse) {
        self.delegate?.didSucceed(response)

    }

    func requestFailWithError(error:NSError) {
        self.delegate?.didFailed(.HasNSError, nserror:error)
    }

    func progress(percent: Float) {
        self.delegate?.progress(percent)
    }
    

    private func getFullURL(url: String?) -> String {
        if let concreteURL = url {
            return self.baseURL + concreteURL
        }
        return self.baseURL
    }
    private func setHeaders(request:NSMutableURLRequest, _ headers: [String:String]? ) {
       if let concreteHeaders = headers {
            for (key,value) in concreteHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
    }

    private func setContentType(request: NSMutableURLRequest, _ type: NKContentType) {
        println("Set content type: \(type.rawValue)")
        request.setValue(type.rawValue,  forHTTPHeaderField:"Content-Type")
    }

    private func detectDataType(data: AnyObject) -> NKContentType? {
        if let json = data as? JSON {
            return NKContentType.JSON
        }
        return nil 
    }

    private func generateURLRequest(absoluteURL: String, method: HTTPMethod) -> NSMutableURLRequest? {
        if let url = NSURL(string: absoluteURL) {
            var request =  NSMutableURLRequest(URL: url)
            request.timeoutInterval = timeoutInterval
            request.HTTPMethod = method.rawValue
            return request
        }
        self.delegate?.didFailed(.MalformedURL, nserror:nil)
        return nil
    }


}


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


protocol HTTPLayerDelegate {
    func requestFailWithError(error:NSError)
    func requestDidFinish(response:NKResponse)
    func progress(percent:Float)
}


class HTTPLayer: NSObject, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    
    var responseData : NSMutableData = NSMutableData()
    var delegate: HTTPLayerDelegate?
    var completionHandler: CompletionHandler?
    var errorHandler: ErrorHandler?
    var progress: Progress?
    var status: HTTPStatus?
    var expectedDownloadSize: Int?
    
    init(_ completionHandler: CompletionHandler?, _ errorHandler: ErrorHandler?, _ progress: Progress?) {
        self.completionHandler = completionHandler
        self.errorHandler = errorHandler
        self.progress = progress
    }


    func request(urlRequest:NSMutableURLRequest){
        urlRequest.setValue("", forHTTPHeaderField: "Accept-Encoding")
        
        let conn = NSURLConnection(request:urlRequest, delegate: self, startImmediately: true)
    }
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        responseData = NSMutableData()
        let httpResponse = response as! NSHTTPURLResponse
        status = HTTPStatus(rawValue: httpResponse.statusCode)
        
        
        NSLog("%@", httpResponse.allHeaderFields)
        
        if status == .OK {
            self.expectedDownloadSize = Int(httpResponse.expectedContentLength)
            println("NKit: Expected Download Size: \(self.expectedDownloadSize)")
        }
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        responseData.appendData(data)
        if let expectedSize = self.expectedDownloadSize {
            println("NKit: responseData length \(self.responseData.length)")
            let percent = Float(100 / self.expectedDownloadSize! * self.responseData.length)

            self.delegate?.progress(percent)
            
            if let handler = self.progress {
                handler(percent: percent)
            }
        }

    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        var response = NKResponse()
        response.status = self.status
        response.data = responseData
        if let string = NSString(data: responseData, encoding: NSUTF8StringEncoding) {
            response.string = string as String
            let json = JSON.loads(response.string!)
            if !json.isError {
                response.json = json
            }
            
        }
        self.delegate?.requestDidFinish(response)
        if let handler = self.completionHandler {
            handler(response)
        }
    }
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.delegate?.requestFailWithError(error)
        if let handler = self.errorHandler {
            handler(.HasNSError, error)
        }
    }
}

//
//  NetworkLibrary.swift
//  GeoPolicy - Socivy
//
//  Created by Taha Doğan Güneş on 10/06/15.
//  Copyright (c) 2015 Taha Doğan Güneş. All rights reserved.
//


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
    
    public func dataUsingEncoding(encoding:NSStringEncoding, allowLossyConversion: Bool) -> NSData? {
        let text = self.toString(pretty: false)
        return text.dataUsingEncoding(encoding, allowLossyConversion: allowLossyConversion)
    }
    
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

