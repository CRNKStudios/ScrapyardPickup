//
//  FileWriter.swift
//  ScrapyardPickup
//
//  Created by Bob on 2017-03-28.
//  Copyright © 2017 CRNK Studios. All rights reserved.
//

import Foundation

public class FileWriter {
    
    // reads a file back as a string
    class func readFile(filename: String) ->String {
        var data:String;
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let path = dir.appendingPathComponent(filename)
            
            
            // read data first
            do {
                data = try String(contentsOf: path, encoding: String.Encoding.utf8);
                
                return data;
            }
            catch {
                /* error handling here */
                NSLog("@error reading data");
            }
        }

        return "";
    }
    
    // writes to a file
    class func writeFile(filename: String, contents:String) {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let path = dir.appendingPathComponent(filename)
            
            
            // writing
            do {
                try contents.write(to: path, atomically: false, encoding: String.Encoding.utf8)
            }
            catch {
                /* error handling here */
                NSLog("@error writing");
            }
        }
    }
    
}
