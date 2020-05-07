//
//  UserPlatformVC.swift
//  ProjectManagmentSystem
//
//  Created by Siya9 on 30/11/16.
//  Copyright © 2016 Siya9. All rights reserved.
//

import UIKit
import CoreData

public protocol UserPlatformDelegate : NSObjectProtocol{
    func willSelect(platforn : Platform)->Bool
    func didSelectedLists(platforns : [Platform])
}

class PlatformListCell: UITableViewCell {
    @IBOutlet var lblPName : UILabel?
    @IBOutlet var lblPUsers : UILabel?
    func configureWithPlatform(platformInfo : Platform)  {
        self.lblPName?.text = platformInfo.lName
        self.lblPUsers?.text = "Users " + String(describing: platformInfo.users?.count)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
}

class UserPlatformVC: UIViewController,NSFetchedResultsControllerDelegate,UITableViewDelegate,UITableViewDataSource {
    
    var managedObjectContext: NSManagedObjectContext!
    @IBOutlet var tblPlatformList : UITableView?
    
    @IBOutlet weak var txtNewPlatform: UITextField!
    var selectedPlatform: [Platform]?
    var delegate: UserPlatformDelegate?
    var isSingleSelection: Bool?
    override func viewDidLoad() {
        super.viewDidLoad()
        if selectedPlatform == nil {
            selectedPlatform = [Platform]()
        }
        if isSingleSelection == nil {
            isSingleSelection = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func btnSavePlatform(sender:UIButton){
        delegate?.didSelectedLists(platforns: selectedPlatform!)
    }
    @IBAction func btnAddPlatform(sender:UIButton){

        if (txtNewPlatform.text?.count)! > 0 && DBUpdateManager.countEntityWith(entityName: "Platform", keyValues: ["lName" : txtNewPlatform.text as AnyObject], moc: DatabaseManager.sharedInstance().managedObjectContext) == 0 {
            MBProgressHUD.showAdded(to: self.view, animated: true)
//            let query:PFQuery = PFQuery.init(className: "PMSPlatform")
//            query.limit = 1
//            query.order(byDescending: "uID")
//            query.findObjectsInBackground { (projects :[PFObject]?, error:Error?) in
//                var uID:Double = 1
//                if (projects?.count)! > 0{
//                    uID = Double(projects?.first?.object(forKey: "uID") as! NSNumber)
//                    uID += 1
//                }
                let newPlatform = PFObject(className:"PMSPlatform")
//                newPlatform["uID"] = uID
                newPlatform["lName"] = self.txtNewPlatform.text
                newPlatform["isDeleted"] = false
                newPlatform.saveInBackground(block: { (isSaved:Bool, error:Error?) in
                    if isSaved{
                        let moc:NSManagedObjectContext = DBUpdateManager.createPrivateMOC(parentMOC: self.managedObjectContext)
                        let objPlatform:Platform = DBUpdateManager.insertObject(entityName: "Platform", moc: moc) as! Platform
                        objPlatform.lName = self.txtNewPlatform.text
                        objPlatform.uID = newPlatform["uID"] as! Int64
                        objPlatform.objectId = newPlatform.objectId
                        DBUpdateManager.saveContext(parentMOC: moc)
                        self.txtNewPlatform.backgroundColor = UIColor.green
                        self.txtNewPlatform.text = ""
                    }
                    MBProgressHUD.hide(for: self.view, animated: true)
                })
//            }
        }
        else{
            txtNewPlatform.backgroundColor = UIColor.red
        }
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
        let cell : PlatformListCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PlatformListCell
        let platformInfo : Platform = fetchedResultsController.object(at: indexPath) as! Platform
        cell.configureWithPlatform(platformInfo: platformInfo)
        if (selectedPlatform?.contains(platformInfo))! {
            cell.backgroundColor = UIColor.orange
        }
        else{
            cell.backgroundColor = UIColor.white
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let platformInfo : Platform = fetchedResultsController.object(at: indexPath) as! Platform
        if (delegate?.responds(to: Selector(("willSelect:platforn:"))))! {
            if (delegate?.willSelect(platforn: platformInfo))!==false {
                return
            }
        }
        if isSingleSelection! {
            selectedPlatform?.removeAll()
        }
        if (selectedPlatform?.contains(platformInfo))! {
            selectedPlatform?.remove(at: (selectedPlatform?.firstIndex(of:platformInfo))!)
        }
        else{
            selectedPlatform?.append(platformInfo)
        }
        if isSingleSelection! {
            tableView.reloadData()
        }
        else{
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
    
    internal func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let objPlatform :Platform = fetchedResultsController.object(at: indexPath as IndexPath) as! Platform
        if objPlatform.users?.count == 0{
            return true
        }
        return false
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let moc:NSManagedObjectContext = DBUpdateManager.createPrivateMOC(parentMOC: self.managedObjectContext)
            let objPlatform :Platform = fetchedResultsController.object(at: indexPath as IndexPath) as! Platform
            let platform:PFObject = PFObject.init(withoutDataWithClassName: "PMSPlatform", objectId: objPlatform.objectId)
            platform["isDeleted"] = true
            platform.saveInBackground(block: { (isSeved:Bool, error:Error?) in
                if isSeved{
                    let objEditPlatform = moc.object(with: objPlatform.objectID) as! Platform
                    moc.delete(objEditPlatform)
                    DBUpdateManager.saveContext(parentMOC: moc)
                }
            })
        }
    }
    
    
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        // Initialize Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Platform")
        // Add Sort Descriptors
        let sortDescriptor = NSSortDescriptor(key: "lName", ascending: true)
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
        self.tblPlatformList?.beginUpdates()
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                self.tblPlatformList?.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath {
                self.tblPlatformList?.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            if (self.tblPlatformList?.indexPathsForVisibleRows?.contains(indexPath!))! {
                self.tblPlatformList?.reloadRows(at: [indexPath!], with: .fade)
            }
            break;
        case .move:
            if let indexPath = indexPath {
                self.tblPlatformList?.deleteRows(at: [indexPath], with: .fade)
            }
            
            if let newIndexPath = newIndexPath {
                self.tblPlatformList?.insertRows(at: [newIndexPath], with: .fade)
            }
            break;
        @unknown default:
            fatalError()
        }
    }
    private func controllerDidChangeContent(controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tblPlatformList?.endUpdates()
    }
}
