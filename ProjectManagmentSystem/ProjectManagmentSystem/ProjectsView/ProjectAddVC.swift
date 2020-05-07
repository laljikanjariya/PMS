//
//  ProjectAddVC.swift
//  ProjectManagmentSystem
//
//  Created by Siya9 on 08/12/16.
//  Copyright © 2016 Siya9. All rights reserved.
//

import UIKit
import CoreData

class ProjectAddVC: UIViewController,UserPlatformDelegate, UserListDelegate {

    @IBOutlet weak var txtPName: UITextField!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var btnPlatform: UIButton!
    @IBOutlet weak var btnAssignTo: UIButton!
    var objProject : Project!
    var managedObjectContext : NSManagedObjectContext!

    override func viewDidLoad() {
        super.viewDidLoad()
        managedObjectContext = DBUpdateManager.createPrivateMOC(parentMOC: DatabaseManager.sharedInstance().managedObjectContext)
        objProject = (DBUpdateManager.insertObject(entityName: "Project", moc: managedObjectContext) as! Project)
        objProject.pStartDate = Date()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        txtPName.text = objProject.pName
    }
    @IBAction func btnBackTapped(_ sender: UIButton) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    @IBAction func btnSaveTapped(_ sender: UIButton) {
        objProject.pName = txtPName.text
        MBProgressHUD.showAdded(to: self.view, animated: true)

        if objProject.pStartDate == nil {
            objProject.pStartDate = Date()
        }
        let objParse:PFObject! = PFObject.init(className: "PMSProject")

        objParse["pName"] = objProject.pName
        objParse["assignTo"] = PFObject.init(withoutDataWithClassName: "PMSUser", objectId:objProject.assignTo?.objectId)
        objParse["platform"] = PFObject.init(withoutDataWithClassName: "PMSPlatform", objectId:objProject.platform?.objectId)
        objParse["isDeleted"] = false
        objParse.saveInBackground { (isSaved:Bool, error:Error?) in
            if isSaved {
                self.objProject.uID = objParse["uID"] as! Int64
                self.objProject.objectId = objParse.objectId
                DBUpdateManager.saveContext(parentMOC: self.managedObjectContext)
                _ = self.navigationController?.popViewController(animated: true)
            }
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
    
    @IBAction func btnPlatformTapped(_ sender: Any) {
        objProject.pName = txtPName.text
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let userPlatformVC : UserPlatformVC = storyBoard.instantiateViewController(withIdentifier: "UserPlatformVC_sid") as! UserPlatformVC
        if ((objProject?.platform) != nil) {
            userPlatformVC.selectedPlatform = [(objProject?.platform )!]
        }
        userPlatformVC.managedObjectContext = self.managedObjectContext
        userPlatformVC.delegate = self
        self.navigationController?.pushViewController(userPlatformVC, animated: true)
    }
    public func willSelect(platforn: Platform) -> Bool {
        return true
    }
    public func didSelectedLists(platforns : [Platform]) {
        objProject?.platform = platforns.first
        _ = self.navigationController?.popViewController(animated: true)
        updateUI()
    }
    @IBAction func btnAssignTapped(_ sender: UIButton) {
        objProject.pName = txtPName.text
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let userListVC : UserListVC = storyBoard.instantiateViewController(withIdentifier: "UserListVC_sid") as! UserListVC
        if ((objProject?.assignTo) != nil) {
            userListVC.selectedUser = [(objProject?.assignTo)!]
        }
        userListVC.managedObjectContext = self.managedObjectContext
        userListVC.delegate = self
        self.navigationController?.pushViewController(userListVC, animated: true)

    }
    public func willSelect(user: User) -> Bool {
        return true
    }
    public func didSelectedLists(user : [User]) {
        objProject?.assignTo = user.first
        _ = self.navigationController?.popViewController(animated: true)
        updateUI()
    }
    func updateUI() {
        txtPName.text = objProject.pName
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "MM/dd/yyyy"
        lblTime?.text = dayTimePeriodFormatter.string(from: objProject.pStartDate!)
        if objProject.platform != nil {
            btnPlatform.setTitle(objProject.platform?.lName, for: .normal)
            btnPlatform.isUserInteractionEnabled = false
        }
        else{
            btnPlatform.setTitle("Select Platform", for: .normal)
            btnPlatform.isUserInteractionEnabled = true
        }
        if (objProject.assignTo != nil) && (objProject.assignTo?.uName?.count)! > 0 {
            btnAssignTo.setTitle(objProject.assignTo?.uName, for: .normal)
        }
        else{
            btnAssignTo.setTitle("Select Assign User", for: .normal)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
