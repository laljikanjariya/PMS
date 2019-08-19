//
//  SnycManager.swift
//  ProjectManagmentSystem
//
//  Created by Siya9 on 07/12/16.
//  Copyright © 2016 Siya9. All rights reserved.
//

import UIKit
import CoreData

class SnycManager: NSObject {
    static var databaseSnycNotification:String = "databaseSnycNotificationKey"
    static var userSnycNotification:String = "userSnycNotificationKey"
    static var projectSnycNotification:String = "projectSnycNotificationKey"
    static var taskSnycNotification:String = "taskSnycNotificationKey"
    static var commentSnycNotification:String = "commentSnycNotificationKey"
    static var platformSnycNotification:String = "platformSnycNotificationKey"

//    var timerUser:Timer?
    var timerProject:Timer?
    var timerTask:Timer?
    var timerComment:Timer?

    class func sharedInstance()-> SnycManager {
        struct Static {
            static let instance: SnycManager = SnycManager()
        }
        return Static.instance
    }
    func connectDatabase(serverIP: String,serverPort: String) {
        let configuration = ParseClientConfiguration {
            // Add your Parse applicationId:
            $0.applicationId = "PMS"
            // Uncomment and add your clientKey (it's not required if you are using Parse Server):
            $0.clientKey = "PMS"
            
            // Uncomment the following line and change to your Parse Server address;
            let url:String = "http://"+serverIP+":"+serverPort+"/parse"
            $0.server = url
            
            // Enable storing and querying data from Local Datastore.
            // Remove this line if you don't want to use Local Datastore features or want to use cachePolicy.
            $0.isLocalDatastoreEnabled = true
        }
        Parse.initialize(with: configuration)
        UserDefaults.standard.removeObject(forKey: "UserUpdateAt")
        UserDefaults.standard.removeObject(forKey: "ProjectUpdateAt")
        UserDefaults.standard.removeObject(forKey: "TaskUpdateAt")
        UserDefaults.standard.removeObject(forKey: "CommentUpdateAt")
        UserDefaults.standard.synchronize()
    }
    class func testConnection(block: PFIntegerResultBlock?){
        let query:PFQuery = PFQuery.init(className: "PMSUser")
        query.countObjectsInBackground(block: block)
    }
    class func snycDatabase()  {
        NotificationCenter.default.addObserver(SnycManager.sharedInstance(),selector: #selector(SnycManager.snycPlatformComlited(notification:)),name: NSNotification.Name(rawValue: "platformSnycNotificationKey"),object: nil)
        SnycManager.forceUpdatePlatformClass(isSendNotification: true)
    }
    func snycPlatformComlited(notification: Notification){
        NotificationCenter.default.removeObserver(self)

        NotificationCenter.default.addObserver(self,selector: #selector(snycUserComlited),name: NSNotification.Name(rawValue: SnycManager.userSnycNotification),object: nil)
        SnycManager.forceUpdateUserClass(isSendNotification: true)
    }
    func snycUserComlited(){
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self,selector: #selector(snycProjectComlited),name: NSNotification.Name(rawValue: SnycManager.projectSnycNotification),object: nil)
        SnycManager.forceUpdateProjectClass(isSendNotification: true)
    }
    func snycProjectComlited(){
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self,selector: #selector(snycTaskComlited),name: NSNotification.Name(rawValue: SnycManager.taskSnycNotification),object: nil)
        SnycManager.forceUpdateTaskClass(isSendNotification: true)
    }
    func snycTaskComlited(){
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self,selector: #selector(snycCommentComlited),name: NSNotification.Name(rawValue: SnycManager.commentSnycNotification),object: nil)
        SnycManager.forceUpdateCommentClass(isSendNotification: true)
    }
    func snycCommentComlited(){
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: SnycManager.databaseSnycNotification), object: nil)
    }
    
