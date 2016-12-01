//
//  ProfilesListViewController.swift
//  PProfiles
//
//  Created by Abhinay Balusu on 11/4/16.
//  Copyright © 2016 profiles. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

import Fabric
import Crashlytics

class ProfilesListViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UIPickerViewDelegate,UIPickerViewDataSource {

    //Button to add new Profile
    @IBOutlet var addProfileButton: UIButton!
    
    //Table view to list all the available Profiles in Firebase
    @IBOutlet weak var profilesListTableView: UITableView!
    
    //Variables to store profile ids and their respective data
    var profilesDictionary: NSMutableDictionary = [:]
    var tempProfilesDictionary: NSMutableDictionary = [:]
    var tempProfileIdsArray: NSArray = []
    var profileIDsArray: NSMutableArray = []
    
    //Picker view for Gender options
    @IBOutlet weak var genderPickerView: UIPickerView!
    @IBOutlet weak var viewForPickerDoneButton: UIView!
    
    //Genders Array
    var genderItems: [String] = ["Select Gender","Male","Female", "Other"]
    
    //ColorPicker class variable
    let colorPickerVC = ColorPickerViewController()
    
    //Sorting Variables
    //variables to sort using gender
    @IBOutlet weak var genderSortButton: UIButton!
    var isSortedByGender:Bool = false
    @IBOutlet weak var sortingOrderImageView: UIImageView!
    @IBOutlet weak var sortingOrderByAgeImageView: UIImageView!
    var isAscendingOrder:Bool = true
    var isAscendingOrder_Age:Bool = true
    @IBOutlet weak var clearSortButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title="Profiles"
        
        //self.navigationController!.navigationBar.barTintColor = UIColor(red: 48.0/255.0, green: 204.0/255.0, blue: 114.0/255.0, alpha: 1.0)
        self.navigationController!.navigationBar.barTintColor = UIColor(red: 50.0/255.0, green: 73.0/255.0, blue: 94.0/255.0, alpha: 1.0)
        //self.navigationController!.navigationBar.barTintColor = UIColor.redColor()
        self.navigationController!.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        
        //Profiles Table View
        profilesListTableView.delegate = self
        profilesListTableView.dataSource = self
        profilesListTableView.separatorColor = UIColor.blackColor()
        profilesListTableView.tableFooterView = UIView(frame: CGRectZero)
        profilesListTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        profilesListTableView.contentInset = UIEdgeInsetsMake(-1.0, 0.0, 0.0, 0.0)
        profilesListTableView.registerNib(UINib(nibName: "ProfileTableViewCell", bundle: nil), forCellReuseIdentifier: "profileCellIdentifier")
        
        //Add profile button
        addProfileButton.frame = CGRectMake(UIScreen.mainScreen().bounds.size.width-addProfileButton.frame.size.width-12, UIScreen.mainScreen().bounds.size.height-addProfileButton.frame.size.height-12, addProfileButton.frame.size.width, addProfileButton.frame.size.height)
        self.view.addSubview(addProfileButton)
        addProfileButton.layer.cornerRadius = 25.0
        
        //Gender Picker View
        genderPickerView.delegate = self
        genderPickerView.dataSource = self
        genderPickerView.hidden = true
        viewForPickerDoneButton.hidden = true
        
