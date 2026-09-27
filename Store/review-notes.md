# App Review notes

---

No account, login or network connection is required.

PRIVACY: no data is collected. Everything is stored on the device in the app's Documents folder. No account, analytics, advertising or third-party SDKs.

HOW TO USE: On first launch the app asks two questions (bedtime and usual drink) and shows today's cutoff. The Today tab shows "Latest coffee" (the latest time the user's usual drink can be had while still being under their "sleep line" at bedtime), a countdown, the caffeine curve for the day (drag across it to read values), today's drinks and the daily total. The cup button logs a drink; each drink tile shows its own cutoff. Week shows the last seven nights. Sleep holds bedtime, usual drink, sensitivity, sleep line and reminders. "How Cutoff works" explains the model and lists 7 cited sources with DOI links (Sleep tab, and the link at the bottom of Today).

HEALTH INFORMATION: The app does arithmetic on a published pharmacokinetic model (first-order absorption and elimination) with a user-selectable half-life. Every figure is cited in the app's Sources screen: Drake et al. 2013 (J Clin Sleep Med, doi 10.5664/jcsm.3170), Nehlig 2018 (Pharmacol Rev, doi 10.1124/pr.117.014407), EFSA 2015 (doi 10.2903/j.efsa.2015.4102), Blanchard and Sawers 1983 (doi 10.1007/BF00613933), Clark and Landolt 2017 (doi 10.1016/j.smrv.2016.01.006), the FDA's 400 mg guidance and USDA FoodData Central. The app states it is not medical advice.

NOTIFICATIONS AND LIVE ACTIVITY: only if the user turns on "Last-call reminder" (Pro) does the app ask for notification permission; reminders are local. The Lock Screen countdown (Pro) is a Live Activity started by the user from the Sleep tab.

IN-APP PURCHASE: the app is free. There is one non-consumable purchase, Cutoff Pro (com.mattbusel.cutoff.pro). Free: the cutoff, the curve, logging any built-in drink. Pro: custom half-life and sleep line, custom drinks, the Week tab, the last-call reminder and the Lock Screen countdown. To see the paywall: open the Week tab, or tap Fast/Slow under "How long it lasts in you" on the Sleep tab, or "Your own drink" when logging, or See Pro on the Cutoff Pro card on the Sleep tab. Restore purchase is on the paywall and on that card.

2. PURPOSE AND TARGET AUDIENCE
Helps adults time their caffeine so it doesn't interfere with sleep. General audience of coffee drinkers; rated 4+.

3. SETUP AND ACCESS
No login. Two onboarding questions.

4. EXTERNAL SERVICES, TOOLS AND PLATFORMS
None. No network requests, analytics or third-party frameworks. SwiftUI, ActivityKit/WidgetKit (Live Activity), UserNotifications (local), StoreKit 2.

5. REGIONAL DIFFERENCES
None.

6. REGULATED INDUSTRY / PROTECTED MATERIAL
Not applicable. Not a medical device and gives no diagnosis or treatment. All art, text and code are my own work.
