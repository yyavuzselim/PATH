//
//  ViewController.swift
//  PlannedAlgorithmicTravelHarmony
//
//  Created by Yavuz Selim Yılmaz on 11.12.2024.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var emailText: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func logInButtonClicked(_ sender: Any) {
        performSegue(withIdentifier: "toAdressesVC", sender: nil)
    }
    
    @IBAction func signUpClicked(_ sender: Any) {
        performSegue(withIdentifier: "toSignUpVC", sender: nil)
    }
}

