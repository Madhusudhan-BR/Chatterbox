//
//  RecentViewController.swift
//  Chatterbox
//
//  Created by Madhusudhan B.R on 4/9/17.
//  Copyright © 2017 Madhusudhan B.R. All rights reserved.
//

import UIKit

class RecentViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,ChooseUserDelegate {
    
    
    
    var recents: [NSDictionary] = []
    @IBOutlet weak var tableView: UITableView!
   
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        loadRecents() 
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func startNewChatBarButtonItemPressed(sender: AnyObject) {
        performSegueWithIdentifier("recentToChooseUserVC", sender: self)

    }
    
    //MARK: UITableviewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recents.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! RecentTableViewCell
        
        let recent = recents[indexPath.row]
        
        cell.bindData(recent)
        
        return cell
    }
    
    //MARK: UITableviewDelegate functions
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        //create recent for both users 
        let recent = recents[indexPath.row]
        RestartRecentChat(recent)
        performSegueWithIdentifier("recentToChatSeg", sender: indexPath)
        
        
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let recent = recents[indexPath.row]
        
        //remove recent from the array
        recents.removeAtIndex(indexPath.row)
        
        //delete recent from firebase
        DeleteRecentItem(recent)
        
        tableView.reloadData()
    }
    
    
    
    
    //MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "recentToChooseUserVC" {
            let vc = segue.destinationViewController as! ChooseUserViewController
            vc.delegate = self
        }
        if segue.identifier == "recentToChatSeg" {
            let indexPath = sender as! NSIndexPath
            let chatVC = segue.destinationViewController as! ChatViewController
            chatVC.hidesBottomBarWhenPushed = true
            
            let recent = recents[indexPath.row]
            // set chatVC 
            
            chatVC.recent = recent
            chatVC.chatRoomId = recent["chatRoomID"] as? String
            
        }

        
    }
    
    //MARK: ChooseUserDelegate
    //MARK: ChooseUserDelegate
    
    func createChatroom(withUser: BackendlessUser) {
        
        let chatVC = ChatViewController()
        chatVC.hidesBottomBarWhenPushed = true
        
        navigationController?.pushViewController(chatVC, animated: true)
        //set chat  VC
        
        chatVC.withUser = withUser
        chatVC.chatRoomId = startChat( backendless.userService.currentUser, user2: withUser)
    }
    
    
    //MARK: Load Recents from firebase
    
    func loadRecents() {
        firebase.child("Recent").queryOrderedByChild("userId").queryEqualToValue(backendless.userService.currentUser.objectId).observeEventType(.Value, withBlock: {
            snapshot in
            
            self.recents.removeAll()
            
            if snapshot.exists() {
                
                let sorted = (snapshot.value!.allValues as NSArray).sortedArrayUsingDescriptors([NSSortDescriptor(key: "date", ascending: false)])
                
                for recent in sorted {
                    
                    self.recents.append(recent as! NSDictionary)
                    
                    //add functio to have offline access as well, this will download with user recent as well so that we will not create it again
                    
                    firebase.child("Recent").queryOrderedByChild("chatRoomID").queryEqualToValue(recent["chatRoomID"]).observeEventType(.Value, withBlock: {
                       snapshot in
                    })
                    
                }
                
            }
            
            self.tableView.reloadData()
        })
        
    }
    

}
