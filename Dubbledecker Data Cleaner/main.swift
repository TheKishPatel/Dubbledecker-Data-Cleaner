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
            print("✅ routeIDArray")
            
            // get all sequences for each id
            for sequence in routeIDArray {
                
                let sequenceURL = URL(string: "https://api.tfl.gov.uk/Line/\(sequence)/Route/Sequence/all")
                
                URLSession.shared.dataTask(with:sequenceURL!, completionHandler: {(data, response, error) in
                    guard let data = data, error == nil else { return }
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! Dictionary<String, Any>
                        let sequence = json as Dictionary<String, Any>
                        let sequenceID: String = sequence["lineId"] as! String
                        
                        var jsonData: Data!
                        do {
                            jsonData = try JSONSerialization.data(withJSONObject: sequence, options: JSONSerialization.WritingOptions())
                            let jsonString = String(data: jsonData as Data, encoding: String.Encoding.utf8)
                            print("✅ Created \(sequenceID) String")
                        } catch let error as NSError {
                            print("Array to JSON conversion failed: \(error.localizedDescription)")
                        }
                        
                        // Write that JSON to the file created earlier
                        let jsonFilePath = getDocumentsDirectory().appendingPathComponent("\(sequence).json")
                        do {
                            let file = try FileHandle(forWritingTo: jsonFilePath)
                            file.write(jsonData)
                            print("✅ Wrote \(sequence) to disk")
                        } catch let error as NSError {
                            print("Couldn't write to file: \(error.localizedDescription)")
                        }
                        
                    } catch let error as NSError {
                        print(error)
                    }
                }).resume()
            }
            
        } catch let error as NSError {
            print(error)
        }
    }).resume()
    
    
    
    
    // Infinitely run the main loop to wait for our request.
    // Only necessary if you are testing in the command line.
    RunLoop.main.run()
}

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

startCoordination()
