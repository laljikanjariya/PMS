//
//  TaksAddVC.swift
//  ProjectManagmentSystem
//
//  Created by Siya9 on 08/12/16.
//  Copyright © 2016 Siya9. All rights reserved.
//

import UIKit
import CoreData

class TaksAddVC: UIViewController,UserListDelegate {

    var objProject : Project!
    var objTask : Task!
    var managedObjectContext: NSManagedObjectContext!
    var isAssignTo:Bool!
    
    @IBOutlet weak var txtTName: UITextField!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var btnAssignTo: UIButton!
    @IBOutlet weak var btnParticipanceTo: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        objTask = DBUpdateManager.insertObject(entityName: "Task", moc: managedObjectContext) as? Task
        objTask.tStartTime = Date()
        objTask.tStatus = 1
        updateUI()
        // Do any additional setup after loading the view.
    }

    @IBAction func btnBackTapped(_ sender: UIButton) {
        MBProgressHUD.hide(for: self.view, animated: true)
        NotificationCenter.default.removeObserver(NSNotification.Name(rawValue: SnycManager.taskSnycNotification))
        _ = self.navigationController?.popViewController(animated: true)
    }
    @IBAction func btnSaveTapped(_ sender: UIButton) {
        objTask.tName = txtTName.text
        MBProgressHUD.showAdded(to: self.view, animated: true)
        objTask.tStartTime = Date()
        let objParse:PFObject! = PFObject.init(className: "PMSTask")

        objParse["tName"] = objTask.tName
        objParse["assignTo"] = PFObject.init(withoutDataWithClassName: "PMSUser", objectId:objTask.assignTo?.objectId)
        objParse["tProject"] = PFObject.init(withoutDataWithClassName: "PMSProject", objectId:objProject.objectId)
        
        var participencs:[NSNumber] = [NSNumber]()
        for participenc:User in (objTask.participence?.allObjects as?[User])! {
            participencs.append(NSNumber(value: participenc.uID))
        }
        objParse["participence"] = participencs
        
        objParse["isDeleted"] = false
        objParse.saveInBackground { (isSaved:Bool, error:Error?) in
            if isSaved {
                self.objTask.uID = objParse["uID"] as! Int64
                self.objTask.objectId = objParse.objectId
                DBUpdateManager.saveContext(parentMOC: self.managedObjectContext)
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(self.btnBackTapped(_:)),
                    name: NSNotification.Name(rawValue: SnycManager.taskSnycNotification),
                    object: nil)
                SnycManager.forceUpdateTaskClass(isSendNotification: true)
            }
            else{
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
    }
    
    @IBAction func btnAssignTapped(_ sender: UIButton) {
        objTask.tName = txtTName.text
        isAssignTo = true
        btnUserTapped()
    }
    @IBAction func btnParticipanceTapped(_ sender: UIButton) {
        objTask.tName = txtTName.text
        isAssignTo = false
        btnUserTapped()
    }
    
    func btnUserTapped() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let userListVC : UserListVC = storyBoard.instantiateViewController(withIdentifier: "UserListVC_sid") as! UserListVC
        if isAssignTo == true {
            if ((objTask?.assignTo) != nil) {
                userListVC.selectedUser = [(objTask?.assignTo)!]
            }
        }
        else {
            if ((objTask?.participence) != nil) && ((objTask?.participence?.allObjects.count)! > 0) {
                userListVC.selectedUser = objTask?.participence?.allObjects as! [User]?
            }
        }

        userListVC.managedObjectContext = self.managedObjectContext
        userListVC.delegate = self
        userListVC.isSingleSelection = isAssignTo
        self.navigationController?.pushViewController(userListVC, animated: true)
    }
    public func willSelect(user: User) -> Bool {
        return true
    }
    public func didSelectedLists(user : [User]) {
        if isAssignTo == true {
            objTask.assignTo = user.first! as User
        }
        else {
            objTask.removeFromParticipence(objTask.participence!)
            objTask.addToParticipence(NSSet.init(array: user))
        }
        updateUI()
        _ = self.navigationController?.popViewController(animated: true)
    }
    func updateUI()  {
        txtTName.text = objTask.tName
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "MM/dd/yyyy"
        lblDate?.text = dayTimePeriodFormatter.string(from: objTask.tStartTime!)
        if (objTask.assignTo != nil) && (objTask.assignTo?.uName?.count)! > 0 {
            btnAssignTo.setTitle(objTask.assignTo?.uName, for: .normal)
        }
        else{
            btnAssignTo.setTitle("Select Assign User", for: .normal)
        }
        var strUserName = ""
        for user:User in (objTask?.participence?.allObjects as?[User])! {
            strUserName.append(user.uName! + ", ")
        }
        if strUserName.count == 0 {
            strUserName = "Select your platform"
        }
        btnParticipanceTo.setTitle(strUserName, for: .normal)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
