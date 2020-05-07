//
//  ServerSettingVC.swift
//  ProjectManagmentSystem
//
//  Created by Siya9 on 07/12/16.
//  Copyright © 2016 Siya9. All rights reserved.
//

import UIKit

class ServerSettingVC: UIViewController {

    @IBOutlet weak var txtServerIP: UITextField!
    @IBOutlet weak var txtServerPort: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,selector: #selector(pushLoginView),name: NSNotification.Name(rawValue: SnycManager.databaseSnycNotification),object: nil)
        txtServerIP.text = "192.168.1.104"
        // Do any additional setup after loading the view.
    }
    @objc func pushLoginView() {
        MBProgressHUD.hide(for: self.view, animated: true)
        NotificationCenter.default.removeObserver(self)
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let projectDetailVC : UserLoginVC = storyBoard.instantiateViewController(withIdentifier: "UserLoginVC_sid") as! UserLoginVC
        NotificationCenter.default.removeObserver(NSNotification.Name(rawValue: SnycManager.databaseSnycNotification))
        self.navigationController?.pushViewController(projectDetailVC, animated: true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func btnConfugureParse(_ sender: UIButton) {
        if (txtServerIP.text?.count)! > 0 && (txtServerPort.text?.count)! > 0 {
            SnycManager.sharedInstance().connectDatabase(serverIP: txtServerIP.text!, serverPort: txtServerPort.text!)
            sender.isHidden = true
        }
        if (txtServerIP.text?.count)! == 0{
            txtServerIP.backgroundColor = UIColor.red
        }
        if (txtServerPort.text?.count)! == 0{
            txtServerPort.backgroundColor = UIColor.red
        }
    }
    @IBAction func btnCheckCommunication(_ sender: UIButton) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        SnycManager.testConnection(block: { (status, error) in
            if error == nil{
                SnycManager.snycDatabase()
            }
            else{
                print("fail")
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        })
    }
}
