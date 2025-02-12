//
//  ViewController.swift
//  PlannedAlgorithmicTravelHarmony
//
//  Created by Yavuz Selim Yılmaz on 11.12.2024.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.layer.cornerRadius = 15 // İstediğin değeri buraya gir
        imageView.clipsToBounds = true 
    }

    @IBAction func logInButtonClicked(_ sender: Any) {
        performSegue(withIdentifier: "toAdressesVC", sender: nil)
    }
    
}

