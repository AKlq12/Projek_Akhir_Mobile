# 🎨 FitPro - UI/UX Prompts untuk Google Stitch

Kumpulan prompt yang dioptimalkan untuk digunakan di **https://stitch.withgoogle.com/**
untuk menghasilkan desain UI Flutter aplikasi fitness **FitPro**.

---

## 🎯 Panduan Penggunaan

1. Buka **https://stitch.withgoogle.com/**
2. Pilih **Mobile** sebagai platform
3. Copy-paste prompt di bawah satu per satu
4. Setelah generate, klik **Export** untuk mendapatkan kode Flutter
5. Sesuaikan kode hasil export ke dalam project

> **Tips:** Stitch menghasilkan satu screen per prompt. Generate setiap screen secara terpisah.

---

## 🎨 Design System (Masukkan ini sebagai konteks awal)

```
Design system for FitPro fitness app:
- Theme: Dark mode
- Primary color: Electric blue (#00B4D8), Cyan (#00C9FF)
- Secondary color: Energetic green (#92FE9D), Lime (#B5FF69)
- Accent color: Vibrant orange (#FF6B35)
- Error color: Coral red (#FF6B6B)
- Background: Deep dark (#0A0E21), Surface (#1A1E36)
- Card background: Dark navy (#1E2243) with subtle border
- Text primary: White (#FFFFFF)
- Text secondary: Cool grey (#8D93AB)
- Font: Google Sans or Inter
- Corner radius: 16px for cards, 12px for buttons, 24px for bottom sheet
- Elevation: Subtle glow effects instead of shadows
- Style: Premium, modern, glassmorphism elements, gradient accents
```

---

## 📱 Prompt Per Screen

---

### 1. Splash Screen

```
Create a mobile splash screen for a premium fitness app called "FitPro". 

Dark background (#0A0E21) with a centered animated logo area. The logo is a stylized dumbbell icon combined with a lightning bolt in a gradient from electric blue (#00B4D8) to energetic green (#92FE9D). Below the logo, display the app name "FitPro" in bold white text with a subtle gradient glow effect. At the bottom, show a small circular loading indicator with the same blue-green gradient. The overall feel should be premium, energetic, and modern. Add subtle particle effects or radial gradient in the background for depth.
```

---

### 2. Login Screen

```
Create a mobile login screen for a premium dark-themed fitness app called "FitPro".

Background: Deep dark (#0A0E21) with a subtle gradient mesh pattern at the top in blue-green tones.

Layout from top to bottom:
1. App logo at the top center - a dumbbell icon with gradient blue-green, with "FitPro" text below it
2. Welcome text: "Welcome Back" in large bold white, subtitle "Sign in to continue your fitness journey" in grey (#8D93AB)
3. Email input field with dark surface (#1E2243) background, rounded corners (12px), email icon prefix, white text, subtle blue border on focus
4. Password input field with same style, lock icon prefix, and visibility toggle suffix icon
5. "Forgot Password?" text link aligned right in blue (#00B4D8)
6. "Sign In" button - full width, rounded (12px), gradient from blue (#00B4D8) to green (#92FE9D), white bold text, with subtle glow shadow
7. Divider line with "OR" text in the center, grey color
8. Biometric login button - circular button with fingerprint icon, outlined border in blue, centered below the divider. Label "Use Fingerprint" below it
9. At the very bottom: "Don't have an account? Sign Up" text with "Sign Up" in blue

Use Material Design 3 components. The inputs should have filled style with rounded corners. Everything should feel premium and modern with spacing and hierarchy.
```

---

### 3. Register Screen

