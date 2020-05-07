//
//  UserSignUpVC.swift
//  ProjectManagmentSystem
//
//  Created by Siya9 on 30/11/16.
//  Copyright © 2016 Siya9. All rights reserved.
//

import UIKit
import CoreData
class UserSignUpVC: UIViewController,UserPlatformDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var objUser : User!
    var objMOC : NSManagedObjectContext!
    @IBOutlet weak var txtUserName:UITextField!
    @IBOutlet weak var txtUserMobile: UITextField!
    @IBOutlet weak var txtUserPassword: UITextField!
    @IBOutlet weak var txtUserConfirmPassword: UITextField!
    @IBOutlet weak var lblUserPlatform: UILabel!
    @IBOutlet weak var btnImage: UIButton!
    var selectedImage:UIImage?
    override func viewDidLoad() {
        super.viewDidLoad()
        objMOC = DBUpdateManager.createPrivateMOC(parentMOC: DatabaseManager.sharedInstance().managedObjectContext)
        if objUser == nil {
            objUser = DBUpdateManager.insertObject(entityName: "User", moc: objMOC) as? User
        }
        else{
            self.updateUIComponents()
        }
        // Do any additional setup after loading the view.
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateUIComponents(){
        var strPlatform = ""
        for platforn:Platform in (objUser?.platform?.allObjects as?[Platform])! {
            strPlatform.append(platforn.lName! + ", ")
        }
        if strPlatform.count == 0 {
            strPlatform = "Select your platform"
        }
        lblUserPlatform.text = strPlatform
        txtUserName.text = objUser?.uName
        txtUserMobile.text = objUser?.uMobile
    }
    
    @IBAction func btnUserImage(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage.rawValue] as? UIImage {
            btnImage.setImage(pickedImage, for: .normal)
            selectedImage = pickedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnPlatformTapped(_ sender: UIButton) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let userPlatformVC : UserPlatformVC = storyBoard.instantiateViewController(withIdentifier: "UserPlatformVC_sid") as! UserPlatformVC
        userPlatformVC.selectedPlatform = objUser?.platform?.allObjects as! [Platform]?
        userPlatformVC.delegate = self
        userPlatformVC.isSingleSelection = false
        userPlatformVC.selectedPlatform = objUser?.platform?.allObjects as! [Platform]?
        userPlatformVC.managedObjectContext = self.objMOC
        self.navigationController?.pushViewController(userPlatformVC, animated: true)
    }
    
    public func willSelect(platforn: Platform) -> Bool {
        return true
    }
    public func didSelectedLists(platforns : [Platform]) {
        objUser?.removeFromPlatform((objUser?.platform)!)
        
        var strPlatform = ""
        var platform = [NSManagedObject]()

        for platforn:Platform in platforns {
            strPlatform.append(platforn.lName! + ", ")
            platform.append(platforn)
        }
        objUser?.addToPlatform(NSSet.init(array: platform))
        lblUserPlatform.text = strPlatform
        _ = self.navigationController?.popViewController(animated: true)
    }
    //MARK: - Sign Up -
    @IBAction func btnSingUpTapped(_ sender: Any) {
        txtUserName.backgroundColor = UIColor.green
        txtUserMobile.backgroundColor = UIColor.green
        txtUserPassword.backgroundColor = UIColor.green
        txtUserConfirmPassword.backgroundColor = UIColor.green
        lblUserPlatform.backgroundColor = UIColor.green
        var isSave:Bool = true
        if (txtUserName.text?.count)! == 0 {
            txtUserName.backgroundColor = UIColor.red
            isSave = false
        }
        if (txtUserMobile.text?.count)! == 0 {
            txtUserMobile.backgroundColor = UIColor.red
            isSave = false
        }
        if (txtUserPassword.text?.count)! == 0 {
            txtUserPassword.backgroundColor = UIColor.red
            txtUserConfirmPassword.backgroundColor = UIColor.red
            isSave = false
        }
        if txtUserPassword.text != txtUserConfirmPassword.text {
            txtUserPassword.backgroundColor = UIColor.red
            txtUserConfirmPassword.backgroundColor = UIColor.red
            isSave = false
        }
        if objUser?.platform?.allObjects.count == 0 {
            lblUserPlatform.backgroundColor = UIColor.red
            isSave = false
        }
        if isSave {
            MBProgressHUD.showAdded(to: self.view, animated: true)
            let newPlatform = PFObject(className:"PMSUser")
            newPlatform["uName"] = self.txtUserName.text
            newPlatform["uMobile"] = self.txtUserMobile.text
            newPlatform["uPassword"] = self.txtUserPassword.text
            var platforms:[NSNumber] = [NSNumber]()
            for platforn:Platform in (self.objUser?.platform?.allObjects as?[Platform])! {
                platforms.append(NSNumber(value: platforn.uID))
            }
            newPlatform["platforms"] = platforms
            newPlatform["isDeleted"] = false
            if selectedImage != nil {

                let imageData = selectedImage!.pngData()
                let imageFile = PFFile(name:"image.png", data:imageData!)
                newPlatform["profileImage"] = imageFile
            }
            newPlatform.saveInBackground(block: { (isSaved:Bool, error:Error?) in
                if isSaved {
                    self.objUser?.uMobile = self.txtUserMobile.text
                    self.objUser?.uPassword = self.txtUserPassword.text
                    self.objUser?.uName = self.txtUserName.text
                    self.objUser.uID = newPlatform["uID"] as! Int64
                    self.objUser.objectId = newPlatform.objectId
                    DBUpdateManager.saveContext(parentMOC: self.objMOC)
                    _ = self.navigationController?.popViewController(animated: true)
                }
                MBProgressHUD.hide(for: self.view, animated: true)
            })
        }
    }
    func save(withFile : PFFile?) {

        
    }
}
