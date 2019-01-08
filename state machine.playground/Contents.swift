
import Foundation
import PlaygroundSupport

protocol State {}

protocol FiniteStateMachineRepresentable: class {
    associatedtype StateType: Hashable
    
    var currentState: StateType { get }
    var allowedTransitions: [StateType: Set<StateType>] { get }
    
    func transition(to: StateType) throws
    func didTransitionFrom(from:StateType, to:StateType)
}

enum InitialRoute: State  {
    case authentication
    case main
}

final class FiniteStateMachine: FiniteStateMachineRepresentable {
    
    typealias StateType = InitialRoute
    
    private(set) var currentState: StateType {
        didSet {
            didTransitionFrom(from: oldValue, to: currentState)
        }
    }
        
    private(set) var allowedTransitions: [StateType: Set<StateType>]
    
    init(initialState: StateType, transitions: [StateType: Set<StateType>]) {
        self.currentState = initialState
        self.allowedTransitions = transitions
    }
    
    func transition(to destination: InitialRoute) {
        
        guard let validState = allowedTransitions[currentState] else {
            print("Invalid current state!")
            // TODO: throw ´invalid current state´ error
            return
        }
        
        guard validState.contains(destination) else {
            print("Invalid transition!")
            // TODO: throw ´invalid transition´ error
            return
        }
        
        currentState = destination
    }
    
    func didTransitionFrom(from: InitialRoute, to: InitialRoute) {
        print("Successfully transitioned from \(from) to \(to)")
        // TODO even later: replace this with an observable property for the current state (and use FRP to propagate this event)
    }
}
    
    
let fsm = FiniteStateMachine(initialState: .authentication,
                             transitions: [
                                .authentication: Set<FiniteStateMachine.StateType>([.main])
                             ])

fsm.transition(to: .main)

// Notes: 
// It's pivotal that the FSM is for pure functions only (no side effects here!)
// Each Coordinator would have an instance of the FSM and it would either observe the machine's currentState or use the didTransition method via delegation, possibly, to inject side-effects (aka making the viewControllers react to the new state)