```
Create a mobile registration screen for a dark-themed fitness app "FitPro".

Background: Deep dark (#0A0E21).

Layout from top to bottom:
1. Back arrow button at top left
2. Title "Create Account" in large bold white text, subtitle "Start your fitness journey today" in grey
3. Profile avatar placeholder circle (80px) with camera icon overlay, centered - tap to add photo
4. Full name input field - dark card background (#1E2243), person icon prefix, rounded 12px
5. Email input field - same style, email icon prefix
6. Password input field - lock icon prefix, visibility toggle, rounded 12px
7. Confirm password input field - same style
8. Fitness goal dropdown selector with chips: "Lose Weight", "Build Muscle", "Stay Fit", "Gain Strength" - selectable chips with blue gradient when selected
9. "Create Account" button - full width gradient blue (#00B4D8) to green (#92FE9D), rounded 12px, white bold text
10. Bottom text: "Already have an account? Sign In" with "Sign In" in blue

All input fields use dark surface (#1E2243) with subtle rounded borders. Material Design 3 style. Premium dark theme aesthetic.
```

---

### 4. Home Dashboard Screen

```
Create a mobile home dashboard screen for a dark-themed fitness app "FitPro".

Background: Deep dark (#0A0E21). This is the main screen after login.

Layout from top to bottom:
1. Top bar: Left side shows "Hello, John 👋" greeting in white, below it "Ready to workout?" in grey. Right side shows a circular user avatar (40px) with border glow
2. Scrollable content below:

Section A - "Today's Stats" - Horizontal scrollable row of 3 stat cards:
   - Card 1: Steps icon + "8,432" large number + "steps" label, circular progress ring showing 84% in blue gradient
   - Card 2: Flame icon + "320" large number + "kcal burned" label, circular progress ring in orange
   - Card 3: Timer icon + "45" large number + "min workout" label, circular progress ring in green
   Each card: Dark card (#1E2243), rounded 16px, with glassmorphism effect

Section B - "Today's Workout" - A large card with gradient overlay (blue to green), showing workout plan name "Upper Body Day", exercise count "6 exercises", estimated time "~45 min", and a "Start Workout" button in white. The card should have a subtle background image of someone exercising (abstract/silhouette)

Section C - "Quick Actions" - 2x2 grid of action cards:
   - "Browse Exercises" with dumbbell icon
   - "AI Coach" with robot/spark icon
   - "Nearby Gyms" with map pin icon
   - "Mini Game" with gamepad icon
   Each card: compact, dark surface, gradient icon color, rounded 16px

Section D - "Weekly Activity" - A bar chart showing 7 days (Mon-Sun) with blue gradient bars representing workout minutes. Current day highlighted with glow.

3. Bottom Navigation Bar: 5 tabs with icons and labels:
   - Home (home icon, active with blue gradient)
   - Exercises (dumbbell icon)
   - Tools (grid/wrench icon)
   - AI Coach (sparkle/robot icon)
   - Profile (person icon)
   Bottom nav background: Dark surface (#1A1E36), with pill-shaped active indicator using blue gradient

Use Material Design 3. Premium feel with subtle animations suggested. Glassmorphism effects on cards.
```

---

### 5. Exercise List Screen

```
Create a mobile exercise browser screen for a dark-themed fitness app.

Background: Deep dark (#0A0E21).

Layout from top to bottom:
1. Top app bar with title "Exercises" in bold white, and a filter icon button on the right

2. Search bar - full width, dark surface (#1E2243), rounded 24px, with search icon prefix and clear button suffix. Placeholder: "Search exercises..."

3. Horizontal scrollable category filter chips below the search bar:
   - "All" (selected, gradient blue-green background)
   - "Arms" (unselected, dark outlined)
   - "Chest" (unselected)
   - "Legs" (unselected)
   - "Back" (unselected)
   - "Shoulders" (unselected)
   - "Core" (unselected)
   Selected chip has gradient fill (blue to green), unselected chips have dark surface with grey border

4. Exercise list - vertical scrollable list of exercise cards:

   Each exercise card contains:
   - Left: Square rounded image thumbnail (70x70px) of the exercise
   - Center: Exercise name in white bold, below it muscle group tag in small blue text, equipment tag in grey
   - Right: Favorite heart icon (outline or filled) and a small arrow icon
   Card style: Dark surface (#1E2243), rounded 16px, slight elevation, tap feedback

   Show 6 example exercise cards:
   - "Barbell Bench Press" - Chest - Barbell
   - "Bicep Curl" - Arms - Dumbbell
   - "Squats" - Legs - Barbell
   - "Pull Up" - Back - Body Weight
   - "Shoulder Press" - Shoulders - Dumbbell
   - "Plank" - Core - Body Weight

5. Bottom: Floating action button in bottom right with "+" icon and gradient blue-green, for logging quick exercise

Include bottom navigation bar with 5 tabs (Home, Exercises active, Tools, AI Coach, Profile).

Material Design 3 components. Clean, spacious design with proper hierarchy.
```

