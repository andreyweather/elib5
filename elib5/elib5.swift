
import Foundation
import SwiftUI

private var getToken: String? {return UserDefaults.standard.object(forKey: token_pref) as? String}
private var tokenFromPref: String? = getToken
private var token: String? = ""
private var account = ""
private var session = ""
private var tokenRefreshAccess = true


private var token_pref: String { return "TOKEN"}
private var session_pref: String { return "SESSION_ID"}
private var account_pref: String {return "ACCOUNT"}
private var email_pref: String { return "EMAIL" }
private var phone_pref: String { return "PHONE" }


private var libraryInit = false
private var addContactRequest = false
private var contactParams: [String: Any] = ["":""]

private var userCat = "prod"

public func setToken (newToken: String?) {
    
    token = newToken
    
    let status =   tokenChangeStatus()
    
    let observer = TokenChangeObserver (object: status)
    
    print(observer.token)
    
    status.token = newToken
    
    
    if  newToken != getToken {
        
        UserDefaults.standard.set(newToken, forKey: token_pref)
    }
}
private class tokenChangeStatus: NSObject {
    
    @objc dynamic var token = tokenFromPref
     
}


private class TokenChangeObserver: NSObject {
    
    @objc var token: tokenChangeStatus
    var observation: NSKeyValueObservation?
    
    init(object: tokenChangeStatus) {
        self.token = object
        super.init()
        
        observation = observe(\.token.token, options: [.old, .new], changeHandler: { object, token in
            
            var getSessionID: String? { return UserDefaults.standard.object(forKey: session_pref) as? String }
            var getAccount: String? {return UserDefaults.standard.object(forKey: account_pref) as? String }
            
            
            if token.newValue != token.oldValue {
                
                if (tokenRefreshAccess) {
                    
                    refreshToken(token: (token.newValue ?? "") ?? "", sessionID: getSessionID ?? "", account: getAccount ?? "")
                }
            }
            
          })
       }
    }

public func logOut () {
    
    tokenRefreshAccess = false
    
    UserDefaults.standard.removeObject(forKey: session_pref)
    UserDefaults.standard.removeObject(forKey: token_pref)
    UserDefaults.standard.removeObject(forKey: account_pref)
    UserDefaults.standard.removeObject(forKey: email_pref)
    UserDefaults.standard.removeObject(forKey: phone_pref)
    
    
}

private func getUrl (selectUser: String, selectUrl: String) -> String {
    
    var url = ""
    
    let devUrl: [String: String] = ["createSession":"https://dev.ext.enkod.ru/sessions",
                                    "startSession":"https://dev.ext.enkod.ru/sessions/start",
                                    "subscribePush":"https://dev.ext.enkod.ru/mobile/subscribe",
                                    "unsubscribePush":"https://dev.ext.enkod.ru/mobile/unsubscribe",
                                    "clickPush":"https://dev.ext.enkod.ru/mobile/click/",
                                    "refreshToken":"https://dev.ext.enkod.ru/mobile/token",
                                    
                                    "cart":"https://dev.ext.enkod.ru/product/cart",
                                    "favourite":"https://dev.ext.enkod.ru/product/favourite",
                                    "pageOpen":"https://dev.ext.enkod.ru/page/open",
                                    "productOpen":"https://dev.ext.enkod.ru/product/open",
                                    "productBuy":"https://dev.ext.enkod.ru/product/order",
                                    "subscribe":"https://dev.ext.enkod.ru/subscribe",
                                    "addExtraFields":"https://dev.ext.enkod.ru/addExtraFields",
                                    "getPerson":"https://dev.ext.enkod.ru/getCartAndFavourite",
                                    "updateBySession":"https://dev.ext.enkod.ru/updateBySession"]
    
    
    let prodUrl: [String: String] =  ["createSession":"https://ext.enkod.ru/sessions",
                                      "startSession":"https://ext.enkod.ru/sessions/start",
                                      "subscribePush":"https://ext.enkod.ru/mobile/subscribe",
                                      "unsubscribePush":"https://ext.enkod.ru/mobile/unsubscribe",
                                      "clichPush":"https://ext.enkod.ru/mobile/click/",
                                      "refreshToken":"https://ext.enkod.ru/mobile/token",
                                      
                                      "cart":"https://ext.enkod.ru/product/cart",
                                      "favourite":"https://ext.enkod.ru/product/favourite",
                                      "pageOpen":"https://ext.enkod.ru/page/open",
                                      "productOpen":"https://ext.enkod.ru/product/open",
                                      "productBuy":"https://ext.enkod.ru/product/order",
                                      "subscribe":"https://ext.enkod.ru/subscribe",
                                      "addExtraFields":"https://ext.enkod.ru/addExtraFields",
                                      "getPerson":"https://ext.enkod.ru/getCartAndFavourite",
                                      "updateBySession":"https://ext.enkod.ru/updateBySession"]
    
    
    if selectUser == "dev" {
        url = devUrl [selectUrl] ?? ""
    }
    
    
    if selectUser == "prod" {
        url =  prodUrl [selectUrl] ?? ""
    }
    
    return url
    
}


