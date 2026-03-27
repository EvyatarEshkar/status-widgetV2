//
//  StatusWidget.swift
//  Status
//
//  Created by Pierluigi Galdi on 18/01/2020.
//  Copyright © 2020 Pierluigi Galdi. All rights reserved.
//

import Foundation
import AppKit
import PockKit
import TinyConstraints

extension NSImage {
    /// Returns an NSImage snapshot of the passed view.
    convenience init?(frame: NSRect, view: NSView) {
        guard let bitmapRep = view.bitmapImageRepForCachingDisplay(in: frame) else { return nil }
        self.init()
        view.cacheDisplay(in: frame, to: bitmapRep)
        addRepresentation(bitmapRep)
        bitmapRep.size = frame.size
    }
}

class StatusV2Widget: PKWidget {

    static var identifier: String = "EvyatarEshkar.StatusV2Widget"
    var customizationLabel: String = "Status V2"
    var view: NSView!

    private var stackView: NSStackView { return view as! NSStackView }
    private var loadedItems: [StatusItem] = []

    // MARK: - PKWidget

    var imageForCustomization: NSImage {
        let sv = NSStackView(frame: .zero)
        sv.orientation = .horizontal
        sv.alignment = .centerY
        sv.distribution = .fill
        sv.spacing = 8
        if Preferences[.shouldShowLangItem]  { sv.addArrangedSubview(SLangItem().view)  }
        if Preferences[.shouldShowWifiItem]  { sv.addArrangedSubview(SWifiItem().view)  }
        if Preferences[.shouldShowPowerItem] { sv.addArrangedSubview(SPowerItem().view) }
        if Preferences[.shouldShowDateItem]  { sv.addArrangedSubview(SClockItem().view) }
        return NSImage(frame: NSRect(origin: .zero, size: sv.fittingSize), view: sv) ?? NSImage()
    }

    func prepareForCustomization() {
        clearItems()
    }

    required init() {
        view = NSStackView(frame: .zero)
        stackView.orientation  = .horizontal
        stackView.alignment    = .centerY
        stackView.distribution = .fill
        stackView.spacing      = 8
    }

    deinit {
        clearItems()
    }

    func viewDidAppear() {
        loadStatusElements()
        NotificationCenter.default.addObserver(
            self, selector: #selector(loadStatusElements),
            name: .shouldReloadStatusWidget, object: nil
        )
    }

    func viewWillDisappear() {
        clearItems()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Loading

    private func clearItems() {
        for v in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        loadedItems.forEach { $0.didUnload() }
        loadedItems.removeAll()
    }

    @objc private func loadStatusElements() {
        clearItems()

        if Preferences[.shouldShowLangItem] {
            let item = SLangItem(); loadedItems.append(item)
            stackView.addArrangedSubview(item.view)
        }
        if Preferences[.shouldShowWifiItem] {
            let item = SWifiItem(); loadedItems.append(item)
            stackView.addArrangedSubview(item.view)
        }
        if Preferences[.shouldShowPowerItem] {
            let item = SPowerItem(); loadedItems.append(item)
            stackView.addArrangedSubview(item.view)
        }
        if Preferences[.shouldShowDateItem] {
            let item = SClockItem(); loadedItems.append(item)
            stackView.addArrangedSubview(item.view)
        }

        // GIF — rightmost item
        if Preferences[.shouldShowGif] {
            let item = SGifItem(); loadedItems.append(item)
            stackView.addArrangedSubview(item.view)
        }

        stackView.height(30)
    }
}
