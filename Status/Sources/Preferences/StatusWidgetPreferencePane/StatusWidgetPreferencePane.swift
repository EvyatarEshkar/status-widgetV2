//
//  StatusWidgetPreferencePane.swift
//  Status
//
//  Programmatic rewrite — drops XIB, adds GIF settings section.
//

import Cocoa
import PockKit
import UniformTypeIdentifiers

// Named differently from any XIB file to prevent nib auto-loading
class StatusV2PreferencePane: NSViewController, NSTextFieldDelegate, PKWidgetPreference {

    static var nibName: NSNib.Name = NSNib.Name("")

    // MARK: Status controls
    private weak var showLangCheck:       NSButton!
    private weak var showWifiCheck:       NSButton!
    private weak var showPowerCheck:      NSButton!
    private weak var showBatteryIconCheck: NSButton!
    private weak var showBatteryPctCheck: NSButton!
    private weak var showDateCheck:       NSButton!
    private weak var timeFormatField:     NSTextField!

    // MARK: GIF controls
    private weak var showGifCheck:            NSButton!
    private weak var gifContentStack:         NSView!
    private weak var gifSourceControl:        NSSegmentedControl!
    private weak var gifURLRow:               NSView!
    private weak var gifURLField:             NSTextField!
    private weak var gifFileRow:              NSView!
    private weak var gifFileField:            NSTextField!
    private weak var gifWidthSlider:          NSSlider!
    private weak var gifWidthLabel:           NSTextField!
    private weak var gifScalePopup:           NSPopUpButton!
    private weak var gifPreviewImageView:     NSImageView!
    private weak var gifPreviewWidthConstraint: NSLayoutConstraint!

    // MARK: - Init

