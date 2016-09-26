import Foundation
import UIKit
import AVFoundation
import MediaPlayer

protocol VideoPlayerViewDelegate: class {
    func videoPlayerView(_ playerView: VideoPlayerView, didFailedWithError error:NSError)
    func videoPlayerViewStarted(_ playerView: VideoPlayerView)
    func videoPlayerViewFinish(_ playerView: VideoPlayerView)
}

class VideoPlayerView: UIView {

    private var player: AVPlayer
    private var playerLayer: AVPlayerLayer
    private var playerItem: AVPlayerItem?

    public var loop: Bool = false

    private static let tracksKey = "tracks"

    weak var delegate: VideoPlayerViewDelegate?

    override init(frame: CGRect) {
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player:player)
        super.init(frame: frame)
        layer.addSublayer(playerLayer)
    }

    required init?(coder aDecoder: NSCoder) {
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player:player)
        super.init(coder: aDecoder)
        layer.addSublayer(playerLayer)
    }

    func commonInit() {
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player:player)
        layer.addSublayer(playerLayer)
    }

    deinit {
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        NotificationCenter.default.removeObserver(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    var videoURL: URL? {
        didSet {
            if let newVideoURL = videoURL {
                loadAsset(fromFileURL: newVideoURL)
            }
        }
    }

    private func loadAsset(fromFileURL fileURL:URL) {
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        NotificationCenter.default.removeObserver(self)

        let asset = AVURLAsset(url:fileURL)
        playerItem = AVPlayerItem(asset: asset)
        
        playerItem?.addObserver(self,
                                forKeyPath: #keyPath(AVPlayerItem.status),
                                options:[.old, .new],
                                context:&playerItemContext)
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(VideoPlayerView.playerItemDidReachEnd(playerItem:)),
                                               name:.AVPlayerItemDidPlayToEndTime,
                                               object:self.playerItem)
        player.replaceCurrentItem(with: playerItem)
        player.play()
    }

    // Define this constant for the key-value observation context.
    private var playerItemContext: String = "ItemStatusContext"

    func playerItemDidReachEnd(playerItem: AVPlayerItem) {
        if loop {
            player.seek(to:kCMTimeZero)
            player.play()
        }
        delegate?.videoPlayerViewFinish(self)
    }

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        // Only handle observations for the playerItemContext
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
        }

        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus

            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }

            // Switch over the status
            switch status {
            case .readyToPlay:
            // Player item is ready to play.
                delegate?.videoPlayerViewStarted(self)
            case .failed:
            // Player item failed. See error.
                if let error = self.playerItem?.error as? NSError {
                    self.delegate?.videoPlayerView(self, didFailedWithError: error)
                }
            case .unknown:
                // Player item is not yet ready.
                return
            }
        }
    }

}