---

### 6. Exercise Detail Screen

```
Create a mobile exercise detail screen for a dark-themed fitness app.

Background: Deep dark (#0A0E21).

Layout:
1. Top section: Large hero image area (250px height) showing exercise illustration/photo with a gradient overlay fading to the dark background at the bottom. Back arrow button and share button overlaid on top. Heart/favorite icon button at top right.

2. Below the image:
   - Exercise name "Barbell Bench Press" in large bold white (24px)
   - Row of tags/chips: "Chest" in blue chip, "Barbell" in grey chip, "Intermediate" in orange chip

3. Section "Muscles Worked" - showing muscle group icons or stylized body illustration:
   - Primary: "Pectoralis Major" with blue dot indicator
   - Secondary: "Triceps", "Anterior Deltoid" with green dot indicators
   Display as horizontal cards with muscle icons

4. Section "Instructions" - numbered list with steps:
   - Step 1: "Lie on a flat bench..."
   - Step 2: "Grip the barbell..."
   - Step 3: "Lower the bar..."
   - Step 4: "Push the bar back up..."
   Each step in a subtle dark card (#1E2243), numbered with blue gradient circle

5. Section "Tips" - info card with lightbulb icon, blue-tinted background, containing 2-3 fitness tips

6. Bottom sticky action bar with two buttons side by side:
   - "Add to Workout" - outlined button in blue
   - "Log Exercise" - filled gradient button blue-to-green
   Both buttons rounded 12px, full width split equally

Material Design 3. Smooth layout with proper spacing. Premium dark aesthetic.
```

---

### 7. Workout Plan List Screen

```
Create a mobile workout plans screen for a dark-themed fitness app.

Background: Deep dark (#0A0E21).

Layout:
1. Top app bar: Title "My Workouts" in bold white, left aligned. Filter dropdown icon on right.

2. Day filter - horizontal scrollable pills for days:
   "All", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
   Active pill has gradient blue-green fill, inactive has dark outline

3. Workout plan cards list - vertical scrollable:

   Each workout card:
   - Gradient accent strip on the left edge (blue-green)
   - Workout name in bold white: "Upper Body Blast"
   - Day label: "Monday" in small blue text
   - Info row with icons: "6 exercises" (dumbbell icon), "~45 min" (clock icon)
   - Bottom row: small exercise icon thumbnails (3 circular images) + "+3 more" text
   - Three-dot menu button at top right
   Card: Dark surface (#1E2243), rounded 16px

   Show 4 example cards:
   - "Upper Body Blast" - Monday - 6 exercises - 45 min
   - "Leg Day Power" - Tuesday - 5 exercises - 40 min
   - "Full Body HIIT" - Wednesday - 8 exercises - 30 min
   - "Back & Biceps" - Thursday - 7 exercises - 50 min

4. Empty state: If no plans, show illustration with text "No workout plans yet. Create your first plan!" with CTA button

5. FAB at bottom right: "+" icon with gradient blue-green, to create new workout plan

Include bottom navigation bar. Material Design 3. Premium dark theme.
```

---

### 8. Active Workout Session Screen

