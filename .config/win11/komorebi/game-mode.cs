// One-click switch between gaming and the normal desktop, run from the Desktop
// shortcuts (and Stream Deck buttons) that setup.ps1 creates.
//
//   game-mode.exe       closes what gets in the way of games: YASB, komorebi
//                       (which shows its hidden windows again as it stops),
//                       whkd, masir and f.lux, and stops Wallpaper Engine's
//                       wallpapers.
//   game-mode.exe off   starts them again: start-desktop.exe for the window
//                       manager stack, since komorebi needs its foreground
//                       trick, then f.lux and the wallpapers.
//
// Wallpaper Engine has no quit command, and killing it makes its next start
// report a crash and offer a safe start. `-control stop` instead frees its GPU
// load and most of its video memory (about 0.8 GB here) while the app stays up.
// f.lux likewise only resets the displays' colour (gamma) ramps when it quits
// normally; killed, it leaves the screen warm until something resets them.
//
// kanata, Riot Vanguard and device software (G Hub, Synapse, Stream Deck) stay.
// install.sh builds it with the .NET Framework csc.exe that ships with Windows.
using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.Win32;

static class Program {
  static readonly string Here =
      Path.GetDirectoryName(Process.GetCurrentProcess().MainModule.FileName);
  static readonly string Flux =
      Path.Combine(Environment.GetEnvironmentVariable("LOCALAPPDATA"),
                   @"FluxSoftware\Flux\flux.exe");
  static readonly string Yasbc = Path.Combine(
      Environment.GetEnvironmentVariable("ProgramFiles"), @"YASB\yasbc.exe");

  static void Main(string[] args) {
    if (args.Length > 0 && args[0] == "off")
      Desktop();
    else
      Game();
  }

  static void Game() {
    Run(Yasbc, "stop");
    Run("komorebic.exe", "stop --whkd --masir");
    string wallpaper = WallpaperEngine();
    if (wallpaper != null && Running("wallpaper64"))
      Run(wallpaper, "-control stop");
    Quit("flux", "f.lux:");
  }

  static void Desktop() {
    Start(Path.Combine(Here, "start-desktop.exe"), "");
    if (!Running("flux"))
      Start(Flux, "/noshow");
    string wallpaper = WallpaperEngine();
    if (wallpaper != null)
      Start(wallpaper, Running("wallpaper64") ? "-control play" : "");
  }

  // The Wallpaper Engine service, which starts the app at logon, names its
  // path, so a moved Steam library needs no change here.
  static string WallpaperEngine() {
    var path = Registry.GetValue(
        @"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Wallpaper " +
            @"Engine Service",
        "ImagePath", null) as string;
    if (path == null)
      return null;
    Match m = Regex.Match(path, "-p \"([^\"]+)\"");
    return m.Success ? m.Groups[1].Value : null;
  }

  static bool Running(string name) {
    return Process.GetProcessesByName(name).Length > 0;
  }

  delegate bool EnumProc(IntPtr hwnd, IntPtr lParam);
  [DllImport("user32.dll")]
  static extern bool EnumWindows(EnumProc proc, IntPtr lParam);
  [DllImport("user32.dll")]
  static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)]
  static extern int GetWindowText(IntPtr hwnd, StringBuilder text, int max);
  [DllImport("user32.dll")]
  static extern bool PostMessage(IntPtr hwnd, uint msg, IntPtr w, IntPtr l);

  // Quits a tray app the way its own Quit does: WM_CLOSE to its (hidden) main
  // window, found by its title prefix. Kills it only if it is still up after 5
  // s.
  static void Quit(string name, string titlePrefix) {
    foreach (var p in Process.GetProcessesByName(name)) {
      uint id = (uint)p.Id;
      EnumWindows((hwnd, l) => {
        uint pid;
        GetWindowThreadProcessId(hwnd, out pid);
        var title = new StringBuilder(256);
        if (pid == id && GetWindowText(hwnd, title, title.Capacity) > 0 &&
            title.ToString().StartsWith(titlePrefix))
          PostMessage(hwnd, 0x10, IntPtr.Zero, IntPtr.Zero); // WM_CLOSE
        return true;
      }, IntPtr.Zero);
      try {
        if (!p.WaitForExit(5000))
          p.Kill();
      } catch (Exception) {
      }
      p.Dispose();
    }
  }

  static void Run(string file, string args) {
    try {
      using (var p = Start(file, args)) if (p != null) p.WaitForExit(15000);
    } catch (Exception) {
    }
  }

  static Process Start(string file, string args) {
    var info = new ProcessStartInfo(file, args) { UseShellExecute = false,
                                                  CreateNoWindow = true };
    try {
      return Process.Start(info);
    } catch (Exception) {
      return null;
    }
  }
}
