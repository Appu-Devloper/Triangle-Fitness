# Triangle Fitness Flutter + Firebase App

## 1. Project Overview

This project is a **Gym Website / Gym Management App** built using:

* Flutter
* Firebase Authentication
* Cloud Firestore
* No backend
* No Cloudflare image storage for now

The app opens with a public Home Page. Visitors can see gym details, subscription plans, and published transformations without login.

Members can login using phone number and password.

Admins can login through a hidden admin login access from the Home Page.

---

# 2. What We Built

We created a complete gym management structure with:

## Public Side

Users can open the app without login and see:

* Gym name
* Gym owner/contact details
* Opening and closing time
* Subscription plans
* Published transformations
* Member login button

## Member Side

Members can:

* Login using phone number and password
* First-time login using receipt number as password
* Change password after first login
* View their profile
* View subscription details
* View payment history
* Logout

## Admin Side

Admins can:

* Login using hidden admin access
* View admin dashboard
* View members list
* Add new members
* View member details
* Edit member details
* Renew subscription
* View payments
* Manage subscription plans
* Manage transformations
* Manage settings

---

# 3. Login System

## Admin Login

Admin login uses normal Firebase Auth email/password.

Example:

```txt
Email: trianglefitness.krs@gmail.com
Password: admin password
```

After login, app checks:

```txt
admins/{adminFirebaseUid}
```

If the admin document exists and `isActive == true`, admin can access admin dashboard.

---

## Member Login

Member login uses phone number and password.

Member enters:

```txt
Phone: 9876543210
Password: REC-0101
```

Internally Flutter converts the phone number into Firebase email:

```txt
9876543210@trianglefitness.local
```

Then Firebase Auth login happens using:

```txt
email: 9876543210@trianglefitness.local
password: REC-0101
```

So members do not need to know this internal email. They only enter phone number.

---

# 4. First-Time Password Flow

When a member is created, their initial password is their receipt number.

Example:

```txt
Phone: 9876543210
Receipt No: REC-0101
Initial Password: REC-0101
```

In Firestore:

```txt
mustChangePassword: true
passwordChanged: false
```

After first login, the app sends the member to Change Password Page.

After password change:

```txt
mustChangePassword: false
passwordChanged: true
```

From next login, member must use the new password.

---

# 5. Firebase Collections Created

We created these Firestore collections:

```txt
admins
subscriptions
members
payments
userCredentials
settings
transformations
```

We skipped:

```txt
enquiries
gallery
image storage
```

because they are not needed right now.

---

# 6. Firestore Database Structure

## 6.1 admins

Used to verify admin access.

Document ID must be the actual Firebase Authentication UID.

```txt
admins/{adminFirebaseUid}
```

Example:

