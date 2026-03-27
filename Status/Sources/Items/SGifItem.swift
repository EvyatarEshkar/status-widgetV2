//
//  SGifItem.swift
//  Status
//

import Foundation
import AppKit

internal class SGifItem: StatusItem {

    // MARK: - StatusItem

    var enabled: Bool { return Preferences[.shouldShowGif] }
    var title: String { return "gif" }
    var view: NSView  { return imageView }

    func action() { }

    func didLoad() {
        applyDimensions()
        applyScaling()
        reload()
    }

    func didUnload() {
        imageView.image = nil
    }

    // MARK: - UI

    private let imageView: NSImageView = {
        let iv = NSImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.animates     = true
        iv.wantsLayer   = true
        iv.layer?.cornerRadius  = 4
        iv.layer?.masksToBounds = true
        return iv
    }()

    private var widthConstraint:  NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

    init() {
        widthConstraint  = imageView.widthAnchor.constraint(equalToConstant: 60)
        heightConstraint = imageView.heightAnchor.constraint(equalToConstant: 30)
        widthConstraint?.isActive  = true
        heightConstraint?.isActive = true
        didLoad()
    }

    deinit { didUnload() }

    // MARK: - Reload

    func reload() {
        applyDimensions()
        applyScaling()

        let sourceType: Int = Preferences[.gifSourceType]
        if sourceType == 0 {
            let path: String = Preferences[.gifFilePath]
            guard !path.isEmpty else { return }
            loadFromFile(path)
        } else {
            let urlStr: String = Preferences[.gifURLString]
            guard !urlStr.isEmpty, let url = URL(string: urlStr) else { return }
            loadFromURL(url)
        }
    }

    // MARK: - Helpers

    private func applyDimensions() {
        let w: Double = Preferences[.gifWidth]
        widthConstraint?.constant = CGFloat(w)
    }

    private func applyScaling() {
        let mode: Int = Preferences[.gifScalingMode]
        switch mode {
        case 1:
            imageView.imageScaling          = .scaleAxesIndependently
            imageView.layer?.contentsGravity = .resizeAspectFill
        case 2:
            imageView.imageScaling          = .scaleAxesIndependently
            imageView.layer?.contentsGravity = .resize
        default:
            imageView.imageScaling          = .scaleProportionallyUpOrDown
            imageView.layer?.contentsGravity = .resizeAspect
        }
    }

    private func loadFromFile(_ path: String) {
        guard let data  = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let image = NSImage(data: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.imageView.image   = image
            self?.imageView.animates = true
        }
    }

    private func loadFromURL(_ url: URL) {
        let req = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let data, let image = NSImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.imageView.image    = image
                self?.imageView.animates = true
            }
        }.resume()
    }
}
