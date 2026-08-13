# App Store Connect — Guideline 2.1 (PassKit / Apple Pay)

Paste into **App Store Connect → Resolution Center** reply (and keep in **Review Notes** for future builds).

---

## Reply to App Review (English)

Hello App Review Team,

Thank you for your message regarding Guideline 2.1 (PassKit / Apple Pay).

**Wayo Ads does include Apple Pay.** PassKit is present because we process real wallet top-ups for **Advertiser** accounts via Stripe + Apple Pay.

### Where to find Apple Pay in the app

Apple Pay is **not** available on Creator accounts. Please use an **Advertiser** account:

1. Sign in with the advertiser demo account provided in App Review Information / below.
2. Complete onboarding as **Advertiser** if prompted (not Creator).
3. Open the bottom tab **Wallet**.
4. Enter a deposit amount (for example `50`).
5. Select funding method **Card** (not bank transfer).
6. Tap **Pay with Apple Pay**.

Merchant ID: `merchant.ma.wayo.wayoadsgo`  
Apple Pay is offered on iPhone and iPad when the device supports Apple Pay / Wallet.

### Why it may have been hard to find

If the reviewer signed in as a **Creator**, the Wallet screen shows creator payouts (Stripe Connect) and does **not** show Apple Pay. Apple Pay is only on the **Advertiser → Wallet → Add funds** flow.

Please let us know if you need updated demo credentials or a short screen recording.

Best regards,  
Wayo Ads Team

---

## Review Notes (short — for next submission)

Apple Pay: Advertiser role only → Wallet tab → enter amount → Card funding → “Pay with Apple Pay”.  
Merchant: merchant.ma.wayo.wayoadsgo.  
Not available on Creator accounts. Use the advertiser demo login in App Review Information.
