//
//  DetailedProfileViewController.swift
//  PProfiles
//
//  Created by Abhinay Balusu on 11/4/16.
//  Copyright © 2016 profiles. All rights reserved.
//

import UIKit
import Photos
import Firebase
import FirebaseAuth
import FirebaseStorage

class DetailedProfileViewController: UIViewController,UITextViewDelegate,UITextFieldDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIPickerViewDelegate,UIPickerViewDataSource,ColorPickerDelegate,UIPopoverPresentationControllerDelegate{

    @IBOutlet weak var profileIconImageView: UIImageView!
    @IBOutlet weak var profileNameTextField: UITextField!
    @IBOutlet weak var profileAgeTextField: UITextField!
    @IBOutlet weak var profileHobbiesTextView: UITextView!
    @IBOutlet weak var profileGenderLabel: UILabel!
    @IBOutlet weak var saveOrUpdateButton: UIButton!
    @IBOutlet weak var deleteProfileButon: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var pickerDoneButtonView: UIView!
    @IBOutlet weak var genderPickerView: UIPickerView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var pickAColorButton: UIButton!
    @IBOutlet weak var colorDisplayLabel: UILabel!
    
    var picker:UIImagePickerController?=UIImagePickerController()
    var popover:UIPopoverController?=nil
    
    var isTOAddProfile:Bool = false
    var barButtonItem: UIBarButtonItem? = nil
    
    var kHieight: CGFloat = 0.0
    
    var genderItems: [String] = ["Select Gender","Male","Female", "Other"]
    
    var isConnected:String = ""
    
    var imageURL : NSURL? = nil
    
    var profileDetailDict : NSDictionary = [:]
    var profileDetailId : String = ""
    
    var isImageUpdated:Bool = false
    
    var hexColorString: String = ""
    
    let colorPickerVc = ColorPickerViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if(userDefaults.objectForKey("isConnected") != nil)
        {
            isConnected = userDefaults.objectForKey("isConnected") as? String ?? "false"
            
        }
        
        profileHobbiesTextView.delegate = self
        profileAgeTextField.delegate = self
        profileNameTextField.delegate = self
        
        genderPickerView.delegate = self
        genderPickerView.dataSource = self
        
        deleteProfileButon.hidden = true
        cancelButton.hidden = true
        
        profileGenderLabel.layer.borderColor = UIColor.lightGrayColor().CGColor
        profileGenderLabel.layer.borderWidth = 1.0

