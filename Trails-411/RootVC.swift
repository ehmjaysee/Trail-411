//
//  RootVC.swift
//  Trails 411
//
//  Created by Michael Chartier on 12/31/20.
//

import UIKit
import Reachability


class RootVC: UIViewController
{

    @IBOutlet weak var O_spinner: UIActivityIndicatorView!
    
    // CloudKit
    let container = ckContainer
    var notificationAuth: UNAuthorizationStatus?
    var subCount = 0
    var subCounter = 0
    let reachability = try? Reachability()

    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        MORCdata.update()       // get the latest trail status
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "TrailsNav") as? UINavigationController {
            self.present( vc, animated: true, completion: nil )
        }
    }

    private func setupNotifications()
    {
        // Determine the current authorization status for this user (allow, deny, not determined)
        UNUserNotificationCenter.current().getNotificationSettings() {
            settings in
            if (settings.authorizationStatus == .authorized) {
                self.notificationAuth = .authorized
                ckManager.checkSubscriptions()
            } else if (settings.authorizationStatus == .notDetermined) {
                // We never requested permission from the user.
                // First show a helpful message telling the user why we are requesting permission.
                // When the user dismiss that message we will call requestAuthorization()
                let msg = "In a moment you will be asked to grant permissions for notifications. If you select NO then you must manually refresh the records for all of your clients in order to see their new recordings.\n\nWe recommend that you allow notifications."
                DispatchQueue.main.async {
                    doAlert(vc: self, title: "Alert", message: msg) {
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge]) {
                            authorized, error in
                            if let error = error {
                                print(error)
                            }
                            if authorized == true {
                                self.notificationAuth = .authorized
                                appDefaults.set(true, forKey: Defaults.notificationAuth)
                                DispatchQueue.main.async {
                                    print("CALLING registerForRemoteNotifications")
                                    UIApplication.shared.registerForRemoteNotifications()
                                }
                                ckManager.checkSubscriptions()
                            } else {
                                self.notificationAuth = .denied
                            }
                        }
                    }
                }
            } else {
                appDefaults.removeObject(forKey: Defaults.notificationAuth)
            }
        }
    }


    
}
