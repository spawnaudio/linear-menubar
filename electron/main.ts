import path from "node:path";
import { app, ipcMain, nativeImage, Tray } from "electron";
import { menubar } from "menubar";
import { fetchIssues, hasApiKey } from "./linear";

const isDev = process.env.NODE_ENV === "development";
const devServerUrl = process.env.VITE_DEV_SERVER_URL ?? "http://127.0.0.1:5173";

function createTrayIcon(): Tray {
  const iconPath = path.join(__dirname, "assets", "iconTemplate.png");
  const image = nativeImage.createFromPath(iconPath);
  image.setTemplateImage(true);
  return new Tray(image.isEmpty() ? nativeImage.createEmpty() : image);
}

function registerIpc(): void {
  ipcMain.handle("linear:hasApiKey", () => hasApiKey());
  ipcMain.handle("linear:fetchIssues", () => fetchIssues());
}

app.whenReady().then(() => {
  registerIpc();

  const mb = menubar({
    tray: createTrayIcon(),
    index: isDev ? devServerUrl : `file://${path.join(__dirname, "..", "dist", "index.html")}`,
    tooltip: "Linear Menubar — focus timer",
    browserWindow: {
      width: 392,
      height: 560,
      webPreferences: {
        preload: path.join(__dirname, "preload.js"),
        contextIsolation: true,
        nodeIntegration: false,
      },
    },
  });

  mb.on("ready", () => {
    // On Linux there may be no system tray host, so open the window up front
    // to make the app usable regardless of the desktop environment.
    if (process.platform === "linux") {
      mb.showWindow();
    }
  });

  mb.on("after-create-window", () => {
    if (isDev) {
      mb.window?.webContents.openDevTools({ mode: "detach" });
    }
  });
});

app.on("window-all-closed", () => {
  // Keep running in the menubar; do not quit when the popover closes.
});