        //To Edit a Profile
        if(isTOAddProfile == false)
        {
            barButtonItem = UIBarButtonItem(title: "Edit Profile", style: .Plain, target: self,action: #selector(editProfileButtonClicked))
            navigationItem.rightBarButtonItem = barButtonItem
            
            enableDisableUIElements(false)
            deleteProfileButon.hidden = false
            barButtonItem!.enabled = true
            
            cancelButton.layer.borderColor = UIColor.greenColor().CGColor
            cancelButton.layer.borderWidth = 2.0
            
            setInitialValues()
            
        }
        //To Add new profile
        else
        {
            self.navigationItem.title="Add Profile"
            
            self.navigationController!.navigationBar.barTintColor = UIColor(red: 50.0/255.0, green: 73.0/255.0, blue: 94.0/255.0, alpha: 1.0)
            //self.navigationController!.navigationBar.barTintColor = UIColor.redColor()
            self.navigationController!.navigationBar.tintColor = UIColor.whiteColor()
            self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
            
            let barButtonItem = UIBarButtonItem(image: UIImage(named: "double_down.png"), style: .Plain, target: self, action: #selector(DetailedProfileViewController.dismissVC))
            navigationItem.leftBarButtonItem = barButtonItem
            
           
            profileIconImageView.userInteractionEnabled = true
            profileGenderLabel.userInteractionEnabled = true
            profileGenderLabel.text = genderItems[0]
            profileIconImageView.layer.cornerRadius = 25.0
            
            saveOrUpdateButton.setTitle("Save", forState: UIControlState.Normal)

        }
        
        //Tap gesture to hide keypad
        let addGestureToHideNumberKeyPad = UITapGestureRecognizer(target: self, action: #selector(self.hideKeyPad))
        self.view.addGestureRecognizer(addGestureToHideNumberKeyPad)
        
        //Tap gesture to select an image
        let addImageGesture = UITapGestureRecognizer(target: self, action: #selector(self.addProfileIcon))
        profileIconImageView.addGestureRecognizer(addImageGesture)
        
        //Gender Picker View
        genderPickerView.hidden = true
        pickerDoneButtonView.hidden = true
        
        //Tap gesture to select gender
        let genderLabelGesture = UITapGestureRecognizer(target: self, action: #selector(self.showPicker))
        profileGenderLabel.addGestureRecognizer(genderLabelGesture)

        //Notification observers on keyboard show/hide to realign the view for better user experience
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DetailedProfileViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DetailedProfileViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        
    }
    
    // MARK: - Setting profile data
    //Setting initial values of a profile
    func setInitialValues()
    {
        profileNameTextField.text = profileDetailDict.objectForKey("name") as? String ?? ""
        profileGenderLabel.text = profileDetailDict.objectForKey("gender") as? String ?? ""
        profileAgeTextField.text = profileDetailDict.objectForKey("age") as? String ?? ""
        profileHobbiesTextView.text = profileDetailDict.objectForKey("hobbies") as? String ?? ""
        colorDisplayLabel.backgroundColor = colorPickerVc.convertHexToUIColor(hexColor: profileDetailDict.objectForKey("color") as? String ?? "")
        
        if(profileDetailDict.objectForKey("color") as? String == "")
        {
            if(profileGenderLabel.text == "Male")
            {
                colorDisplayLabel.backgroundColor = UIColor(red: 0.0/255.0, green: 128.0/255.0, blue: 255.0/255.0, alpha: 1.0)
            }
            else if(profileGenderLabel.text == "Female")
            {
                colorDisplayLabel.backgroundColor = UIColor(red: 48.0/255.0, green: 204.0/255.0, blue: 114.0/255.0, alpha: 1.0)
            }
        }
        
        
        let iconURL = NSURL(string: profileDetailDict.objectForKey("icon") as? String ?? "")
        profileIconImageView?.kf_setImageWithURL(iconURL, placeholderImage: UIImage(named: "user.png"))

    }
    
    func hideKeyPad()
    {
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.profileAgeTextField.resignFirstResponder()
        })
    }
    
    // MARK: - Gender picker view setup
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
        profileGenderLabel.text = genderItems[row]
        
//        if(genderItems[row] == "Male")
//        {
//            colorDisplayLabel.backgroundColor = UIColor(red: 22.0/255.0, green: 131.0/255.0, blue: 251.0/255.0, alpha: 1.0)
//
//        }
//        else if(genderItems[row] == "Female")
//        {
//            colorDisplayLabel.backgroundColor = UIColor(red: 36.0/255.0, green: 198.0/255.0, blue: 89.0/255.0, alpha: 1.0)
//        }
    }
    func showPicker()
    {
        genderPickerView.hidden = false
        pickerDoneButtonView.hidden = false
        self.view.bringSubviewToFront(genderPickerView)
        self.view.bringSubviewToFront(pickerDoneButtonView)
    }
    
    //// MARK: - Profile Image setup
    func addProfileIcon()
    {
        let alert:UIAlertController=UIAlertController(title: "Choose Image", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let cameraAction = UIAlertAction(title: "Camera", style: UIAlertActionStyle.Default)
        {
            UIAlertAction in
            self.openCamera()
            
        }
        let gallaryAction = UIAlertAction(title: "Gallery", style: UIAlertActionStyle.Default)
        {
            UIAlertAction in
            self.openGallary()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel)
        {
            UIAlertAction in
            
        }
        
        // Add the actions
        picker?.delegate = self
        alert.addAction(cameraAction)
        alert.addAction(gallaryAction)
        alert.addAction(cancelAction)
        // Present the controller
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone
        {
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else
        {
            popover=UIPopoverController(contentViewController: alert)
            popover!.presentPopoverFromRect(self.view.frame, inView: self.view, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
        }
    }
    
    func openCamera()
    {
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera))
        {
            picker!.sourceType = UIImagePickerControllerSourceType.Camera
            self .presentViewController(picker!, animated: true, completion: nil)
        }
        else
        {
            openGallary()
        }
    }
    
    func openGallary()
    {
        picker!.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone
        {
            self.presentViewController(picker!, animated: true, completion: nil)
        }
        else
        {
            popover=UIPopoverController(contentViewController: picker!)
            popover!.presentPopoverFromRect(self.view.frame, inView: self.view, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        picker .dismissViewControllerAnimated(true, completion: nil)
        print(info[UIImagePickerControllerOriginalImage])
        if(info[UIImagePickerControllerOriginalImage] != nil)
        {
            profileIconImageView.image=info[UIImagePickerControllerOriginalImage] as? UIImage
            imageURL = info[UIImagePickerControllerReferenceURL] as? NSURL
            isImageUpdated = true
            
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController)
    {
        print("picker cancel.")
        picker .dismissViewControllerAnimated(true, completion: nil)
    }
    

    // MARK: - Save or Update Data
    @IBAction func saveOrUpdateProfileButtonClicked(sender: AnyObject)
    {
        if(isTOAddProfile==false)
        {
            enableDisableUIElements(false)
            
        }
            
        spinner.startAnimating()
        saveOrUpdateButton.enabled = false
        
        print("name:"+"\(profileNameTextField.text)")
        
        if(profileNameTextField.text != "" && profileGenderLabel.text != "" && profileAgeTextField.text != "" && profileHobbiesTextView.text != "" && profileGenderLabel.text != genderItems[0])
        {
            if(isConnected == "true")
            {
                if(self.profileIconImageView.image != nil)
                {
                    if FIRAuth.auth()?.currentUser == nil {
                        FIRAuth.auth()?.signInAnonymouslyWithCompletion({ (user, error) in
                            
                            if(error != nil)
                            {
                                print(error?.localizedDescription)
                                self.showAlertView((error?.localizedDescription)!)
                            }
                            else
                            {
                                
                            }
                        })
                    }
                    
                    let storageRef = FIRStorage.storage().reference()
                    
                    let imageData = UIImageJPEGRepresentation(self.profileIconImageView.image!, 0.8)
                    //                        let imagePath = FIRAuth.auth()!.currentUser!.uid +
                    //                                "/\(Int(NSDate().timeIntervalSinceReferenceDate * 1000)).jpg"
                    if(isImageUpdated)
                    {
                        let imagePath = "images"+"/\(Int(NSDate().timeIntervalSinceReferenceDate * 1000)).jpg"
                        let metadata = FIRStorageMetadata()
                        metadata.contentType = "image/jpeg"
                        
                        storageRef.child(imagePath).putData(imageData!, metadata: metadata, completion: { (metadata, error) in
                            
                            if let error = error {
                                print("Error uploading: \(error)")
                                
                                self.showAlertView(error.localizedDescription)
                                
                                self.saveOrUpdateButton.enabled = true
                                self.spinner.stopAnimating()
                                
                                return
                            }
                            else{
                                
                                self.uploadSuccess(metadata!, storagePath: imagePath)
                            }
                            
                        })

                    }
                    else
                    {
                        saveProfileToFirebase(profileDetailDict.objectForKey("icon") as? String ?? "")
                    }
                    
                }
                else
                {
                    saveProfileToFirebase("")
                    
                }
                
            }
            
        }
        else{
            saveOrUpdateButton.enabled = true
            spinner.stopAnimating()
            
            showAlertView("Please Enter All The Details To Continue")
        }

    }
    
    func uploadSuccess(metadata: FIRStorageMetadata, storagePath: String) {
        print("Upload Succeeded!")
        
        print(metadata.downloadURL()!.absoluteString)
        saveProfileToFirebase(metadata.downloadURL()!.absoluteString)
    }
    
    func saveProfileToFirebase(imagePath: String)
    {
        let ref = FIRDatabase.database().referenceWithPath("profiles/")
        //let currentTimestamp = FIRServerValue.timestamp()
        
        //Adding new profile
        if(isTOAddProfile)
        {
            let autoID = ref.childByAutoId()
            
            let profileDetails = ["id": autoID.key as AnyObject,"name": self.profileNameTextField.text as! AnyObject,"gender": profileGenderLabel.text as! AnyObject,"age": self.profileAgeTextField.text as! AnyObject,"hobbies": self.profileHobbiesTextView.text as AnyObject, "created_at": FIRServerValue.timestamp(),"icon": imagePath as AnyObject,"color": self.hexColorString as AnyObject]
            
            
            autoID.setValue(profileDetails)
            
            showAlertView("Profile Added Successfully")

        }
        //Updating already existing profile
        else
        {
            let autoID = ref.child(profileDetailId)
            
            let profileDetails = ["id": autoID.key as AnyObject,"name": self.profileNameTextField.text as! AnyObject,"gender": profileGenderLabel.text as! AnyObject,"age": self.profileAgeTextField.text as! AnyObject,"hobbies": self.profileHobbiesTextView.text as AnyObject, "created_at": FIRServerValue.timestamp(),"icon": imagePath as AnyObject, "color": self.hexColorString as AnyObject]
            
            
            autoID.updateChildValues(profileDetails)
            
            showAlertView("Profile Updated Successfully")
        }
        
        saveOrUpdateButton.enabled = true
        spinner.stopAnimating()
        
    }
    
    func showAlertView(message: String)
    {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func editProfileButtonClicked()
    {
        
        saveOrUpdateButton.setTitle("Update", forState: UIControlState.Normal)
        
        enableDisableUIElements(true)
        
    }
    
    // MARK: - Enable/Disable UI Elements
    func enableDisableUIElements(isEnabled: Bool)
    {
        profileNameTextField.enabled = isEnabled
        profileAgeTextField.enabled = isEnabled
        profileGenderLabel.userInteractionEnabled = isEnabled
        profileHobbiesTextView.userInteractionEnabled = isEnabled
        profileIconImageView.userInteractionEnabled = isEnabled
        pickAColorButton.enabled = isEnabled
        
        barButtonItem?.enabled = !isEnabled
        saveOrUpdateButton.hidden = !isEnabled
        cancelButton.hidden = !isEnabled
        
        setTextFieldBorderColorAndWidth(profileNameTextField, buttonStatusDeleteOrSave: isEnabled)
        setTextFieldBorderColorAndWidth(profileAgeTextField, buttonStatusDeleteOrSave: isEnabled)
        
        if(isEnabled)
        {
            profileHobbiesTextView.layer.borderColor = UIColor.greenColor().CGColor
            profileHobbiesTextView.layer.borderWidth = 1.0
            
            profileGenderLabel.layer.borderColor = UIColor.greenColor().CGColor
            profileGenderLabel.layer.borderWidth = 1.0
        }
        else{
            profileHobbiesTextView.layer.borderColor = UIColor.lightGrayColor().CGColor
            profileHobbiesTextView.layer.borderWidth = 1.0
            
            profileGenderLabel.layer.borderColor = UIColor.lightGrayColor().CGColor
            profileGenderLabel.layer.borderWidth = 1.0
        }
    }
    
    func setTextFieldBorderColorAndWidth(textField: UITextField, buttonStatusDeleteOrSave: Bool)
    {
        if(buttonStatusDeleteOrSave == true){
            
            textField.layer.borderColor = UIColor.greenColor().CGColor
            textField.layer.borderWidth = 1.0
            
        }
        else{
            
            textField.layer.borderColor = UIColor.lightGrayColor().CGColor
            textField.layer.borderWidth = 1.0

        }
        
    }
    func dismissVC()
    {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: {})
    }
    
    // MARK: - TextField Delegate Method
    func textFieldShouldReturn(textField: UITextField) -> Bool // called when 'return' key pressed. return NO to ignore.
    {
        textField.resignFirstResponder()
        
        return true;
    }
    
    // MARK: - TextView Delegate Methods
    func textViewDidBeginEditing(textView: UITextView) {
        
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            
            
            
            self.view.frame.origin.y -= (self.kHieight-self.profileHobbiesTextView.frame.size.height)
                
        })
        
    }

    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                
                
                self.view.frame.origin.y += (self.kHieight-self.profileHobbiesTextView.frame.size.height)
                
                
                textView.resignFirstResponder()
            })
            
            return false
        }
        return true
    }

    // MARK: - Notification Observers
    func keyboardWillShow(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            //self.commentView.frame.origin.y -= keyboardSize.height
            //whereItIsTextViewBottom.constant = keyboardSize.size.height
            kHieight = keyboardSize.size.height
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                //self.view.layoutIfNeeded()
            })
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        //whereItIsTextViewBottom.constant = whereitisTextView.frame.origin.y+whereitisTextView.frame.size.height
        kHieight = 0.0
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }

    // MARK: - Button Actions
    @IBAction func cancelButtonClicked(sender: AnyObject) {
        
        enableDisableUIElements(false)
        
        setInitialValues()
        
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.view.frame.origin.y = 0
            self.view.layoutIfNeeded()
        })
        
        //profileIconImageView.image = UIImage(named: "user.png")
        
        
    }
    @IBAction func deleteProfileButtonClicked(sender: AnyObject) {
        
        let deleteProfileRef = FIRDatabase.database().referenceWithPath("profiles/\(profileDetailId)")
        deleteProfileRef.removeValue()
        
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    @IBAction func showHidePickerView(sender: AnyObject) {
        
        if(pickerDoneButtonView.hidden == false)
        {
            genderPickerView.hidden = true
            pickerDoneButtonView.hidden = true
        }
        
    }
    
    @IBAction func pickAColorButtonClicked(sender: AnyObject) {
        
        showColorPicker()
        
    }
    
    //// MARK: - Color Palatte
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        // show popover box for iPhone and iPad both
        return UIModalPresentationStyle.None
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // called by color picker after color selected.
    func colorPickerDidColorSelected(selectedUIColor selectedUIColor: UIColor, selectedHexColor: String) {
        
        // update color value within class variable
        //self.selectedColor = selectedUIColor
        self.hexColorString = selectedHexColor
        print(selectedHexColor)
        
        // set preview background to selected color
        self.colorDisplayLabel.backgroundColor = selectedUIColor
    }
    
    // show color picker from UIButton
    private func showColorPicker(){
        
        
        // set modal presentation style
        colorPickerVc.modalPresentationStyle = .Popover
        
        // set max. size
        colorPickerVc.preferredContentSize = CGSizeMake(265, 400)
        
        // set color picker deleagate to current view controller
        // must write delegate method to handle selected color
        colorPickerVc.colorPickerDelegate = self
        
        // show popover
        if let popoverController = colorPickerVc.popoverPresentationController {
            
            // set source view
            popoverController.sourceView = self.view
            
            // show popover form button
            popoverController.sourceRect = self.pickAColorButton.frame
            
            // show popover arrow at feasible direction
            popoverController.permittedArrowDirections = UIPopoverArrowDirection.Any
            
            // set popover delegate self
            popoverController.delegate = self
        }
        
        //show color popover
        presentViewController(colorPickerVc, animated: true, completion: nil)
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
