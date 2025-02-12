import UIKit

class SplashScreenVC: UIViewController {
    
    // MARK: - UI Elements
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "PATH"
        label.font = .systemFont(ofSize: 40, weight: .heavy)
        label.textColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Planned Algortihmic Travel Harmony"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .systemGray
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let routeLine: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let startPin: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(systemName: "mappin.circle.fill")
        image.tintColor = .systemRed
        image.contentMode = .scaleAspectFit
        image.alpha = 0
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    private let endPin: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(systemName: "mappin.and.ellipse")
        image.tintColor = .systemGreen
        image.contentMode = .scaleAspectFit
        image.alpha = 0
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimationSequence()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        // Add subviews
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(routeLine)
        containerView.addSubview(startPin)
        containerView.addSubview(endPin)
        
        // Initial states
        routeLine.transform = CGAffineTransform(scaleX: 0.0, y: 1.0)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Container
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            containerView.heightAnchor.constraint(equalToConstant: 200),
            
            // Title
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            
            // Subtitle
            subtitleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            
            // Route Line
            routeLine.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            routeLine.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 20),
            routeLine.widthAnchor.constraint(equalToConstant: 200),
            routeLine.heightAnchor.constraint(equalToConstant: 4),
            
            // Start Pin
            startPin.trailingAnchor.constraint(equalTo: routeLine.leadingAnchor, constant: -5),
            startPin.centerYAnchor.constraint(equalTo: routeLine.centerYAnchor),
            startPin.widthAnchor.constraint(equalToConstant: 30),
            startPin.heightAnchor.constraint(equalToConstant: 30),
            
            // End Pin
            endPin.leadingAnchor.constraint(equalTo: routeLine.trailingAnchor, constant: 5),
            endPin.centerYAnchor.constraint(equalTo: routeLine.centerYAnchor),
            endPin.widthAnchor.constraint(equalToConstant: 30),
            endPin.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    // MARK: - Animations
    private func startAnimationSequence() {
        // 1. Start Pin Animation
        UIView.animate(withDuration: 0.6, delay: 0.2, options: .curveEaseOut) {
            self.startPin.alpha = 1
            self.startPin.transform = CGAffineTransform(translationX: 0, y: -10)
        }
        
        // 2. Route Line Animation
        UIView.animate(withDuration: 1.0, delay: 0.8, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2, options: .curveEaseOut) {
            self.routeLine.transform = .identity
        }
        
        // 3. End Pin Animation
        UIView.animate(withDuration: 0.6, delay: 1.8, options: .curveEaseOut) {
            self.endPin.alpha = 1
            self.endPin.transform = CGAffineTransform(translationX: 0, y: -10)
        }
        
        // 4. Title Animation with gradient
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            self.animateTextWithGradient()
        }
        
        // 5. Subtitle Fade In
        UIView.animate(withDuration: 0.8, delay: 3.0) {
            self.subtitleLabel.alpha = 1
        }
        
        // 6. Navigate to main screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.navigateToMain()
        }
    }
    
    private func animateTextWithGradient() {
        let gradient = CAGradientLayer()
        gradient.frame = titleLabel.bounds
        gradient.colors = [
            UIColor.systemBlue.cgColor,
            UIColor.systemIndigo.cgColor
        ]
        
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        
        titleLabel.textColor = .black
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 0.8
        animation.repeatCount = 1
        
        gradient.add(animation, forKey: nil)
        titleLabel.layer.mask = gradient
    }
    
    // MARK: - Navigation
    private func navigateToMain() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let mainVC = storyboard.instantiateViewController(withIdentifier: "ViewController") as? ViewController {
            mainVC.modalPresentationStyle = .fullScreen
            mainVC.modalTransitionStyle = .crossDissolve
            self.present(mainVC, animated: true)
        }
    }
}