public func EnkodConnect (_account: String?) {
    
    if (_account != nil) {
        
        account = _account ?? ""
        UserDefaults.standard.set(account, forKey: account_pref)
        
    }
    
    tokenRefreshAccess = true
    
    var getSessionID: String? { return UserDefaults.standard.object(forKey: session_pref) as? String }
    var getAccount: String? {return UserDefaults.standard.object(forKey: account_pref) as? String }
    var getToken: String? { return UserDefaults.standard.object(forKey: token_pref) as? String }
    
    
    if getSessionID == nil {
        
        createSession(account: account)
        
    }
    
    else {
        
        startSession (account: getAccount ?? "", sessionID: getSessionID ?? "")
            
    }
}

private func createSession (account: String) {
    
    let urlFromMap = getUrl(selectUser:userCat, selectUrl:"createSession")
    
    guard let url = URL(string: urlFromMap) else { return }
    var urlRequest = URLRequest(url: url)
    urlRequest.addValue(account, forHTTPHeaderField: "X-Account")
    urlRequest.httpMethod = "POST"
    URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           
            let sessionID: String? = json["session_id"] as? String? {

           
                session = sessionID ?? ""

                UserDefaults.standard.set(session, forKey: session_pref)
                
                print ("createSession")
        
            DispatchQueue.main.async {
                
            
                startSession (account: account, sessionID: session)
                
            }
            
        } else if error != nil {
            
            DispatchQueue.main.async {
                
               print ("created_session_error")
            }
        }
    }.resume()
}


private func startSession (account: String, sessionID: String) {
    
    let urlFromMap = getUrl(selectUser:userCat, selectUrl:"startSession")
    
    guard let url = URL(string: urlFromMap) else { return }
    var urlRequest = URLRequest(url: url)
    urlRequest.addValue(account, forHTTPHeaderField: "X-Account")
    urlRequest.addValue(sessionID, forHTTPHeaderField: "X-Session-Id")
    urlRequest.httpMethod = "POST"
    URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
       
        
        if data != nil {
                 
                print ("startSession")
            
                subscribePush (account: account, sessionID: sessionID, token: getToken ?? "")
            

        } else if error != nil {
            
            DispatchQueue.main.async {
                
                print ("start_session_error")
                
            }
        }
    }.resume()
}

