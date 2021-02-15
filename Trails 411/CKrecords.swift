//
//  CKrecords.swift
//  Trails 411
//
//  Created by Michael Chartier on 2/15/21.
//

import Foundation
import CloudKit
import UserNotifications
import Reachability


// Default CloudKit Container used by this app
let ckContainer = CKContainer.init(identifier: "iCloud.com.ehmjaysee.Trails-411")

// Complete list of keys we use to index into the cloud kit records
enum MyCloudKitKeys: String {
    // CustomerRecord
    case name
    case status
}

extension CKRecord
{
    subscript(key: MyCloudKitKeys) -> Any? {
        get { return self[key.rawValue] }
        set { self[key.rawValue] = newValue as? CKRecordValue }
    }
}

class CKtrail: NSObject
{
    let ckRecord: CKRecord
    var name: String { return ckRecord[.name] as? String ?? "?" }
    var status: String { return ckRecord[.status] as? String ?? "?" }
    var id: String { return ckRecord.recordID.recordName }

    // Creating objects from CloudKit records
    init( ckRecord: CKRecord )
    {
        self.ckRecord = ckRecord
        super.init()
    }


} // class CKtrail

let ckManager = CKmanager.shared

class CKmanager
{
    // Singleon
    static let shared = CKmanager()
    private init() { }  // private ensures this class will be a singleton

    
    
    // CloudKit
    let container = ckContainer
    var notificationAuth: UNAuthorizationStatus?
    var subCount = 0
    var subCounter = 0
    let reachability = try? Reachability()

    // Change this version number any time we change the format of any CloudKit subscription.
    // This will force the code to delete the old subscriptions and replace with new.
    let currentSubscriptionVersion = 1

    func start()
    {
        // Handle network connection status changes
        reachability?.whenReachable = { status in
            //self.databaseInit()
            //self.iCloudKVS_init()
        }
        try? reachability?.startNotifier()

    }


    /////////////////////////////////////////////////////////////////////
    /// MARK: CloudKit Subscription Management
    /////////////////////////////////////////////////////////////////////

    func checkSubscriptions()
    {
        // Subscriptions are versioned, meaning we will need to replace them if/when they are updated.
        let ckSubVersion = iCloudKVS.longLong(forKey: Defaults.ckSubVersion)
        
        if (ckSubVersion != currentSubscriptionVersion) {
            deletePrivateSubs()
        }
    }
    
