//
//  UserListVC.swift
//  ProjectManagmentSystem
//
//  Created by Siya9 on 01/12/16.
//  Copyright © 2016 Siya9. All rights reserved.
//

import UIKit
import CoreData

public protocol UserListDelegate : NSObjectProtocol{
    func willSelect(user : User)->Bool
    func didSelectedLists(user : [User])
}

class UserListCell: UITableViewCell {
    @IBOutlet var lblUName : UILabel?
    func configureWithUser(userInfo : User)  {
        self.lblUName?.text = userInfo.uName
//        self.lblUPlatform?.text = userInfo.platform?.allObjects.fir
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
}
class UserListVC: UIViewController,NSFetchedResultsControllerDelegate,UITableViewDelegate,UITableViewDataSource {

    var managedObjectContext: NSManagedObjectContext!
    @IBOutlet var tblUserList : UITableView?
    var selectedUser: [User]?
    var delegate: UserListDelegate?
    var isSingleSelection: Bool?

    
    override func viewDidLoad() {
        super.viewDidLoad()

//        self.managedObjectContext = DatabaseManager.sharedInstance().managedObjectContext
        if selectedUser == nil {
            selectedUser = [User]()
        }
        else{
            var selectedUserOlse = [User]()
            for platforn:User in selectedUser! {
                selectedUserOlse.append((managedObjectContext.object(with: platforn.objectID) as! User))
            }
            selectedUser = selectedUserOlse
        }
        if isSingleSelection == nil {
            isSingleSelection = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func btnSaveUser(sender:UIButton){
        delegate?.didSelectedLists(user: selectedUser!)
    }

    private func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if let sections = fetchedResultsController.sections {
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
        }
        return 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell : UserListCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UserListCell
        let userInfo : User = fetchedResultsController.object(at: indexPath) as! User
        cell.configureWithUser(userInfo: userInfo)
        if (selectedUser?.contains(userInfo))! {
            cell.backgroundColor = UIColor.orange
        }
        else{
            cell.backgroundColor = UIColor.white
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let userInfo : User = fetchedResultsController.object(at: indexPath) as! User
        if (delegate?.responds(to: Selector(("willSelect:platforn:"))))! {
            if (delegate?.willSelect(user: userInfo))!==false {
                return
            }
        }
        if isSingleSelection! {
            selectedUser?.removeAll()
        }
        if (selectedUser?.contains(userInfo))! {
            selectedUser?.remove(at: (selectedUser?.index(of:userInfo))!)
        }
        else{
            selectedUser?.append(userInfo)
        }
        if isSingleSelection! {
            tableView.reloadData()
        }
        else{
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        // Initialize Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        // Add Sort Descriptors
        let sortDescriptor = NSSortDescriptor(key: "uName", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Initialize Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController.init(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("An error occurred")
        }
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    private func controllerWillChangeContent(controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tblUserList?.beginUpdates()
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                self.tblUserList?.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath {
                self.tblUserList?.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            if (self.tblUserList?.indexPathsForVisibleRows?.contains(indexPath!))! {
                self.tblUserList?.reloadRows(at: [indexPath!], with: .fade)
            }
            break;
        case .move:
            if let indexPath = indexPath {
                self.tblUserList?.deleteRows(at: [indexPath], with: .fade)
            }
            
            if let newIndexPath = newIndexPath {
                self.tblUserList?.insertRows(at: [newIndexPath], with: .fade)
            }
            break;
        }
    }
    private func controllerDidChangeContent(controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tblUserList?.endUpdates()
    }
}
