import UIKit
import PhotosUI
import FittedSheets
import BottomSheet




class ChatViewController: UIViewController, UITextFieldDelegate,UIScrollViewDelegate,PHPickerViewControllerDelegate {

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let mainSheetView = UIView()
    private let textView = UITextView()
    private let imageButton = UIButton(type: .system)
    private let sendButton = UIButton(type: .system)
    
    // MARK: - Layout Constraints
    private var mainSheetHeightConstraint: NSLayoutConstraint!
    private var mainSheetBottomConstraint: NSLayoutConstraint!
    
    private var lastKeyboardHeight: CGFloat = 0
    private var initialBottomConstant: CGFloat = 0
    private let defaultKeyboardHeight: CGFloat = 300 // Fallback if keyboard height isn't yet known
    
    private var sheetController : SheetViewController?
    
    
    private let hyKeyboardListener = HyKeyboardListener()
    
    private var keyboardWindow: UIWindow? {
        return hyKeyboardListener.keyboardWindow
    }
    
    private var tileVC = TilePickerViewController()


    
    // Main sheet's height relative to the device height
    private var mainSheetInitialHeight: CGFloat {
        return view.bounds.height * 0.3
    }
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupMainSheetView()
        setupMainSheetSubviews()
        setupPanGesture()
        textView.keyboardDismissMode = .interactive
        hyKeyboardListener.delegate = self

    }
    
    
    @objc private func showStartImagePicker() {
        let config = PHPickerConfiguration()
        let container = PickerContainerViewController(configuration: config)

        var options = SheetOptions()
        options.pullBarHeight = 0
        options.useInlineMode = false
        options.useFullScreenMode = false
        options.shrinkPresentingViewController = false


        let sheet = SheetViewController(
            controller: container,
            sizes: [.percent(0.25), .fullscreen],
            options: options
        )

        sheet.cornerRadius = 20
        sheet.gripSize = CGSize(width: 60, height: 6)
        sheet.hasBlurBackground = false
        sheet.dismissOnPull = true
        sheet.dismissOnOverlayTap = true

        // ✅ Present from root so it stays under your composer
        if let root = self.view.window?.rootViewController {
            root.present(sheet, animated: true)
        } else {
            self.present(sheet, animated: true)
        }
    }

    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // Dismiss embedded picker
        picker.willMove(toParent: nil)
        picker.view.removeFromSuperview()
        picker.removeFromParent()
    }


    
    
    @objc private func handleKeyboardFrameChange(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
            let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }

        let keyboardHeight = view.frame.height - endFrame.origin.y
        lastKeyboardHeight = keyboardHeight
        
        mainSheetBottomConstraint.constant = -keyboardHeight
        scrollView.contentInset.bottom = keyboardHeight

        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: UIView.AnimationOptions(rawValue: curve << 16),
                       animations: {
            self.view.layoutIfNeeded()
        })
    }

    @objc private func handleKeyboardWillHide(_ notification: Notification) {
        mainSheetBottomConstraint.constant = 0
        scrollView.contentInset.bottom = 0

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    
    // MARK: - Setup ScrollView
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        // This enables the system's interactive keyboard dismissal.
        scrollView.keyboardDismissMode = .interactive
        scrollView.delegate = self
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    // MARK: - Setup Main Sheet
    private func setupMainSheetView() {
        mainSheetView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        mainSheetView.layer.cornerRadius = 25
        mainSheetView.clipsToBounds = true
        mainSheetView.translatesAutoresizingMaskIntoConstraints = false
        // Add the sheet directly to the view (so it's not affected by the scroll view's content size)
        // but we will update its bottom constraint based on keyboard frame.
        view.addSubview(mainSheetView)
        
        mainSheetHeightConstraint = mainSheetView.heightAnchor.constraint(equalToConstant: mainSheetInitialHeight)
        mainSheetHeightConstraint.isActive = true
        
        // Initially, the sheet is pinned to the safe area's bottom.
        mainSheetBottomConstraint = mainSheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        mainSheetBottomConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            mainSheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainSheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    
    private func setupPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        // Optionally, add it to mainSheetView (or any view you prefer).
        mainSheetView.addGestureRecognizer(panGesture)
    }
    
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view).y
        
        switch gesture.state {
        case .began:
            initialBottomConstant = mainSheetBottomConstraint.constant
            
        case .changed:
            // Only handle downward drags.
            guard translation.y > 0 else { return }
            
            if hyKeyboardListener.isUp {
                // Drag the keyboard window and sheet view.
                if translation.y < hyKeyboardListener.height {
                    keyboardWindow?.transform = CGAffineTransform(translationX: 0, y: translation.y)
                } else {
                    keyboardWindow?.transform = CGAffineTransform(translationX: 0, y: hyKeyboardListener.height)
                }
                mainSheetView.transform = CGAffineTransform(translationX: 0, y: translation.y)
            } else {
                mainSheetView.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
            
        case .ended, .cancelled:
            let d = pow(velocity, 2) / 5000  // friction
            let finalTranslation = translation.y + (velocity >= 0 ? d : -d)
            
            if hyKeyboardListener.isUp && finalTranslation > hyKeyboardListener.height / 2 {
                // Dismiss the keyboard if dragged enough.
                
                print("hyKeyboardListener ended - cancelled ")
                UIView.animate(withDuration: 0.3, animations: {
                    self.keyboardWindow?.transform = .identity
                    self.mainSheetView.transform = .identity
                     self.view.endEditing(true)

                }, completion: { _ in
                    // Dismiss the keyboard (resigning first responder)
                   // self.view.endEditing(true)
                })
            } else {
                // Otherwise, snap everything back.
                UIView.animate(withDuration: 0.3) {
                    self.keyboardWindow?.transform = .identity
                    self.mainSheetView.transform = .identity
                }
            }
            
        default:
            break
        }
    }



    
    private func setupMainSheetSubviews() {
        // Configure the text field.
        textView.backgroundColor = .systemPink
        textView.isEditable = true
        
        textView.text = "Enter text..."
        textView.translatesAutoresizingMaskIntoConstraints = false
        mainSheetView.addSubview(textView)
        
        // Configure the Image button.
        imageButton.setImage(UIImage(named: "image")?.withRenderingMode(.alwaysOriginal), for: .normal)
        imageButton.translatesAutoresizingMaskIntoConstraints = false
        // (Add your image picker action here)
        imageButton.addTarget(self, action: #selector(imageButtonTapped), for: .touchUpInside)
        mainSheetView.addSubview(imageButton)
        
        // Configure the Send button.
        sendButton.setImage(UIImage(named: "send")?.withRenderingMode(.alwaysOriginal), for: .normal)

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        mainSheetView.addSubview(sendButton)
        
        // Layout: text field at the top; buttons 10 points above the sheet's safe area at the bottom.
        let safeArea = mainSheetView.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: mainSheetView.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: mainSheetView.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: mainSheetView.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(equalToConstant: 150),
            
            imageButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -10),
            imageButton.leadingAnchor.constraint(equalTo: mainSheetView.leadingAnchor, constant: 40),
            imageButton.widthAnchor.constraint(equalToConstant: 30),
            imageButton.heightAnchor.constraint(equalToConstant: 30),
            
            sendButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -10),
            sendButton.trailingAnchor.constraint(equalTo: mainSheetView.trailingAnchor, constant: -40),
            sendButton.widthAnchor.constraint(equalToConstant: 30),
            sendButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    
    // MARK: - Button Actions