    class func forceUpdateProjectClass(isSendNotification : Bool){
        SnycManager.sharedInstance().timerProject?.invalidate()
        SnycManager.sharedInstance().timerProject = nil
        SnycManager.sharedInstance().updateProjectClass(isSendNotification: isSendNotification)
    }
    // MARK: - Project Class -
    func updateProjectClass(isSendNotification : Bool) {
        if timerProject == nil {
            timerProject = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.updateProjectClass), userInfo: nil, repeats: true);
        }
        let moc:NSManagedObjectContext = DBUpdateManager.createPrivateMOC(parentMOC: DatabaseManager.sharedInstance().managedObjectContext)
        
        let userUpdateAt:NSDate? = UserDefaults.standard.object(forKey: "ProjectUpdateAt") as? NSDate
        self.snycProjectTable(lastSnycDate: userUpdateAt,isSendNotification : isSendNotification, moc: moc)
    }
    func snycProjectTable(lastSnycDate : NSDate? ,isSendNotification : Bool, moc:NSManagedObjectContext)  {
        let query:PFQuery = PFQuery.init(className: "PMSProject")
        let moc:NSManagedObjectContext = DBUpdateManager.createPrivateMOC(parentMOC: DatabaseManager.sharedInstance().managedObjectContext)
        if lastSnycDate != nil {
            query.whereKey("updatedAt", greaterThan: lastSnycDate ?? "")
        }
        else{
            DBUpdateManager.deleteEntityWith(entityName: "Project", predicate: nil, moc: moc)
        }
        query.includeKey("assignTo")
        query.includeKey("platform")
        query.findObjectsInBackground { (projects :[PFObject]?, error:Error?) in
            print("Project Count %@",projects?.count ?? 0)
            if (projects?.count)! > 0{
                for project:PFObject in projects!{
                    self.updateProjectInfoFrom(pfProject: project, moc: moc)
                }
                let sortedArray = projects?.sorted(by: { $0.updatedAt?.compare($1.updatedAt!) == ComparisonResult.orderedDescending})
                let lastUpdate:PFObject = (sortedArray?.first)!
                UserDefaults.standard.set(lastUpdate.updatedAt, forKey: "ProjectUpdateAt")
                UserDefaults.standard.synchronize()
            }
            if moc.hasChanges{
                DBUpdateManager.saveContext(parentMOC: moc)
            }
            if isSendNotification{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: SnycManager.projectSnycNotification), object: nil)
            }
        }
    }
    func updateProjectInfoFrom(pfProject : PFObject, moc : NSManagedObjectContext)  {

        let project:Project = self.getObject(withClassName: "Project", fromUID: pfProject.value(forKey: "uID") as AnyObject, isCreate: true, moc: moc) as! Project
        if pfProject["isDeleted"] as! Bool {
            moc.delete(project)
        }
        else{
            project.uID = Int64((pfProject.object(forKey: "uID") as! NSNumber).doubleValue)
            project.objectId = pfProject.objectId
            project.pName = pfProject.value(forKey: "pName") as! String?
            project.pStartDate = pfProject.createdAt as NSDate?
            let userAssignTo:PFObject = pfProject.object(forKey: "assignTo") as! PFObject
            let user:User? = self.getObject(withClassName: "User", fromUID: userAssignTo.value(forKey: "uID") as AnyObject, isCreate: false, moc: moc) as? User
            if user != nil {
                project.assignTo = user;
                user?.addToProjects(project)
            }
            let pfPlatform:PFObject = pfProject.object(forKey: "platform") as! PFObject
            let platform:Platform? = self.getObject(withClassName: "Platform", fromUID: pfPlatform.value(forKey: "uID") as AnyObject, isCreate: true, moc: moc) as? Platform
            if platform != nil {
                project.platform = platform;
            }
        }
    }
    // MARK: - Task Class -
    class func forceUpdateTaskClass(isSendNotification : Bool){
        SnycManager.sharedInstance().timerTask?.invalidate()
        SnycManager.sharedInstance().timerTask = nil
        SnycManager.sharedInstance().updateTaskClass(isSendNotification : isSendNotification)
    }
    func updateTaskClass(isSendNotification : Bool) {
        if timerTask == nil {
            timerTask = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(self.updateTaskClass(isSendNotification:)), userInfo: false, repeats: true);
        }
        let moc:NSManagedObjectContext = DBUpdateManager.createPrivateMOC(parentMOC: DatabaseManager.sharedInstance().managedObjectContext)
        
        let taskUpdateAt:NSDate? = UserDefaults.standard.object(forKey: "TaskUpdateAt") as? NSDate
        self.snycTaskTable(lastSnycDate: taskUpdateAt,isSendNotification : isSendNotification, moc: moc)
    }
    func snycTaskTable(lastSnycDate : NSDate? ,isSendNotification : Bool, moc:NSManagedObjectContext)  {
        let query:PFQuery = PFQuery.init(className: "PMSTask")
        let moc:NSManagedObjectContext = DBUpdateManager.createPrivateMOC(parentMOC: DatabaseManager.sharedInstance().managedObjectContext)
        if lastSnycDate != nil {
            query.whereKey("updatedAt", greaterThan: lastSnycDate ?? "")
        }
        else{
            DBUpdateManager.deleteEntityWith(entityName: "Task", predicate: nil, moc: moc)
        }
        query.includeKey("assignTo")
        query.includeKey("tProject")
        query.findObjectsInBackground { (tasks :[PFObject]?, error:Error?) in
            print("Task Count %@",tasks?.count ?? 0)
            if (tasks?.count)! > 0{
                for task:PFObject in tasks!{
                    self.updateTaskInfoFrom(pfTask: task, moc: moc)
                }
                let sortedArray = tasks?.sorted(by: { $0.updatedAt?.compare($1.updatedAt!) == ComparisonResult.orderedDescending})
                let lastUpdate:PFObject = (sortedArray?.first)!
                UserDefaults.standard.set(lastUpdate.updatedAt, forKey: "TaskUpdateAt")
                UserDefaults.standard.synchronize()
            }
            if moc.hasChanges{
                DBUpdateManager.saveContext(parentMOC: moc)
            }
            if isSendNotification{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: SnycManager.taskSnycNotification), object: nil)
            }        }
    }
    func updateTaskInfoFrom(pfTask : PFObject, moc : NSManagedObjectContext)  {
        let task:Task = self.getObject(withClassName: "Task", fromUID: pfTask.value(forKey: "uID") as AnyObject
            , isCreate: true, moc: moc) as! Task
        task.objectId = pfTask.objectId
        task.tName = pfTask.value(forKey: "tName") as! String?
        
        let userAssignTo:PFObject = pfTask.object(forKey: "assignTo") as! PFObject
        let user:User? = self.getObject(withClassName: "User", fromUID: userAssignTo.value(forKey: "uID") as AnyObject, isCreate: false, moc: moc) as? User
        if user != nil {
            task.assignTo = user;
            user?.addToTasksManage(task)
        }
        
        let pfPlatform:PFObject = pfTask.object(forKey: "tProject") as! PFObject
        let project:Project? = self.getObject(withClassName: "Project", fromUID: pfPlatform.value(forKey: "uID") as AnyObject, isCreate: true, moc: moc) as? Project
        if project != nil {
            task.project = project;
        }
        
        for devUID in pfTask["participence"] as! [NSNumber] {
            let user:User = self.getObject(withClassName: "User", fromUID: devUID as AnyObject, isCreate: true, moc: moc) as! User
            task.addToParticipence(user)
            user.addToTasksDevelop(task)
        }
    }
    
    // MARK: - Comment Class -
    class func forceUpdateCommentClass(isSendNotification : Bool){
        SnycManager.sharedInstance().timerComment?.invalidate()
        SnycManager.sharedInstance().timerComment = nil
        SnycManager.sharedInstance().snycCommentTable(isSendNotification : isSendNotification)
    }
    func snycCommentTable(isSendNotification : Bool){
        if timerComment == nil {
            timerComment = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.snycCommentTable(isSendNotification:)), userInfo: false, repeats: true);
        }
        let moc:NSManagedObjectContext = DBUpdateManager.createPrivateMOC(parentMOC: DatabaseManager.sharedInstance().managedObjectContext)
        
        let userUpdateAt:NSDate? = UserDefaults.standard.object(forKey: "CommentUpdateAt") as? NSDate
        self.snycCommentTable(lastSnycDate: userUpdateAt,isSendNotification : isSendNotification, moc: moc)
    }
    func snycCommentTable(lastSnycDate : NSDate? ,isSendNotification : Bool, moc:NSManagedObjectContext)  {
        let query:PFQuery = PFQuery.init(className: "PMSComment")
        let moc:NSManagedObjectContext = DBUpdateManager.createPrivateMOC(parentMOC: DatabaseManager.sharedInstance().managedObjectContext)
        if lastSnycDate != nil {
            query.whereKey("updatedAt", greaterThan: lastSnycDate ?? "")
        }
        else{
            DBUpdateManager.deleteEntityWith(entityName: "Comment", predicate: nil, moc: moc)
        }
        query.includeKey("task")
        query.includeKey("user")
        query.findObjectsInBackground { (comments :[PFObject]?, error:Error?) in
            print("Comment Count %@",comments?.count ?? 0)
            if (comments?.count)! > 0{
                for comment:PFObject in comments!{
                    self.updateCommentInfoFrom(pfComment: comment, moc: moc)
                }
                let sortedArray = comments?.sorted(by: { $0.updatedAt?.compare($1.updatedAt!) == ComparisonResult.orderedDescending})
                let lastUpdate:PFObject = (sortedArray?.first)!
                UserDefaults.standard.set(lastUpdate.updatedAt, forKey: "CommentUpdateAt")
                UserDefaults.standard.synchronize()
            }
            if moc.hasChanges{
                DBUpdateManager.saveContext(parentMOC: moc)
            }
            if isSendNotification{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: SnycManager.commentSnycNotification), object: nil)
            }
        }
    }
    func updateCommentInfoFrom(pfComment : PFObject, moc : NSManagedObjectContext)  {
        let comment:Comment = self.getObject(withClassName: "Comment", fromUID: pfComment.value(forKey: "uID") as AnyObject, isCreate: true, moc: moc) as! Comment
        comment.uID = Int64((pfComment.object(forKey: "uID") as! NSNumber).doubleValue)
        comment.comment = pfComment.value(forKey: "commentText") as! String?
        comment.objectId = pfComment.objectId
        
        let user:PFObject = pfComment.object(forKey: "user") as! PFObject
        let userCD:User? = self.getObject(withClassName: "User", fromUID: user.value(forKey: "uID") as AnyObject, isCreate: true, moc: moc) as? User
        if userCD != nil {
            comment.user = userCD;
        }
        
        let task:PFObject = pfComment.object(forKey: "task") as! PFObject
        let taskCD:Task? = self.getObject(withClassName: "Task", fromUID: task.value(forKey: "uID") as AnyObject, isCreate: true, moc: moc) as? Task
        if taskCD != nil {
            comment.task = taskCD;
        }
        comment.time = pfComment.createdAt as NSDate?
    }
    
    // MARK: - User Class -
    class func forceUpdateUserClass(isSendNotification : Bool){
//        SnycManager.sharedInstance().timerUser?.invalidate()
//        SnycManager.sharedInstance().timerUser = nil
        SnycManager.sharedInstance().updateUserClass(isSendNotification : isSendNotification)
    }
    func updateUserClass(isSendNotification : Bool){
//        if timerUser == nil {
//            timerUser = Timer.scheduledTimer(timeInterval: 40, target: self, selector: #selector(self.updateUserClass(isSendNotification:)), userInfo: false, repeats: true);
//        }
        
        let moc:NSManagedObjectContext = DBUpdateManager.createPrivateMOC(parentMOC: DatabaseManager.sharedInstance().managedObjectContext)
        
        let userUpdateAt:NSDate? = UserDefaults.standard.object(forKey: "UserUpdateAt") as? NSDate
        self.snycUserTable(lastSnycDate: userUpdateAt,isSendNotification : isSendNotification, moc: moc)
    }
    func snycUserTable(lastSnycDate : NSDate? ,isSendNotification : Bool, moc:NSManagedObjectContext)  {
        let query:PFQuery = PFQuery.init(className: "PMSUser")
        if lastSnycDate != nil {
            query.whereKey("updatedAt", greaterThan: lastSnycDate ?? "")
        }
        else{
            DBUpdateManager.deleteEntityWith(entityName: "User", predicate: nil, moc: moc)
        }
        query.includeKey("profileImage")
        query.findObjectsInBackground { (users :[PFObject]?, error:Error?) in
            print("User Count %@",users?.count ?? 0)
            if (users?.count)! > 0{
                for user:PFObject in users!{
                    self.updateUserInfoFrom(pfUser: user, moc: moc)
                }
                if moc.hasChanges{
                    DBUpdateManager.saveContext(parentMOC: moc)
                }
                let sortedArray = users?.sorted(by: { $0.updatedAt?.compare($1.updatedAt!) == ComparisonResult.orderedDescending})
                let lastUpdate:PFObject = (sortedArray?.first)!
                UserDefaults.standard.set(lastUpdate.updatedAt, forKey: "UserUpdateAt")
                UserDefaults.standard.synchronize()
            }
            if isSendNotification{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: SnycManager.userSnycNotification), object: nil)
            }
        }
    }
    func updateUserInfoFrom(pfUser : PFObject, moc : NSManagedObjectContext)  {

        let user:User = self.getObject(withClassName: "User", fromUID: pfUser.value(forKey: "uID") as AnyObject, isCreate: true, moc: moc) as! User
        if pfUser["isDeleted"] as! Bool {
            moc.delete(user)
        }
        else{
            user.objectId = pfUser.objectId
            user.uID = Int64((pfUser.object(forKey: "uID") as! NSNumber).doubleValue)
            user.uMobile = pfUser.value(forKey: "uMobile") as! String?
            user.uName = pfUser.value(forKey: "uName") as! String?
            user.uPassword = pfUser.value(forKey: "uPassword") as! String?
            var platforms:[Platform] = [Platform]()
            for platfornUID in pfUser["platforms"] as! [NSNumber] {
                let platform:Platform = self.getObject(withClassName: "Platform", fromUID: platfornUID as AnyObject, isCreate: true, moc: moc) as! Platform
                platforms.append(platform)
            }
            let profileImage:PFFile? = pfUser.object(forKey: "profileImage") as? PFFile
            user.profileImage = profileImage?.url
            user.removeFromPlatform(user.platform!)
            user.addToPlatform(NSSet.init(array: platforms))
        }
    }
    // MARK: - Platform Class -
    class func forceUpdatePlatformClass(isSendNotification : Bool){
        SnycManager.sharedInstance().snycPlatformTable(isSendNotification : isSendNotification)
    }
    func snycPlatformTable(isSendNotification : Bool){
        let moc:NSManagedObjectContext = DBUpdateManager.createPrivateMOC(parentMOC: DatabaseManager.sharedInstance().managedObjectContext)
        
        let userUpdateAt:NSDate? = UserDefaults.standard.object(forKey: "PlatformUpdateAt") as? NSDate
        self.snycPlatformTable(lastSnycDate: userUpdateAt,isSendNotification : isSendNotification, moc: moc)
    }
    func snycPlatformTable(lastSnycDate : NSDate? ,isSendNotification : Bool, moc:NSManagedObjectContext)  {
        let query:PFQuery = PFQuery.init(className: "PMSPlatform")
        let moc:NSManagedObjectContext = DBUpdateManager.createPrivateMOC(parentMOC: DatabaseManager.sharedInstance().managedObjectContext)
        if lastSnycDate != nil {
            query.whereKey("updatedAt", greaterThan: lastSnycDate ?? "")
        }
        else{
            DBUpdateManager.deleteEntityWith(entityName: "Platform", predicate: nil, moc: moc)
        }
        query.findObjectsInBackground { (platforms :[PFObject]?, error:Error?) in
            print("Platform Count %@",platforms?.count ?? 0)
            if (platforms?.count)! > 0{
                for project:PFObject in platforms!{
                    self.updatePlatformInfoFrom(pfProject: project, moc: moc)
                }
                let sortedArray = platforms?.sorted(by: { $0.updatedAt?.compare($1.updatedAt!) == ComparisonResult.orderedDescending})
                let lastUpdate:PFObject = (sortedArray?.first)!
                UserDefaults.standard.set(lastUpdate.updatedAt, forKey: "PlatformUpdateAt")
                UserDefaults.standard.synchronize()
            }
            if moc.hasChanges{
                DBUpdateManager.saveContext(parentMOC: moc)
            }
            if isSendNotification{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: SnycManager.platformSnycNotification), object: nil)
            }
        }
    }
    func updatePlatformInfoFrom(pfProject : PFObject, moc : NSManagedObjectContext)  {
        let platform:Platform = self.getObject(withClassName: "Platform", fromUID: pfProject.value(forKey: "uID") as AnyObject, isCreate: true, moc: moc) as! Platform
        platform.uID = Int64((pfProject.object(forKey: "uID") as! NSNumber).doubleValue)
        platform.lName = pfProject.value(forKey: "lName") as! String?
        platform.objectId = pfProject.objectId
    }
    
    
    
    func getObject(withClassName:String, fromUID:AnyObject,isCreate:Bool, moc : NSManagedObjectContext) -> NSManagedObject? {
        let keyValues : [String : AnyObject] = ["uID":fromUID as AnyObject]
        let entity = DBUpdateManager.fetchEntityWith(entityName: withClassName, keyValues: keyValues, moc: moc, isCreate: isCreate)
        entity?.setValue(fromUID, forKey: "uID")
        return entity
    }
}
