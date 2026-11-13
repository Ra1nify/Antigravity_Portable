/**
 * Antigravity Portable Bootstrap Hook
 * Injected into dist/main.js to isolate all configurations, userdata,
 * extensions, and cache into the local './data' folder adjacent to the application.
 */
(function() {
    const path = require('path');
    const fs = require('fs');

    // Determine the root portable directory:
    // - On macOS: execPath is <rootDir>/Antigravity.app/Contents/MacOS/Antigravity
    // - On Windows: execPath is <rootDir>/Antigravity.exe
    // - On Linux: execPath is <rootDir>/Antigravity
    const isMac = process.platform === 'darwin';
    const rootDir = isMac
        ? path.dirname(path.resolve(path.dirname(process.execPath), '../../..'))
        : path.dirname(process.execPath);

    const portableData = path.join(rootDir, 'data');

    // Ensure the data directory exists
    try {
        if (!fs.existsSync(portableData)) {
            fs.mkdirSync(portableData, { recursive: true });
        }
    } catch (_) {}

    // Redirect environment variables before any core module evaluates them
    if (process.platform === 'win32') {
        process.env.USERPROFILE = portableData;
        process.env.APPDATA = path.join(portableData, 'AppData', 'Roaming');
        process.env.LOCALAPPDATA = path.join(portableData, 'AppData', 'Local');
    } else {
        process.env.HOME = portableData;
        process.env.XDG_CONFIG_HOME = path.join(portableData, '.config');
        process.env.XDG_DATA_HOME = path.join(portableData, '.local', 'share');
    }

    // Redirect Electron userData directory
    try {
        const { app } = require('electron');
        if (app && typeof app.setPath === 'function') {
            app.setPath('userData', path.join(portableData, 'UserData'));
        }
    } catch (_) {}
})();
