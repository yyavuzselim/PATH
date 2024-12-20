//
//  SignUpVC.swift
//  PlannedAlgorithmicTravelHarmony
//
//  Created by Yavuz Selim Yılmaz on 11.12.2024.
//

import UIKit

class SignUpVC: UIViewController {

    @IBOutlet weak var passwordAgainText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var emailText: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func signUpClicked(_ sender: Any) {
        performSegue(withIdentifier: "toAdressesVC2", sender: nil)
    }
    
}
