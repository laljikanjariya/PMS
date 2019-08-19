 //
//  UtityManager.swift
//  ProjectManagmentSystem
//
//  Created by Siya9 on 29/11/16.
//  Copyright © 2016 Siya9. All rights reserved.
//

import UIKit

class UtilityManager: NSObject {
    class func getDurationFrom(fromDate:Date , toDate:Date?) -> String{
        var todate1 = toDate
        
        if todate1 == nil {
            todate1 = Date()
        }
        let calendar = NSCalendar.current as NSCalendar
        let dayHourMinuteSecond: NSCalendar.Unit = [.day, .hour, .minute, .second]

        let components : DateComponents = calendar.components(dayHourMinuteSecond, from: fromDate, to: toDate!, options: [])
        
        var timeString : String
        
        if components.day! > 7 {
            timeString = ""
        }
        else if components.day! > 0 {
            timeString = "Day \(components.day!) Ago"
        }
        else if components.hour! > 0 {
            timeString = "Hour \(components.hour!) Ago"
        }
        else if components.minute! > 0 {
            timeString = "Minute \(components.minute!) Ago"
        }
        else{
            timeString = "Just Now"
        }
        return timeString;
    }
}
