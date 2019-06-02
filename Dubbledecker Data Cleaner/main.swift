//
//  main.swift
//  Dubbledecker Data Cleaner
//
//  Created by Kish Patel on 27/05/2019.
//  Copyright © 2019 Kish Patel. All rights reserved.
//

import Foundation

func startCoordination() {
    
    //Get latest bus IDs from routes
    let routesURL = URL(string: "https://api.tfl.gov.uk/Line/Mode/bus/Route/")
    var giantRouteDictionary : Dictionary<String, Any> = [:]
    
    URLSession.shared.dataTask(with:routesURL!, completionHandler: {(data, response, error) in
        guard let data = data, error == nil else { return }
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! Array<Any>
            let routes = json as Array<Any>
            var routeIDArray : Array<String> = []
            
            // get all ids in routes
            for route in routes {
                
                let routeDict:Dictionary<String, Any> = route as! Dictionary<String, Any>
                let routeID: String = routeDict["id"] as! String
                routeIDArray.append(routeID)
            }
            print("✅ Got array of Route IDs")
            let routeIDArrayCount = routeIDArray.count

            // get all sequences for each id
            for sequence in routeIDArray {
                
                let sequenceURL = URL(string: "https://api.tfl.gov.uk/Line/\(sequence)/Route/Sequence/all")
                
                var request = URLRequest(url: sequenceURL!)
                request.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
                
                URLSession.shared.dataTask(with:request, completionHandler: {(data, response, error) in
                    guard let data = data, error == nil else { return }
                    
                    do {
                        print("Starting Request")
                        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! Dictionary<String, Any>
                        let sequenceJSON = json as Dictionary<String, Any>
                        let sequenceID: String = sequenceJSON["lineId"] as! String
                        
                        let sequenceDictionary : Dictionary = [sequenceID:sequenceJSON]
                        giantRouteDictionary = giantRouteDictionary.merging(sequenceDictionary) { $1 }
                        
                        print("👉 Added \(sequenceID) to Giant Dictionary")
                        let giantRouteDictionaryCount = giantRouteDictionary.count
                        print("🏋️‍♀️ \(giantRouteDictionaryCount) / \(routeIDArrayCount) objects in Giant Dictionary")
                        
                        if giantRouteDictionaryCount == routeIDArrayCount {
                            
                            print("✅ Giant Dictionary Created")
                            writeDictionaryToFile(dict:giantRouteDictionary)
                        }
//
                    } catch let error as NSError {
                        print(error)
                    }
                }).resume()
            }
            

            
            
        } catch let error as NSError {
            print(error)
        }
    }).resume()
}

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

func writeDictionaryToFile(dict: Dictionary<String, Any>) {
    
    var jsonData: Data!
    var jsonString: String!
    do {
        jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        jsonString = String(data: jsonData as Data, encoding: String.Encoding.utf8)
    } catch let error as NSError {
        print("Creating strings failed: \(error.localizedDescription)")
    }

    // Start writing file
    let jsonFile = "db.json"

    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {

        let fileURL = dir.appendingPathComponent("DDBusSequences").appendingPathComponent(jsonFile)
        //writing
        do {
            try jsonString.write(to: fileURL, atomically: false, encoding: .utf8)
            print("💥💥💥 Wrote Dictionary to file 💥💥💥")
            print("👌 You can now kill the app 👌")
        }
        catch {/* error handling here */}
    }
}

startCoordination()
// Infinitely run the main loop to wait for our request.
// Only necessary if you are testing in the command line.
RunLoop.main.run()
