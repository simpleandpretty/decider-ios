import Foundation
import UIKit

class MediaResources {

    static func mediaURL(forGameOption option:FightMove) -> URL {
        let bundle = Bundle.main
        guard
            let mediaURL = bundle.url(forResource: option.rawValue, withExtension: "mp4")
            else {
                fatalError("Unable to find option image")
        }
        return mediaURL
    }

    static func emoji(forFightMove fightMove:FightMove) -> String {
        switch fightMove {
        case .rock:
            return "👊"
        case .paper:
            return "🖐"
        case .scissor:
            return "✌"
        }
    }


    static func mediaURLForChallenge() -> URL {
        let bundle = Bundle.main
        guard
            let mediaURL = bundle.url(forResource: "challenge", withExtension: "mp4")
            else {
                fatalError("Unable to find option image")
        }
        return mediaURL
    }

    static func mediaURLForConclusion() -> URL {
        let bundle = Bundle.main
        guard
            let mediaURL = bundle.url(forResource: "conclusion", withExtension: "mp4")
            else {
                fatalError("Unable to find option image")
        }
        return mediaURL
    }
}
