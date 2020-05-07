//
//  UserLoginVC.swift
//  ProjectManagmentSystem
//
//  Created by Siya9 on 29/11/16.
//  Copyright © 2016 Siya9. All rights reserved.
//

import UIKit
import CoreData

class UserLoginVC: UIViewController {

    @IBOutlet weak var txtMobileNo: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        // Do any additional setup after loading the view.
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func btnLoginTapped(_ sender: UIButton) {
        if (txtPassword.text?.count)! > 0 && (txtPassword.text?.count)! > 0 {
            let keyValues : [String : AnyObject] = ["uMobile":txtMobileNo.text as AnyObject,"uPassword":txtPassword.text as AnyObject]
            let obj = DBUpdateManager.fetchEntityWith(entityName: "User", keyValues: keyValues , moc: DatabaseManager.sharedInstance().managedObjectContext)
            if (obj?.count)! > 0 {
                DatabaseManager.sharedInstance().currentUser = obj?.first as? User
                let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                let projectDetailVC : ProjectListVC = storyBoard.instantiateViewController(withIdentifier: "ProjectListVC_sid") as! ProjectListVC
                self.navigationController?.pushViewController(projectDetailVC, animated: true)
                
//                let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
//                let projectDetailVC : UserSignUpVC = storyBoard.instantiateViewController(withIdentifier: "UserSignUpVC_sid") as! UserSignUpVC
//                projectDetailVC.objUser = obj?.first as! User
//                self.navigationController?.pushViewController(projectDetailVC, animated: true)
            }
        }
    }
    @IBAction func btnSignUpTapped(_ sender: UIButton) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let userSignUpVC : UserSignUpVC = storyBoard.instantiateViewController(withIdentifier: "UserSignUpVC_sid") as! UserSignUpVC
        
        userSignUpVC.objMOC = DBUpdateManager.createPrivateMOC(parentMOC: DatabaseManager.sharedInstance().managedObjectContext)
        self.navigationController?.pushViewController(userSignUpVC, animated: true)
    }
}
