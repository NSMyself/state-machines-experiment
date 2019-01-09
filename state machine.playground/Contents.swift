import UIKit
import Foundation
import PlaygroundSupport

// CORE
protocol State: Hashable {}

protocol FiniteStateMachineRepresentable: class {
    associatedtype StateType: State
    
    var currentState: StateType { get set }
    var allowedTransitions: [Transition<StateType>] { get set }
    
    func send(event: StateType) throws
    func didComplete(_ transition: Transition<StateType>)
}

enum FiniteStateMachineError: Error {
    case invalidCurrentState
    case invalidTransaction(from: String, to: String)
}

extension FiniteStateMachineRepresentable {
    
    func send(event nextState: StateType) throws {
        
        let validStates = allowedTransitions.filter { $0.from.contains(currentState) }
        
        guard validStates.count > 0 else {
            throw FiniteStateMachineError.invalidCurrentState
        }
        
        let validDestinations = validStates.filter { $0.to == nextState }
        
        guard let transition = validDestinations.first else {
            throw FiniteStateMachineError.invalidTransaction(from: String(describing: currentState), to: String(describing: nextState))
        }
        
        currentState = transition.to
        didComplete(transition)
    }
    
    func didComplete(_ transition: Transition<StateType>) {
        print("Successfully executed \(transition.name ?? "nameless") transition")
        transition.handler?()
    }
}


final class FiniteStateMachine: FiniteStateMachineRepresentable {
    
    typealias StateType = InitialRoute
    
    var currentState: StateType
    var allowedTransitions: [Transition<StateType>]
    
    init(initialState: StateType, allowedTransitions transitions: [Transition<StateType>]) {
        self.currentState = initialState
        self.allowedTransitions = transitions
    }
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

// Example enum representing a fictional set of routes within an app
// Think of this from a Flow Coordinator's perspective
enum InitialRoute: State  {
    case entry
    case authentication
    case registration
    case main
}

let fsm = FiniteStateMachine(initialState: .entry,
                             allowedTransitions: [
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

do {
    try fsm.send(event: .main)
    print("✨ Event sent.")
} catch FiniteStateMachineError.invalidCurrentState {
    print("💥 Invalid current state!")
} catch FiniteStateMachineError.invalidTransaction(let from, let to) {
    print("💥 Invalid transaction: \(from) to \(to)")
}