//    @objc private func imageButtonTapped() {
//        // For demonstration, dismiss the keyboard.
//        let tmp = self.mainSheetBottomConstraint.constant
//        view.endEditing(true)
//        // You can also trigger your image picker sheet here.
//        mainSheetBottomConstraint.constant = tmp
//
//        showStartImagePicker()
//    }
    
    @objc private func imageButtonTapped() {

                
        
//        let currentBottom = mainSheetBottomConstraint.constant
//        self.view.endEditing(true) // Dismiss keyboard
//        mainSheetBottomConstraint.constant = currentBottom // Lock position
//        self.view.layoutIfNeeded()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//              self.presentImagePickerSheet()
//          }


        
        let options = SheetOptions(
            // The full height of the pull bar. The presented view controller will treat this area as a safearea inset on the top
            pullBarHeight: 24,
            
            // The corner radius of the shrunken presenting view controller
            presentingViewCornerRadius: 20,
            
            // Extends the background behind the pull bar or not
            shouldExtendBackground: true,
            
            // Attempts to use intrinsic heights on navigation controllers. This does not work well in combination with keyboards without your code handling it.
            setIntrinsicHeightOnNavigationControllers: true,
            
            // Pulls the view controller behind the safe area top, especially useful when embedding navigation controllers
            useFullScreenMode: true,
            
            // Shrinks the presenting view controller, similar to the native modal
            shrinkPresentingViewController: true,
            
            // Determines if using inline mode or not
            useInlineMode: false,
            
            // Adds a padding on the left and right of the sheet with this amount. Defaults to zero (no padding)
            horizontalPadding: 0,
            
            // Sets the maximum width allowed for the sheet. This defaults to nil and doesn't limit the width.
            maxWidth: nil
        )

        self.sheetController = SheetViewController(
            controller: tileVC,
            sizes: [.fixed(200), .percent(0.8)])
        
        if let sheetController = self.sheetController {
            

            
            // The corner curve of the sheet (iOS 13 or later)
            sheetController.cornerCurve = .continuous
            
            // The corner radius of the sheet
            sheetController.cornerRadius = 20
            
            
            // Set the pullbar's background explicitly
            sheetController.pullBarBackgroundColor = UIColor.blue
            
            // Determine if the rounding should happen on the pullbar or the presented controller only (should only be true when the pull bar's background color is .clear)
            sheetController.treatPullBarAsClear = false
            
            // Disable the dismiss on background tap functionality
            sheetController.dismissOnOverlayTap = false
            
            // Disable the ability to pull down to dismiss the modal
            sheetController.dismissOnPull = true
            
            /// Allow pulling past the maximum height and bounce back. Defaults to true.
            sheetController.allowPullingPastMaxHeight = false
            
            /// Automatically grow/move the sheet to accomidate the keyboard. Defaults to true.
            sheetController.autoAdjustToKeyboard = true
            
            // Color of the sheet anywhere the child view controller may not show (or is transparent), such as behind the keyboard currently
            
            // Change the overlay color
            
            sheetController.shouldDismiss = { _ in
                // This is called just before the sheet is dismissed. Return false to prevent the build in dismiss events
                return true
            }
            sheetController.didDismiss = { _ in
                // This is called after the sheet is dismissed
            }
            
            present(sheetController, animated: true)
            
        }


        
        
//        textView.inputView = bottomSheetViewController.view
//         textView.reloadInputViews()
//         textView.becomeFirstResponder()
                
    }
    
    private func presentImagePickerSheet() {
//        let pickerSheet = ImagePickerSheetViewController()
//        pickerSheet.modalPresentationStyle = .overFullScreen
//        pickerSheet.modalTransitionStyle = .crossDissolve

//        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
//            let height: CGFloat = 300
//            pickerSheet.view.frame = CGRect(
//                x: 0,
//                y: window.bounds.height - height,
//                width: window.bounds.width,
//                height: height
//            )
//            window.rootViewController?.addChild(pickerSheet)
//            window.addSubview(pickerSheet.view)
//            pickerSheet.didMove(toParent: window.rootViewController)
//        }
    }


    
    
    @objc private func sendButtonTapped() {
        view.endEditing(true)
        print("Send tapped with text: \(textView.text ?? "")")
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // (If an image picker sheet is showing, dismiss it here.)
        return true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("\(scrollView.contentOffset.y)")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

protocol HyKeyboardListenerDelegate: AnyObject {
    func hyKeyboardListener(_ listener: HyKeyboardListener, willShowWith model: HyKeyboardListener.Model)
    func hyKeyboardListener(_ listener: HyKeyboardListener, willHideWith model: HyKeyboardListener.Model)
}

class HyKeyboardListener {

    public private(set) var isUp: Bool = false
    public var height: CGFloat = 0

    public struct Model {
        let duration: TimeInterval
        let animationOptions: UIView.AnimationOptions
        let frame: CGRect
    }

    public weak var delegate: HyKeyboardListenerDelegate?
    public weak var keyboardWindow: UIWindow?

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidBecomeVisible(_:)), name: UIWindow.didBecomeVisibleNotification, object: nil)

    }

    @objc private func windowDidBecomeVisible(_ info: Notification) {
        let type = String(describing: info.object)
        if type.range(of: "UIRemoteKeyboardWindow") != nil {
            if let window = info.object as? UIWindow {
                self.keyboardWindow = window
            }
            print("That's UIRemoteKeyboardWindow")
//            keyboardWindow = info.object
        }
    }

    private func getModel(notification: Notification) -> Model {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.3

        let animationOptions: UIView.AnimationOptions
        if let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {
            animationOptions = UIView.AnimationOptions(rawValue: curve << 16)
        } else {
            animationOptions = .curveEaseOut
        }

        var frame: CGRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero

        for window in UIApplication.shared.windows {
            if String(describing: type(of: window)) == "UIRemoteKeyboardWindow" {
                keyboardWindow = window
                let keyboardViewController = window.rootViewController
                for view in keyboardViewController?.view.subviews ?? [] {
                    if String(describing: type(of: view)) == "UIInputSetHostView" {
                        if frame.minY <= 0 {
                            frame = view.frame
                        }
                    }
                }
            }
        }

        if frame.minY <= 0 {
            let safeAreaBottomInset = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
            let screenHeight = UIScreen.main.bounds.height

            let y = screenHeight - frame.height - safeAreaBottomInset
            frame.origin.y = y
        }

        self.height = frame.height

        return Model(duration: duration, animationOptions: animationOptions, frame: frame)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {

        isUp = true

        if let delegate {
            delegate.hyKeyboardListener(self, willShowWith: getModel(notification: notification))
        }
    }

    func findKeyboardWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            // Iterate over all connected scenes
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    // Iterate over all windows in the window scene
                    for window in windowScene.windows {
                        if NSStringFromClass(window.classForCoder) == "UIRemoteKeyboardWindow" {
                            return window
                        }
                    }
                }
            }
        } else {
            // Iterate over all windows in the application (for iOS 12 and below)
            for window in UIApplication.shared.windows {
                if NSStringFromClass(window.classForCoder) == "UIRemoteKeyboardWindow" {
                    return window
                }
            }
        }
        return nil
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        isUp = false

        if let delegate {
            delegate.hyKeyboardListener(self, willHideWith: getModel(notification: notification))
        }
    }

    @objc private func keyboardDidHide(_ notification: Notification) {
        isUp = false
        keyboardWindow = nil
    }

}