        //Checking device height, if it is less than 667.0 i.e. 5 and 5s ad moving the clear button to navigation bar for better user experience
        print("Device Height: \(UIScreen.mainScreen().bounds.size.height)")
        if(UIScreen.mainScreen().bounds.size.height < 667.0)
        {
            clearSortButton.hidden = true
            
            let clearSortBarButtonItem = UIBarButtonItem(title: "Remove Filters", style: .Plain, target: self,action: #selector(ProfilesListViewController.clearAllTypeOfSorts))
            navigationItem.rightBarButtonItem = clearSortBarButtonItem
        }
        else
        {
            clearSortButton.hidden = false
        }
        
        //to save value of connection status
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        //Checking Network Connection
        let connectedRef = FIRDatabase.database().referenceWithPath(".info/connected")
        //listener for whether we are connected to firebase (and thus likely internet)
        connectedRef.observeEventType(.Value, withBlock: { snapshot in
            if let connected = snapshot.value as? Bool where connected {
                print("Connected")
                userDefaults.setObject("true", forKey: "isConnected")
                //if connected calling the function to get data
                self.getProfilesDataFromFirebase()
                
            } else {
                print("Not connected")
                userDefaults.setObject("false", forKey: "isConnected")
            }
        })
        
        let button = UIButton(type: UIButtonType.RoundedRect)
        button.frame = CGRectMake(20, 50, 100, 30)
        button.setTitle("Crash", forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(self.crashButtonTapped(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        view.addSubview(button)
        view.bringSubviewToFront(button)

        
    }
    
    @IBAction func crashButtonTapped(sender: AnyObject) {
        Crashlytics.sharedInstance().crash()
    }

    
    // MARK: - Getting Data from Firebase
    //to retrieve data from Firebase
    func getProfilesDataFromFirebase()
    {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if(userDefaults.objectForKey("isConnected") != nil)
        {
            if(userDefaults.objectForKey("isConnected") as? String ?? "" == "true")
            {
                let profilesRootRef = FIRDatabase.database().referenceWithPath("profiles/") //Firebase(url:FIREBASE_URL+"users")
                
                profilesRootRef.keepSynced(true)
                profilesRootRef.observeEventType(.Value, withBlock: { snapshot in
                    
                    self.profileIDsArray.removeAllObjects()
                    self.profilesDictionary.removeAllObjects()
                    
                    print(profilesRootRef)
                    print(snapshot.value)
                    
                    if !(snapshot.value is NSNull)
                    {
                        let snap = snapshot.value!.allValues as NSArray
                        print(snap)
                        
                        let sortedSnapshot = snap.sort({ $0.objectForKey("id") as? String > $1.objectForKey("id") as? String})
                        print(sortedSnapshot)
                        
                        for i in 0 ..< snapshot.value!.count
                        {
                            //print(json.allValues[i])
                            let userJsonData = snapshot.value?.allValues[i] as! NSDictionary
                            print(userJsonData)
                            
                            let profileDictionary = NSMutableDictionary()
                            
                            var profileId = ""
                            if(userJsonData.objectForKey("id") != nil)
                            {
                                profileId = userJsonData.objectForKey("id") as! String
                                self.profileIDsArray.addObject(profileId)
                                profileDictionary.setValue(profileId, forKey: "id")
                                
                            }
                            
                            if(userJsonData.objectForKey("name") != nil)
                            {
                                profileDictionary.setValue(userJsonData.objectForKey("name") as! String, forKey: "name")
                            }
                            else
                            {
                                profileDictionary.setValue("No Name", forKey: "name")
                            }
                            
                            if(userJsonData.objectForKey("age") != nil)
                            {
                                profileDictionary.setValue(userJsonData.objectForKey("age") as! String, forKey: "age")
                            }
                            else
                            {
                                profileDictionary.setValue("No Age", forKey: "age")
                            }
                            
                            if(userJsonData.objectForKey("gender") != nil)
                            {
                                profileDictionary.setValue(userJsonData.objectForKey("gender") as! String, forKey: "gender")
                            }
                            else
                            {
                                profileDictionary.setValue("Other", forKey: "gender")
                            }
                            
                            if(userJsonData.objectForKey("hobbies") != nil)
                            {
                                profileDictionary.setValue(userJsonData.objectForKey("hobbies") as! String, forKey: "hobbies")
                            }
                            else
                            {
                                profileDictionary.setValue("No Hobbies", forKey: "hobbies")
                            }
                            
                            if(userJsonData.objectForKey("icon") != nil)
                            {
                                profileDictionary.setValue(userJsonData.objectForKey("icon") as! String, forKey: "icon")
                            }
                            else
                            {
                                profileDictionary.setValue("", forKey: "icon")
                            }
                            
                            if(userJsonData.objectForKey("color") != nil)
                            {
                                profileDictionary.setValue(userJsonData.objectForKey("color") as! String, forKey: "color")
                            }
                            else
                            {
                                profileDictionary.setValue("", forKey: "color")
                            }
                            
                            self.profilesDictionary.setValue(profileDictionary, forKey: profileId)
                            
                        }
                        self.tempProfileIdsArray = self.profileIDsArray.copy() as! NSArray
                        
                        self.profilesListTableView.reloadData()
                    }
                    }, withCancelBlock: { error in
                        print(error.localizedDescription)
                        
                        self.showAlertView(error.localizedDescription)
                })
                
            }
            else{
                
                self.showAlertView("Please Check your Network Connection")
            }
        }
        else{
            
            self.showAlertView("Error connecting to internet")
        }

    }
    
    // MARK: - Gender Picker View
    //Gender Picker view setup
    @IBAction func showHideGenderPickerView(sender: AnyObject) {
        
        if(viewForPickerDoneButton.hidden == false)
        {
            genderPickerView.hidden = true
            viewForPickerDoneButton.hidden = true
        }
    }
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return genderItems.count
    }
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return genderItems[row]
        
    }
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        genderSortButton.setTitle(genderItems[row], forState: .Normal)
        if(row == 0)
        {
            genderSortButton.setTitle("Gender", forState: .Normal)
        }
        isSortedByGender = true
        //getting all Male Profiles
        if(row == 1)
        {
            profileIDsArray.removeAllObjects()
            tempProfilesDictionary.removeAllObjects()
            
            for i in 0 ..< profilesDictionary.count
            {
                let gender = profilesDictionary.objectForKey(profilesDictionary.allKeys[i])?.objectForKey("gender") as! String
                
                if(gender == "Male")
                {
                    profileIDsArray.addObject(profilesDictionary.allKeys[i])
                    tempProfilesDictionary.setValue(profilesDictionary.objectForKey(profilesDictionary.allKeys[i]), forKey: profilesDictionary.allKeys[i] as! String)
                }
                
            }
            profilesListTableView.reloadData()
        }
        //Getting all Female Profiles
        else if(row == 2)
        {
            profileIDsArray.removeAllObjects()
            tempProfilesDictionary.removeAllObjects()
            
            for i in 0 ..< profilesDictionary.count
            {
                let gender = profilesDictionary.objectForKey(profilesDictionary.allKeys[i])?.objectForKey("gender") as! String
                
                if(gender == "Female")
                {
                    profileIDsArray.addObject(profilesDictionary.allKeys[i])
                    tempProfilesDictionary.setValue(profilesDictionary.objectForKey(profilesDictionary.allKeys[i]), forKey: profilesDictionary.allKeys[i] as! String)
                }
                
            }
            profilesListTableView.reloadData()
        }
        else
        {
            profileIDsArray.removeAllObjects()
            tempProfilesDictionary.removeAllObjects()
            
            for i in 0 ..< profilesDictionary.count
            {
                let gender = profilesDictionary.objectForKey(profilesDictionary.allKeys[i])?.objectForKey("gender") as! String
                
                if(gender == "Other")
                {
                    profileIDsArray.addObject(profilesDictionary.allKeys[i])
                    tempProfilesDictionary.setValue(profilesDictionary.objectForKey(profilesDictionary.allKeys[i]), forKey: profilesDictionary.allKeys[i] as! String)
                }
                
            }
            profilesListTableView.reloadData()
        }
        
        self.tempProfileIdsArray = self.profileIDsArray.copy() as! NSArray
        
    }
    
    
    //Alert view
    func showAlertView(message: String)
    {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Sorting
    //Sorting
    //Sort by gender
    @IBAction func sortByGenderButtonClicked(sender: AnyObject) {
        
        genderPickerView.hidden = false
        viewForPickerDoneButton.hidden = false
        self.view.bringSubviewToFront(genderPickerView)
        self.view.bringSubviewToFront(viewForPickerDoneButton)
        
    }
    //Clears all types of filters
    @IBAction func clearSortButtonClicked(sender: AnyObject) {
        
        clearSorts()
    }
    
    func clearSorts()
    {
        if(isSortedByGender)
        {
            genderSortButton.setTitle("Gender", forState: .Normal)
        }
        profileIDsArray.removeAllObjects()
        
        for i in 0 ..< profilesDictionary.count
        {
            profileIDsArray.addObject(profilesDictionary.allKeys[i])
        }
        profilesListTableView.reloadData()
        isSortedByGender = false
        sortingOrderImageView.image = UIImage(named: "sort.png")
        sortingOrderByAgeImageView.image = UIImage(named: "sort.png")
        isAscendingOrder = true
        isAscendingOrder_Age = true
    }
    func clearAllTypeOfSorts()
    {
        clearSorts()
    }
    
    //Sorting by name in ascending and descending order
    @IBAction func sortByProfileNameButtonClicked(sender: AnyObject) {
        
        profileIDsArray.removeAllObjects()
        
        var snap = []
        
        if(isSortedByGender)
        {
            snap = tempProfilesDictionary.allValues as NSArray
        }
        else
        {
            snap = profilesDictionary.allValues as NSArray
        }
        print(snap)
        
        var sortedSnapshot = snap.sort({ $0.objectForKey("name") as? String > $1.objectForKey("name") as? String})
        print(sortedSnapshot)
        
        if(isAscendingOrder == false)
        {
            isAscendingOrder = true
            sortingOrderImageView.image = UIImage(named: "descending.png")
        }
        else{
            
            sortedSnapshot = sortedSnapshot.reverse()
            isAscendingOrder = false
            sortingOrderImageView.image = UIImage(named: "ascending.png")
            
        }
        
        
        
        for i in 0 ..< sortedSnapshot.count
        {
            let pData = sortedSnapshot[i] as! NSDictionary
            profileIDsArray.addObject(pData.objectForKey("id")!)
        }

        
        
        profilesListTableView.reloadData()
        
    }
   
    //Sorting by age in ascending and descending order
    @IBAction func sortProfilesByAgeButtonClicked(sender: AnyObject) {
        
        profileIDsArray.removeAllObjects()
        
        var snap = []
        
        if(isSortedByGender)
        {
            snap = tempProfilesDictionary.allValues as NSArray
        }
        else
        {
            snap = profilesDictionary.allValues as NSArray
        }
        print(snap)
        
        var sortedSnapshot = snap.sort({ $0.objectForKey("age") as? String > $1.objectForKey("age") as? String})
        print(sortedSnapshot)
        
        if(isAscendingOrder_Age == false)
        {
            isAscendingOrder_Age = true
            sortingOrderByAgeImageView.image = UIImage(named: "descending.png")
        }
        else{
            
            sortedSnapshot = sortedSnapshot.reverse()
            isAscendingOrder_Age = false
            sortingOrderByAgeImageView.image = UIImage(named: "ascending.png")
            
        }
        
        for i in 0 ..< sortedSnapshot.count
        {
            let pData = sortedSnapshot[i] as! NSDictionary
            profileIDsArray.addObject(pData.objectForKey("id")!)
        }
        
        profilesListTableView.reloadData()
        
    }
    
    // MARK: - Profiles Table View
    //Profiles table view setup
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profileIDsArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("profileCellIdentifier", forIndexPath: indexPath) as! ProfileTableViewCell
        
        cell.profileName.text = profilesDictionary.objectForKey(profileIDsArray[indexPath.row])?.objectForKey("name") as? String ?? "No Name"
        cell.profileAge.text = "Age: "+((profilesDictionary.objectForKey(profileIDsArray[indexPath.row])?.objectForKey("age"))! as! String)
        
        cell.profileImageView.layer.cornerRadius = 20.0
        cell.profileImageView.clipsToBounds = true
        
        let hexColorString = (profilesDictionary.objectForKey(profileIDsArray[indexPath.row])?.objectForKey("color"))! as? String ?? ""
        
        if(hexColorString == "")
        {
            let gender = profilesDictionary.objectForKey(profileIDsArray[indexPath.row])?.objectForKey("gender")! as? String ?? "Other"
            if(gender == "Male")
            {
                cell.backgroundColor = UIColor(red: 0.0/255.0, green: 128.0/255.0, blue: 255.0/255.0, alpha: 1.0)
                
            }
            else if(gender == "Female")
            {
                cell.backgroundColor = UIColor(red: 48.0/255.0, green: 204.0/255.0, blue: 114.0/255.0, alpha: 1.0)
            }
        }
        else
        {
            cell.backgroundColor = colorPickerVC.convertHexToUIColor(hexColor: hexColorString)
        }
        
        
        let iconURL = NSURL(string: profilesDictionary.objectForKey(profileIDsArray[indexPath.row])?.objectForKey("icon") as! String)
        cell.profileImageView?.kf_setImageWithURL(iconURL, placeholderImage: UIImage(named: "user.png"))
        
        return cell
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let detailedVC = DetailedProfileViewController()
        detailedVC.isTOAddProfile = false
        detailedVC.profileDetailId = profileIDsArray[indexPath.row] as! String
        detailedVC.profileDetailDict = profilesDictionary.objectForKey(profileIDsArray[indexPath.row]) as! NSDictionary
        self.navigationController?.pushViewController(detailedVC, animated: true)
        
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 50
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            // handle delete (by removing the data from your array and updating the tableview)
            print("deleted")
            let deleteProfileRef = FIRDatabase.database().referenceWithPath("profiles/\(profileIDsArray[indexPath.row])")
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                
                deleteProfileRef.removeValue()
                self.profilesListTableView.reloadData()
                
            })
        }
    }

    // MARK: - Adding New Profile
    //functionality to add new profiles
    @IBAction func addProfileButtonClicked(sender: AnyObject) {
        
    
        let addProfileVC = DetailedProfileViewController()
        addProfileVC.isTOAddProfile = true
        let newNavVC = UINavigationController()
        newNavVC.viewControllers = [addProfileVC]
        self.presentViewController(newNavVC, animated: true, completion: nil)
        //self.navigationController?.presentViewController(addProfileVC, animated: true, completion: nil)
        
    }
    
    // MARK: - Memory Warning
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
