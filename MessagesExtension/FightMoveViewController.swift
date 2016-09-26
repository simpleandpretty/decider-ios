import UIKit
import Messages

protocol FightMoveControllerDelegate: class {
    func fightMoveControllerDidSelectMove(_ controller: FightMoveViewController)
}

class FightMoveViewController: UIViewController {

    static let storyboardIdentifier = "FightMoveViewController"

    @IBOutlet var rockButton: UIButton!
    @IBOutlet var scissorButton: UIButton!
    @IBOutlet var paperButton: UIButton!
    @IBOutlet var videoView: VideoPlayerView!
    @IBOutlet var messsageLabel: UILabel!
    
    var session: MSSession?
    var conversation: MSConversation?
    var originalMessage: MSMessage?
    var fight: Fight?

    weak var delegate: FightMoveControllerDelegate?
    var presentationStyle: MSMessagesAppPresentationStyle = .compact

    func setup(conversation: MSConversation) {
        if  let message = conversation.selectedMessage,
            let existingSession = message.session,
            let fightURL = message.url
        {
            session = existingSession
            fight = Fight.decode(fromURL: fightURL)
            originalMessage = message
        } else {
            session = MSSession()
            fight = Fight(attackerOption: nil, defenderOption: nil, ended: false)
        }
        self.conversation = conversation
    }

    override func viewDidLoad() {
        rockButton.backgroundColor = UIColor.deciderBlueBackground
        scissorButton.backgroundColor = UIColor.deciderBlueBackground
        paperButton.backgroundColor = UIColor.deciderBlueBackground
        propagate(presentationStyle: self.presentationStyle)
        videoView.loop = true
        guard
            let fight = self.fight
            else {
                return
        }
        switch fight.state {
        case .attacking:
            videoView.videoURL = MediaResources.mediaURLForChallenge()
        case .defending:
            videoView.videoURL = MediaResources.mediaURLForConclusion()
        case .finished:
            print("Fight is finished")
        }

    }

    @IBAction func sendAction(_ sender:UIButton) {
        var option: FightMove?
        switch sender {
        case rockButton:
            option = .rock
        case scissorButton:
            option = .scissor
        case paperButton:
            option = .paper
        default:
            option = nil
        }

        guard let safeOption = option else {
            return
        }

        sendMessage(withOption: safeOption)
    }

    func sendMessage(withOption option:FightMove) {
        guard
            let session = self.session,
            let conversation = self.conversation,
            var fight = self.fight,
            let remoteIdentifier = conversation.remoteParticipantIdentifiers.first
            else {
                return
        }
        switch fight.state {
        case .attacking:
            fight.attackerOption = option

            let message = MSMessage(session: session)
            let template = MSMessageTemplateLayout()
            template.imageTitle = NSLocalizedString("TAP TO FIGHT", comment: "Prompt to start fight.")
            template.caption = "$\(conversation.localParticipantIdentifier) has challenged $\(remoteIdentifier) to be the Decider!"
            template.mediaFileURL = MediaResources.mediaURLForChallenge()
            message.layout = template
            message.url = fight.encode()
            message.summaryText = template.caption
            conversation.insert(message)

        case .defending:
            fight.defenderOption = option
            let message = MSMessage(session: session)
            let template = MSMessageTemplateLayout()
            var senderName = ""
            if let senderUUID = originalMessage?.senderParticipantIdentifier.uuidString {
                senderName = "$"+senderUUID
            }
            template.imageTitle = NSLocalizedString("TAP TO SEE WHO WON!", comment: "")
            let caption = "$\(conversation.localParticipantIdentifier) retaliated to \(senderName) Decider!"
            template.mediaFileURL = MediaResources.mediaURLForConclusion()
            template.caption = caption
            message.layout = template
            message.summaryText = "\(senderName) has challenged $\(conversation.localParticipantIdentifier) to be the Decider!\n"
                + caption
            message.url = fight.encode()

            // Now we've constructed the message, insert it into the conversation
            conversation.insert(message)
        case .finished:
            print("Fight is finished")
        }

        delegate?.fightMoveControllerDidSelectMove(self)
    }
    
}

extension FightMoveViewController: PropagatePresentationStyle {
    public func propagate(presentationStyle: MSMessagesAppPresentationStyle) {
        self.presentationStyle = presentationStyle
        if self.isViewLoaded {
            self.videoView.isHidden = presentationStyle == .compact            
        }
    }


}