```
Create a mobile active workout session screen for a dark-themed fitness app.

Background: Deep dark (#0A0E21). This screen is shown when the user is actively doing a workout.

Layout:
1. Top bar: Small "x" close button at left, workout name "Upper Body Blast" centered, timer "12:34" in bold green on right showing elapsed time

2. Current exercise section (large, centered):
   - Exercise image placeholder (200x150px rounded)
   - Exercise name "Barbell Bench Press" in large bold white (22px)
   - Current set indicator: "Set 3 of 4" in blue text
   - Large rep/weight display: "12 reps × 60 kg" in very large white text

3. Progress bar showing overall workout progress (e.g., "Exercise 3 of 6"), using gradient blue-green fill on dark track

4. Input section - dark card (#1E2243) with rounded corners:
   - Row with "-" / number / "+" stepper for Reps (default 12)
   - Row with "-" / number / "+" stepper for Weight kg (default 60)
   - Notes text field (optional)

5. Action buttons row:
   - "Rest Timer" button - outlined blue, shows a rest countdown when tapped
   - "Complete Set" button - filled gradient blue-green, bold white text, large and prominent

6. Bottom section: horizontal list of upcoming exercises as small circular thumbnails with names below, scrollable. Current exercise highlighted with blue ring.

7. Shake indicator: small text at bottom "🔀 Shake to shuffle next exercise" in grey

No bottom navigation on this screen (it's a full-screen workout mode). Material Design 3. Focus on usability during exercise.
```

---

### 9. Tools Menu Screen

```
Create a mobile tools menu screen for a dark-themed fitness app.

Background: Deep dark (#0A0E21).

Layout:
1. Top: Title "Tools" in bold white text, subtitle "Useful tools for your fitness journey" in grey

2. Grid of tool cards (2 columns, 3 rows = 6 cards):

   Card 1 - "Currency Converter":
   - Icon: Dollar/currency exchange icon
   - Gradient accent: Blue to cyan
   - Subtitle: "Convert 160+ currencies"

   Card 2 - "World Clock":
   - Icon: Globe/clock icon
   - Gradient accent: Purple to blue
   - Subtitle: "WIB, WITA, WIT & more"

   Card 3 - "Nearby Gyms":
   - Icon: Map pin / location icon
   - Gradient accent: Green to teal
   - Subtitle: "Find gyms around you"

   Card 4 - "Mini Game":
   - Icon: Gamepad / lightning icon
   - Gradient accent: Orange to yellow
   - Subtitle: "Test your reflexes"

   Card 5 - "Step Counter":
   - Icon: Footsteps / shoe icon
   - Gradient accent: Pink to red
   - Subtitle: "Track daily steps"

   Card 6 - "Shake Surprise":
   - Icon: Vibration / shuffle icon
   - Gradient accent: Cyan to green
   - Subtitle: "Shake for random exercise"

   Each card style:
   - Dark surface (#1E2243) with rounded 16px corners
   - Large icon at top center with gradient background circle (48px)
   - Tool name in white bold text below
   - Subtitle in grey small text
   - Subtle glassmorphism effect
   - Height: ~160px each

3. Include bottom navigation bar with Tools tab active.

Material Design 3. Premium dark theme. Cards should feel interactive with implied hover/press states.
```

---

### 10. Currency Converter Screen

```
Create a mobile currency converter screen for a dark-themed fitness app.

Background: Deep dark (#0A0E21).

Layout:
1. Top app bar: Back arrow, title "Currency Converter" in white, subtitle "Gym memberships worldwide" in small grey text

2. Main conversion card - large dark card (#1E2243), rounded 20px:

   Top half - "From" section:
   - Label "From" in grey
   - Large amount input "1,000.00" in white bold (28px font)
   - Currency selector button showing flag emoji + currency code "🇺🇸 USD" with dropdown arrow
   - Below: full currency name "United States Dollar" in small grey

   Centered swap button between top and bottom: circular button with up-down arrows icon, gradient blue-green border, dark fill. Tapping swaps the two currencies.

   Bottom half - "To" section:
   - Label "To" in grey
   - Converted amount "15,870,000.00" in green bold (28px font)
   - Currency selector button "🇮🇩 IDR" with dropdown arrow
   - Below: "Indonesian Rupiah" in small grey

3. Exchange rate info below the card:
   - "1 USD = 15,870 IDR" in white
   - "Last updated: 2 hours ago" in grey small
   - Refresh icon button

4. Section "Popular Conversions" - horizontal scrollable chips:
   - "USD → IDR", "EUR → IDR", "GBP → IDR", "JPY → IDR", "SGD → IDR"
   Chips in dark outlined style, tap to quick-select

5. Section "Recent Conversions" - list of 3 recent conversion entries:
   Each: "USD → IDR" with amount "1,000 → 15,870,000" and timestamp
   Dark card style

6. Bottom: Info text "💡 Compare gym membership costs across countries" in blue tinted card

Material Design 3. Clean calculator-style layout. Premium dark theme.
```

