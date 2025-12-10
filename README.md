# Budget Snap 📸💰

**Privacy-First Budget Tracking via Screenshots**

A secure iOS app that extracts banking transactions from screenshots using Apple's Vision framework—all processing happens on-device with zero cloud sync or tracking.

![iOS 17.0+](https://img.shields.io/badge/iOS-17.0%2B-blue)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-green)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## Features

### 🎯 Smart Screenshot Processing
- **Batch Import**: Select multiple banking app screenshots at once
- **On-Device OCR**: Extract transaction details (date, amount, merchant, description) using Apple Vision
- **Duplicate Detection**: Automatically prevents reprocessing the same transactions
- **Manual Correction**: Easy-to-use UI for fixing OCR errors or unclear captures
- **Confidence Scoring**: Transactions are flagged for review based on extraction quality

### 💰 Intuitive Budget Management
- **Category-Based Budgets**: Set monthly spending limits for each category
- **Visual Progress**: Real-time progress bars and spending indicators
- **Smart Alerts**: Get notified when approaching or exceeding budget limits
- **Auto-Copy**: Duplicate last month's budgets with one tap
- **Month Navigation**: Easily switch between months to view historical budgets

### 🎨 Transaction Organization
- **Custom Categories**: Create personalized categories with icons and colors
- **Quick Categorization**: Tap or swipe to assign transactions to categories
- **Smart Filtering**: View all, uncategorized, or needs-review transactions
- **Search**: Find transactions by merchant or description
- **Review System**: Mark transactions as reviewed after verification

### 🔒 Complete Privacy & Portability
- **100% Local Processing**: No data leaves your device, ever
- **Encrypted Backups**: Export your data with password-protected encryption
- **Easy Migration**: Transfer data between devices with encrypted backup files
- **No Tracking**: Zero analytics, no third-party SDKs, complete privacy

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Installation

### Option 1: Build from Source

1. Clone the repository:
```bash
git clone https://github.com/yourusername/budget-snap.git
cd budget-snap
```

2. Open the project in Xcode:
```bash
open BudgetSnap.xcodeproj
```

3. Select your development team in the project settings:
   - Select the `BudgetSnap` project in the navigator
   - Select the `BudgetSnap` target
   - Go to "Signing & Capabilities"
   - Select your team from the dropdown

4. Build and run:
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

### Option 2: Install via Xcode

1. Download the latest release
2. Open `BudgetSnap.xcodeproj` in Xcode
3. Connect your iOS device
4. Build and install on your device

## Usage Guide

### Getting Started

1. **First Launch**: The app will create default spending categories (Groceries, Dining, Transportation, etc.)

2. **Import Screenshots**:
   - Go to the Transactions tab
   - Tap the + button
   - Select banking app screenshots from your photo library
   - The app will process them and extract transactions

3. **Review Transactions**:
   - Transactions marked with ⚠️ need review
   - Tap any transaction to edit details
   - Swipe left to delete, swipe right to mark as reviewed
   - Assign categories by tapping and selecting

4. **Create Budgets**:
   - Go to the Budgets tab
   - Tap + to add a budget
   - Select a category and set a monthly limit
   - Use "Copy from Last Month" to duplicate budgets

5. **Manage Categories**:
   - Go to the Categories tab
   - Tap + to create custom categories
   - Choose an icon and color
   - Edit or delete non-default categories

6. **Backup Your Data**:
   - Go to Settings
   - Tap "Export Data"
   - Enter a strong password
   - Save the encrypted .bsbackup file

### Tips for Best Results

**Screenshot Quality**:
- Ensure screenshots are clear and well-lit
- Capture the entire transaction list
- Avoid screenshots with overlapping UI elements

**OCR Accuracy**:
- The app works best with standard banking app layouts
- Manual review is recommended for complex transactions
- Edit any incorrectly detected amounts immediately

**Budget Management**:
- Set realistic limits based on historical spending
- Use the progress indicators to track spending throughout the month
- Review transactions regularly to keep categories accurate

## Architecture

### Tech Stack

- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Local data persistence
- **Vision Framework**: On-device OCR text recognition
- **CryptoKit**: AES-GCM encryption for data export
- **PhotosUI**: Photo library integration

### Project Structure

```
BudgetSnap/
├── BudgetSnapApp.swift          # App entry point
├── ContentView.swift             # Main tab navigation
├── Models/
│   ├── Transaction.swift         # Transaction data model
│   ├── Budget.swift             # Budget data model
│   └── Category.swift           # Category data model
├── Views/
│   ├── TransactionsView.swift   # Transaction list
│   ├── TransactionEditView.swift
│   ├── ScreenshotImportView.swift
│   ├── BudgetsView.swift        # Budget management
│   ├── BudgetEditView.swift
│   ├── MonthPickerView.swift
│   ├── CategoriesView.swift     # Category management
│   ├── CategoryEditView.swift
│   └── SettingsView.swift       # Settings & data export
├── Services/
│   ├── OCRService.swift         # Vision OCR processing
│   ├── TransactionParser.swift  # Parse OCR text
│   ├── DuplicateDetectionService.swift
│   └── DataExportService.swift  # Encrypted export/import
└── Info.plist
```

### Data Models

**Transaction**:
- Date, amount, merchant, description
- Category relationship
- OCR metadata (original text, screenshot hash)
- Review status

**Budget**:
- Monthly limit per category
- Month/year identifier
- Category relationship

**Category**:
- Name, icon, color
- Default flag
- Relationships to transactions and budgets

## Privacy & Security

### Data Storage
- All data stored locally using SwiftData
- No cloud synchronization
- No network requests
- No analytics or tracking

### Encryption
- Backups encrypted with AES-256-GCM
- PBKDF2 key derivation (100,000 rounds)
- Password never stored or transmitted

### Permissions
- **Photo Library**: Required only for importing screenshots
- **No other permissions needed**

## Development

### Running Tests

```bash
xcodebuild test -scheme BudgetSnap -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Building for Release

1. Update version in `Info.plist`
2. Archive the app: `Product > Archive`
3. Distribute via App Store or TestFlight

### Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Roadmap

- [ ] iPad support with adaptive layouts
- [ ] Dark mode refinements
- [ ] Recurring transaction detection
- [ ] Spending trends and analytics
- [ ] Budget rollover options
- [ ] CSV import/export
- [ ] Widgets for home screen
- [ ] iCloud sync (optional, user-controlled)

## Known Issues

- OCR accuracy varies with banking app UI designs
- Some date formats may not be recognized
- Manual review recommended for transactions under 70% confidence

## FAQ

**Q: Does this app connect to my bank?**
A: No. Budget Snap never accesses your bank accounts. You manually provide screenshots.

**Q: Is my data secure?**
A: Yes. All processing happens on your device. Data never leaves your phone unless you explicitly export it.

**Q: Can I use this on multiple devices?**
A: Yes. Export your data as an encrypted backup and import it on another device.

**Q: What banking apps work best?**
A: Most mobile banking apps work well. Apps with clear, text-based transaction lists produce the best results.

**Q: Can I trust the OCR results?**
A: The app flags low-confidence transactions for review. Always verify important transactions.

## License

MIT License - see [LICENSE](LICENSE) file for details

## Support

- **Issues**: Report bugs on [GitHub Issues](https://github.com/yourusername/budget-snap/issues)
- **Discussions**: Join the conversation in [GitHub Discussions](https://github.com/yourusername/budget-snap/discussions)

## Acknowledgments

- Built with Apple's Vision framework
- Uses SwiftUI and SwiftData
- Inspired by the need for privacy-focused financial tools

---

**Your finances. Your device. Your control.** 🔒✨