    private func deletePrivateSubs()
    {
        print(#function)
        
        subCounter = 0
        
        container.privateCloudDatabase.fetchAllSubscriptions(completionHandler: {
            subs, error in
            if let error = error {
                print("SUB FETCH ERROR " + error.localizedDescription)
            } else if let subs = subs {
                print("SUB FETCH \(subs.count)")
                if (subs.count == 0) {
                    self.deletePublicSubs()
                } else {
                    self.subCount = subs.count
                    for item in subs {
                        print("DELETE \(item.subscriptionID)")
                        self.container.privateCloudDatabase.delete(withSubscriptionID: item.subscriptionID, completionHandler: {
                            message, error in
                            if let error = error {
                                print("SUB DELETE ERROR " + error.localizedDescription)
                            }
                            if let msg = message {
                                print("SUB DELETE MSG " + msg)
                            }
                            self.privateSubWasDeleted()
                        })
                    }
                }
            }
        })
    }
    
    private func privateSubWasDeleted()
    {
        DispatchQueue.main.async {
            self.subCounter += 1
            if (self.subCounter == self.subCount) {
                self.deletePublicSubs()
            }
        }
    }
    
    // Note: This function will only delete the subscriptions in the public database made by the current user.
    // Subscriptions made by other users are not affected.
    private func deletePublicSubs()
    {
        print(#function)
        subCounter = 0
        
        container.publicCloudDatabase.fetchAllSubscriptions(completionHandler: {
            subs, error in
            if let error = error {
                print("SUB FETCH ERROR " + error.localizedDescription)
            } else if let subs = subs {
                print("SUB FETCH \(subs.count)")
                if (subs.count == 0) {
                    self.createSubscriptions()
                } else {
                    self.subCount = subs.count
                    for item in subs {
                        print("DELETE \(item.subscriptionID)")
                        self.container.publicCloudDatabase.delete(withSubscriptionID: item.subscriptionID, completionHandler: {
                            message, error in
                            if let error = error {
                                print("SUB DELETE ERROR " + error.localizedDescription)
                            }
                            if let msg = message {
                                print("SUB DELETE MSG " + msg)
                            }
                            self.publicSubWasDeleted()
                        })
                    }
                }
            }
        })
    }

    private func publicSubWasDeleted()
    {
        DispatchQueue.main.async {
            self.subCounter += 1
            if (self.subCounter == self.subCount) {
                self.createSubscriptions()
            }
        }
    }
    
    private func createSubscriptions()
    {
        subCount = 3
        subCounter = 0
        
        // Create subscriptions in the CloudKit database for this user. Only do this once per user.
        // 1) "Customer" record create/delete/update
        // 2) "CustomerBike" record create/delete/update
        // 3) "LoggerData" record create/update

        // 1) "Customer" record
        let info1 = CKSubscription.NotificationInfo()
        info1.desiredKeys = ["custID"]
        info1.shouldSendContentAvailable = true

        let sub1 = CKQuerySubscription(
            recordType: "Customer",
            predicate: NSPredicate(value: true),
            options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate])
        sub1.notificationInfo = info1
        
        container.privateCloudDatabase.save(sub1) {
            savedSubscription, error in
            if let error = error {
                print("[Customer] " + error.localizedDescription)
            }
            if let subscriptionID = savedSubscription?.subscriptionID {
//                iCloudKVS.set(subscriptionID, forKey: Defaults.ckSubCustomer)
//                appLog.debug("Customer Sub Create ✓")
                self.subscriptionWasAdded()
            }
        }

        // 2) "CustomerBike" record
        let info2 = CKSubscription.NotificationInfo()
        info2.desiredKeys = ["custID", "bikeID"]
        info2.shouldSendContentAvailable = true

        let sub2 = CKQuerySubscription(
            recordType: "CustomerBike",
            predicate: NSPredicate(value: true),
            options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate])
        sub2.notificationInfo = info2
        
        container.privateCloudDatabase.save(sub2) {
            savedSubscription, error in
            if let error = error {
                print("[Customer Bike] " + error.localizedDescription)
            }
            if let subscriptionID = savedSubscription?.subscriptionID {
//                iCloudKVS.set(subscriptionID, forKey: DefaultsKeys.ckSubBike)
//                appLog.debug("CustomerBike Sub Create ✓")
                self.subscriptionWasAdded()
            }
        }
        
        // 3) "LoggerData" record
        let info3 = CKSubscription.NotificationInfo()
        info3.desiredKeys = ["custID", "bikeID", "sessionName"]
        info3.shouldSendContentAvailable = true

        let sub3 = CKQuerySubscription(
            recordType: "LoggerData",
//            predicate: NSPredicate(format: "coachID == %@", coachID),
            predicate: NSPredicate(format: "recordName == fred"), //debug
            options: [.firesOnRecordCreation, .firesOnRecordUpdate])
        sub3.notificationInfo = info3
        
        container.publicCloudDatabase.save(sub3) {
            savedSubscription, error in
            if let error = error as? CKError {
                print("[LoggerData] " + error.localizedDescription)
            }
            if let subscriptionID = savedSubscription?.subscriptionID {
//                iCloudKVS.set(subscriptionID, forKey: Defaults.ckSubLogger)
//                appLog.debug("LoggerData Sub Create ✓")
                self.subscriptionWasAdded()
            }
        }
    }

    private func subscriptionWasAdded()
    {
        DispatchQueue.main.async {
            self.subCounter += 1
            if (self.subCounter == self.subCount) {
                // Save the version number
                iCloudKVS.set(self.currentSubscriptionVersion, forKey: Defaults.ckSubVersion)
            }
        }
    }

}