//
//  AcronymsFeature.swift
//  TILApp-iOS
//
//  Created by Łukasz Stachnik on 26/05/2023.
//

import SwiftUI
import ComposableArchitecture

struct AcronymsFeature: ReducerProtocol {
    
    struct State: Equatable {
        var isLoading = false
        var acronyms: [AcronymResponse] = []
        var path: [Destination] = []
        var searchTerm = ""
        
        enum Destination: Equatable, Hashable {
            case edit(AcronymResponse)
            case create
        }
        
        var searchResults: [AcronymResponse] {
            if searchTerm.isEmpty {
                return acronyms
            } else {
                return acronyms.filter {
                    $0.long.lowercased().contains(searchTerm.lowercased()) ||
                    $0.short.lowercased().contains(searchTerm.lowercased())
                }
            }
        }
    }
    
    enum Action: Equatable {
        case fetchAcronyms
        case searchAcronyms(String)
        case deleteAcronym(String)
        case editAcronym(AcronymResponse)
        case createAcronym
        case addCategory(_ acronymId: String)
        case categoryAdded
        case navigationPathChanged([State.Destination])
        
        case acronymsResponse([AcronymResponse])
        case deleteResponse(String)
    }
    
    @Dependency(\.acronymsClient) var acronymClient
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .fetchAcronyms:
                state.isLoading = true
                return .run { send in
                    try await send(.acronymsResponse(self.acronymClient.all()))
                }
            case .deleteAcronym(let id):
                return .run { send in
                    try await self.acronymClient.delete(id)
                    await send(.deleteResponse(id))
                }
            case .searchAcronyms(let term):
                state.searchTerm = term
                return .none
            case .editAcronym(let acronym):
                state.path.append(.edit(acronym))
                return .none
            case .createAcronym:
                state.path.append(.create)
                return .none
            case .addCategory(let acronymID):
                state.isLoading = true
                return .run { send in
                    guard let categoryID = UIPasteboard.general.string else { return }
                    try await self.acronymClient.addCategory(acronymID, categoryID)
                    await send(.categoryAdded)
                }
            case .categoryAdded:
                state.isLoading = false
                return .none
            case let .navigationPathChanged(path):
                state.path = path
                return .none
            case .acronymsResponse(let acronyms):
                state.acronyms = acronyms
                state.isLoading = false
                return .none
            case .deleteResponse(let id):
                state.acronyms.removeAll(where: { $0.id.uuidString == id })
                return .none
            }
        }
    }
}
