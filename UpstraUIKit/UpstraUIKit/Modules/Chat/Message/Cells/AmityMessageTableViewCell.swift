//
//  AmityMessageTableViewCell.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 7/8/2563 BE.
//  Copyright © 2563 Amity Communication. All rights reserved.
//

import UIKit
import AmitySDK

class AmityMessageTableViewCell: UITableViewCell, AmityMessageCellProtocol {
    
    // MARK: - Delegate
    weak var delegate: AmityMessageCellDelegate?
    
    // MARK: - IBOutlet Properties
    @IBOutlet var avatarView: AmityAvatarView!
    @IBOutlet var containerView: AmityResponsiveView!
    @IBOutlet var displayNameLabel: UILabel!
    @IBOutlet var metadataLabel: UILabel!
    @IBOutlet var messageImageView: UIImageView!
    @IBOutlet var statusMetadataImageView: UIImageView!
    @IBOutlet var errorButton: UIButton!
    
    // MARK: Container
    @IBOutlet var containerMessageView: UIView!
    @IBOutlet var containerMetadataView: UIView!
    
    // MARK: - Properties
    var screenViewModel: AmityMessageListScreenViewModelType!
    var message: AmityMessageModel!
    
    var indexPath: IndexPath!
    let editMenuItem = UIMenuItem(title: AmityLocalizedStringSet.edit.localizedString, action: #selector(editTap))
    let deleteMenuItem = UIMenuItem(title: AmityLocalizedStringSet.delete.localizedString, action: #selector(deleteTap))
    let reportMenuItem = UIMenuItem(title: AmityLocalizedStringSet.report.localizedString, action: #selector(reportTap))
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if message.isOwner {
            switch message.messageType {
            case .text:
                return action == #selector(editTap) || action == #selector(deleteTap)
            default:
                return action == #selector(deleteTap)
            }
        } else {
            return action == #selector(reportTap)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        statusMetadataImageView.isHidden = true
        containerMessageView.isHidden = false
        metadataLabel.isHidden = false
    }
    
    func setViewModel(with viewModel: AmityMessageListScreenViewModelType) {
        screenViewModel = viewModel
    }
    
    func setIndexPath(with _indexPath: IndexPath) {
        indexPath = _indexPath
    }
    
    func setRoundCorner(isOwner: Bool) -> CACornerMask {
        if isOwner {
            return [.layerMinXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        } else {
            return [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        }
    }
    
    func display(message: AmityMessageModel) {
        self.message = message
        if message.isOwner {
            
            containerView.layer.maskedCorners = setRoundCorner(isOwner: message.isOwner)
            
            switch message.messageType {
            case .text, .audio:
                containerView.backgroundColor = AmityColorSet.messageBubble
            case .image:
                containerView.backgroundColor = AmityColorSet.messageBubbleInverse
            default:
                containerView.backgroundColor = AmityColorSet.backgroundColor
            }
        } else {
            avatarView.placeholder = AmityIconSet.defaultAvatar
            containerView.layer.maskedCorners = setRoundCorner(isOwner: message.isOwner)
            
            switch message.messageType {
            case .text, .audio:
                containerView.backgroundColor = AmityColorSet.messageBubbleInverse
            default:
                containerView.backgroundColor = AmityColorSet.backgroundColor
            }
            
            displayNameLabel.font = AmityFontSet.body
            displayNameLabel.textColor = AmityColorSet.base.blend(.shade1)
            
            setDisplayName(for: message)
        }
        setMetadata(message: message)
    }
    
    func setMetadata(message: AmityMessageModel) {
        let fullString = NSMutableAttributedString()
        let style: [NSAttributedString.Key : Any]? = [.foregroundColor: AmityColorSet.base.blend(.shade2),
                                                      .font: AmityFontSet.caption]
        if message.isDeleted {
            containerMessageView.isHidden = true
            statusMetadataImageView.isHidden = false
            let deleteMessage =  String.localizedStringWithFormat(AmityLocalizedStringSet.MessageList.deleteMessage.localizedString, message.time)
            fullString.append(NSAttributedString(string: deleteMessage, attributes: style))
            statusMetadataImageView.image = AmityIconSet.iconDeleteMessage
        } else if message.isEdited {
            let editMessage = String.localizedStringWithFormat(AmityLocalizedStringSet.MessageList.editMessage.localizedString, message.time)
            fullString.append(NSAttributedString(string: editMessage, attributes: style))
        } else {
            if message.isOwner {
                errorButton.isHidden = true
                switch message.syncState {
                case .error:
                    errorButton.isHidden = false
                    fullString.append(NSAttributedString(string: message.time, attributes: style))
                case .syncing:
                    fullString.append(NSAttributedString(string: AmityLocalizedStringSet.MessageList.sending.localizedString, attributes: style))
                case .synced:
                    fullString.append(NSAttributedString(string: message.time, attributes: style))
                default:
                    break
                }
            } else {
                fullString.append(NSAttributedString(string: message.time, attributes: style))
            }
        }
        metadataLabel.attributedText = fullString
    }
    
    private func setDisplayName(for message: AmityMessageModel) {
        setDisplayName(message.displayName)
    }
    
    private func setDisplayName(_ name: String?) {
        displayNameLabel.text = name
    }
}

// MARK: - Action
private extension AmityMessageTableViewCell {
    @objc
    func editTap() {
        screenViewModel.action.performCellEvent(for: .edit(indexPath: indexPath))
    }
    
    @objc
    func deleteTap() {
        switch message.syncState {
        case .error:
            screenViewModel.action.performCellEvent(for: .deleteErrorMessage(indexPath: indexPath))
        default:
            screenViewModel.action.performCellEvent(for: .delete(indexPath: indexPath))
        }
        
    }
    
    @objc
    func reportTap() {
        screenViewModel.action.performCellEvent(for: .report(indexPath: indexPath))
    }
    
    @IBAction func errorTap() {
        screenViewModel.action.performCellEvent(for: .deleteErrorMessage(indexPath: indexPath))
    }
}

// MARK: - Setup View
private extension AmityMessageTableViewCell {
    private func setupView() {
        selectionStyle = .none
        
        statusMetadataImageView.isHidden = true
        containerView.backgroundColor = UIColor.gray.withAlphaComponent(0.25)
        containerView.layer.cornerRadius = 4
        containerView.menuItems = [editMenuItem, deleteMenuItem, reportMenuItem]
        
        contentView.backgroundColor = AmityColorSet.backgroundColor
    }
}