private func refreshToken(token: String, sessionID: String, account: String) {
    
 let urlFromMap = getUrl(selectUser:userCat, selectUrl:"refreshToken")
 guard let url = URL(string: urlFromMap) else { return }
 var urlRequest = URLRequest(url: url)
 urlRequest.httpMethod = "PUT"
 urlRequest.addValue(account, forHTTPHeaderField: "X-Account")
 urlRequest.addValue("application/json", forHTTPHeaderField: "content-type")
 urlRequest.addValue(sessionID, forHTTPHeaderField: "X-Session-Id")

 let json: [String: Any] = ["sessionId": sessionID, "token": token]
 let jsonData = try? JSONSerialization.data(withJSONObject: json)
 urlRequest.httpBody = jsonData

 URLSession.shared.dataTask(with: urlRequest) {(data, response, error) in
     if data != nil {
         
         print("refreshToken")
         
     } else if error != nil {
         print("error refreshToken")
     }
 }.resume()
}

private func subscribePush (account: String, sessionID: String, token: String) {
    
    print("\(account), \(token), \(sessionID)")
    
    let urlFromMap = getUrl(selectUser:userCat, selectUrl:"subscribePush")
    
    guard let url = URL(string: urlFromMap) else { return }
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.addValue(account, forHTTPHeaderField: "X-Account")
    urlRequest.addValue("application/json", forHTTPHeaderField: "content-type")
    urlRequest.addValue(sessionID, forHTTPHeaderField: "X-Session-Id")
    
    let json: [String: Any] = ["sessionId": sessionID, "token": token, "os": "ios"]
    
    let jsonData = try? JSONSerialization.data(withJSONObject: json)
    urlRequest.httpBody = jsonData
     
    
    URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
        if data != nil {
            
            
            DispatchQueue.main.async {
                
                print ("subscribePush")
  
                let status = LibInitStatus()
                let observer = LibInitObserver (object: status)
                print(observer.status)
                status.statusName = "init"
            }
            
        } else if error != nil {
            
            DispatchQueue.main.async {
                
                print ("subscribe_push_error")
                
            }
        }
        
    }.resume()
}


public func addContact (email: String = "", phone: String = "", params: [String:Any]? = nil) {

    UserDefaults.standard.set(email, forKey: email_pref)
    UserDefaults.standard.set(phone, forKey: phone_pref)
    
    var getSessionID: String? {return UserDefaults.standard.object(forKey: session_pref) as? String}
    var getAccount: String? {return UserDefaults.standard.object(forKey: account_pref) as? String }
    
    
    var user  = [String:Any] ()
    
    if (email != "" && phone != "" )  {
        
        user = ["email": email, "phone": phone]
        
    }
    
    if (email != "" && phone == "") {
        
         user = ["email": email]

    }
    
    if (email == "" && phone != "") {
        
         user = ["phone": phone]
        
    }
    
    if params != nil && params?.keys.count != 0 {
        
        for (k, v) in params! {
            
            contactParams[k] = v
            user[k] = v
            
        }
    }
    
    contactParams = ["fields": user]
    

            JSONSerialization.isValidJSONObject(contactParams)
      
            let json = try? JSONSerialization.data(withJSONObject: contactParams, options: [])
                      
    DispatchQueue.main.async {
        
        
  
        if (libraryInit) {
            
            if getAccount != nil && getSessionID != nil {
                
                guard let urlRequest = prepareRequest("POST", getUrl(selectUser:userCat, selectUrl:"subscribe"), json, account: getAccount ?? "", session: getSessionID ?? "") else { return }
                
                print ("libraryInit")
                
                URLSession.shared.dataTask(with: urlRequest) {(data, response, error) in
                    if data != nil {
                        
                        DispatchQueue.main.async {
                            do {
                                print("addContact email: \(email), phone: \(phone)")
                            }
                        }
                        
                    } else if error != nil {
                        DispatchQueue.main.async {
                            
                            print("add_contact_error")
                            
                        }
                    }
                }.resume()
            }
        }
        
        else {
            
            print ("nolibraryInit")
            let status = AddContactRequestStatus()
            let observer = AddContactRequestObserver(object: status)
            print(observer.status)
            status.status = "request"
            
      }
   }
}



