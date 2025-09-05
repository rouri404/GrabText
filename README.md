<div align="center">
  <h1>GrabText</h1>
  <p>
    <img src="https://img.shields.io/badge/version-1.2.0-blue" alt="Version">
    <img src="https://img.shields.io/badge/Platform-Linux-lightgrey" alt="Platform">
    <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
    <img src="https://img.shields.io/badge/status-active-success" alt="Status">
    <a href="README.pt.md"><img src="https://img.shields.io/badge/Language-Português%20%F0%9F%87%A7%F0%9F%87%B7-blue" alt="Português"></a>
  </p>
    <p>
    Capture and copy text from any image or video on your screen. A simple yet powerful OCR tool for Linux-based systems.
  </p>
</div>

---

## About the Project

<div align="center">
  <img src="preview.gif" width="70%" alt="Preview">
</div>

**GrabText** is a productivity tool that streamlines the process of capturing text from anywhere on your screen. Whether it's from an image, a video, a protected document, or a web page, simply select the desired area, and the text will be recognized and copied to your clipboard instantly.

It utilizes **Tesseract** for character recognition and **Flameshot** for intuitive screen selection.

---

## Features

*   **Multilingual OCR:** Robust support for text recognition in English (`en`) and Portuguese (`pt`).
*   **Intuitive Screen Capture:** Use the Flameshot interface to easily select the desired screen area.
*   **Instant Copy:** Recognized text is automatically copied to the clipboard.
*   **Flexible Configuration:** Switch the OCR language using an environment variable, as needed.
*   **Activity Logging:** Detailed logs are generated to facilitate debugging.

---

## Compatibility

This project was developed and tested to work on major Linux desktop environments. Shortcut automation is most effective in the following environments:

*   **Ideal Support Environments:** GNOME, XFCE
*   **Guided Support Environments:** KDE Plasma
*   **Supported Distributions:** Any `apt`-based (Debian, Ubuntu), `pacman`-based (Arch Linux), `dnf`-based (Fedora), or `zypper`-based (openSUSE) distribution.

---

## Installation

1.  **Clone this repository:**
    ```bash
    git clone https://github.com/rouri404/GrabText.git
    cd GrabText
    ```

2.  **Make the installation script executable:**
    ```bash
    chmod +x install.sh
    ```

3.  **Run the installer:**
    ```bash
    ./install.sh
    ```
    The script will ask for your password to install system packages (if not already installed) and configure the rest of the environment.

---

## Manual Installation and Prerequisites

If the `install.sh` script encounters any errors, you can manually install the dependencies with the following commands:

#### For Arch Linux and derivatives (Manjaro, EndeavourOS)
```bash
sudo pacman -S flameshot tesseract tesseract-data-por tesseract-data-eng xclip python-pip libnotify
```

#### For Debian, Ubuntu, and derivatives (Mint, Pop!_OS)
```bash
sudo apt install flameshot tesseract-ocr tesseract-ocr-por tesseract-ocr-eng xclip python3-pip libnotify-bin
```

#### For Fedora
```bash
sudo dnf install flameshot tesseract tesseract-langpack-por langpacks-eng xclip python3-pip libnotify
```

#### For openSUSE
```bash
sudo zypper install flameshot tesseract-ocr tesseract-ocr-data-por tesseract-ocr-eng xclip python3-pip libnotify-tools
```
After manual installation, continue with step 2 in the **Installation** section above.

---

## How to Use

1.  Press the `INSERT` key.
2.  The capture interface will appear. Select the desired area of the screen with the text.
3.  Press `Enter` or click the `✓` (Confirm) icon.
4.  The extracted text will be in your clipboard, ready to be pasted with `Ctrl+V`.

### Forcing OCR Language

You can force the OCR language (between English `en` and Portuguese `pt`) using the `GRABTEXT_LANG` environment variable.

*   **For a single execution:**
    ```bash
    GRABTEXT_LANG=en ./launch.sh
    ```
    or
    ```bash
    GRABTEXT_LANG=pt ./launch.sh
    ```

*   **To set permanently (e.g., in .bashrc or .zshrc):**
    Add the line below to the end of your shell configuration file (e.g., `~/.bashrc`):
    ```bash
    export GRABTEXT_LANG=en
    ```
    After editing the file, run `source ~/.bashrc` (or the corresponding file) to apply the change immediately.

---

## Troubleshooting and FAQ

<details>
  <summary><strong>The shortcut was not created automatically. How do I configure it manually?</strong></summary>
  
  If automation failed or was skipped, you can configure the shortcut manually in a few steps. The command you'll need to use is the absolute path to the `launch.sh` script, which the installer created for you.
  
  **Example Command:** `/home/your-user/'Desktop'/GrabText/launch.sh`

  Follow the guide corresponding to your desktop environment:

  #### For GNOME (Ubuntu, Fedora)
  1.  Open **Settings** > **Keyboard** > **Keyboard Shortcuts**.
  2.  Scroll to **Custom Shortcuts** and click the `+`.
  3.  Fill in the fields:
      * **Name:** `GrabText`
      * **Command:** Enter the full path to the `launch.sh` file.
      * **Shortcut:** Press the `INSERT` key.
  4.  Click "Add".

  #### For KDE Plasma
  1.  Open **System Settings** > **Shortcuts** > **Custom Shortcuts**.
  2.  Go to `Edit` > `New` > `Global Shortcut` > `Command/URL`.
  3.  Fill in the fields:
      * **Name:** `GrabText`
      * **Trigger** tab: Press the `INSERT` key.
      * **Action** tab: In the "Command/URL" field, enter the full path to `launch.sh`.
  4.  Click "Apply".

  #### For XFCE
  1.  Go to **Settings** > **Keyboard** > **Application Shortcuts**.
  2.  Click **"Add"**.
  3.  In the "Command" field, enter the full path to `launch.sh`.
  4.  When the system asks for the key, press `INSERT`.
</details>

<details>
  <summary><strong>OCR does not extract any text or the result is incorrect.</strong></summary>
  
  OCR quality depends 99% on image quality. Remember best practices:
  * **High Contrast:** Dark text on a light, solid background works best.
  * **Standard Fonts:** Very artistic or small fonts are difficult to read.
  * **Good Resolution:** If the text on the screen is small, use zoom (`Ctrl` + `+`) in the application before capturing the screen.
</details>

<details>
  <summary><strong>How can I customize the appearance of the capture interface?</strong></summary>
  
  The interface appearance is controlled by Flameshot. To customize colors, buttons, and opacity, run the following command in the terminal:
  ```bash
  flameshot config
  ```
  The `install.sh` already applies a minimalist initial configuration, but you can adjust it as you prefer through this panel. If the appearance doesn't change after editing, try completely closing Flameshot with `killall flameshot` and triggering the shortcut again.
</details>

<details>
  <summary><strong>Where can I find logs for debugging?</strong></summary>
  
  GrabText now generates a log file named `grabtext.log` in the project directory. This log is always in English and has a clean, structured format, which facilitates the identification and debugging of any issues that may arise during the tool's execution. You can consult it for detailed information about the OCR process and other operations.
</details>

---

## Uninstallation

To remove GrabText and its components:

1.  Navigate to the project folder.
2.  Make the uninstaller executable:
    ```bash
    chmod +x uninstall.sh
    ```
3.  Run the script and follow the instructions:
    ```bash
    ./uninstall.sh
    ```