---

### 11. Timezone Converter Screen

```
Create a mobile world clock / timezone converter screen for a dark-themed fitness app.

Background: Deep dark (#0A0E21).

Layout:
1. Top app bar: Back arrow, title "World Clock" in white

2. Current local time section at top:
   - "Your Local Time" label in grey
   - Large digital clock "15:42:30" in bold white (36px)
   - "WIB (UTC+7) • Jakarta" in blue text
   - Date: "Wednesday, 9 April 2025" in grey

3. World clocks list - vertical scrollable cards:

   Each clock card contains:
   - Left: City/region name in bold white, timezone code in grey below (e.g., "WIB UTC+7")
   - Right: Current time in that zone in large white text, AM/PM if applicable
   - Subtle gradient strip on left edge matching a unique color per timezone
   - Card: Dark surface (#1E2243), rounded 16px

   Show these default clocks:
   - "Jakarta (WIB)" - UTC+7 - "15:42" - Blue accent
   - "Makassar (WITA)" - UTC+8 - "16:42" - Green accent
   - "Jayapura (WIT)" - UTC+9 - "17:42" - Teal accent
   - "London (GMT)" - UTC+0 - "08:42" - Purple accent
   - "New York (EST)" - UTC-5 - "03:42" - Orange accent
   - "Tokyo (JST)" - UTC+9 - "17:42" - Red accent

   Each card also has a 3-dot menu for removing

4. "Add Timezone" button at bottom of list - outlined button with "+" icon, blue text, dashed border

5. Floating action button at bottom right: "+" icon with gradient blue-green to add new timezone via searchable city picker

6. Bottom info card: "💡 Plan your international workout live sessions" in blue tinted card

Material Design 3. The clocks should feel like a live dashboard. Premium dark theme.
```

---

### 12. Nearby Gym Screen (LBS / Map)

```
Create a mobile nearby gym finder screen for a dark-themed fitness app.

Background: Deep dark (#0A0E21).

Layout:
1. Top app bar: Back arrow, title "Nearby Gyms" in white, search icon button on right

2. Map section (occupying top 55% of screen):
   - Dark-styled map (like dark mode Google Maps or Mapbox dark style)
   - User location marker: blue glowing dot with pulse animation ring
   - Gym markers: orange/green pin icons scattered on map (5-6 markers)
   - One selected marker shows a small popup card above it with gym name
   - Zoom controls (+ / -) on right edge of map
   - "Re-center" button (compass icon) on right edge below zoom

3. Bottom sheet / panel (45% of screen, draggable):
   - Handle bar at top center (small grey pill)
   - Title: "5 Gyms Found" in white, "Within 5 km" in grey
   - Distance filter: slider or chips "1 km", "3 km", "5 km", "10 km" - selected has blue fill

   - Scrollable list of gym cards:
     Card layout per gym:
     - Gym name in white bold: "FitZone Gym & Fitness"
     - Address in grey: "Jl. Sudirman No. 123"
     - Distance: "1.2 km" with location pin icon in blue
     - Rating: "4.5 ⭐" stars
     - "Navigate" button (small, outlined, blue) on the right
     Card: Dark surface (#1E2243), rounded 12px

     Show 4-5 gym entries

4. No bottom navigation on this screen (back navigation in app bar).

Material Design 3. The map should feel immersive. Premium dark theme with the bottom sheet providing scannable list information.
```

---

### 13. AI Chat Screen (Gemini Fitness Coach)

