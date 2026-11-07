// Open a program on the monitor under the mouse: launch-on-cursor-monitor.exe
// <program> [args...] whkd runs it for Win+T, Win+B and Hyper+E. It is compiled
// C# instead of a PowerShell script because a cold PowerShell costs ~0.6 s per
// keypress; install.sh builds it with the .NET Framework csc.exe that ships
// with Windows.
//
// komorebi tiles a new window on the monitor where it first appears. The
// program is started with that monitor as its ShellExecute monitor, which
// places windows that let Windows pick their position. Programs that restore
// their own last position (Chrome, Explorer) appear elsewhere, so their new
// window is moved once komorebi manages it. The new window is found in
// komorebi's state, not by foreground: Windows does not always activate it.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;

static class Launcher {
  [StructLayout(LayoutKind.Sequential)]
  struct Point {
    public int X, Y;
  }

  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
  struct ShellExecuteInfo {
    public int cbSize;
    public uint fMask;
    public IntPtr hwnd;
    public string lpVerb, lpFile, lpParameters, lpDirectory;
    public int nShow;
    public IntPtr hInstApp, lpIDList;
    public string lpClass;
    public IntPtr hkeyClass;
    public uint dwHotKey;
    public IntPtr hMonitor;
    public IntPtr hProcess;
  }

  [DllImport("user32.dll")]
  static extern bool GetCursorPos(out Point p);
  [DllImport("user32.dll")]
  static extern IntPtr MonitorFromPoint(Point p, uint flags);
  [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
  static extern bool ShellExecuteEx(ref ShellExecuteInfo info);

  const uint MonitorDefaultToNearest = 2;
  const uint SeeMaskHMonitor = 0x00200000, SeeMaskFlagNoUi = 0x00000400;

  static int Main(string[] args) {
    if (args.Length == 0)
      return 2;
    string file = args[0];
    string exe = Path.GetFileName(file);

    // Focus the cursor's monitor in komorebi too: its index is where the new
    // window belongs. The state is parsed only after the launch, because the
    // parser's first use costs ~0.3 s.
    Komorebic("focus-monitor-at-cursor");
    string before = Komorebic("state");

    Point cursor;
    GetCursorPos(out cursor);
    var info = new ShellExecuteInfo {
      fMask = SeeMaskHMonitor | SeeMaskFlagNoUi,
      lpFile = file,
      lpParameters = JoinArguments(args, 1),
      nShow = 1,
      hMonitor = MonitorFromPoint(cursor, MonitorDefaultToNearest),
    };
    info.cbSize = Marshal.SizeOf(info);
    if (!ShellExecuteEx(ref info))
      return 1;

    var state = Parse(before);
    if (state == null || (bool)state["is_paused"])
      return 0; // komorebi is down, or paused for game mode
    int target = (int)Get(state, "monitors")["focused"];
    var known = new HashSet<long>();
    foreach (var w in Windows(state, exe))
      known.Add(w.Key);

    // Give komorebi up to 5 s to manage the new window, then move it if it
    // landed elsewhere. komorebi focuses a window it has just tiled, and
    // move-to-monitor acts on the focused one.
    for (int i = 0; i < 100; i++) {
      Thread.Sleep(50);
      state = Parse(Komorebic("state"));
      if (state == null)
        return 0;
      var fresh = new List<KeyValuePair<long, int>>();
      foreach (var w in Windows(state, exe))
        if (!known.Contains(w.Key))
          fresh.Add(w);
      if (fresh.Count == 0)
        continue;
      if (fresh.Count == 1 && fresh[0].Value != target &&
          FocusedHwnd(state) == fresh[0].Key) {
        Komorebic("move-to-monitor " + target);
        // komorebi skips re-laying out a window whose resize animation (for the
        // brief arrival above) has not moved it yet, so the monitor the new
        // window left can keep its windows half-sized. Retile once that
        // animation (220 ms in komorebi.json) is over.
        Thread.Sleep(500);
        Komorebic("retile");
      }
      return 0;
    }
    return 0;
  }

  // komorebi's state, parsed into dictionaries (objects) and object arrays
  // (arrays).
  static Dictionary<string, object> Parse(string json) {
    var serializer = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
    return (Dictionary<string, object>)serializer.DeserializeObject(json);
  }

  static Dictionary<string, object> Get(object o, string key) {
    return (Dictionary<string, object>)((Dictionary<string, object>)o)[key];
  }
  static object[] Elements(object o, string key) {
    return (object[])Get(o, key)["elements"];
  }
  static object Focused(object o, string key) {
    object[] e = Elements(o, key);
    return e.Length == 0 ? null : e[(int)Get(o, key)["focused"]];
  }
  static long Hwnd(object window) {
    return Convert.ToInt64(((Dictionary<string, object>)window)["hwnd"]);
  }

  // Tiled windows of one program in komorebi's state, as (hwnd, monitor index).
  static IEnumerable<KeyValuePair<long, int>>
  Windows(Dictionary<string, object> state, string exe) {
    object[] monitors = Elements(state, "monitors");
    for (int m = 0; m < monitors.Length; m++)
      foreach (object workspace in Elements(monitors[m], "workspaces"))
        foreach (object container in Elements(workspace, "containers"))
          foreach (object window in Elements(container, "windows"))
            if (exe.Equals(
                    ((Dictionary<string, object>)window)["exe"] as string,
                    StringComparison.OrdinalIgnoreCase))
              yield return new KeyValuePair<long, int>(Hwnd(window), m);
  }

  static long FocusedHwnd(Dictionary<string, object> state) {
    object workspace = Focused(Focused(state, "monitors"), "workspaces");
    object container =
        workspace == null ? null : Focused(workspace, "containers");
    object window = container == null ? null : Focused(container, "windows");
    return window == null ? 0 : Hwnd(window);
  }

  static string Komorebic(string arguments) {
    var start = new ProcessStartInfo("komorebic.exe", arguments) {
      UseShellExecute = false,
      CreateNoWindow = true,
      RedirectStandardOutput = true,
      StandardOutputEncoding = Encoding.UTF8,
    };
    using (var process = Process.Start(start)) {
      string output = process.StandardOutput.ReadToEnd();
      process.WaitForExit();
      return output;
    }
  }

  static string JoinArguments(string[] args, int first) {
    var parts = new List<string>();
    for (int i = first; i < args.Length; i++)
      parts.Add(args[i].IndexOf(' ') >= 0 ? "\"" + args[i] + "\"" : args[i]);
    return string.Join(" ", parts);
  }
}
