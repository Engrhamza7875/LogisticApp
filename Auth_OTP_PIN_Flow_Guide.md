# SabCargo Auth Flow Guide (MongoDB + Backend + Flutter)

This document defines the exact authentication flow for your existing SabCargo setup, while keeping:

- the MongoDB Atlas database configured by the backend
- the same Node.js backend (`backend/server.js`)
- the same Flutter frontend structure

It is a functional flow document you can implement directly.

---

## 1) Registration Flow

### Goal
Allow user registration with email verification before login.

### Input
- Name
- Email
- Phone

### Backend Process
On `Register` click:
1. Validate name/email/phone format.
2. Check email is unique.
3. Create user with:
   - `isVerified = false`
   - `pin = NULL` (or empty until PIN set)
4. Generate OTP (6 digits).
5. Hash OTP using `bcrypt`.
6. Save OTP with:
   - `userId`
   - `otpHash`
   - `expiresAt = now + 2 minutes`
   - `used = false`
7. Send OTP to user email.
8. Return success and redirect user to OTP verification screen.

---

## 2) OTP Verification Flow

### OTP Security Rules
- Expires after **2 minutes**
- Single-use only
- Stored hashed (never plain text)
- Only one active OTP per user

### Backend Process
On OTP submit:
1. Find latest active OTP for user.
2. Check `used == false`.
3. Check `expiresAt > now`.
4. Compare entered OTP with stored hash (`bcrypt.compare`).
5. If valid:
   - mark OTP `used = true`
   - set user `isVerified = true`
   - redirect to Login screen
6. If expired:
   - return `OTP expired, request a new one`
7. If invalid:
   - return `Invalid OTP`

---

## 3) Login Flow (Email/Phone + PIN)

### Goal
Allow only verified users with correct PIN.

### Backend Process
1. Accept login input: email/phone + PIN.
2. Find user by email or phone.
3. Ensure `isVerified = true`.
4. Compare PIN using bcrypt hash.
5. If valid:
   - issue JWT token
   - return user profile + token
6. If incorrect:
   - return `Incorrect PIN. Please try again or reset your PIN`

---

## 4) Reset PIN Flow

### Step A: Request Reset OTP
1. User clicks `Forgot PIN`.
2. User enters email.
3. Backend generates new OTP.
4. New OTP must invalidate old OTP:
   - mark previous OTPs for user as `used = true` (or inactive)
5. Store new OTP hashed with 2-minute expiry.
6. Send OTP via email.

### Step B: Verify OTP + Set New PIN
1. User enters OTP.
2. Validate OTP with same rules (not used, not expired, hash match).
3. If valid:
   - allow set new PIN
   - hash new PIN with bcrypt
   - update user PIN hash
   - mark OTP as used

---

## 5) Mandatory OTP Rules

1. Only one active OTP per user at a time.
2. Generating new OTP invalidates all previous OTPs.
3. OTP expires in 2 minutes.
4. OTP cannot be reused after successful verification.

---

## 6) Backend Requirements

### Security
- Use JWT for authenticated endpoints.
- Hash both PIN and OTP using bcrypt.
- Never store plain PIN/OTP.

### Validation
- Validate email format.
- Validate phone format.
- Enforce unique email.

### Required User Fields
- `name`
- `email`
- `phone`
- `pinHash`
- `isVerified`

### Required OTP Fields
- `userId`
- `otpHash`
- `expiresAt`
- `used`
- `createdAt`

---

## 7) MongoDB collections

The backend stores authentication records in `users` and `userOtps`. PINs and OTPs are bcrypt hashes. OTP documents include `userId`, `expiresAt`, `used`, and `createdAt`. Configure the Atlas URI only in the backend environment.

---

## 8) API Endpoint Flow (Backend)

Suggested endpoints for this flow:

- `POST /api/auth/register`
- `POST /api/auth/verify-otp`
- `POST /api/auth/login`
- `POST /api/auth/request-pin-reset`
- `POST /api/auth/verify-reset-otp`
- `POST /api/auth/set-new-pin`

JWT-protected example:
- `GET /api/profile` with `Authorization: Bearer <token>`

---

## 9) Flutter UI Screens (Required)

Implement/keep these screens with loading and error states:

1. Registration Screen
   - name/email/phone inputs
   - loading button
   - backend error message

2. OTP Verification Screen
   - OTP input
   - countdown (2 minutes)
   - resend OTP action

3. Login Screen
   - email/phone + PIN input
   - show exact incorrect PIN message

4. Reset PIN Screen
   - enter email
   - OTP verification
   - set new PIN form

---

## 10) Error Messages (User-Facing)

Use consistent messages from backend:

- `OTP expired, request a new one`
- `Invalid OTP`
- `Incorrect PIN. Please try again or reset your PIN`
- `Email already exists`
- `User not verified. Please verify OTP first`

---

## 11) Implementation Notes for Current Project

- Keep the MongoDB URI only in backend environment configuration (`MONGODB_URI`).
- Keep current Flutter service layer and add new auth methods there.
- Update backend queries to use hashed fields (`PinHash`, `OtpHash`).
- Add JWT middleware for protected routes.
- Add email sending service (SMTP / provider API) for OTP delivery.

---

## 12) Minimum Test Checklist

1. Register with new email -> OTP sent.
2. Verify OTP within 2 minutes -> success.
3. Verify same OTP again -> fail (used).
4. Wait >2 minutes -> OTP expired message.
5. Login with wrong PIN -> correct error message.
6. Reset PIN -> old OTP invalidated when new one generated.
7. Login with new PIN -> success, old PIN fails.