```
Create a mobile AI chatbot screen for a dark-themed fitness app. The AI is a "Fitness Coach" powered by Gemini.

Background: Deep dark (#0A0E21).

Layout:
1. Top app bar: Back arrow, centered title area with:
   - Small robot/spark icon (gradient blue-green) + "AI Fitness Coach" text in white
   - Subtitle "Powered by Gemini" in small grey
   - Three-dot menu on right

2. Chat messages area (scrollable, fills main content):

   Message 1 - AI greeting (left aligned):
   - Small circular AI avatar (robot icon with gradient blue-green background)
   - Message bubble: Dark card (#1E2243) with rounded corners (top-left square, others rounded 16px)
   - Text: "Hi there! 💪 I'm your AI Fitness Coach. Ask me anything about workouts, nutrition, exercise form, or let me create a personalized plan for you!"
   - Timestamp "09:30 AM" in small grey below

   Message 2 - User message (right aligned):
   - Message bubble: Gradient blue-green background, white text, rounded (top-right square, others rounded 16px)
   - Text: "Can you suggest a chest workout for beginners?"
   - Timestamp below

   Message 3 - AI response (left aligned):
   - Longer message with formatted text:
   - "Here's a great chest workout for beginners: 🏋️"
   - Numbered list: "1. Push-ups - 3 sets × 10 reps" etc.
   - Bold and formatted text within the bubble
   - Timestamp below

   Message 4 - AI typing indicator (left aligned):
   - Small bubble with three animated dots (...)

3. Quick prompt chips - horizontal scrollable row above the input:
   - "Suggest Workout" (dumbbell icon)
   - "Nutrition Tips" (apple icon)
   - "Form Check" (check icon)
   - "Recovery Advice" (heart icon)
   Chips: Dark outlined, rounded 20px, small text

4. Message input bar at bottom:
   - Dark surface (#1E2243) rounded 24px
   - Text input: "Ask your coach..." placeholder in grey
   - Attachment icon button (for sending exercise images)
   - Send button: Circular gradient blue-green with arrow-up icon

5. No bottom navigation on this full-screen chat. Or optionally include it.

Material Design 3. The chat should feel modern and conversational, like ChatGPT but fitness-themed. Premium dark aesthetic.
```

---

### 14. Mini Game - Reaction Reflex

```
Create a mobile mini game screen for a dark-themed fitness app. The game is called "Reaction Reflex" - a reaction time test game.

Background: Deep dark (#0A0E21).

Layout for the "waiting" state:
1. Top bar: Back arrow, title "Reaction Reflex" in white, high score badge "Best: 215ms" in green on right

2. Main game area (large, centered, fills most of screen):
   - Large circle (250px diameter) centered on screen
   - Circle color: Dark red/maroon (#8B0000) for "wait" state
   - Inside the circle: Text "WAIT..." in white bold (24px)
   - Below the circle: Instruction text "Tap when the circle turns GREEN" in grey

3. Current round indicator: "Round 2 of 5" in white, with 5 small dots (2 filled blue, 3 empty) below

4. Previous round results - small row at bottom:
   - "Round 1: 234ms ⚡" in yellow
   - "Round 2: --" in grey
   - etc.

5. Stats card at bottom: Dark surface card showing:
   - "Average: 234ms" 
   - "Rating: Great! 🔥"

---

Alternative layout for "GO!" state (the circle turns green):
   - Circle turns bright green (#92FE9D) with glow effect
   - Inside: fitness icon (like a dumbbell or running figure) + "TAP NOW!" text
   - The entire screen has a subtle green pulse glow

---

Alternative layout for "Results" screen after 5 rounds:
   - Trophy icon at top (gradient gold)
   - "Your Results" in large bold white
   - Average time: "218ms" in very large green text
   - Rating: "⚡ Excellent Reflexes!" in gradient text
   - 5 round breakdown in a list
   - "Play Again" button - gradient blue-green, full width
   - "Share Score" button - outlined blue

Material Design 3. Fun, game-like feel while staying in the dark premium theme. Bright accent colors for the game elements.
```

---

### 15. Profile Screen

