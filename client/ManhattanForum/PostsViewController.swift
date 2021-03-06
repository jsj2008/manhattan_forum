//
//  PostsViewController.swift
//  ManhattanForum
//
//  Created by Dimitri Roche on 8/19/14.
//  Copyright (c) 2014 dimroc. All rights reserved.
//

import UIKit

class PostsViewController: UITableViewController, PostHandable {
    var cellHeights = [String: CGFloat]()

    class var TopicsViewRefreshNotificationKey: String! {
        get { return "TopicsViewRefreshNotificationKey" }
    }
    
    class var PostFilterNotificationKey: String! {
        get { return "PostFilterNotificationKey" }
    }
    
    class var ThankFeedbackNotificationKey: String! {
        get { return "ThankFeedbackNotificationKey" }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl?.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)

        registerNibCell("PostCell")
        registerNibCell("RefreshPreviousCell")
        
        let postDataSource = self.tableView.dataSource as PostDataSource
        self.navigationItem.title = "NYC"
        postDataSource.postHandler = self
        postDataSource.postFilter = PostFilter.mappedFilters("NYC")
        postDataSource.refreshFromLocal()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshPrevious", name: PostsViewController.TopicsViewRefreshNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refresh:", name: PostRepository.PostCreatedNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "filterPosts:", name: PostsViewController.PostFilterNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "thankFeedback", name: PostsViewController.ThankFeedbackNotificationKey, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let postDataSource = self.tableView.dataSource as PostDataSource
        if(indexPath.row >= postDataSource.posts.count) {
            return cellHeights["RefreshPreviousCell"]!
        } else {
            return cellHeights["PostCell"]!
        }
    }

    @IBAction func refresh(sender: AnyObject) {
        let postDataSource = self.tableView.dataSource as PostDataSource
        handleRefresh(postDataSource.refresh())
    }
    
    // MARK: - PostHandable Protocol
    func playPostVideo(post: Post!) {
        presentMoviePlayerOverlay(NSURL(string: post.video.url)!)
    }
    
    func showPostDetails(post: Post!) {
        // Disable the display of comments. Not worth it atm.
        // DDLogHelper.debug("Showing comments for post \(post!.objectId)")
        // performSegueWithIdentifier("ShowPostDetailsSegue", sender: post)
    }
    
    func filterPosts(notification: NSNotification) {
        let postFilter = notification.object as PostFilter
        let postDataSource = self.tableView.dataSource as PostDataSource
        postDataSource.postFilter = postFilter
        NSLog("Post filter name: \(postFilter.name)")
        self.navigationItem.title = postFilter.name
        refresh(self)
    }
    
    func thankFeedback() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.presentViewController(
                UIAlertControllerFactory.ok("Thanks for the feedback", message: "All feedback is welcome!"),
                animated: true,
                completion: nil)
        })
    }

    func refreshPrevious() {
        let postDataSource = self.tableView.dataSource as PostDataSource
        handleRefresh(postDataSource.refreshPrevious())
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "ShowPostDetailsSegue") {
            let destination: PostCommentsViewController = segue.destinationViewController as PostCommentsViewController
            destination.post = sender as? Post
        }
    }

    private func handleRefresh(task: BFTask!) {
        task.continueWithBlockOnMain { (task: BFTask!) -> AnyObject! in
            if (task.success) {
                self.tableView.reloadData()
            } else {
                DDLogHelper.debug(task.error.debugDescription)
                
                self.presentViewController(
                    UIAlertControllerFactory.ok("Error refreshing previous posts", message: task.error.localizedDescription),
                    animated: true,
                    completion: nil)
            }
            
            self.refreshControl?.endRefreshing()
            return nil
        }
    }

    private func registerNibCell(cellName: String!) {
        let nib = UINib(nibName: cellName, bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: cellName)
        
        let uiview = NSBundle.mainBundle().loadNibNamed(cellName, owner: self, options: nil)[0] as? UIView
        cellHeights[cellName] = uiview?.bounds.size.height
    }
}