private func prepareRequest(_ method: String, _ url: String, _ body: Data?, account: String, session: String) -> URLRequest?{
    
    let account = account
    let session = session
    let url = URL(string: url)
    var urlRequest = URLRequest(url:url!)
    urlRequest.httpMethod = method
    urlRequest.addValue(account, forHTTPHeaderField: "X-Account")
    urlRequest.addValue(session, forHTTPHeaderField: "X-Session-Id")
    urlRequest.addValue("application/json", forHTTPHeaderField: "content-type")
    urlRequest.httpBody = body
    return urlRequest
    
}


public struct Product {
    
     public init(id: String? = nil, categoryId: String? = nil, count: Int? = nil, price: String? = nil, picture: String? = nil, params: [String : Any]? = nil) {
         
        self.id = id
        self.categoryId = categoryId
        self.count = count
        self.price = price
        self.picture = picture
        self.params = params
    }
    
    public var id: String?
    public var categoryId: String?
    public var count: Int?
    public var price: String?
    public var picture: String?
    public var params: [String:Any]?
    
}


public func TrackingMapBilder(_ product: Product) -> [String:Any] {
    var productMap = [String:Any]()
    
  
    if product.id != nil {
        productMap["productId"] = product.id
    }
    
    if product.categoryId != nil {
        productMap["categoryId"] = product.categoryId
    }
    
    if product.count != nil {
        productMap["count"] = product.count
    }
    
    if product.price != nil {
        productMap["price"] = product.price
    }
    
    if product.picture != nil {
        productMap["picture"] = product.picture
    }
    
    if product.params != nil && product.params?.keys.count != 0 {
    
        for (key, _) in product.params! {
            
            productMap[key] = product.params?[key]
            
        }
    }

    return productMap
}


public func AddToFavourite (product: Product) {
    
    var getSessionID: String? {return UserDefaults.standard.object(forKey: session_pref) as? String}
    var getAccount: String? {return UserDefaults.standard.object(forKey: account_pref) as? String }
    
    if getSessionID != nil && getAccount != nil  {
        
    var map = TrackingMapBilder(product)
    
    map ["action"] = "productLike"
    
    let lastUpdate = Int(Date().timeIntervalSince1970)
    
    let wishlist: [String:Any] = ["products":map["productId"] ?? "", "lastUpdate": lastUpdate]

    let history: [[String:Any]] = [map]
    
    let json: [String : Any] = ["wishlist": wishlist, "history": history]
    
    do {
        
        guard JSONSerialization.isValidJSONObject(json) else {
            throw TrackerErr.invalidJson
            
        }
        
        let requestBody = try JSONSerialization.data(withJSONObject: json)
        
            
        guard let urlRequest = prepareRequest("POST", getUrl(selectUser:userCat, selectUrl:"favourite"), requestBody, account: getAccount ?? "", session: getSessionID ?? "") else { return }
            
            
            URLSession.shared.dataTask(with: urlRequest) {(data, response, error) in
                
                if data != nil {
                    
                    
                    DispatchQueue.main.async {
                        print("AddToFavourite")
                    }
                    
                } else if error != nil {
                    
                    DispatchQueue.main.async {
                        
                        print("Error AddToFavourite")
                    }
                }
                
            }.resume()
            
        } catch {
            
            print("Error AddToFavourite")
        }
    }
}


