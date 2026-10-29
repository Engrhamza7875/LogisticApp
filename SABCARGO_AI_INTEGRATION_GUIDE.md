# 🚀 Sabcargo AI Integration: Step-by-Step Guide

This document is designed to help you understand exactly how the AI was integrated into the Sabcargo app so that you can maintain it, update it, or rebuild it yourself in the future.

---

## 🛠️ Phase 1: Provider Setup (OpenRouter)

We switched to **OpenRouter** because it provides better quota management and more reliable access to the Gemini 2.0 Flash model.

1.  **Get an API Key**: Go to [OpenRouter.ai](https://openrouter.ai/keys), create an account, and generate a new key.
2.  **Model Selection**: We use `google/gemini-2.0-flash-001`. It is fast, cheap, and highly intelligent for logistics.

---

## 📦 Phase 2: Flutter Project Configuration

To talk to the AI API over the internet, we need the `http` package.

1.  **Open `pubspec.yaml`**: Ensure the `http` dependency is added.
    ```yaml
    dependencies:
      http: ^1.2.0
    ```
2.  **Internet Permissions**: 
    - In `android/app/src/main/AndroidManifest.xml`, ensure this line is present to allow the app to use the internet:
    ```xml
    <uses-permission android:name="android.permission.INTERNET"/>
    ```

---

## 🧠 Phase 3: The AI Service Layer (`lib/services/ai_service.dart`)

This is the "Brain" of the integration. It handles the API calls.

### 1. Configuration
Define your `_apiKey` and the `_baseUrl` for OpenRouter.
```dart
static const String _apiKey = 'YOUR_KEY_HERE';
static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
```

### 2. The System Instruction (The Persona)
This is a long text variable that tells the AI who it is. 
> [!TIP]
> **To change rates or routes later**, simply update the text inside the `_systemInstruction` variable in this file!

### 3. The API Call Logic
The `getChatResponse` function does the following:
- Sends a **POST** request to OpenRouter.
- Passes the **System Instruction** (telling it the rules).
- Passes the **User Prompt** (the question).
- Receives the JSON response and extracts the text message.

---

## 🎨 Phase 4: UI Integration (`lib/screens/chatbot_screen.dart`)

This is the interface the user sees.

1.  **State Management**: We use a `List<ChatMessage>` to store the conversation history.
2.  **Sending a Message**:
    - Add user's text to the list.
    - Set `_isTyping = true` (triggers the animation).
    - Call `_aiService.getChatResponse(text)`.
    - Once the response arrives: Add the AI response to the list and set `_isTyping = false`.
3.  **Quick Replies**: Pre-made buttons (ActionChips) that trigger the `_sendMessage` function automatically for common questions like "Track My Order."

---

## 📋 Phase 5: Essential Business Data

To keep the client happy, the AI is programmed with these specific facts:

*   **Standard Rate**: 30 SAR per kg.
*   **Offices**: Al Olaya (Head), Al Shifa (South), Airport Cargo Center.
*   **Key Routes**: Pakistan, Bangladesh, India, Philippines, Indonesia, etc.
*   **Tracking Rules**: Explains how to use the "Orders" tab and tracking search bar.

---

## 🛡️ Best Practices for Next Time

- **Timeout**: Always add a `.timeout()` (e.g., 30 seconds) to your API calls so the app doesn't hang if the internet is slow.
- **Clear Errors**: Don't just show a generic "Error." Catch specific errors like `SocketException` (No Internet) so the user knows what to fix.
- **Model Versions**: If a model stops working, check the [OpenRouter Documentation](https://openrouter.ai/models) for the newest model string (e.g., `google/gemini-2.0-flash`).

---

© 2026 Sabcargo | Technical Implementation Strategy
