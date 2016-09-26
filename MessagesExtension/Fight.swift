import Foundation

enum FightMove: String {
    case rock
    case scissor
    case paper

    func localizedText() -> String {
        switch self {
        case .rock:
            return NSLocalizedString("Rock", comment: "")
        case .scissor:
            return NSLocalizedString("Scissors", comment: "")
        case .paper:
            return NSLocalizedString("Paper", comment: "")
        }
    }
}

struct Fight {
    var attackerOption: FightMove?
    var defenderOption: FightMove?
    var ended: Bool = false

    var state: FightState {
        if attackerOption == nil && defenderOption == nil {
            return .attacking
        } else if defenderOption == nil {
            return .defending
        } else if attackerOption == nil {
            assertionFailure("Incorrect State")
        }

        return .finished
    }

    var result: FightResult {
        guard
            let attack = attackerOption,
            let defense = defenderOption
            else {
                return .notEnded
        }
        if attack == defense {
            return .draw
        }

        switch attack {
        case .rock:
            if defense == .paper {
                return .defenderWon
            } else {
                return .attackerWon
            }
        case .paper:
            if defense == .scissor {
                return .defenderWon
            } else {
                return .attackerWon
            }
        case .scissor:
            if defense == .rock {
                return .defenderWon
            } else {
                return .attackerWon
            }
        }        
    }
}

enum FightState {
    case attacking
    case defending
    case finished
}

enum FightResult {
    case notEnded
    case attackerWon
    case defenderWon
    case draw
}


extension Fight {

    enum EncodeKey: String {
        case attackerOption
        case defenderOption
        case state
    }

    func encode() -> URL {
        let baseURL = "www.simpleandpretty.co/decider"

        guard var components = URLComponents(string: baseURL) else {
            fatalError("Invalid base url")
        }

        var items = [URLQueryItem]()

        if let safeAttackerOption = attackerOption {
            let attackerItem = URLQueryItem(name: EncodeKey.attackerOption.rawValue, value: safeAttackerOption.rawValue)
            items.append(attackerItem)
        }

        if let safeDefenderOption = defenderOption {
            let defenderItem = URLQueryItem(name: EncodeKey.defenderOption.rawValue, value: safeDefenderOption.rawValue)
            items.append(defenderItem)
        }

        items.append(URLQueryItem(name: EncodeKey.state.rawValue, value: ended.description))
        components.queryItems = items

        guard let url = components.url else {
            fatalError("Invalid URL components")
        }
        
        return url
    }

    static func decode(fromURL:URL) -> Fight? {

        guard var components = URLComponents(url: fromURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        var attackerOption:FightMove?
        var defenderOption:FightMove?
        var finished: Bool = false

        guard let items = components.queryItems else {
            return nil
        }

        for item in items {
            guard let value = item.value else {
                continue
            }
            switch item.name {
            case EncodeKey.attackerOption.rawValue:
                attackerOption = FightMove(rawValue:value)
            case EncodeKey.defenderOption.rawValue:
                defenderOption = FightMove(rawValue:value)
            case EncodeKey.state.rawValue:
                if let state = Bool(value) {
                    finished = state
                } else {
                    finished = false
                }
            default:
                print("Unknow key on decoding:\(item.name)")
            }

        }

        return Fight(attackerOption: attackerOption, defenderOption: defenderOption, ended: finished)
    }
}