public func RemoveFromFavourite (product: Product) {
    
    
    var getSessionID: String? {return UserDefaults.standard.object(forKey: session_pref) as? String}
    var getAccount: String? {return UserDefaults.standard.object(forKey: account_pref) as? String }
    
    if getSessionID != nil && getAccount != nil  {
        
        var map = TrackingMapBilder(product)
        
        
        map ["action"] = "productDislike"
        
        let lastUpdate = Int(Date().timeIntervalSince1970)
        
        let wishlist: [String:Any] = ["products":map["productId"] ?? "", "lastUpdate": lastUpdate]
        
        let history: [[String:Any]] = [map]
        
        let json: [String : Any] = ["wishlist": wishlist, "history": history]
        
        
        do {
            
            guard JSONSerialization.isValidJSONObject(json) else {
                throw TrackerErr.invalidJson
            }
            let requestBody =  try JSONSerialization.data(withJSONObject: json)
            
            
            guard let urlRequest = prepareRequest("POST", getUrl(selectUser:userCat, selectUrl:"favourite"), requestBody, account: getAccount ?? "", session: getSessionID ?? "") else { return }
            
            URLSession.shared.dataTask(with: urlRequest) {(data, response, error) in
                if data != nil {
                    
                    
                    DispatchQueue.main.async {
                        
                        print("RemoveFromFavourite")
                    }
                } else if error != nil {
                    
                    DispatchQueue.main.async {
                        print("Error RemoveFromFavourite")
                    }
                }
            }.resume()
            
        } catch {
            
            print("Error RemoveFromFavourite")
        }
    }
}

public func AddToCart (product: Product) {
    
    var getSessionID: String? {return UserDefaults.standard.object(forKey: session_pref) as? String}
    var getAccount: String? {return UserDefaults.standard.object(forKey: account_pref) as? String }
    
    if getSessionID != nil && getAccount != nil  {
        
        var map = TrackingMapBilder(product)
        
        map ["action"] = "productAdd"
        
        let lastUpdate = Int(Date().timeIntervalSince1970)
        
        let cart: [String:Any] = ["lastUpdate": lastUpdate, "products": [["productId": map["productId"]]]]
        
        let history: [[String:Any]] = [map]
        
        let json: [String : Any] = ["cart": cart, "history": history]
        
        do {
            
            guard JSONSerialization.isValidJSONObject(json) else {
                throw TrackerErr.invalidJson
            }
            
            let requestBody =  try JSONSerialization.data(withJSONObject: json)
            
            guard let urlRequest = prepareRequest("POST", getUrl(selectUser:userCat, selectUrl:"cart"), requestBody,  account: getAccount ?? "", session: getSessionID ?? "") else { return }
            
            URLSession.shared.dataTask(with: urlRequest) {(data, response, error) in
                if data != nil {
                    
                    
                    DispatchQueue.main.async {
                        
                        print("AddToCart")
                    }
                } else if error != nil {
                    DispatchQueue.main.async {
                        
                        print("Error AddToCart")
                    }
                }
            }.resume()
        } catch {
            
            print("Error AddToCart")
        }
    }
}


public func RemoveFromCart (product: Product) {
    
    var getSessionID: String? {return UserDefaults.standard.object(forKey: session_pref) as? String}
    var getAccount: String? {return UserDefaults.standard.object(forKey: account_pref) as? String }
    
    if getSessionID != nil && getAccount != nil  {
        
        var map = TrackingMapBilder(product)
        
        map ["action"] = "productRemove"
        
        let lastUpdate = Int(Date().timeIntervalSince1970)
        
        let cart: [String:Any] = ["lastUpdate": lastUpdate, "products": [["productId": map["productId"]]]]
        
        let history: [[String:Any]] = [map]
        
        let json: [String : Any] = ["cart": cart, "history": history]
        
        
        do {
            
            guard JSONSerialization.isValidJSONObject(json) else {
                throw TrackerErr.invalidJson
                
            }
            
            let requestBody = try JSONSerialization.data(withJSONObject: json)
            
            
            guard let urlRequest = prepareRequest("POST", getUrl(selectUser:userCat, selectUrl:"cart"), requestBody, account: getAccount ?? "", session: getSessionID ?? "") else { return }
            
            URLSession.shared.dataTask(with: urlRequest) {(data, response, error) in
                if data != nil {
                    
                    DispatchQueue.main.async {
                        
                        print("RemoveFromCart")
                        
                    }
                } else if error != nil {
                    DispatchQueue.main.async {
                        
                        print("Error RemoveFromCart")
                        
                    }
                }
            }.resume()
            
        } catch {
            
            print("Error RemoveFromCart")
            
        }
    }
}