```
Create a mobile profile screen for a dark-themed fitness app.

Background: Deep dark (#0A0E21).

Layout:
1. Top section with curved/wave gradient background (blue-green gradient fading to dark):
   - Centered circular user avatar (100px) with gradient blue-green ring border (3px)
   - User name "John Doe" in bold white (22px) below
   - Email "john@example.com" in grey below
   - "Edit Profile" small outlined button below

2. Stats row - 3 stat items in a horizontal card:
   - "128" workouts completed (dumbbell icon, blue)
   - "15" day streak (flame icon, orange)
   - "845K" total steps (footsteps icon, green)
   Card: Dark surface (#1E2243), rounded 16px, divided by subtle vertical lines

3. Fitness info card:
   - Grid showing: Height "175 cm", Weight "72 kg", Goal "Build Muscle", BMI "23.5"
   - Dark card (#1E2243), rounded 16px
   - Each info item has a small icon and label-value pair

4. Menu list items (each as a tappable row with icon, label, and right arrow):
   - 📝 "Saran & Kesan TPM" (with blue icon)
   - 🔔 "Notification Settings" (with orange icon)
   - 🎨 "Appearance" (with purple icon)
   - 🔒 "Security & Biometric" (with green icon)
   - ℹ️ "About App" (with grey icon)
   - 🚪 "Logout" (with red icon, no arrow, text in red)

   Each row: Dark surface background, rounded 12px, proper spacing, icon in a small colored circle on the left

5. App version "FitPro v1.0.0" centered at bottom in small grey text

Include bottom navigation bar with Profile tab active. Material Design 3. Premium dark theme with the gradient header creating visual hierarchy.
```

---

### 16. Saran & Kesan Screen

```
Create a mobile feedback form screen for a dark-themed app. The screen is titled "Saran & Kesan TPM" (Suggestions & Impressions for a university course).

Background: Deep dark (#0A0E21).

Layout:
1. Top app bar: Back arrow, title "Saran & Kesan" in white, subtitle "Teknologi Pemrograman Mobile" in small grey

2. Course info card at top:
   - Dark card (#1E2243) with blue gradient left border
   - University/course icon
   - "Mata Kuliah: Teknologi Pemrograman Mobile" in white
   - "Dosen: [Nama Dosen]" in grey
   - Semester info in grey

3. Form section:

   Label "Kesan (Impressions)" in white with star emoji ⭐
   - Large text area input (4 lines minimum height)
   - Dark surface (#1E2243), rounded 12px, white text
   - Placeholder: "Bagikan kesan Anda terhadap mata kuliah ini..."
   - Character count "0/500" in grey bottom right

   Label "Saran (Suggestions)" in white with bulb emoji 💡
   - Large text area input (4 lines minimum height)
   - Same style as above
   - Placeholder: "Berikan saran untuk perbaikan mata kuliah..."
   - Character count "0/500" in grey bottom right

4. "Submit" button - full width, gradient blue-green, rounded 12px, white bold text, bottom margin

5. Section "Riwayat Saran & Kesan" (History) below:
   - If previous submissions exist, show them as expandable cards
   - Each card shows date, preview of kesan text, and expand icon
   - Dark card style

Material Design 3. Clean form design, easy to read. Premium dark theme. Indonesian language for labels.
```

---

### 17. Edit Profile Screen

```
Create a mobile edit profile screen for a dark-themed fitness app.

Background: Deep dark (#0A0E21).

Layout:
1. Top app bar: Back arrow / "Cancel" text on left, title "Edit Profile" centered, "Save" text button in blue-green on right

2. Avatar section centered:
   - Large circular avatar (120px) with current user photo
   - "Change Photo" blue text link below
   - Or camera icon overlay on the avatar circle

3. Form fields (all using dark surface #1E2243, rounded 12px):
   - Full Name: prefilled "John Doe", person icon
   - Email: prefilled "john@example.com", email icon (disabled/read-only, greyed out)
   - Date of Birth: date picker style, calendar icon, "1995-06-15"
   - Gender: dropdown selector, "Male" / "Female" / "Other"
   - Height (cm): number input, ruler icon, "175"
   - Weight (kg): number input, scale icon, "72"
   - Fitness Goal: dropdown, "Build Muscle" / "Lose Weight" / "Stay Fit" / "Gain Strength"

4. Each field has a label above it in grey small text

5. Delete account section at bottom:
   - Small red text "Delete Account" with warning icon
   - Separated by divider from main form

Material Design 3. Clean form layout with proper spacing. All inputs have filled dark style. Premium dark theme.
```