    override init(nibName: NSNib.Name?, bundle: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func loadView() {
        self.view = buildUI()
    }

    func reset() {
        Preferences.reset()
        NotificationCenter.default.post(name: .shouldReloadStatusWidget, object: nil)
        self.view = buildUI()
    }

    // MARK: - Build UI

    private func buildUI() -> NSView {
        let root = NSStackView()
        root.orientation  = .vertical
        root.alignment    = .leading
        root.spacing      = 5
        root.edgeInsets   = NSEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        root.translatesAutoresizingMaskIntoConstraints = false
        root.widthAnchor.constraint(greaterThanOrEqualToConstant: 340).isActive = true

        // ── STATUS ITEMS ─────────────────────────────────────────────────────
        root.addArrangedSubview(sectionLabel("Status Items"))

        let langCk = makeCheckbox("Language / Input Source", tag: 0,
                                  on: Preferences[.shouldShowLangItem])
        showLangCheck = langCk
        root.addArrangedSubview(langCk)

        let wifiCk = makeCheckbox("WiFi Signal", tag: 1,
                                  on: Preferences[.shouldShowWifiItem])
        showWifiCheck = wifiCk
        root.addArrangedSubview(wifiCk)

        let powerCk = makeCheckbox("Battery", tag: 2,
                                   on: Preferences[.shouldShowPowerItem])
        showPowerCheck = powerCk
        root.addArrangedSubview(powerCk)

        // Battery sub-options (indented)
        let battSub = NSStackView()
        battSub.orientation = .vertical
        battSub.alignment   = .leading
        battSub.spacing     = 3
        battSub.edgeInsets.left = 18
        let iconCk = makeCheckbox("Show icon", tag: 21,
                                  on: Preferences[.shouldShowBatteryIcon])
        showBatteryIconCheck = iconCk
        let pctCk  = makeCheckbox("Show percentage", tag: 22,
                                  on: Preferences[.shouldShowBatteryPercentage])
        showBatteryPctCheck = pctCk
        battSub.addArrangedSubview(iconCk)
        battSub.addArrangedSubview(pctCk)
        root.addArrangedSubview(battSub)

        let dateCk = makeCheckbox("Date & Time", tag: 3,
                                  on: Preferences[.shouldShowDateItem])
        showDateCheck = dateCk
        root.addArrangedSubview(dateCk)

        // Time format
        let tf = NSTextField()
        tf.stringValue       = Preferences[.timeFormatTextField]
        tf.placeholderString = "EE dd MMM HH:mm"
        tf.delegate          = self
        timeFormatField = tf

        let helpBtn = NSButton(title: "", target: self, action: #selector(openTimeFormatHelp))
        helpBtn.bezelStyle = .helpButton

        let tfInner = NSStackView(views: [tf, helpBtn])
        tfInner.spacing = 6
        let tfRow = makeRow("Format:", tfInner)
        tfRow.edgeInsets.left = 18
        root.addArrangedSubview(tfRow)

        // ── SEPARATOR ────────────────────────────────────────────────────────
        root.addArrangedSubview(makeSeparator())

        // ── GIF ──────────────────────────────────────────────────────────────
        root.addArrangedSubview(sectionLabel("GIF"))

        let shouldShowGif: Bool = Preferences[.shouldShowGif]
        let gifToggle = NSButton(checkboxWithTitle: "Show GIF on right edge",
                                 target: self, action: #selector(gifToggleChanged))
        gifToggle.state = shouldShowGif ? .on : .off
        showGifCheck = gifToggle
        root.addArrangedSubview(gifToggle)

        // GIF content stack — shown only when toggle is on
        let gifStack = NSStackView()
        gifStack.orientation  = .vertical
        gifStack.alignment    = .leading
        gifStack.spacing      = 5
        gifStack.edgeInsets.left = 8
        gifStack.isHidden     = !shouldShowGif
        gifContentStack = gifStack

        // Source selector: File | URL
        let sourceCtrl = NSSegmentedControl(
            labels: ["File", "URL"],
            trackingMode: .selectOne,
            target: self,
            action: #selector(gifSourceChanged)
        )
        let savedSource: Int = Preferences[.gifSourceType]
        sourceCtrl.selectedSegment = savedSource
        gifSourceControl = sourceCtrl
        gifStack.addArrangedSubview(makeRow("Source:", sourceCtrl))

        // URL row
        let urlF = NSTextField()
        let savedURLStr: String = Preferences[.gifURLString]
        urlF.stringValue       = savedURLStr
        urlF.placeholderString = "https://example.com/animation.gif"
        urlF.target = self
        urlF.action = #selector(gifURLChanged)
        gifURLField = urlF
        let urlRow = makeRow("URL:", urlF)
        gifURLRow = urlRow
        gifStack.addArrangedSubview(urlRow)

        // File row
        let fileF = NSTextField()
        let savedPath: String = Preferences[.gifFilePath]
        fileF.stringValue       = savedPath
        fileF.placeholderString = "No file selected"
        fileF.isEditable        = false
        fileF.isSelectable      = false
        gifFileField = fileF

        let chooseBtn = NSButton(title: "Choose…", target: self, action: #selector(gifChooseFile))
        let fileInner = NSStackView(views: [fileF, chooseBtn])
        fileInner.spacing = 6
        let fileRow = makeRow("File:", fileInner)
        gifFileRow = fileRow
        gifStack.addArrangedSubview(fileRow)

        // Width slider
        let savedW: Double = Preferences[.gifWidth]
        let wSlider = NSSlider(value: savedW, minValue: 30, maxValue: 300,
                               target: self, action: #selector(gifWidthChanged))
        wSlider.controlSize = .small
        gifWidthSlider = wSlider
        let wLabel = NSTextField(labelWithString: "\(Int(savedW)) pt")
        wLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        gifWidthLabel = wLabel
        let wInner = NSStackView(views: [wSlider, wLabel])
        wInner.spacing = 6
        gifStack.addArrangedSubview(makeRow("Width:", wInner))

        // Scaling popup
        let scaleP = NSPopUpButton()
        scaleP.addItems(withTitles: ["Fit", "Fill (crop)", "Stretch"])
        let savedScale: Int = Preferences[.gifScalingMode]
        scaleP.selectItem(at: savedScale)
        scaleP.target = self
        scaleP.action = #selector(gifScalingChanged)
        gifScalePopup = scaleP
        gifStack.addArrangedSubview(makeRow("Scaling:", scaleP))

        // Preview (Touch Bar height)
        let piv = NSImageView()
        piv.wantsLayer = true
        piv.layer?.cornerRadius   = 4
        piv.layer?.masksToBounds  = true
        piv.imageScaling          = .scaleProportionallyUpOrDown
        piv.animates              = true
        piv.translatesAutoresizingMaskIntoConstraints = false
        gifPreviewImageView = piv

        let previewBox = NSView()
        previewBox.translatesAutoresizingMaskIntoConstraints = false
        previewBox.wantsLayer = true
        previewBox.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        previewBox.layer?.cornerRadius    = 4
        previewBox.addSubview(piv)

        let pwc = previewBox.widthAnchor.constraint(equalToConstant: CGFloat(savedW))
        gifPreviewWidthConstraint = pwc
        NSLayoutConstraint.activate([
            piv.leadingAnchor.constraint(equalTo: previewBox.leadingAnchor),
            piv.trailingAnchor.constraint(equalTo: previewBox.trailingAnchor),
            piv.topAnchor.constraint(equalTo: previewBox.topAnchor),
            piv.bottomAnchor.constraint(equalTo: previewBox.bottomAnchor),
            previewBox.heightAnchor.constraint(equalToConstant: 30),
            pwc
        ])
        gifStack.addArrangedSubview(makeRow("Preview:", previewBox))

        root.addArrangedSubview(gifStack)

        // Apply initial source row visibility and preview
        refreshGIFSourceRows()
        refreshGIFPreview()

        return root
    }

    // MARK: - Status Actions

    @objc private func checkboxChanged(_ sender: NSButton) {
        let key: Preferences.Keys
        switch sender.tag {
        case 0:  key = .shouldShowLangItem
        case 1:  key = .shouldShowWifiItem
        case 2:  key = .shouldShowPowerItem
        case 21: key = .shouldShowBatteryIcon
        case 22: key = .shouldShowBatteryPercentage
        case 3:  key = .shouldShowDateItem
        default: return
        }
        Preferences[key] = sender.state == .on
        NotificationCenter.default.post(name: .shouldReloadStatusWidget, object: nil)
    }

    @objc private func openTimeFormatHelp() {
        guard let url = URL(string: "https://www.mowglii.com/itsycal/datetime.html") else { return }
        NSWorkspace.shared.open(url)
    }

    // Fires on every keystroke — SClockItem's 1-second timer picks it up automatically
    func controlTextDidChange(_ obj: Notification) {
        guard let field = obj.object as? NSTextField, field === timeFormatField else { return }
        Preferences[.timeFormatTextField] = field.stringValue
    }

    // MARK: - GIF Actions

    @objc private func gifToggleChanged() {
        let on = showGifCheck.state == .on
        Preferences[.shouldShowGif] = on
        gifContentStack.isHidden = !on
        NotificationCenter.default.post(name: .shouldReloadStatusWidget, object: nil)
    }

    @objc private func gifSourceChanged() {
        Preferences[.gifSourceType] = gifSourceControl.selectedSegment
        refreshGIFSourceRows()
        refreshGIFPreview()
        NotificationCenter.default.post(name: .shouldReloadStatusWidget, object: nil)
    }

    @objc private func gifURLChanged() {
        let text = gifURLField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        Preferences[.gifURLString] = text
        refreshGIFPreview()
        NotificationCenter.default.post(name: .shouldReloadStatusWidget, object: nil)
    }

    @objc private func gifChooseFile() {
        let panel = NSOpenPanel()
        if #available(macOS 12.0, *) {
            panel.allowedContentTypes = [UTType.gif]
        } else {
            panel.allowedFileTypes = ["gif"]
        }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories    = false
        panel.begin { [weak self] result in
            guard let self, result == .OK, let url = panel.url else { return }
            Preferences[.gifFilePath] = url.path
            self.gifFileField.stringValue = url.path
            self.refreshGIFPreview()
            NotificationCenter.default.post(name: .shouldReloadStatusWidget, object: nil)
        }
    }

    @objc private func gifWidthChanged() {
        let w = gifWidthSlider.doubleValue
        Preferences[.gifWidth] = w
        gifWidthLabel.stringValue = "\(Int(w)) pt"
        gifPreviewWidthConstraint.constant = CGFloat(w)
        NotificationCenter.default.post(name: .shouldReloadStatusWidget, object: nil)
    }

    @objc private func gifScalingChanged() {
        let mode = gifScalePopup.indexOfSelectedItem
        Preferences[.gifScalingMode] = mode
        if let piv = gifPreviewImageView { applyScaling(mode, to: piv) }
        NotificationCenter.default.post(name: .shouldReloadStatusWidget, object: nil)
    }

    // MARK: - GIF Helpers

    private func refreshGIFSourceRows() {
        let isURL = gifSourceControl.selectedSegment == 1
        gifURLRow.isHidden  = !isURL
        gifFileRow.isHidden =  isURL
    }

    private func refreshGIFPreview() {
        guard let piv = gifPreviewImageView else { return }
        let isURL  = gifSourceControl.selectedSegment == 1
        let mode   = gifScalePopup.indexOfSelectedItem

        if isURL {
            let str: String = Preferences[.gifURLString]
            guard let url = URL(string: str) else { return }
            URLSession.shared.dataTask(with: url) { [weak self, weak piv] data, _, _ in
                guard let self, let piv, let data, let img = NSImage(data: data) else { return }
                DispatchQueue.main.async {
                    piv.image    = img
                    piv.animates = true
                    self.applyScaling(mode, to: piv)
                }
            }.resume()
        } else {
            let path: String = Preferences[.gifFilePath]
            guard !path.isEmpty,
                  let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let img  = NSImage(data: data) else { return }
            piv.image    = img
            piv.animates = true
            applyScaling(mode, to: piv)
        }
    }

    private func applyScaling(_ mode: Int, to iv: NSImageView) {
        switch mode {
        case 1:
            iv.imageScaling         = .scaleAxesIndependently
            iv.layer?.contentsGravity = .resizeAspectFill
        case 2:
            iv.imageScaling         = .scaleAxesIndependently
            iv.layer?.contentsGravity = .resize
        default:
            iv.imageScaling         = .scaleProportionallyUpOrDown
            iv.layer?.contentsGravity = .resizeAspect
        }
    }

    // MARK: - UI Factory

    private func makeCheckbox(_ title: String, tag: Int, on: Bool) -> NSButton {
        let btn = NSButton(checkboxWithTitle: title, target: self, action: #selector(checkboxChanged(_:)))
        btn.tag   = tag
        btn.state = on ? .on : .off
        return btn
    }

    private func sectionLabel(_ text: String) -> NSTextField {
        let lbl = NSTextField(labelWithString: text.uppercased())
        lbl.font      = NSFont.systemFont(ofSize: 10, weight: .semibold)
        lbl.textColor = NSColor.secondaryLabelColor
        return lbl
    }

    private func makeRow(_ label: String, _ control: NSView) -> NSStackView {
        let lbl = NSTextField(labelWithString: label)
        lbl.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        lbl.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        let row = NSStackView(views: [lbl, control])
        row.orientation = .horizontal
        row.alignment   = .firstBaseline
        row.spacing     = 6
        return row
    }

    private func makeSeparator() -> NSBox {
        let sep = NSBox()
        sep.boxType = .separator
        return sep
    }
}