public func ProductOpen (product: Product) {
    
    var getSessionID: String? {return UserDefaults.standard.object(forKey: session_pref) as? String}
    var getAccount: String? {return UserDefaults.standard.object(forKey: account_pref) as? String }
    
    if getSessionID != nil && getAccount != nil  {
        
        let map = TrackingMapBilder(product)
        
        let lastUpdate = Int(Date().timeIntervalSince1970)
 
        
        let product = ["id": map["productId"] ?? "", "lastUpdate": lastUpdate, "params" : map]
        
       
        
        let json: [String : Any] = ["action": "productOpen","product": product]
        
        
        do {
            
            let requestBody =   try JSONSerialization.data(withJSONObject: json)
            guard let urlRequest = prepareRequest("POST", getUrl(selectUser:userCat, selectUrl:"productOpen"), requestBody,  account: getAccount ?? "", session: getSessionID ?? "") else { return }
            
            
            
            URLSession.shared.dataTask(with: urlRequest) {(data, response, error) in
                if data != nil {
                    
                    
                    DispatchQueue.main.async {
                        
                        print("ProductOpen")
                        
                    }
                } else if error != nil {
                    DispatchQueue.main.async {
                        
                        print("Error ProductOpen")
                    }
                }
            }.resume()
            
        } catch {
            
            print("Error ProductOpen")
            
        }
    }
}

public struct Order {
    
    public init(id: String? = nil, count: Int? = nil, price: String? = nil, params: [String : Any]? = nil) {
        
        self.id = id
        self.count = count
        self.price = price
        self.params = params
    }
    
    public var id: String?
    public var count: Int?
    public var price: String?
    public var params: [String:Any]?
   
}


