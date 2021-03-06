//
//  SupportViewController.swift
//  Timely Goals
//
//  Created by David Solomon on 2/16/18.
//  Copyright © 2018 David Solomon. All rights reserved.
//

import UIKit
import MessageUI

class SupportViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    @IBAction func emailSupport(_ sender: UIButton) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["Support <solodavestudios@gmail.com>"])
            mail.setSubject("Report Issue")
            mail.setMessageBody("<p>Dear Support,</p>", isHTML: true)
            present(mail, animated: true, completion: nil)
        } else {
            print("Error loading email")
        }
    }
    
    @IBAction func dismiss(_ sender: UIButton) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }
    @IBAction func rateApp(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: "https://itunes.apple.com/us/app/its-go-time/id1357722489?ls=1&mt=8")!, options: [:], completionHandler: nil)

    }
}
