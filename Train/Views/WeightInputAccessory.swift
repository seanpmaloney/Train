import SwiftUI
import UIKit

// UIKit-based input accessory view
class WeightInputAccessoryView: UIInputView {
    private var onQuickAdd: ((Double) -> Void)?
    private var onUndo: (() -> Void)?
    private var hasUndoValue = false
    
    private let quickAddValues = [2.5, 5.0, 10.0, 15.0, 25.0, 45.0]
    private let containerView = UIView()
    private let scrollView = UIScrollView()
    private let buttonStack = UIStackView()
    
    init(onQuickAdd: @escaping (Double) -> Void, onUndo: @escaping () -> Void, hasUndoValue: Bool) {
        self.onQuickAdd = onQuickAdd
        self.onUndo = onUndo
        self.hasUndoValue = hasUndoValue
        
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 55)
        super.init(frame: frame, inputViewStyle: .keyboard)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = UIColor(white: 0.17, alpha: 1.0)
        autoresizingMask = [.flexibleWidth]
        
        // Container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // Scroll view setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        containerView.addSubview(scrollView)
        
        // Button stack setup
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .horizontal
        buttonStack.spacing = 8
        buttonStack.alignment = .center
        scrollView.addSubview(buttonStack)
        
        // Add quick add buttons
        for value in quickAddValues {
            buttonStack.addArrangedSubview(createQuickAddButton(value: value))
        }
        
        // Add undo button if needed
        if hasUndoValue {
            let divider = createDivider()
            containerView.addSubview(divider)
            
            let undoButton = createUndoButton()
            containerView.addSubview(undoButton)
            
            // Divider constraints
            NSLayoutConstraint.activate([
                divider.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                divider.heightAnchor.constraint(equalToConstant: 24),
                divider.widthAnchor.constraint(equalToConstant: 1),
                divider.trailingAnchor.constraint(equalTo: undoButton.leadingAnchor, constant: -8),
                
                undoButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                undoButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
            ])
        }
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Container view
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Scroll view
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor,
                constant: hasUndoValue ? -70 : -16
            ),
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Button stack
            buttonStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            buttonStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            buttonStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
            buttonStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8),
            buttonStack.heightAnchor.constraint(equalTo: scrollView.heightAnchor, constant: -16)
        ])
    }
    
    private func createQuickAddButton(value: Double) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("+\(Int(value))", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(white: 0.25, alpha: 1.0)
        button.layer.cornerRadius = 10
        
        // Fixed size for buttons
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 36),
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.tag = Int(value * 10)
        button.addTarget(self, action: #selector(quickAddTapped(_:)), for: .touchUpInside)
        return button
    }
    
    private func createDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = UIColor(white: 0.3, alpha: 1.0)
        divider.translatesAutoresizingMaskIntoConstraints = false
        return divider
    }
    
    private func createUndoButton() -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "arrow.uturn.backward", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(white: 0.25, alpha: 1.0)
        button.layer.cornerRadius = 18
        
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 36),
            button.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        button.addTarget(self, action: #selector(undoTapped), for: .touchUpInside)
        return button
    }
    
    @objc private func quickAddTapped(_ sender: UIButton) {
        let value = Double(sender.tag) / 10.0
        onQuickAdd?(value)
    }
    
    @objc private func undoTapped() {
        onUndo?()
    }
}

// UIViewControllerRepresentable for hosting the accessory view controller
struct WeightInputAccessoryViewHost: UIViewControllerRepresentable {
    @Binding var weight: Double
    @Binding var previousWeight: Double?
    @FocusState.Binding var isFocused: Bool
    
    func makeUIViewController(context: Context) -> WeightInputAccessoryViewController {
        WeightInputAccessoryViewController(
            weight: $weight,
            previousWeight: $previousWeight,
            isFocused: _isFocused
        )
    }
    
    func updateUIViewController(_ uiViewController: WeightInputAccessoryViewController, context: Context) {
        // No updates needed - bindings handle state changes
    }
}

// Updated view modifier to use the host
struct WeightInputAccessoryModifier: ViewModifier {
    @Binding var weight: Double
    @Binding var previousWeight: Double?
    @FocusState.Binding var isFocused: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            // Only inject the host when focused
            if isFocused {
                WeightInputAccessoryViewHost(
                    weight: $weight,
                    previousWeight: $previousWeight,
                    isFocused: _isFocused
                )
                .frame(width: 0, height: 0) // Make it invisible
            }
        }
    }
}

// Update the view controller to become first responder when needed
class WeightInputAccessoryViewController: UIViewController {
    private var weight: Binding<Double>
    private var previousWeight: Binding<Double?>
    private var isFocused: FocusState<Bool>.Binding
    private var accessoryView: WeightInputAccessoryView?
    
    init(weight: Binding<Double>, previousWeight: Binding<Double?>, isFocused: FocusState<Bool>.Binding) {
        self.weight = weight
        self.previousWeight = previousWeight
        self.isFocused = isFocused
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var inputAccessoryView: UIView? {
        if accessoryView == nil {
            accessoryView = WeightInputAccessoryView(
                onQuickAdd: { [weak self] value in
                    self?.weight.wrappedValue += value
                },
                onUndo: { [weak self] in
                    if let previous = self?.previousWeight.wrappedValue {
                        self?.weight.wrappedValue = previous
                    }
                },
                hasUndoValue: previousWeight.wrappedValue != nil
            )
        }
        return accessoryView
    }
    
    override var canBecomeFirstResponder: Bool {
        true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }
} 
