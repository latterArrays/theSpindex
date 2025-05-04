# Spindex
![Spindex Logo](assets/TheSpindexFullLogo.png)
### Welcome to Spindex!
Spindex is an app for cataloging your analogue music collection - built by a vinyl lover, for vinyl lovers. Gone are the days of accidently purchasing a second copy of an album you already own! Create wish lists, manage your collection, and show off your favorites.

### What is Spindex?
Spindex is a cross-platform mobile application built using [Flutter](https://flutter.dev/), a UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase. This app leverages the power of [Firebase](https://firebase.google.com/) to provide backend services such as authentication, database, cloud storage, and serverless functions. Additionally, it integrates with the [Discogs API](https://www.discogs.com/developers/) to fetch music-related data, and the [OpenAI API](https://platform.openai.com/docs/overview) for image processing and metadata extraction.

## Features
- **Cross-Platform**: Runs seamlessly on both iOS and Android devices.
- **Firebase Integration**:
    - **Authentication**: Secure user sign-in and sign-up, as well as password reset emails.
    - **Cloud Firestore**: Real-time database for storing and syncing user data.
    - **Cloud Storage**: For managing and storing user-uploaded files.
    - **Remote Configuration**: Store API keys safely and load them dynamically - no need to hard code secrets into your app.
    - **Firebase Functions**: Used to proxy API requests and mitigate CORS issues when interacting with external APIs like Discogs.
- **Discogs API Integration**: Fetch detailed music metadata, including album art, track lists, and artist information.

## Getting Started
If you want to build Spindex on your own machine, you can follow these instructions to get started. Note: You will need to deploy your own Firebase function and modify the files to include your own Firebase project identifiers, as well as your own configuration for Discogs and OpenAI API keys.

### Prerequisites
- Install [Flutter](https://flutter.dev/docs/get-started/install) on your machine.
- Set up your Flutter environment for [iOS](https://flutter.dev/docs/get-started/install/macos) and/or [Android](https://flutter.dev/docs/get-started/install/windows).
- Ensure you have a [Firebase](https://www.firebase.com) project set up with the necessary services enabled.
- Familiarize yourself with the [FlutterFire documentation](https://firebase.flutter.dev/) for integrating Firebase with Flutter.

### Installation
1. Clone the repository:
     ```bash
     git clone https://github.com/yourusername/spindex.git
     cd spindex
     ```
2. Install dependencies:
     ```bash
     flutter pub get
     ```
3. Configure Firebase:
     - Download the `google-services.json` file for Android and place it in the `android/app` directory.
     - Download the `GoogleService-Info.plist` file for iOS and place it in the `ios/Runner` directory.
     - **Important**: These files contain sensitive information and should not be committed to version control. Ensure they are listed in your `.gitignore` file.
4. Configure API Keys:
     - Add your Discogs API key and OpenAI API key to a secure location. You can configure these keys in Firebase Remote Config for added security and dynamic updates.
     - Update your app to fetch these keys from Firebase Remote Config at runtime. Refer to the [FlutterFire Remote Config documentation](https://firebase.flutter.dev/docs/remote-config/overview/) for guidance.
     - Alternatively, you can use environment variables or a secure configuration file if Remote Config is not an option.
5. Deploy Firebase Functions:
     - Navigate to the `functions` directory:
         ```bash
         cd functions
         ```
     - Install dependencies:
         ```bash
         npm install
         ```
     - Deploy the functions:
         ```bash
         firebase deploy --only functions
         ```

### Running the App
1. Run the app on an emulator or connected device:
     ```bash
     flutter run
     ```
2. For specific platforms:
     - iOS: Ensure you have Xcode installed and run:
         ```bash
         flutter run -d ios
         ```
     - Android: Ensure you have an Android emulator or device connected and run:
         ```bash
         flutter run -d android
         ```

### Sensitive Files and `.gitignore`
To ensure sensitive files are not committed to version control, make sure the following entries remain in your `.gitignore` file:
```
# Firebase configuration files
android/app/google-services.json
ios/Runner/GoogleService-Info.plist

# Environment files
.env*
```

### Contributing
Contributions are welcome! Please fork the repository and submit a pull request.

### License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

### Contact
For any questions or feedback, feel free to reach out at `matt@latterarrays.com`.