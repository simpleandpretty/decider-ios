import UIKit
import Messages


protocol PlayFightViewControllerDelegate: class {
    func playFightViewControllerDidSelectMakeOfficial(_ controller: PlayFightViewController)
}

class PlayFightViewController: UIViewController {

    enum PlayState {
        case playStart
        case playAttack
        case playDefense
        case playEnd
    }

    static let storyboardIdentifier = "PlayFightViewController"

    @IBOutlet var captionLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var emojiLabel: UILabel!
    @IBOutlet var makeOfficialButton: UIButton!
    @IBOutlet var fightVideoView: VideoPlayerView!


    weak var delegate: PlayFightViewControllerDelegate?

    var fight: Fight!
    var message: MSMessage!
    var conversation: MSConversation!

    var state: PlayState = .playStart

    func setup(conversation: MSConversation) {
        self.conversation = conversation
        guard
            let message = conversation.selectedMessage,
            let fightURL = message.url
            else {
                return;
        }
        fight = Fight.decode(fromURL: fightURL)
        self.message = message
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        fightVideoView.delegate = self

        makeOfficialButton.contentEdgeInsets = UIEdgeInsets(top:12, left:12, bottom:12, right:12)
        makeOfficialButton.layer.cornerRadius = 5

        advanceState()
    }

    @IBAction func makeItOfficialAction(_ sender:UIButton) {
        sendMessage()
    }

    func sendMessage() {
        guard
            let session = message.session,
            let conversation = self.conversation,
            let remoteIdentifier = conversation.remoteParticipantIdentifiers.first,
            fight.state == .finished
            else {
                return
        }

        let newMessage = MSMessage(session: session)
        let template = MSMessageTemplateLayout()
        var winnerId = message.senderParticipantIdentifier
        var looserId = conversation.localParticipantIdentifier        
        switch fight.result {
        case .attackerWon:
            if message.senderParticipantIdentifier == conversation.localParticipantIdentifier {
                winnerId = remoteIdentifier
                looserId = conversation.localParticipantIdentifier
            } else {
                looserId = remoteIdentifier
                winnerId = conversation.localParticipantIdentifier
            }
        case .defenderWon:
            if message.senderParticipantIdentifier == conversation.localParticipantIdentifier {
                looserId = remoteIdentifier
                winnerId = conversation.localParticipantIdentifier
            } else {
                winnerId = remoteIdentifier
                looserId = conversation.localParticipantIdentifier
            }
        case .draw:
            captionLabel.text = NSLocalizedString("It was a draw...", comment: "")
        default:
            captionLabel.text = NSLocalizedString("Still fighting it out!", comment: "")
        }

        template.imageTitle = NSLocalizedString("Tap to watch replay", comment: "Prompt to start fight.").uppercased()
        var caption = "🏆 $\(winnerId) is the Decider! 💩 $\(looserId) is the looser!"
        if fight.result == .draw {
            caption = NSLocalizedString("It was a draw...", comment: "")
        }
        template.caption = caption
        template.mediaFileURL = MediaResources.mediaURLForConclusion()
        newMessage.layout = template
        var endFight = fight!
        endFight.ended = true
        newMessage.url = endFight.encode()
        newMessage.summaryText = template.caption
        conversation.insert(newMessage)

        delegate?.playFightViewControllerDidSelectMakeOfficial(self)
    }

    fileprivate func advanceState() {
        if fight.state == .defending {
            titleLabel.text = NSLocalizedString("Waiting for retaliation", comment: "Title for fight replay when waiting for answer.").uppercased()
        } else {
            titleLabel.text = NSLocalizedString("Fight replay", comment: "Title for fight replay fight is done.").uppercased()
        }

        switch state {
        case .playStart:
            if let attackOption = fight?.attackerOption {
                fightVideoView.videoURL = MediaResources.mediaURL(forGameOption: attackOption)
                if fight.state == .defending {
                    if message.senderParticipantIdentifier == conversation.localParticipantIdentifier {
                        captionLabel.text = "You attacked with \(attackOption.localizedText())!"
                    } else {
                        captionLabel.text = "They attacked you with a \(attackOption.localizedText())!"
                    }
                } else if fight.state == .finished {
                    if message.senderParticipantIdentifier == conversation.localParticipantIdentifier {
                        captionLabel.text = "\(attackOption.localizedText()) attack!"
                    } else {
                        captionLabel.text = "\(attackOption.localizedText()) attack!"
                    }
                }
                emojiLabel.text = MediaResources.emoji(forFightMove: attackOption)
                state = .playAttack
            } else {
                state = .playEnd
            }

        case .playAttack:
            if let defendOption = fight.defenderOption {
                fightVideoView.videoURL = MediaResources.mediaURL(forGameOption: defendOption)
                if message.senderParticipantIdentifier == conversation.localParticipantIdentifier {
                    captionLabel.text = "\(defendOption.localizedText()) Retaliation!"
                } else {
                    captionLabel.text = "\(defendOption.localizedText()) Retaliation!"
                }
                emojiLabel.text = MediaResources.emoji(forFightMove: defendOption)
                state = .playDefense
            } else {
                state = .playEnd
            }
        case .playDefense:
            state = .playEnd            
            var emoji = ""
            switch fight.result {
            case .attackerWon:
                if message.senderParticipantIdentifier == conversation.localParticipantIdentifier {
                    captionLabel.text = NSLocalizedString("You lost! :(", comment: "")
                    emoji = "💩"
                } else {
                    captionLabel.text = NSLocalizedString("You won! :)", comment: "")
                    emoji = "🏆"
                }
            case .defenderWon:
                if message.senderParticipantIdentifier == conversation.localParticipantIdentifier {
                    captionLabel.text = NSLocalizedString("You won! :)", comment: "")
                    emoji = "🏆"
                } else {
                    captionLabel.text = NSLocalizedString("You lost! :(", comment: "")
                    emoji = "💩"
                }
            case .draw:
                captionLabel.text = NSLocalizedString("It was a draw...", comment: "")
                emoji = "💪"
            default:
                captionLabel.text = NSLocalizedString("Still fighting it out!", comment: "")
            }
            fightVideoView.videoURL = MediaResources.mediaURLForConclusion()
            emojiLabel.text = emoji
        case .playEnd:
            if fight.state == .finished && !fight.ended {
                makeOfficialButton.isHidden = false
                captionLabel.isHidden = true
            }
        }
    }
}

extension PlayFightViewController: VideoPlayerViewDelegate {

    func videoPlayerViewStarted(_ playerView: VideoPlayerView) {

    }

    func videoPlayerViewFinish(_ playerView: VideoPlayerView) {
        DispatchQueue.main.async {
            self.advanceState()
        }
    }

    func videoPlayerView(_ playerView: VideoPlayerView, didFailedWithError error: NSError) {

    }
}