import UIKit

class TilePickerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let colors: [UIColor] = (0..<30).map { _ in
        UIColor(
            red: .random(in: 0.3...1),
            green: .random(in: 0.3...1),
            blue: .random(in: 0.3...1),
            alpha: 1
        )
    }

    private var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.register(TileCell.self, forCellWithReuseIdentifier: "TileCell")
        collectionView.dataSource = self
        collectionView.delegate = self

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TileCell", for: indexPath) as! TileCell
        cell.backgroundColor = colors[indexPath.item]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 48) / 3 // 3 tiles per row
        return CGSize(width: width, height: width)
    }
}

class TileCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 12
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



class KeyboardContainerViewController: UIViewController {

    private let dragHandle = UIView()
    private let contentView = UIView()
    private var heightConstraint: NSLayoutConstraint!
    private var initialTouchPoint: CGPoint = .zero
    private var initialHeight: CGFloat = 300
    private let maxHeight: CGFloat = UIScreen.main.bounds.height * 0.9
    private let minHeight: CGFloat = 200
    private var isDragging = false
    private var initialFrame: CGRect = .zero
    private var initialKeyboardHeight: CGFloat = 0
    private var currentHeight: CGFloat = 300

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPanGesture()
        initialKeyboardHeight = view.frame.height
        currentHeight = initialKeyboardHeight
    }

    private func setupUI() {
        view.backgroundColor = .clear

        // Drag handle
        dragHandle.translatesAutoresizingMaskIntoConstraints = false
        dragHandle.backgroundColor = .lightGray
        dragHandle.layer.cornerRadius = 3
        view.addSubview(dragHandle)

        NSLayoutConstraint.activate([
            dragHandle.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            dragHandle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dragHandle.widthAnchor.constraint(equalToConstant: 40),
            dragHandle.heightAnchor.constraint(equalToConstant: 6)
        ])

        // Content
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .systemGroupedBackground
        contentView.layer.cornerRadius = 20
        contentView.clipsToBounds = true
        view.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: dragHandle.bottomAnchor, constant: 8),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Add dummy tile picker
        let pickerVC = TilePickerViewController()
        addChild(pickerVC)
        contentView.addSubview(pickerVC.view)
        pickerVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pickerVC.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            pickerVC.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            pickerVC.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pickerVC.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
        pickerVC.didMove(toParent: self)
    }

    private func setupPanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .began:
            initialTouchPoint = gesture.location(in: view)
            isDragging = true

        case .changed:
            guard isDragging else { return }
            
            // Calculate new height based on drag direction
            let heightDelta = -translation.y // Negative because we want to expand upward
            let newHeight = max(minHeight, min(maxHeight, currentHeight + heightDelta))
            currentHeight = newHeight
            
            // Update the input view's height
            if let inputView = view.superview {
                inputView.frame.size.height = newHeight
                inputView.setNeedsLayout()
            }
            
            // Update the keyboard window position
            if let keyboardWindow = findKeyboardWindow() {
                let keyboardTransform = CGAffineTransform(translationX: 0, y: -heightDelta)
                keyboardWindow.transform = keyboardTransform
            }
            
            gesture.setTranslation(.zero, in: view)

        case .ended, .cancelled:
            isDragging = false
            let velocity = gesture.velocity(in: view).y
            let shouldDismiss = velocity < -1000 || currentHeight < minHeight + 100

            if shouldDismiss {
                // Dismiss and restore normal keyboard
                if let responder = findFirstResponder(in: UIApplication.shared.windows.first!) {
                    responder.reloadInputViews()
                    responder.becomeFirstResponder()
                }
            } else if currentHeight > (minHeight + maxHeight) / 2 {
                // Snap to full height
                UIView.animate(withDuration: 0.3) {
                    if let inputView = self.view.superview {
                        inputView.frame.size.height = self.maxHeight
                        inputView.setNeedsLayout()
                    }
                    self.currentHeight = self.maxHeight
                    
                    // Move keyboard up
                    if let keyboardWindow = self.findKeyboardWindow() {
                        keyboardWindow.transform = CGAffineTransform(translationX: 0, y: -(self.maxHeight - self.initialKeyboardHeight))
                    }
                }
            } else {
                // Snap back to initial height
                UIView.animate(withDuration: 0.3) {
                    if let inputView = self.view.superview {
                        inputView.frame.size.height = self.initialKeyboardHeight
                        inputView.setNeedsLayout()
                    }
                    self.currentHeight = self.initialKeyboardHeight
                    
                    // Reset keyboard position
                    if let keyboardWindow = self.findKeyboardWindow() {
                        keyboardWindow.transform = .identity
                    }
                }
            }

        default:
            break
        }
    }

    private func findKeyboardWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    for window in windowScene.windows {
                        if NSStringFromClass(window.classForCoder) == "UIRemoteKeyboardWindow" {
                            return window
                        }
                    }
                }
            }
        } else {
            for window in UIApplication.shared.windows {
                if NSStringFromClass(window.classForCoder) == "UIRemoteKeyboardWindow" {
                    return window
                }
            }
        }
        return nil
    }

    // Helper to find first responder
    private func findFirstResponder(in view: UIView) -> UIResponder? {
        if view.isFirstResponder { return view }
        for subview in view.subviews {
            if let responder = findFirstResponder(in: subview) {
                return responder
            }
        }
        return nil
    }
}

extension KeyboardContainerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}


extension ChatViewController: HyKeyboardListenerDelegate {
    func hyKeyboardListener(_ listener: HyKeyboardListener, willShowWith model: HyKeyboardListener.Model) {
        // Update the sheet’s bottom constraint so that it moves with the keyboard.
        mainSheetBottomConstraint.constant = -model.frame.height
        UIView.animate(withDuration: model.duration,
                       delay: 0,
                       options: model.animationOptions,
                       animations: {
                           self.view.layoutIfNeeded()
                       })
    }
    
    func hyKeyboardListener(_ listener: HyKeyboardListener, willHideWith model: HyKeyboardListener.Model) {
        // Reset the sheet’s bottom constraint when the keyboard hides.
        
        mainSheetBottomConstraint.constant = 0
        UIView.animate(withDuration: model.duration,
                       delay: 0,
                       options: model.animationOptions,
                       animations: {
                           self.view.layoutIfNeeded()
                       })
    }
}

