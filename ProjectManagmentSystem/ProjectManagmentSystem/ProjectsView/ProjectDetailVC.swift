//
//  ProjectDetailVC.swift
//  ProjectManagmentSystem
//
//  Created by Siya9 on 29/11/16.
//  Copyright © 2016 Siya9. All rights reserved.
//

import UIKit
import CoreData

class TaskListCell: UITableViewCell {
    @IBOutlet var lblTName : UILabel?
    func configureWithTask(taskInfo : Task)  {
        self.lblTName?.text = taskInfo.tName
//        self.lblTime?.text = UtilityManager.getDurationFrom(fromDate: projectInfo.pStartDate as! Date, toDate: Date())
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
}

class ProjectDetailVC: UIViewController, NSFetchedResultsControllerDelegate,UITableViewDelegate,UITableViewDataSource {

    @IBOutlet var tblProjectDetail : UITableView?
    @IBOutlet weak var tableHeader: ProjectDetailHeaderView!
    
    var objProject : Project!
    var managedObjectContext : NSManagedObjectContext!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.managedObjectContext = DatabaseManager.sharedInstance().managedObjectContext
        tableHeader.updateUIWithProject(projectInfo: objProject)
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        tableHeader.updateUIWithProject(projectInfo: objProject)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
//    @IBAction func saveProject(sender:UIButton){
//        MBProgressHUD.showAdded(to: self.view, animated: true)
//        objProject.pName = tableHeader.txtPName.text
//        if objProject.pStartDate == nil {
//            objProject.pStartDate = NSDate()
//        }
//        
//        if objProject.objectId != nil && (objProject.objectId?.characters.count)! > 0 {
//            self.inserUpdateProjectInParse(uID: Double(self.objProject.uID))
//        }
//        else{
//            let query:PFQuery = PFQuery.init(className: "PMSProject")
//            query.limit = 1
//            query.order(byDescending: "uID")
//            query.findObjectsInBackground { (projects :[PFObject]?, error:Error?) in
//                var uID:Double = 1
//                if (projects?.count)! > 0{
//                    uID = Double(projects?.first?.object(forKey: "uID") as! NSNumber)
//                    uID += 1
//                }
//                self.inserUpdateProjectInParse(uID: uID)
//            }
//        }
//    }
//    func inserUpdateProjectInParse(uID:Double) {
//        let objParse:PFObject!
//        if objProject.objectId != nil && (objProject.objectId?.characters.count)! > 0 {
//            objParse = PFObject.init(withoutDataWithObjectId: objProject.objectId)
//        }
//        else{
//            objParse = PFObject.init(className: "PMSProject")
//        }
//        objParse["uID"] = uID
//        objParse["pName"] = objProject.pName
//        objParse["assignTo"] = PFObject.init(withoutDataWithClassName: "PMSUser", objectId:objProject.assignTo?.objectId)
//        objParse["platform"] = PFObject.init(withoutDataWithClassName: "PMSPlatform", objectId:objProject.platform?.objectId)
//        let assignto:PFRelation = objParse.relation(forKey: "tasks")
//        for task:Task in self.objProject.tasks?.allObjects as! [Task]  {
//            let objTaskParse:PFObject!
//            if task.objectId != nil && (task.objectId?.characters.count)! > 0 {
//                objTaskParse = PFObject.init(withoutDataWithClassName: "PMSTask", objectId:task.objectId)
//            }
//            else{
//                objTaskParse = PFObject.init(className: "PMSTask")
//            }
//            objTaskParse["tName"] = task.tName
//            do {
//                try objTaskParse.save()
//            } catch {
//                print("An error occurred while save task in server")
//            }
//            assignto.add(objTaskParse)
//        }
//        objParse.saveInBackground { (isSaved:Bool, error:Error?) in
//            if isSaved {
//                DBUpdateManager.saveContext(parentMOC: self.managedObjectContext)
//                _ = self.navigationController?.popViewController(animated: true)
//            }
//            MBProgressHUD.hide(for: self.view, animated: true)
//        }
//    }
    @IBAction func backToProjectList(sender:UIButton){
        _ = navigationController?.popViewController(animated: true)
    }

    @IBAction func btnAddTaskTapped(_ sender: UIButton) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let userListVC : TaksAddVC = storyBoard.instantiateViewController(withIdentifier: "TaksAddVC_sid") as! TaksAddVC
        userListVC.objProject = self.objProject
        userListVC.managedObjectContext = DBUpdateManager.createPrivateMOC(parentMOC: self.managedObjectContext)
        self.navigationController?.pushViewController(userListVC, animated: true)
    }
//MARK: - Tableview -
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
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell")
        
        return headerCell
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell : TaskListCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TaskListCell
        let taskInfo : Task = fetchedResultsController.object(at: indexPath) as! Task
        cell.configureWithTask(taskInfo:taskInfo)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let objTask :Task = fetchedResultsController.object(at: indexPath) as! Task
        
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let taksDetailVC : TaksDetailVC = storyBoard.instantiateViewController(withIdentifier: "TaksDetailVC_sid") as! TaksDetailVC
        taksDetailVC.objTask = objTask

        self.navigationController?.pushViewController(taksDetailVC, animated: true)

    }
    //MARK: - CoreData -
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        // Initialize Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Task")
        // Add Sort Descriptors
        let sortDescriptor = NSSortDescriptor(key: "tName", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        
        fetchRequest.predicate = NSPredicate(format: "self.project.uID == %d", Int64(self.objProject.uID))
//         Initialize Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController.init(fetchRequest: fetchRequest, managedObjectContext: DatabaseManager.sharedInstance().managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
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
        self.tblProjectDetail?.beginUpdates()
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                self.tblProjectDetail?.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath {
                self.tblProjectDetail?.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            if (self.tblProjectDetail?.indexPathsForVisibleRows?.contains(indexPath!))! {
                self.tblProjectDetail?.reloadRows(at: [indexPath!], with: .fade)
            }
            break;
        case .move:
            if let indexPath = indexPath {
                self.tblProjectDetail?.deleteRows(at: [indexPath], with: .fade)
            }
            
            if let newIndexPath = newIndexPath {
                self.tblProjectDetail?.insertRows(at: [newIndexPath], with: .fade)
            }
            break;
        }
    }
    private func controllerDidChangeContent(controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tblProjectDetail?.endUpdates()
    }
}
class ProjectDetailHeaderView: UIView {

    @IBOutlet weak var txtPName: UITextField!
    @IBOutlet weak var lblParticepenc: UILabel!
    @IBOutlet weak var btnAssign: UIButton!
    @IBOutlet weak var btnPlatform: UIButton!
    @IBOutlet weak var lblDate: UILabel!

    func updateUIWithProject(projectInfo : Project)  {
        txtPName.text = projectInfo.pName
        txtPName.isUserInteractionEnabled = false
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "MM/dd/yyyy"
        lblDate?.text = dayTimePeriodFormatter.string(from: projectInfo.pStartDate as! Date)
        if projectInfo.platform != nil {
            btnPlatform.setTitle(projectInfo.platform?.lName, for: .normal)
            btnPlatform.isUserInteractionEnabled = false
        }
        else{
            btnPlatform.setTitle("Select Platform", for: .normal)
            btnPlatform.isUserInteractionEnabled = true
        }
        if (projectInfo.assignTo != nil) && (projectInfo.assignTo?.uName?.characters.count)! > 0 {
            btnAssign.setTitle(projectInfo.assignTo?.uName, for: .normal)
        }
        else{
            btnAssign.setTitle("Select Assign User", for: .normal)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
