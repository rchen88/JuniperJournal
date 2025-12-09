# Juniper Journal

Juniper Journal is an environmental education and collaborative learning app designed to help students and educators engage with sustainability through project-based learning. It serves as a project database and design tool where students create NGSS-aligned learning modules and user-led projects.

**Users:** Designed for K-12 students, educators, and eco-focused organizations.

**Design focus:** Clean, green aesthetic with intuitive UX and accessible layouts.

## Key Features

- Learn and apply sustainability and engineering concepts.
- Share and replicate design projects with measurable impact data.
- Collaborate through chats, classroom communities, and shared journals.
- Explore projects, join design challenges, and access curated resources.

## Impact System

- Track progress in key areas (energy, waste, water, carbon, education, biogrowth).
- Earn EcoPoints, badges, and milestones for completed work.
- View impact dashboards and set personal sustainability goals.

**Goal:** Make sustainability education interactive, measurable, and community-driven

---

## 🚀 Getting Started

Follow these steps to set up the Juniper Journal project on your local machine.

### Prerequisites

Before you begin, ensure you have the following installed:

#### 1. **Flutter SDK**

**macOS/Linux:**
```bash
# Download Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable

# Add Flutter to your PATH (add this to your ~/.zshrc or ~/.bashrc)
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

**Windows:**
1. Download the Flutter SDK from [flutter.dev](https://docs.flutter.dev/get-started/install/windows)
2. Extract the zip file to a location (e.g., `C:\src\flutter`)
3. Add Flutter to your PATH
4. Run `flutter doctor` in Command Prompt

#### 2. **IDE (Choose one)**

**Option A: VS Code** (Recommended)
1. Download from [code.visualstudio.com](https://code.visualstudio.com/)
2. Install Flutter extension
3. Install Dart extension

**Option B: Android Studio**
1. Download from [developer.android.com](https://developer.android.com/studio)
2. Install Flutter plugin
3. Install Dart plugin

#### 3. **iOS Simulator** (macOS only)

```bash
# Install Xcode from the Mac App Store
xcode-select --install

# Open Xcode to install additional components
open -a Simulator
```

#### 4. **Android Emulator**

1. Open Android Studio
2. Go to **Tools → Device Manager**
3. Click **Create Device**
4. Select a device (e.g., Pixel 7)
5. Download a system image (e.g., API 33)
6. Click **Finish**

### Installation Steps

#### Step 1: Clone the Repository

```bash
git clone <your-repository-url>
cd JuniperJournal
```

#### Step 2: Install Flutter Dependencies

```bash
flutter pub get
```

#### Step 3: Set Up Supabase Backend

1. **Create a Supabase Account**
   - Go to [supabase.com](https://supabase.com)
   - Sign up for a free account
   - Create a new project

2. **Enable Authentication**
   - In your Supabase dashboard, go to **Authentication → Providers**
   - Enable **Email** provider
   - Configure email settings (confirmation, password reset, etc.)

3. **Set Up Database Tables**

   Run these SQL commands in the Supabase SQL Editor (**SQL Editor** in the sidebar):

   ```sql
   -- Learning Module Table
   CREATE TABLE learning_module (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
     module_name TEXT NOT NULL,
     difficulty TEXT,
     eco_points INTEGER,
     author_id UUID REFERENCES auth.users(id),
     learning_objectives TEXT[],
     anchoring_phenomenon TEXT,
     driving_question TEXT,
     concept_exploration TEXT,
     activity TEXT,
     assessment TEXT,
     solution TEXT
   );

   -- Projects Table
   CREATE TABLE projects (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
     project_name TEXT NOT NULL,
     tags TEXT[],
     user_id UUID REFERENCES auth.users(id),
     problem_statement TEXT,
     timeline JSONB,
     materials_cost JSONB,
     metrics JSONB,
     solution TEXT
   );

   -- Enable Row Level Security
   ALTER TABLE learning_module ENABLE ROW LEVEL SECURITY;
   ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

   -- Create policies (users can read all, but only modify their own)
   CREATE POLICY "Anyone can view learning modules"
     ON learning_module FOR SELECT
     USING (true);

   CREATE POLICY "Users can insert their own modules"
     ON learning_module FOR INSERT
     WITH CHECK (auth.uid() = author_id);

   CREATE POLICY "Users can update their own modules"
     ON learning_module FOR UPDATE
     USING (auth.uid() = author_id);

   CREATE POLICY "Anyone can view projects"
     ON projects FOR SELECT
     USING (true);

   CREATE POLICY "Users can insert their own projects"
     ON projects FOR INSERT
     WITH CHECK (auth.uid() = user_id);

   CREATE POLICY "Users can update their own projects"
     ON projects FOR UPDATE
     USING (auth.uid() = user_id);
   ```

4. **Create Storage Bucket** (for images)
   - Go to **Storage** in the Supabase dashboard
   - Create a new bucket called `images`
   - Set it to **Public** for now (or configure policies as needed)

#### Step 4: Configure Environment Variables

1. **Copy the example environment file:**

   ```bash
   cp .env.example .env
   ```

2. **Fill in your Supabase credentials:**

   Open `.env` and add your Supabase keys:

   ```env
   SUPABASE_URL=https://your-project-ref.supabase.co
   SUPABASE_KEY=your-anon-public-key
   ```

   **Where to find these:**
   - Go to your Supabase project dashboard
   - Click **Settings** (gear icon) → **API**
   - Copy **Project URL** → Paste as `SUPABASE_URL`
   - Copy **anon public** key → Paste as `SUPABASE_KEY`

#### Step 5: Verify Setup

Run Flutter doctor to ensure everything is configured correctly:

```bash
flutter doctor
```

You should see checkmarks (✓) for:
- Flutter SDK
- Connected device (simulator/emulator)
- IDE

### Running the App

#### Start iOS Simulator (macOS only)

```bash
open -a Simulator
```

#### Start Android Emulator

```bash
flutter emulators --launch <emulator_id>

