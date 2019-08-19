//
//  AddTaksVC.swift
//  ProjectManagmentSystem
//
//  Created by Siya9 on 03/12/16.
//  Copyright © 2016 Siya9. All rights reserved.
//

import UIKit
import CoreData
class CommentListCell: UITableViewCell {
    @IBOutlet var lblComment : UILabel?
    @IBOutlet var lblUser : UILabel?
    @IBOutlet var lblTime : UILabel?
    func configureWithComment(commentInfo : Comment)  {
        self.lblComment?.text = commentInfo.comment
        self.lblUser?.text = commentInfo.user?.uName
        self.lblTime?.text = UtilityManager.getDurationFrom(fromDate: commentInfo.time as! Date, toDate: Date())
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
}
class TaksDetailVC: UIViewController,NSFetchedResultsControllerDelegate,UITableViewDelegate,UITableViewDataSource {

    var objTask : Task!
    var managedObjectContext: NSManagedObjectContext!
    
    @IBOutlet weak var tblComment: UITableView!
    @IBOutlet weak var taskDetailHeaderView: TaskDetailHeaderView!
    @IBOutlet weak var txtComment: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        managedObjectContext = DatabaseManager.sharedInstance().managedObjectContext
        taskDetailHeaderView.updateUIWithTask(taskInfo: objTask)
        tblComment.rowHeight = UITableViewAutomaticDimension
        tblComment.estimatedRowHeight = 50
        // Do any additional setup after loading the view.
    }
    @IBAction func btnBackTapped(_ sender: UIButton) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnAddCommentTapped(_ sender: UIButton) {

        MBProgressHUD.showAdded(to: self.view, animated: true)

        let objParse:PFObject! = PFObject.init(className: "PMSComment")
        
        objParse["commentText"] = txtComment.text
        objParse["task"] = PFObject.init(withoutDataWithClassName: "PMSTask", objectId:objTask.objectId)
        objParse["user"] = PFObject.init(withoutDataWithClassName: "PMSUser", objectId:DatabaseManager.sharedInstance().currentUser.objectId)
        objParse["isDeleted"] = false
        objParse.saveInBackground { (isSaved:Bool, error:Error?) in
            if isSaved {
                SnycManager.forceUpdateCommentClass(isSendNotification: true)
            }
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //MARK: - tableview -
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
        let cell : CommentListCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CommentListCell
        let commentInfo : Comment = fetchedResultsController.object(at: indexPath) as! Comment
        cell.configureWithComment(commentInfo:commentInfo)
        return cell
    }
    //MARK: - CoreData -
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        // Initialize Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Comment")
        // Add Sort Descriptors
        let sortDescriptor = NSSortDescriptor(key: "time", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Initialize Fetched Results Controller
        fetchRequest.predicate = NSPredicate(format: "self.task.uID == %d", Int64(self.objTask.uID))
        
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
        self.tblComment?.beginUpdates()
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                self.tblComment?.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath {
                self.tblComment?.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            if (self.tblComment?.indexPathsForVisibleRows?.contains(indexPath!))! {
                self.tblComment?.reloadRows(at: [indexPath!], with: .fade)
            }
            break;
        case .move:
            if let indexPath = indexPath {
                self.tblComment?.deleteRows(at: [indexPath], with: .fade)
            }
            
            if let newIndexPath = newIndexPath {
                self.tblComment?.insertRows(at: [newIndexPath], with: .fade)
            }
            break;
        }
    }
    private func controllerDidChangeContent(controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tblComment?.endUpdates()
    }
}
class TaskDetailHeaderView: UIView {
    
    @IBOutlet weak var txtTName: UITextField!
    @IBOutlet weak var lblTStatus: UILabel!
    @IBOutlet weak var btnAssign: UIButton!
    @IBOutlet weak var lblParticepenc: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    
    func updateUIWithTask(taskInfo : Task)  {
        txtTName.text = taskInfo.tName
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "MM/dd/yyyy"
        lblDate?.text = dayTimePeriodFormatter.string(from: taskInfo.tStartTime as! Date)
        if (taskInfo.assignTo != nil) && (taskInfo.assignTo?.uName?.characters.count)! > 0 {
            btnAssign.setTitle(taskInfo.assignTo?.uName, for: .normal)
        }
        else{
            btnAssign.setTitle("Select Assign User", for: .normal)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