```js
{
  "uid": "adminFirebaseUid",
  "name": "Nandhi",
  "email": "trianglefitness.krs@gmail.com",
  "role": "SUPER_ADMIN",
  "isActive": true,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

Important:

```txt
Do not use Auto ID for admins.
Document ID must be Firebase Auth UID.
```

---

## 6.2 subscriptions

Used to store gym subscription plans.

Example documents:

```txt
subscriptions/monthly
subscriptions/quarterly
subscriptions/half_yearly
subscriptions/yearly
```

Example:

```js
{
  "name": "Monthly",
  "durationDays": 30,
  "price": 1196,
  "isActive": true,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

For default plans, manual document IDs are used.

For plans created from UI, Auto ID can be used.

---

## 6.3 members

Used to store member profile and current subscription.

Document ID can be Auto ID.

Example:

```txt
members/2XtNSLwhmfVN5GzSt1Mz
```

Example data:

```js
{
  "uid": "memberFirebaseAuthUid",
  "memberCode": "TF-0001",
  "name": "Test Member",
  "phone": "9876543210",
  "email": "",
  "address": "Test Address",
  "receiptNo": "REC-0101",
  "weightKg": 75,
  "heightCm": 174,

  "subscription": {
    "planId": "monthly",
    "planName": "Monthly",
    "startDate": "timestamp",
    "endDate": "timestamp",
    "status": "ACTIVE",
    "amount": 1196,
    "paymentStatus": "PAID"
  },

  "status": "ACTIVE",
  "createdBy": "adminFirebaseUid",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

Important:

```txt
status should be uppercase: ACTIVE
Do not use Active, active, or other formats.
```

---

## 6.4 userCredentials

Used to connect Firebase Auth UID to member profile.

Document ID must be the actual member Firebase Auth UID.

```txt
userCredentials/{memberFirebaseAuthUid}
```

Example:

```js
{
  "uid": "memberFirebaseAuthUid",
  "memberId": "2XtNSLwhmfVN5GzSt1Mz",
  "memberCode": "TF-0001",
  "phone": "9876543210",
  "loginEmail": "9876543210@trianglefitness.local",

  "initialLoginType": "RECEIPT_NO",
  "mustChangePassword": true,
  "passwordChanged": false,

  "role": "MEMBER",
  "isActive": true,

  "lastLoginAt": null,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

Important:

```txt
No passwordHash is used.
No plain password is stored in Firestore.
Firebase Auth manages the password.
```

---

## 6.5 payments

Used to store all payment and renewal history.

Document ID uses Auto ID.

Example:

```js
{
  "memberId": "2XtNSLwhmfVN5GzSt1Mz",
  "memberCode": "TF-0001",
  "memberName": "Test Member",
  "phone": "9876543210",

  "receiptNo": "REC-0101",
  "amount": 1196,
  "paymentMode": "CASH",
  "paymentStatus": "PAID",

  "paymentDate": "timestamp",
  "subscriptionStartDate": "timestamp",
  "subscriptionEndDate": "timestamp",

  "collectedBy": "adminFirebaseUid",

  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

Used for:

* Member payment history
* Admin payment list
* Collection reports
* Renewal records

---

## 6.6 settings

Used to store public gym profile details.

Document ID:

```txt
settings/gymProfile
```

Example:

```js
{
  "gymName": "Triangle Fitness",
  "ownerName": "Nandhi",
  "phone": "",
  "email": "trianglefitness.krs@gmail.com",
  "address": "",

  "openingTime": "05:00 AM",
  "closingTime": "10:00 PM",

  "instagramUrl": "",
  "facebookUrl": "",
  "whatsappNumber": "",

  "updatedAt": "timestamp"
}
```

This data is shown publicly on the Home Page without login.

---

## 6.7 transformations

Used to store member transformation stories.

No images are used for now.

Example:

```js
{
  "memberId": "2XtNSLwhmfVN5GzSt1Mz",
  "memberCode": "TF-0001",
  "name": "Test Member",

  "title": "3 Months Transformation",
  "description": "Lost 10 KG in 3 Months",

  "weightBeforeKg": 90,
  "weightAfterKg": 80,
  "heightCm": 174,
  "durationText": "3 Months",

  "isPublished": true,
  "displayOrder": 1,

  "uploadedBy": "adminFirebaseUid",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

Only transformations where:

```txt
isPublished == true
```

are shown publicly.

---

# 7. Important Firebase Auth Setup

## Admin Auth User

Created in:

```txt
Firebase Console → Authentication → Users
```

Admin email:

```txt
trianglefitness.krs@gmail.com
```

The admin UID must be used as document ID in:

```txt
admins/{adminFirebaseUid}
```

---

## Member Auth User

For member:

```txt
Phone: 9876543210
Receipt No: REC-0101
```

Firebase Auth user should be:

```txt
Email: 9876543210@trianglefitness.local
Password: REC-0101
```

The generated UID must be used in:

```txt
userCredentials/{memberFirebaseAuthUid}
```

And the same UID must be saved in:

```txt
members/{memberId}.uid
```

---

# 8. Secondary Firebase App for Add Member

When admin creates a new member from Flutter, we should not use the main Firebase Auth instance directly.

If we use:

```dart
FirebaseAuth.instance.createUserWithEmailAndPassword()
```

then Firebase switches current login from admin to newly created member.

To avoid that, we use a secondary Firebase app.

Flow:

```txt
Admin stays logged in using main FirebaseAuth
Secondary FirebaseAuth creates member account
Secondary FirebaseAuth signs out
Admin remains logged in
```

This is the correct Flutter-only method without backend.

---

# 9. App Pages Implemented / Planned

## Public Pages

```txt
Home Page
Member Login Page
```

Home Page shows:

* Gym settings
* Subscription plans
* Published transformations
* Member login button
* Hidden admin login access

---

## Member Pages

```txt
Member Login Page
Change Password Page
Member Dashboard Page
```

Member Dashboard shows:

* Member profile
* Subscription details
* Payment history

---

## Admin Pages

```txt
Admin Login Page
Admin Dashboard Page
Members List Page
Add Member Page
Member Details Page
Edit Member Page
Renew Subscription Page
Payments List Page
Subscriptions Management Page
Transformations Management Page
Settings Page
```

---

# 10. Hidden Admin Login

Admin login is not shown directly.

Instead:

```txt
Long press gym logo/name
```

or:

```txt
Tap gym logo/name 5 times
```

Then Admin Login Page opens.

Admin login checks:

```txt
admins/{currentUser.uid}
```

If `isActive == true`, admin dashboard opens.

---

# 11. Firestore Security Rules

Final rule goal:

* Public can read settings
* Public can read active subscription plans
* Public can read published transformations
* Members can read their own data
* Members can read their own payment history
* Admin can manage members, payments, subscriptions, transformations, and settings

Rules used:

```js
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    function isSignedIn() {
      return request.auth != null;
    }

    function isAdmin() {
      return isSignedIn()
        && exists(/databases/$(database)/documents/admins/$(request.auth.uid))
        && get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.isActive == true;
    }

    function ownsMemberProfile(memberId) {
      return isSignedIn()
        && exists(/databases/$(database)/documents/members/$(memberId))
        && get(/databases/$(database)/documents/members/$(memberId)).data.uid == request.auth.uid;
    }

    match /admins/{adminId} {
      allow read: if isSignedIn() && request.auth.uid == adminId;
      allow write: if false;
    }

    match /settings/{id} {
      allow read: if true;
      allow write: if isAdmin();
    }

    match /subscriptions/{planId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    match /transformations/{id} {
      allow read: if resource.data.isPublished == true || isAdmin();
      allow create, update, delete: if isAdmin();
    }

    match /userCredentials/{uid} {
      allow read: if isAdmin() || request.auth.uid == uid;

      allow update: if isAdmin() ||
        (
          request.auth.uid == uid &&
          request.resource.data.diff(resource.data).changedKeys()
            .hasOnly(['mustChangePassword', 'passwordChanged', 'lastLoginAt', 'updatedAt'])
        );

      allow create, delete: if isAdmin();
    }

    match /members/{memberId} {
      allow read: if isAdmin() || ownsMemberProfile(memberId);
      allow create, update, delete: if isAdmin();
    }

    match /payments/{paymentId} {
      allow read: if isAdmin() || ownsMemberProfile(resource.data.memberId);
      allow create, update, delete: if isAdmin();
    }
  }
}
```

---

# 12. Step-by-Step Process We Followed

## Step 1: Firebase Project Setup

We selected the correct Firebase project using:

```bash
flutterfire configure
```

This generated:

```txt
lib/firebase_options.dart
```

Then Firebase was initialized in Flutter using:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## Step 2: Created Firestore Collections

We created:

```txt
admins
subscriptions
members
payments
userCredentials
settings
transformations
```

---

## Step 3: Created Admin Access

We created Firebase Auth admin user.

Then we created:

```txt
admins/{adminFirebaseUid}
```

This allows admin verification after login.

---

## Step 4: Created Subscription Plans

We created default plans like:

```txt
monthly
quarterly
half_yearly
yearly
```

These are shown on the public Home Page and used while adding/renewing members.

---

## Step 5: Created Test Member

We created a test member in `members`.

Then we created a Firebase Auth member user:

```txt
9876543210@trianglefitness.local
```

Then we connected it through:

```txt
userCredentials/{memberFirebaseAuthUid}
```

---

## Step 6: Fixed Firestore Rules

Initially login worked but Firestore gave:

```txt
permission-denied
```

We fixed rules to allow:

* Members to read own `userCredentials`
* Members to read own `members` document
* Admin to read own `admins` document

---

## Step 7: Built Member Login

Member enters phone and password.

Flutter converts:

```txt
9876543210
```

to:

```txt
9876543210@trianglefitness.local
```

Then Firebase Auth login happens.

---

## Step 8: Built Change Password

If:

```txt
mustChangePassword == true
```

member is sent to Change Password Page.

After password update:

```txt
mustChangePassword = false
passwordChanged = true
```

---

## Step 9: Built Member Dashboard

Member Dashboard loads:

```txt
userCredentials/{uid}
members/{memberId}
payments where memberId == current memberId
```

It shows:

* Profile
* Subscription
* Payment history

---

## Step 10: Built Hidden Admin Login

Admin login is opened using hidden action from Home Page.

After admin login, app checks:

```txt
admins/{uid}
```

---

## Step 11: Built Admin Features

Admin pages planned/implemented:

* Dashboard
* Add Member
* Members List
* Member Details
* Edit Member
* Renew Subscription
* Payments List
* Subscriptions Management
* Transformations Management
* Settings Page

---

# 13. What Needs to Be Tested

## Public Home Page Testing

Test without login:

```txt
1. Open app
2. Home Page should open directly
3. Gym name should show from settings/gymProfile
4. Contact details should show
5. Subscription plans should show
6. Published transformations should show
7. Unpublished transformations should not show
```

---

## Member Login Testing

Test:

```txt
Phone: 9876543210
Password: new password
```

Check:

```txt
1. Login success
2. Member dashboard opens
3. Member profile is correct
4. Subscription details are correct
5. Payment history is visible
6. Logout works
```

---

## First Login Testing

Create a new member.

Login with:

```txt
Phone: new member phone
Password: receipt number
```

Check:

```txt
1. Change Password Page opens
2. New password saves correctly
3. Firestore updates:
   mustChangePassword = false
   passwordChanged = true
4. Old receipt number password no longer works
5. New password works
```

---

## Admin Login Testing

Test:

```txt
1. Open Home Page
2. Long press gym name/logo
3. Admin Login Page opens
4. Login with admin email/password
5. Admin dashboard opens
```

If permission error comes, check:

```txt
admins document ID must match Firebase Auth UID
```

---

## Add Member Testing

Test admin adding new member.

Check that these are created:

```txt
1. Firebase Auth user
2. members document
3. userCredentials document
4. payments document
```

Also check:

```txt
1. Admin remains logged in
2. New member can login using phone + receipt number
3. New member is forced to change password
```

---

## Members List Testing

Check:

```txt
1. All members show
2. Search by name works
3. Search by phone works
4. Search by memberCode works
5. Filter ACTIVE works
6. Filter INACTIVE works
7. Filter EXPIRED works
8. Tapping member opens Member Details
```

---

## Member Details Testing

Check:

```txt
1. Profile details show correctly
2. Subscription details show correctly
3. Payment history shows correctly
4. Edit Member button works
5. Renew Subscription button works
```

---

## Renew Subscription Testing

Check:

```txt
1. Select plan
2. Amount auto fills
3. End date auto calculates
4. Save renewal
5. Member subscription updates
6. New payment document is created
7. Member dashboard shows new subscription
```

---

## Edit Member Testing

Check:

```txt
1. Edit name/address/weight/height/status
2. Save changes
3. Member document updates
4. userCredentials memberCode/phone updates if needed
```

Important:

```txt
Changing phone in Firestore does not automatically change Firebase Auth login email.
A separate Change Login Phone feature is needed later.
```

---

## Payments Testing

Check:

```txt
1. Payments list shows all records
2. Search by receipt number works
3. Search by member name works
4. Filter by PAID/PENDING works
5. Filter by payment mode works
6. Total collection calculation is correct
```

---

## Subscription Management Testing

Check:

```txt
1. Add new subscription plan
2. Edit plan price
3. Deactivate plan
4. Deactivated plan does not show in Add Member/Renew Subscription dropdown
```

---

## Transformations Testing

Check:

```txt
1. Add transformation
2. Publish transformation
3. It appears on public Home Page
4. Unpublish transformation
5. It disappears from public Home Page
```

---

## Settings Testing

Check:

```txt
1. Update gymName
2. Update phone/email/address
3. Update opening/closing time
4. Home Page shows updated data
```

---

# 14. What We Need to Do in Future

## 14.1 Image Upload

Currently image upload is skipped because Cloudflare required a card.

Future image options:

```txt
Option 1: Cloudflare Images
Option 2: Firebase Storage
Option 3: Supabase Storage
```

When image upload is added, we can add these fields.

In `members`:

```js
"profileImage": {
  "url": "",
  "imageId": ""
}
```

In `transformations`:

```js
"beforeImage": {
  "url": "",
  "imageId": ""
},
"afterImage": {
  "url": "",
  "imageId": ""
}
```

---

## 14.2 Attendance

Future collection:

```txt
attendance
```

Example:

```js
{
  "memberId": "",
  "memberCode": "",
  "name": "",
  "date": "2026-06-13",
  "checkInTime": "timestamp",
  "checkOutTime": "timestamp",
  "createdAt": "timestamp"
}
```

Can add:

* Manual attendance
* QR scan attendance
* Daily attendance report

---

## 14.3 Receipt PDF

Future feature:

* Generate payment receipt PDF
* Share on WhatsApp
* Download receipt
* Print receipt

---

## 14.4 WhatsApp Reminder

Future feature:

* Remind members before subscription expiry
* Send due payment reminders
* Send renewal messages

Without backend, this can be semi-manual.

With backend, it can be automatic.

---

## 14.5 Push Notifications

Future feature:

* Subscription expiry reminder
* Payment due notification
* Gym announcements
* Offers

Can use Firebase Cloud Messaging.

---

## 14.6 Better Admin Roles

Currently:

```txt
SUPER_ADMIN
MEMBER
```

Future roles:

```txt
SUPER_ADMIN
ADMIN
STAFF
TRAINER
MEMBER
```

---

## 14.7 Change Login Phone

Currently phone change updates Firestore only.

Future flow needed:

```txt
Change phone number
Update Firebase Auth email
Update userCredentials.loginEmail
Update members.phone
```

This needs careful validation.

---

## 14.8 Member App Improvements

Future member features:

* Workout plan
* Diet plan
* Attendance history
* Progress tracking
* BMI calculation
* Transformation request
* Payment receipt download

---

## 14.9 Reports

Future admin reports:

* Daily collection
* Monthly collection
* Active members
* Expired members
* Pending payments
* New members this month
* Renewal report

---

# 15. Important Notes

## Do Not Store Password in Firestore

We do not store:

```txt
password
passwordHash
```

Firebase Auth manages password securely.

---

## Use Uppercase Status

Use:

```txt
ACTIVE
INACTIVE
EXPIRED
BLOCKED
PAID
PENDING
```

Do not mix:

```txt
Active
active
paid
Paid
```

---

## Document ID Rules

Use Firebase Auth UID as document ID for:

```txt
admins
userCredentials
```

Use Auto ID for:

```txt
members
payments
transformations
```

Use manual ID for:

```txt
settings/gymProfile
subscriptions/monthly
subscriptions/quarterly
subscriptions/half_yearly
subscriptions/yearly
```

---

# 16. Final Current Status

Current app status:

```txt
Core gym app is ready.
Firebase structure is ready.
Member login is ready.
Admin login is ready.
Public home page data is ready.
Firestore rules are ready.
Admin management pages are planned/implemented step by step.
```

Next main focus:

```txt
Full testing
Bug fixing
UI polish
Future image upload
```

---

# 17. Simple App Flow Summary

```txt
App opens
↓
Home Page opens without login
↓
Visitor can see plans/settings/transformations
↓
Member clicks Member Login
↓
Member logs in with phone + password
↓
If first login, change password
↓
Member dashboard opens
```

Admin flow:

```txt
Home Page
↓
Long press gym name/logo
↓
Admin Login
↓
Admin Dashboard
↓
Manage members, payments, plans, settings, transformations
```

This is the complete Flutter + Firebase-only gym app structure.
