import UIKit
import Foundation
import PlaygroundSupport

protocol State: Hashable {}

protocol FiniteStateMachineRepresentable: class {
    associatedtype StateType: State
    
    var currentState: StateType { get }
    var allowedTransitions: [Transition<StateType>] { get }
    
    func send(event: StateType) throws
    func didComplete(_ transition: Transition<StateType>)
}

final class FiniteStateMachine: FiniteStateMachineRepresentable {
    
    typealias StateType = InitialRoute
    
    private(set) var currentState: StateType
    private(set) var allowedTransitions: [Transition<StateType>]
    
    init(initialState: StateType, transitions: [Transition<StateType>]) {
        self.currentState = initialState
        self.allowedTransitions = transitions
    }
    
    func send(event nextState: InitialRoute) {
        
         let validStates = allowedTransitions.filter { $0.from.contains(currentState) }
        
        guard validStates.count > 0 else {
            print("Unable to find an allowed transition starting from \(currentState)")
            // TODO: throw ´invalid current state´ error
            return
        }
        
        let validDestinations = validStates.filter { $0.to == nextState }
        
        guard let transition = validDestinations.first else {
            print("Invalid transition!")
            // TODO: throw ´invalid transition´ error
            return
        }
        
        currentState = transition.to
        didComplete(transition)
    }
    
    func didComplete(_ transition: Transition<StateType>) {
        print("Successfully executed \(transition.name ?? "nameless") transition")
        transition.handler?()
        // TODO even later: replace this with an observable property for the current state (and use FRP to propagate this event)
    }
}
    
enum InitialRoute: State  {
    case entry
    case authentication
    case registration
    case main
}

struct Transition<T: State> {
    var name: String?
    let from: Set<T>
    let to: T
    var handler: (() -> Void)?
    
    init(name: String? = nil, from source: T, to destination: T, handler: (()->Void)? = nil) {
        self.init(name: name, from: Set<T>([source]), to: destination, handler: handler)
    }
    
    init(name: String? = nil, from sourceArray: [T], to destination: T, handler: (()->Void)? = nil) {
        self.init(name: name, from: Set<T>(sourceArray), to: destination, handler: handler)
    }
    
    init(name: String? = nil, from: Set<T>, to: T, handler: (()->Void)? = nil) {
        self.name = name
        self.from = from
        self.to = to
        self.handler = handler
    }
}

extension Transition: Hashable {
    func hash(into hasher: inout Hasher) {
        
        if let name = name {
            hasher.combine(name)
        }
        
        hasher.combine(from)
        hasher.combine(to)
    }
    
    static func == (lhs: Transition, rhs: Transition) -> Bool {
        return (lhs.from.hashValue == rhs.from.hashValue) && (lhs.to.hashValue == rhs.to.hashValue)
    }
}

let fsm = FiniteStateMachine(initialState: .entry,
                             transitions: [
                                    Transition(
                                        name: "login",
                                        from: [.entry, .registration],
                                        to: .authentication,
                                        handler: { print("User wants to login") }
                                    ),
                                    Transition(
                                        name: "register",
                                        from: [.entry, .authentication],
                                        to: .registration,
                                        handler: { print("User wants to register") }
                                    ),
                                    Transition(
                                        name: "loggedIn",
                                        from: [.authentication, .registration],
                                        to: .main,
                                        handler: { print("User actually logged in") }
                                    )
                             ])

fsm.send(event: .authentication)

// Notes:
// The FSM should be kept side-effects free; only Transition objects can have side effects (via the `handler` instance variable)
// Each Coordinator would have an instance of the FSM and it would either observe the machine's currentState or use the didTransition method via delegation, possibly

// TODO tl;dr:
// 1. Add custom error handling
// 2. Setup a "fake" coordinator and a delegate method between the FSM and it's parent coordinator; make the live views reflect changes in the current state
// 3. replace the `didTransition` method with proper FRP bindings
