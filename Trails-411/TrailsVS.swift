//
//  TrailsVS.swift
//  Trails 411
//
//  Created by Michael Chartier on 12/31/20.
//

import UIKit

class TrailsVS: UIViewController
{

    @IBOutlet weak var O_bottomView: UIView!
    @IBOutlet weak var O_controls: UIBarButtonItem!
    @IBOutlet weak var O_bottomHeight: NSLayoutConstraint!
    @IBOutlet weak var O_table: UITableView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        O_table.delegate = self
        O_table.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(trailUpdate(notification:)), name: Notif_TrailUpdate, object: nil)

    }
    
    @IBAction func A_controls(_ sender: Any)
    {
        let newHeight: CGFloat = (O_bottomHeight.constant == 1.0) ? 108.0 : 1.0
                
        UIView.animate(withDuration: 0.5) {
            self.O_bottomHeight.constant = newHeight
            self.view.layoutIfNeeded()
        }

    }
    
}

extension TrailsVS: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allTrails.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let trail = allTrails[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrailCell", for: indexPath)
        if let trailCell = cell as? TrailCell {
            trailCell.O_title.text = trail.name
            if trail.isOpen {
                trailCell.O_icon.image = #imageLiteral(resourceName: "open-sign")
            } else {
                trailCell.O_icon.image = #imageLiteral(resourceName: "barrier")
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { showSelected() }
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) { showSelected() }
    
    private func showSelected()
    {
        // The table is configured for multiselect mode.
        // In this mode the table delegate gets called each time the user taps on any row to select or deselect that row.
        O_table.beginUpdates()
        O_table.endUpdates()
    }

    /*
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let rows = tableView.indexPathsForSelectedRows, rows.contains(indexPath) {
            return 74
        } else {
            return 45
        }
    }
    */
    
    @objc func trailUpdate( notification: NSNotification )
    {
        DispatchQueue.main.async {
            let section0: IndexSet = [0]
            self.O_table.reloadSections(section0, with: .automatic)
        }
    }

}