public func productBuy (orders: [Order], orderId: String? = nil, orderParams: [String:Any]? = nil, orderDatetime: String? = nil) {
    
    var getSessionID: String? {return UserDefaults.standard.object(forKey: session_pref) as? String}
    var getAccount: String? {return UserDefaults.standard.object(forKey: account_pref) as? String }
    
    if getSessionID != nil && getAccount != nil  {
        
        var orderId = orderId
        var sum = 0.0
        var orderInfo = [String:Any]()
        var orderFields = [String:Any]()
        var orderList = [[String:Any]]()
        var dopParams = [String:Any]()
        
        print (orders.count)
        
        
        func sumCalculation (price: Double, count: Double) throws {
            sum += price*count
        }
        
        if (orders.count != 0) {
            
            for i in 0 ... orders.count - 1 {
                
                if (orders[i].id != nil && orders[i].id != "" &&
                    orders[i].price != nil && orders[i].price != "" &&
                    orders[i].count != nil && orders[i].count ?? 1 > 0
                    
                ) {
                    
                    orderFields["productId"] = orders[i].id
                    orderFields["price"] = orders[i].price
                    orderFields["count"] = orders[i].count
                    
                    if orders[i].params != nil && orders[i].params?.keys.count != 0 {
                        
                        print ("in params")
                        
                        for (k, v) in orders[i].params! {
                            orderFields[k] = v
                        }
                    }
                    
                    print (orderFields)
                    
                    
                    do {
                        try sumCalculation(price: Double(orders[i].price ?? "0.0") ?? 0.0, count: Double(orders[i].count ?? 0))
                    }catch {
                        
                    }
                    
                    orderList.append(orderFields)
                    
                    
                }
            }
        }
        
        
        if orderId == "" || orderId == nil {orderId = UUID().uuidString.lowercased() }
        
        let orderSum = String(format: "%.2f", sum)
        
        if orderParams != nil && orderParams?.keys.count != 0 {
            
            for (k, v) in orderParams! {
                
                dopParams[k] = v
            }
        }
        
        
        dopParams["sum"] = orderSum
        
        if orderDatetime != nil {
            dopParams["orderDatetime"] = orderDatetime
        }
        
        print (orderFields)
        
        orderInfo["items"] = orderList
        orderInfo["order"] = dopParams
        
        
        let json = ["orderId": orderId as Any,
                    "orderInfo": orderInfo] as [String : Any]
        
        do {
            
            guard JSONSerialization.isValidJSONObject(json) else {
                throw TrackerErr.invalidJson
                
            }
            
            let requestBody =  try JSONSerialization.data(withJSONObject: json)
            
            
            guard let urlRequest = prepareRequest("POST", getUrl(selectUser:userCat, selectUrl:"productBuy"), requestBody,  account: getAccount ?? "", session: getSessionID ?? "") else { return }
            
            URLSession.shared.dataTask(with: urlRequest) {(data, response, error) in
                if data != nil {
                    DispatchQueue.main.async {
                        
                        print("productBuy")
                    }
                } else if error != nil {
                    DispatchQueue.main.async {
                        
                        print("Error productBuy")
                    }
                }
            }.resume()
            
        } catch {
            
            print("Error productBuy")
        }
    }
}


 public func clickPush (pd: [String:Any]){
     
    let urlFromMap = getUrl(selectUser:userCat, selectUrl:"clickPush")
    
    var getSessionID: String? {return UserDefaults.standard.object(forKey: session_pref) as? String}
    var getAccount: String? {return UserDefaults.standard.object(forKey: account_pref) as? String }
     
    guard let url = URL(string: urlFromMap) else { return }
     
     if getAccount != nil && getSessionID != nil {
         
         let account = getAccount ?? ""
         let session = getSessionID ?? ""
         
         print(account)
         
         var urlRequest = URLRequest(url: url)
         urlRequest.addValue(account, forHTTPHeaderField: "X-Account")
         
         urlRequest.addValue("application/json", forHTTPHeaderField: "content-type")
         urlRequest.httpMethod = "POST"
         
         let data = pd
         
         let json: [String: Any] = ["sessionId": session, "personId": Int(data["personId"] as! String) ?? 0, "messageId": Int(data["messageId"] as! String) ?? -1, "intent": Int(data["intent"] as! String) ?? 2, "url": data["url"]as! String]
         
         
         let jsonData = try? JSONSerialization.data(withJSONObject: json)
         urlRequest.httpBody = jsonData
         URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
             if data != nil {
                 
                 print("clickPush")
                 
             } else if error != nil {
                 
                 print("Error clickPush")
             }
         }.resume()
     }
}

