//
//  ProjectListVC.swift
//  ProjectManagmentSystem
//
//  Created by Siya9 on 29/11/16.
//  Copyright © 2016 Siya9. All rights reserved.
//

import UIKit
import CoreData

class ProjectListCell: UITableViewCell {
    @IBOutlet var lblPName : UILabel?
    @IBOutlet var lblTime : UILabel?
    func configureWithProject(projectInfo : Project)  {
        self.lblPName?.text = projectInfo.pName
        self.lblTime?.text = UtilityManager.getDurationFrom(fromDate: projectInfo.pStartDate!, toDate: Date())
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
}

class ProjectListVC: UIViewController,NSFetchedResultsControllerDelegate,UITableViewDelegate,UITableViewDataSource {
    
    var managedObjectContext: NSManagedObjectContext!
    @IBOutlet var tblProjectList : UITableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.managedObjectContext = DatabaseManager.sharedInstance().managedObjectContext
        self.navigationController?.isNavigationBarHidden = true
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnLogoutUserTapped(sender:UIButton){
        DatabaseManager.sharedInstance().currentUser = nil
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func addProject(sender:UIButton){
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let projectDetailVC : ProjectAddVC = storyBoard.instantiateViewController(withIdentifier: "ProjectAddVC_sid") as! ProjectAddVC
        self.navigationController?.pushViewController(projectDetailVC, animated: true)
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
        let cell : ProjectListCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ProjectListCell
        let projectInfo : Project = fetchedResultsController.object(at: indexPath) as! Project
        cell.configureWithProject(projectInfo:projectInfo)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let projectDetailVC : ProjectDetailVC = storyBoard.instantiateViewController(withIdentifier: "ProjectDetailVC_sid") as! ProjectDetailVC
        projectDetailVC.objProject = fetchedResultsController.object(at: indexPath) as? Project
        projectDetailVC.managedObjectContext = self.managedObjectContext
        self.navigationController?.pushViewController(projectDetailVC, animated: true)

//        let objProject :Project = fetchedResultsController.object(at: indexPath) as! Project
//        let moc:NSManagedObjectContext = DBUpdateManager.createPrivateMOC(parentMOC: self.managedObjectContext)
//        self.showProjectDetailVC(objProject: moc.object(with: objProject.objectID) as! Project, moc: moc)
    }

    internal func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
//    public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//        
//        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") {action in
//            //handle delete
//        }
//        
//        let editAction = UITableViewRowAction(style: .normal, title: "Edit") {action in
//            //handle edit
//        }
//        
//        return [deleteAction, editAction]
//    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let objProject :Project = fetchedResultsController.object(at: indexPath as IndexPath) as! Project
            
            let platform:PFObject = PFObject.init(withoutDataWithClassName: "PMSProject", objectId: objProject.objectId)
            
            platform["isDeleted"] = true
            platform.saveInBackground(block: { (isSeved:Bool, error:Error?) in
                if isSeved{
                    let moc:NSManagedObjectContext = DBUpdateManager.createPrivateMOC(parentMOC: self.managedObjectContext)
                    let objProject :Project = self.fetchedResultsController.object(at: indexPath as IndexPath) as! Project
                    let objEditProject = moc.object(with: objProject.objectID) as! Project
                    moc.delete(objEditProject)
                    DBUpdateManager.saveContext(parentMOC: moc)
                }
            })
        }
    }
    
    func showProjectDetailVC(objProject : Project , moc:NSManagedObjectContext){
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let projectDetailVC : ProjectDetailVC = storyBoard.instantiateViewController(withIdentifier: "ProjectDetailVC_sid") as! ProjectDetailVC
        projectDetailVC.objProject = objProject
        projectDetailVC.managedObjectContext = moc
        self.navigationController?.pushViewController(projectDetailVC, animated: true)
    }
    //MARK: - CoreData -
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        // Initialize Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Project")
        // Add Sort Descriptors
        let sortDescriptor = NSSortDescriptor(key: "pName", ascending: true)
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
        self.tblProjectList?.beginUpdates()
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                self.tblProjectList?.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath {
                self.tblProjectList?.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            if (self.tblProjectList?.indexPathsForVisibleRows?.contains(indexPath!))! {
                self.tblProjectList?.reloadRows(at: [indexPath!], with: .fade)
            }
            break;
        case .move:
            if let indexPath = indexPath {
                self.tblProjectList?.deleteRows(at: [indexPath], with: .fade)
            }
            
            if let newIndexPath = newIndexPath {
                self.tblProjectList?.insertRows(at: [newIndexPath], with: .fade)
            }
            break;
        @unknown default:
            fatalError()
        }
    }
    private func controllerDidChangeContent(controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tblProjectList?.endUpdates()
    }
}