# Or launch from Android Studio:
# Tools → Device Manager → Click Play button
```

#### Run the App

```bash
# Run in debug mode
flutter run

# Run on specific device
flutter run -d <device-id>

# List available devices
flutter devices
```

The app should now launch! You'll see:
1. **Landing Screen** with logo and Sign up/Log in buttons
2. **Sign up** to create a new account
3. **Home Screen** with the "+" button to create learning modules or projects

---

## 🏗️ Project Structure

```
lib/
├── main.dart                          # App entry point
├── src/
│   ├── backend/
│   │   ├── auth/
│   │   │   └── auth_service.dart      # Authentication logic
│   │   ├── db/
│   │   │   ├── supabase_database.dart # Supabase client
│   │   │   └── repositories/          # Data access layer
│   │   └── storage/
│   │       └── storage_service.dart   # Image uploads
│   ├── frontend/
│   │   ├── home_page/
│   │   │   ├── landing.dart           # Landing screen
│   │   │   ├── login.dart             # Login screen
│   │   │   ├── signup.dart            # Signup screen
│   │   │   └── home.dart              # Main home screen
│   │   ├── learning_module/           # Learning module screens
│   │   └── submission_template/       # Project submission screens
│   ├── styling/
│   │   └── app_colors.dart            # App color palette
│   └── widgets/
│       └── toolbar.dart               # Shared widgets
```

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

---

## 🐛 Troubleshooting

### "Unable to load asset: .env"
- Make sure you created a `.env` file (not `.env.example`)
- Verify `.env` is in the project root directory
- Run `flutter clean` and `flutter pub get`

### "Supabase connection failed"
- Double-check your `SUPABASE_URL` and `SUPABASE_KEY` in `.env`
- Ensure you copied the **anon public** key (not the service role key)
- Verify your Supabase project is active

### "CocoaPods not installed" (iOS)
```bash
sudo gem install cocoapods
cd ios
pod install
cd ..
```

### "Gradle build failed" (Android)
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Hot reload not working
- Stop the app and run `flutter clean`
- Delete the `build/` folder
- Run `flutter pub get`
- Restart the app

### iOS simulator not showing
```bash
# Kill existing simulators
killall Simulator

# Restart simulator
open -a Simulator
```

---

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)

---

## 🌱 Roadmap

- [ ] Google OAuth integration
- [ ] Profile
- [ ] Display completed projects
- [ ] View / Edit completed projects
- [ ] Impact dashboard
- [ ] Badge system
- [ ] Community features

---