public func pushClickAction (userInfo: [AnyHashable : Any], Identifier: String) {

    let intent_0 = (userInfo[AnyHashable("intent_0")] as? String)
    let intent_1 = (userInfo[AnyHashable("intent_1")] as? String)
    let intent_2 = (userInfo[AnyHashable("intent_2")] as? String)
    let intent_3 = (userInfo[AnyHashable("intent_3")] as? String)
  
    let url_0 = (userInfo[AnyHashable("url")] as? String)
    let url_1 = (userInfo[AnyHashable("url_1")] as? String)
    let url_2 = (userInfo[AnyHashable("url_2")] as? String)
    let url_3 = (userInfo[AnyHashable("url_3")] as? String)
    

    
    func intentAction (Identifier: String) {
        
        if Identifier == "com.apple.UNNotificationDefaultActionIdentifier" {
             
            var dataForPushClick = [String: Any]()
            
            dataForPushClick = [
              
              "personId": userInfo[AnyHashable("personId")] ?? "0",
              "messageId": userInfo[AnyHashable("messageId")] ?? "0",
              "intent": intent_0 ?? "",
              "url": url_0 ?? ""
              
            ]
            
            clickPush (pd: dataForPushClick)
                              
            switch intent_0 {
                
            case "0":
                
                print("deep link")
                
            case "1":
              
                do {
                    if let url = URL(string: url_0 ?? ""), UIApplication.shared.canOpenURL(url) {
                        
                        UIApplication.shared.open(url)
                    }
                }
                 
            default:
                print("openApp")
   
            }
        }
        
        if Identifier == "button1" {
            
            var dataForPushClick = [String: Any]()
            
            dataForPushClick = [
              
              "personId": userInfo[AnyHashable("personId")] ?? "0",
              "messageId": userInfo[AnyHashable("messageId")] ?? "0",
              "intent": intent_1 ?? "",
              "url": url_1 ?? ""
              
            ]
            
            clickPush (pd: dataForPushClick)
         
            switch intent_1 {
                
            case "0":
                print("deep link")
                
            case "1":
                do {
                    if let url = URL(string: url_1 ?? ""), UIApplication.shared.canOpenURL(url) {
                        
                        UIApplication.shared.open(url)
                    }
                }
            default:
                print("openApp")
                
            }
        }
        if Identifier == "button2" {
            
            var dataForPushClick = [String: Any]()
            
            dataForPushClick = [
              
              "personId": userInfo[AnyHashable("personId")] ?? "0",
              "messageId": userInfo[AnyHashable("messageId")] ?? "0",
              "intent": intent_2 ?? "",
              "url": url_2 ?? ""
              
            ]
            
            clickPush (pd: dataForPushClick)
         
            switch intent_2 {
            case "0":
                print("deep link")
            case "1":
                do {
                    if let url = URL(string: url_2 ?? ""), UIApplication.shared.canOpenURL(url) {
                        
                        UIApplication.shared.open(url)
                    }
                }
            default:
                print("openApp")
                
            }
        }
        
        if Identifier == "button3" {
            
            var dataForPushClick = [String: Any]()
            
            dataForPushClick = [
              
              "personId": userInfo[AnyHashable("personId")] ?? "0",
              "messageId": userInfo[AnyHashable("messageId")] ?? "0",
              "intent": intent_3 ?? "",
              "url": url_3 ?? ""
              
            ]
            
            clickPush (pd: dataForPushClick)
         
            switch intent_3 {
                
            case "0":
                print("deep link")
            case "1":
                do {
                    if let url = URL(string: url_3 ?? ""), UIApplication.shared.canOpenURL(url) {
                        
                        UIApplication.shared.open(url)
                    }
                }
            default:
                print("openApp")
                
            }
        }
    }
    
   intentAction (Identifier: Identifier)
    
}

public func devSwitch () {
    
    userCat = "dev"
    
}

class LibInitStatus: NSObject {
    
    @objc dynamic var statusName = "no_init"
     
}

class LibInitObserver: NSObject {
            @objc var status: LibInitStatus
    var observation: NSKeyValueObservation?
    
    init(object: LibInitStatus) {
        self.status = object
        super.init()
        
        observation = observe(\.status.statusName, options: [.old, .new], changeHandler: { object, change in
            
        
            
            libraryInit = true
            
            if (addContactRequest) {
                
                var getEmail: String? { return UserDefaults.standard.object(forKey: email_pref) as? String }
                var getPhone: String? {return UserDefaults.standard.object(forKey: phone_pref) as? String }
                
                addContact(email: getEmail ?? "", phone: getPhone ?? "", params: contactParams)
                
            
                }
            })
        }
    }


class AddContactRequestStatus: NSObject {
    
    @objc dynamic var status = "no_request"
     
}


class AddContactRequestObserver: NSObject {
            @objc var status: AddContactRequestStatus
    var observation: NSKeyValueObservation?
    
    init(object: AddContactRequestStatus) {
        self.status = object
        super.init()
        
        observation = observe(\.status.status, options: [.old, .new], changeHandler: { object, change in
            
            addContactRequest = true
            
            
            })
        }
    }


enum TrackerErr : Error{
    case emptyProductId
    case notExistedProductId
    case emptyCart
    case emptyFavourite
    case emptyEmail
    case emptyEmailAndPhone
    case invalidJson
    case badRequest
    case emptyProducts
    case alreadyLoggedIn
    case emptySession
}