---

### 18. Notification Settings Screen (Inside Settings)

```
Create a mobile notification settings screen for a dark-themed fitness app.

Background: Deep dark (#0A0E21).

Layout:
1. Top app bar: Back arrow, title "Notifications" in white

2. Toggle options as list tiles with switch toggles:

   Section "Workout Reminders":
   - "Daily Workout Reminder" - toggle switch (blue-green when on) - enabled
   - "Reminder Time" - shows "08:00 AM" with clock icon, tappable to change time picker
   - "Rest Day Reminders" - toggle - disabled

   Section "Activity":
   - "Step Goal Achievement" - toggle - enabled
   - "Daily Step Goal" - shows "10,000 steps" with edit pencil, tappable
   - "Workout Completion" - toggle - enabled

   Section "Social":
   - "New Features & Updates" - toggle - enabled
   - "Tips & Motivation" - toggle - disabled

   Each section has a header in blue small caps text.
   Each row: Dark surface background, icon on left in colored circle, title in white, subtitle in grey if applicable, switch on right.

3. "Save Preferences" button at bottom - gradient blue-green, full width, rounded 12px

Material Design 3. Clean settings layout. Premium dark theme. Switches use blue-green gradient track when enabled.
```

---

## 💡 Bonus: Additional Prompt Tips

### Jika hasil Stitch kurang bagus, coba tambahkan modifier ini:

```
Additional style modifiers you can append to any prompt:

"Make it look like a premium app similar to Nike Training Club or MyFitnessPal dark mode."

"Add subtle glassmorphism effects on the cards with a blur(10) effect and semi-transparent backgrounds."

"Use smooth gradient transitions between sections. No harsh color boundaries."

"Ensure very generous padding and spacing. Minimum 16px padding inside cards, 12px between elements."

"The design should look like it was designed by a professional UI designer at a top tech company."

"Add micro-interaction hints: subtle scale-up on press for buttons, smooth transitions between states."
```

### Untuk mendapatkan konsistensi antar screen:

```
Append this to each prompt for consistency:

"Follow these exact design tokens:
- Background: #0A0E21
- Surface/Card: #1E2243  
- Primary gradient: #00B4D8 → #92FE9D (left to right)
- Accent: #FF6B35
- Text primary: #FFFFFF
- Text secondary: #8D93AB
- Border radius cards: 16px
- Border radius buttons: 12px
- Border radius inputs: 12px
- Font: Google Sans
- Icon size: 24px in navigation, 48px in feature cards"
```

---

## 📋 Urutan Generate yang Disarankan

| # | Screen | Prioritas |
|---|--------|-----------|
| 1 | Splash Screen | ⭐⭐⭐ |
| 2 | Login Screen | ⭐⭐⭐ |
| 3 | Register Screen | ⭐⭐⭐ |
| 4 | Home Dashboard | ⭐⭐⭐ |
| 5 | Exercise List | ⭐⭐⭐ |
| 6 | Exercise Detail | ⭐⭐ |
| 7 | Workout Plan List | ⭐⭐ |
| 8 | Active Workout Session | ⭐⭐ |
| 9 | Tools Menu | ⭐⭐⭐ |
| 10 | Currency Converter | ⭐⭐ |
| 11 | Timezone Converter | ⭐⭐ |
| 12 | Nearby Gym (Map) | ⭐⭐ |
| 13 | AI Chat | ⭐⭐⭐ |
| 14 | Mini Game | ⭐⭐ |
| 15 | Profile | ⭐⭐⭐ |
| 16 | Saran & Kesan | ⭐⭐ |
| 17 | Edit Profile | ⭐ |
| 18 | Notification Settings | ⭐ |
