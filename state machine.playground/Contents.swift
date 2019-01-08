
import Foundation
import PlaygroundSupport

protocol StateMachineDelegate: class {
    associatedtype State
    
    func transition(to state: State)
    func shouldTransition(from: State, to: State) -> Bool
    func didTransition(from: State, to: State)
}

final class StateMachine<P: StateMachineDelegate> {
    
    weak var delegate: P?
    internal var currentState: P.State {
        willSet {
            guard let delegate = delegate else {
                fatalError("State machine delegate not set!")
            }
            
            guard delegate.shouldTransition(from: currentState, to: newValue) else {
                print("Neps")
                return
            }
            print(newValue)
            self.currentState = newValue
        }
        
        didSet {
            delegate?.didTransition(from: oldValue, to: currentState)
        }
    }

    init(state: P.State) {
        self.currentState = state
    }
}

class AppCoordinator {
     var machine = StateMachine<AppCoordinator>(state: .ready)
    
    init() {
        machine.delegate = self
    }
}
    
extension AppCoordinator: StateMachineDelegate {
    
    typealias State = AsyncNetworkState
    
    enum AsyncNetworkState{
        case ready, fetching, saving(id: Int)
    }
    
    func transition(to state: State) {
        guard shouldTransition(from: machine.currentState, to: state) else { return }
        machine.currentState = state
    }
    
    func shouldTransition(from: State, to: State) -> Bool {
        print("Should? \(to)")
        switch (machine.currentState, to) {
        case (.ready, .fetching):
            return true
        default:
            return false
        }
    }
    
    func didTransition(from: State, to: State) {
        print("Transitioned from: \(from) to \(to)")
    }
}

let coordinator = AppCoordinator()
coordinator.machine.currentState = AppCoordinator.AsyncNetworkState.saving(id: 14)

